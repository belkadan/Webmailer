/*******************************************************************************
 Copyright (c) 2006-2011 Jordy Rose
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 
 Except as contained in this notice, the name(s) of the above copyright holders
 shall not be used in advertising or otherwise to promote the sale, use or other
 dealings in this Software without prior authorization.
*******************************************************************************/

#import "WebmailerPref.h"
#import "ImageForStateTransformer.h"
#import "AutosortArrayController.h"
#import "NSDictionary+NSArray+PlistMutableCopy.h"
#import "WebmailerShared.h"

/*!
 * The main controller for the Webmailer preferences pane, which is mainly handling
 * the list of configurations. Webmailer defaults are saved in the
 * "com.belkadan.Webmailer" domain.
 *
 * @truename ComBelkadanWebmailer_PrefPane
 */
@implementation WebmailerPref
- (id)initWithBundle:(NSBundle *)bundle
{
	if (self = [super initWithBundle:bundle])
	{
		defaults = [[DefaultsDomain domainForName:WebmailerAppDomain] retain];
		if ([defaults objectForKey:WebmailerCurrentDestinationKey] == nil)
		{
			// First time setup
			NSDictionary *initialDefaults = [[NSDictionary alloc] initWithContentsOfFile:[bundle pathForResource:@"default" ofType:@"plist"]];
			[defaults beginTransaction];
			[defaults setDictionary:initialDefaults];
			[defaults endTransaction];
			[initialDefaults release];
		}
		
		NSURL *daemonURL = [[NSURL alloc] initFileURLWithPath:[bundle pathForResource:@"Webmailer" ofType:@"app"]];
		LSRegisterURL((CFURLRef) daemonURL, false);
		[daemonURL release];
		
		configurations = [[defaults objectForKey:WebmailerConfigurationsKey] mutableDeepPropertyListCopy];

		NSImage *activeImage;
#if defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_10_6 <= MAC_OS_X_VERSION_MAX_ALLOWED
		if (&NSImageNameStatusAvailable != NULL)
		{
			activeImage = [[NSImage imageNamed:NSImageNameStatusAvailable] copy];
		}
		else
#endif
		{
			activeImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:@"active"]];
		}

		ImageForStateTransformer *transformer = [[ImageForStateTransformer alloc] initWithTrueImage:activeImage falseImage:nil];
		[NSValueTransformer setValueTransformer:transformer forName:@"ImageForState"];
		[transformer release];
		[activeImage release];
	}
	return self;
}

