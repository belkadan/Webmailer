/*******************************************************************************
 Copyright (c) 2006-2009 Jordy Rose
 
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
 * the list of configurations. Nearly all preferences are saved with the CFPreferences
 * API, in order to save to the "com.belkadan.Webmailer" domain.
 *
 * @truename ComBelkadanWebmailer_PrefPane
 */
@implementation WebmailerPref
- (id)initWithBundle:(NSBundle *)bundle
{
	if (self = [super initWithBundle:bundle])
	{
		NSArray *immutableConfigurations = (NSArray *) CFPreferencesCopyAppValue((CFStringRef) WebmailerConfigurationsKey, (CFStringRef) WebmailerAppDomain);
		if (immutableConfigurations == nil)
		{
			// First time setup
			NSDictionary *initialDefaults = [[NSDictionary alloc] initWithContentsOfFile:[bundle pathForResource:@"default" ofType:@"plist"]];
			CFPreferencesSetMultiple((CFDictionaryRef) initialDefaults, NULL, (CFStringRef) WebmailerAppDomain, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
			CFPreferencesAppSynchronize((CFStringRef) WebmailerAppDomain);
			
			immutableConfigurations = (NSArray *) CFPreferencesCopyAppValue((CFStringRef) WebmailerConfigurationsKey, (CFStringRef) WebmailerAppDomain);
			[initialDefaults release];
		}
		
		NSURL *daemonURL = [[NSURL alloc] initWithString:[bundle pathForResource:@"Webmailer" ofType:@"app"]];
		LSRegisterURL((CFURLRef) daemonURL, false);
		[daemonURL release];
		
		configurations = [immutableConfigurations mutableDeepPropertyListCopy];
		CFRelease(immutableConfigurations);

		NSImage *activeImage;
#if defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_10_6 <= MAC_OS_X_VERSION_MAX_ALLOWED
		activeImage = [[NSImage imageNamed:@"NSStatusAvailable"] copy]; // don't use the constant to avoid crash on Tiger
		if (!activeImage)
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
		CFPreferencesSetAppValue((CFStringRef) WebmailerCurrentDestinationKey, currentDestination, (CFStringRef) WebmailerAppDomain);
		CFPreferencesSetAppValue((CFStringRef) WebmailerConfigurationsKey, configurations, (CFStringRef) WebmailerAppDomain);
		
		CFPreferencesAppSynchronize((CFStringRef) WebmailerAppDomain);
	}
}

/*!
 * Saves changes to the name or destination of a configuration back to user defaults,
 * using CFPreferences. If the row that was changed was the active configuration,
 * also refreshes the "currentDestination" key.
 */
- (IBAction)update:(id)sender
{
	CFPreferencesSetAppValue((CFStringRef) WebmailerConfigurationsKey, configurations, (CFStringRef) WebmailerAppDomain);
	
	NSInteger row = [configurationTable selectedRow];
	NSArray *arrangedConfigurations = [(NSArrayController *)[configurationTable dataSource] arrangedObjects];
		
	if (row >= 0 && [[[arrangedConfigurations objectAtIndex:row] objectForKey:WebmailerDestinationIsActiveKey] boolValue])
	{
		NSString *currentDestination = [[arrangedConfigurations objectAtIndex:row] objectForKey:WebmailerDestinationURLKey];
		CFPreferencesSetAppValue((CFStringRef) WebmailerCurrentDestinationKey, currentDestination, (CFStringRef) WebmailerAppDomain);
	}
	
	CFPreferencesAppSynchronize((CFStringRef) WebmailerAppDomain);
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
	CFPreferencesSetAppValue((CFStringRef) WebmailerConfigurationsKey, configurations, (CFStringRef) WebmailerAppDomain);
	CFPreferencesAppSynchronize((CFStringRef) WebmailerAppDomain);
}

- (void)dealloc
{
	[configurations release];
	[super dealloc];
}

@end
