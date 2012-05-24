#import "WebmailerPref.h"
#import "AutosortArrayController.h"
#import "DefaultsDomain.h"
#import "EditTrackingTableView.h"
#import "ImageForStateTransformer.h"
#import "NSDictionary+NSArray+PlistMutableCopy.h"
#import "URLHandlerController.h"
#import "WebmailerShared.h"

static NSString *const kAppleMailID = @"com.apple.mail";

@implementation ComBelkadanWebmailer_PrefPane
- (id)initWithBundle:(NSBundle *)bundle
{
	if (self = [super initWithBundle:bundle])
	{
		defaults = [[DefaultsDomain domainForName:WebmailerAppDomain] retain];
		if ([defaults objectForKey:WebmailerCurrentDestinationKey] == nil)
		{
			// First time setup
			NSDictionary *initialDefaults = [[NSDictionary alloc] initWithContentsOfFile:[bundle pathForResource:@"default" ofType:@"plist"]];
			[defaults setDictionary:initialDefaults];
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

	mailtoController.shouldFullRefresh = YES;
	[mailtoController setScheme:WebmailerMailtoScheme fallbackBundleID:kAppleMailID];
	[mailtoController addObserver:self forKeyPath:@"selectedBundleID" options:0 context:[WebmailerPref class]];
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
		[[configurationController arrangedObjects] setValue:nil forKey:WebmailerDestinationIsActiveKey];
		
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
		@"", WebmailerDestinationNameKey,
		@"", WebmailerDestinationURLKey,
		nil];

	// Avoid a save with manual KVO notifications.
	NSIndexSet *lastIndex = [NSIndexSet indexSetWithIndex:[configurations count]];
	[self willChange:NSKeyValueChangeInsertion valuesAtIndexes:lastIndex forKey:@"configurations"];
	[configurations addObject:newConfiguration];
	[self didChange:NSKeyValueChangeInsertion valuesAtIndexes:lastIndex forKey:@"configurations"];
	[newConfiguration release];
	
	[configurationTable selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
	[configurationTable editColumn:1 row:0 withEvent:nil select:YES];
}

#pragma mark -

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == [WebmailerPref class])
	{
		NSAssert(object == mailtoController, @"No other objects should be observed.");
		(void)LSSetDefaultHandlerForURLScheme((CFStringRef)WebmailerMailtoScheme, (CFStringRef)mailtoController.selectedBundleID);
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}

}

#pragma mark -

- (NSUInteger)countOfConfigurations { return [configurations count]; }
- (NSArray *)configurationsAtIndexes:(NSIndexSet *)indexes { return [configurations objectsAtIndexes:indexes]; }
- (void)getConfigurations:(id *)buffer range:(NSRange)range { [configurations getObjects:buffer range:range]; }

- (void)insertConfigurations:(NSArray *)newConfigurations atIndexes:(NSIndexSet *)indexes
{
	[configurations insertObjects:newConfigurations atIndexes:indexes];
	[defaults setObject:configurations forKey:WebmailerConfigurationsKey];
}

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