- (void)mainViewDidLoad
{
	NSSortDescriptor *sortByName = [[NSSortDescriptor alloc] initWithKey:WebmailerDestinationNameKey ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
	NSSortDescriptor *sortByDestination = [[NSSortDescriptor alloc] initWithKey:WebmailerDestinationURLKey ascending:YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortByName, sortByDestination, nil];
	[(NSArrayController *)[configurationTable dataSource] setSortDescriptors:sortDescriptors];
	[sortDescriptors release];
	[sortByName release];
	[sortByDestination release];
	
	[configurationTable setDoubleAction:@selector(apply:)];
	[configurationTable setTarget:self];
}

/*!
 * Sets the selected configuration as the active destination, and saves this into
 * the preferences. The active configuration is marked in two ways; the "active"
 * key in each configuration's data dictionary, and the global "currentDestination"
 * key. This is to allow quick access for the URL handler application while
 * maintaining a tabular view in the preference pane. It also provides a bit of
 * redundancy, useful for finding corrupted preferences and saving data.
 */
- (IBAction)apply:(id)sender
{
	NSInteger row = [configurationTable clickedRow];
	if (row < 0) row = [configurationTable selectedRow];
	
	if (row >= 0)
	{
		NSArrayController *configurationController = (NSArrayController *)[configurationTable dataSource];
		[[configurationController arrangedObjects] setValue:[NSNumber numberWithBool:NO] forKey:WebmailerDestinationIsActiveKey];
		
		id newActiveDestination = [[configurationController arrangedObjects] objectAtIndex:row];
		[newActiveDestination setValue:[NSNumber numberWithBool:YES] forKey:WebmailerDestinationIsActiveKey];

		NSString *currentDestination = [newActiveDestination valueForKey:WebmailerDestinationURLKey];
		[defaults beginTransaction];
			[defaults setObject:currentDestination forKey:WebmailerCurrentDestinationKey];
			[defaults setObject:configurations forKey:WebmailerConfigurationsKey];
		[defaults endTransaction];
	}
}

/*!
 * Saves changes to the name or destination of a configuration back to user defaults.
 * If the row that was changed was the active configuration,
 * also refreshes the "currentDestination" key.
 */
- (IBAction)update:(id)sender
{
	[defaults beginTransaction];
	[defaults setObject:configurations forKey:WebmailerConfigurationsKey];
	
	NSInteger row = [configurationTable selectedRow];
	NSArray *arrangedConfigurations = [(NSArrayController *)[configurationTable dataSource] arrangedObjects];
		
	if (row >= 0 && [[[arrangedConfigurations objectAtIndex:row] objectForKey:WebmailerDestinationIsActiveKey] boolValue])
	{
		NSString *currentDestination = [[arrangedConfigurations objectAtIndex:row] objectForKey:WebmailerDestinationURLKey];
		[defaults setObject:currentDestination forKey:WebmailerCurrentDestinationKey];
	}
	
	[defaults endTransaction];
}

/*!
 * Adds a new configuration to the list, and tells the table view to edit the name
 * of this configuration (name column, first cell).
 */
- (IBAction)add:(id)sender
{
	NSMutableDictionary *newConfiguration = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
		[NSNumber numberWithBool:NO], WebmailerDestinationIsActiveKey,
		@"", WebmailerDestinationNameKey,
		@"", WebmailerDestinationURLKey,
		nil];
	[(NSArrayController *)[configurationTable dataSource] insertObject:newConfiguration atArrangedObjectIndex:0];
	[newConfiguration release];
	
	[configurationTable selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
	[configurationTable editColumn:1 row:0 withEvent:nil select:YES];
}

#pragma mark -

// This family of methods is for KVC on the smart app choosing preference.
// Notice there is no backing variable.

/*!
 * Returns NO if the Webmailer daemon should attempt to intelligently
 * pick which app to handle a destination with. Careful of the negative!
 *
 * By default, Webmailer will try to be smart as of version 1.2.
 */
- (BOOL)appChoosingDisabled
{
	return [[defaults objectForKey:WebmailerDisableAppChoosingKey] boolValue];
}

/*!
 * Sets whether or not the Webmailer daemon should attempt to intelligently
 * pick which app to handle a destination with.
 *
 * Setting this to YES will emulate the behavior of Webmailer before version 1.2.
 */
- (void)setAppChoosingDisabled:(BOOL)disableAppChoosing
{
	[defaults setObject:[NSNumber numberWithBool:disableAppChoosing] forKey:WebmailerDisableAppChoosingKey];
}

#pragma mark -

// This family of methods is for KVC on the configurations list
// Only -remove... is interesting, because it has to save its changes
// (-insert... is always paired with an edit in Webmailer, which triggers a save anyway)

- (NSUInteger)countOfConfigurations { return [configurations count]; }
- (NSArray *)configurationsAtIndexes:(NSIndexSet *)indexes { return [configurations objectsAtIndexes:indexes]; }
- (void)getConfigurations:(id *)buffer range:(NSRange)range { [configurations getObjects:buffer range:range]; }
- (void)insertConfigurations:(NSArray *)newConfigurations atIndexes:(NSIndexSet *)indexes { [configurations insertObjects:newConfigurations atIndexes:indexes]; }

- (void)removeConfigurationsAtIndexes:(NSIndexSet *)indexes
{
	[configurations removeObjectsAtIndexes:indexes];
	[defaults setObject:configurations forKey:WebmailerConfigurationsKey];
}

- (void)dealloc
{
	[configurations release];
	[defaults release];
	[super dealloc];
}

@end
