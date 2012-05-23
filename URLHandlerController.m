#import "URLHandlerController.h"

static const NSSize kIconSize = {16, 16};

@interface ComBelkadanWebmailer_URLHandlerController ()
- (void)chooseAppPanelDidEnd:(NSOpenPanel *)openPanel returnCode:(NSInteger)returnCode contextInfo:(void *)unused;

@property(readwrite,copy) NSString *scheme;
@property(readwrite,copy) NSString *fallbackBundleID;
@end


@implementation ComBelkadanWebmailer_URLHandlerController
@synthesize selectedBundleID, fallbackBundleID, scheme, shouldFullRefresh;

- (void)awakeFromNib
{
	numberOfExtraItems = [popup numberOfItems];
	if (self.scheme) [self refresh:nil];
}

- (void)dealloc
{
	[scheme release];
	[fallbackBundleID release];
	[selectedBundleID release];
	[super dealloc];
}

- (void)setScheme:(NSString *)newScheme fallbackBundleID:(NSString *)fallback
{
	NSParameterAssert(newScheme != nil);
	NSParameterAssert(fallback != nil);

	if (![self.scheme isEqual:newScheme] || ![self.fallbackBundleID isEqual:fallback])
	{
		self.scheme = newScheme;
		self.fallbackBundleID = fallback;
		[self refresh:nil];
	}
}

#pragma mark -

- (NSMenuItem *)menuItemForApplicationWithID:(NSString *)identifier name:(NSString *)name icon:(NSImage *)icon
{
	NSAssert(identifier, @"Must have an identifier.");
	if (!name) name = identifier;
	
	NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:name action:@selector(chooseApp:) keyEquivalent:@""];
	[item setRepresentedObject:identifier];
	[item setTarget:self];
	[item setImage:icon];
	
	return [item autorelease];	
}

- (NSMenuItem *)menuItemForApplicationWithID:(NSString *)identifier mustExist:(BOOL)mustExist
{
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	
	NSString *path = [workspace absolutePathForAppBundleWithIdentifier:identifier];
	if (!path && mustExist) return nil;
	
	NSString *name;
	NSImage *icon;
	
	if (path != nil)
	{
		name = [[NSFileManager defaultManager] displayNameAtPath:path];		
		icon = [workspace iconForFile:path];
		[icon setSize:kIconSize];
	}
	else
	{
		name = identifier;
		icon = nil;
	}
	
	return [self menuItemForApplicationWithID:identifier name:name icon:icon];
}

- (IBAction)refresh:(id)sender
{
	static NSArray *sortByTitleDescriptors = nil;
	if (sortByTitleDescriptors == nil)
	{
		// This is not thread-safe, but locking to protect this is overkill.
		// The possible one-time leak is preferable.
		NSSortDescriptor *sortByTitle = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
		sortByTitleDescriptors = [[NSArray alloc] initWithObjects:sortByTitle, nil];
		[sortByTitle release];
	}
	
	NSMenu *menu = [[NSMenu alloc] init];
	NSMutableArray *menuItems = [[NSMutableArray alloc] init];
	NSMenuItem *selectedItem = nil;
	
	// Get all the relevant applications.
	NSString *currentIdentifier = self.selectedBundleID;
	if (!currentIdentifier || self.shouldFullRefresh)
	{
		CFStringRef defaultHandler = LSCopyDefaultHandlerForURLScheme((CFStringRef) self.scheme);
		currentIdentifier = [NSMakeCollectable(defaultHandler) autorelease];
		if (!currentIdentifier) currentIdentifier = self.fallbackBundleID;

		self.selectedBundleID = currentIdentifier;
	}

	NSArray *appIDs = (NSArray *) LSCopyAllHandlersForURLScheme((CFStringRef) self.scheme);
	if (!appIDs)
	{
		appIDs = (NSArray *) CFArrayCreate(NULL, (const void **)&currentIdentifier, 1, &kCFTypeArrayCallBacks);
	}
	
	// Create menu items for all the applications.
	for (NSString *nextID in appIDs)
	{
		NSMenuItem *item = [self menuItemForApplicationWithID:nextID mustExist:YES];
		if (item)
		{
			[menuItems addObject:item];
			
			// LaunchServices returns lowercase identifiers!
			if ([nextID compare:currentIdentifier options:NSCaseInsensitiveSearch] == NSOrderedSame)
			{
				selectedItem = item;			
			}			
		}
	}
	CFRelease(appIDs);
	
	// Sort the menu items, then add them to the menu.
	[menuItems sortUsingDescriptors:sortByTitleDescriptors];
	for (NSMenuItem *item in menuItems)
	{
		[menu addItem:item];
	}
	[menu addItem:[NSMenuItem separatorItem]];
	[menuItems release];
	
	// If we happen to have a selected item that didn't show up in LaunchServices,
	// add it after the separator.
	if (selectedItem == nil)
	{
		selectedItem = [self menuItemForApplicationWithID:currentIdentifier mustExist:NO];
		[menu addItem:selectedItem];
	}

	// Transfer over any non-app items from the old menu.
	NSInteger extraItemIndex = [popup numberOfItems] - numberOfExtraItems;
	for (NSInteger i = 0; i < numberOfExtraItems; ++i) {
		NSMenuItem *extraItem = [[popup itemAtIndex:extraItemIndex] retain];
		[popup removeItemAtIndex:extraItemIndex];
		[menu addItem:extraItem];
		[extraItem release];
	}
	
	// Finally, put the new menu in place on the popup button.
	[popup setMenu:menu];
	[popup selectItem:selectedItem];
	
	[menu release];
}

#pragma mark -

- (void)setSelectedBundleID:(NSString *)newID
{
	[selectedBundleID autorelease];
	selectedBundleID = [newID copy];
	[popup selectItemAtIndex:[popup indexOfItemWithRepresentedObject:selectedBundleID]];
}

- (IBAction)chooseApp:(id)sender
{
	self.selectedBundleID = [sender representedObject];
}

- (IBAction)chooseOther:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setResolvesAliases:YES];
	[openPanel setAllowsMultipleSelection:NO];
	
	[openPanel beginSheetForDirectory:nil file:nil types:[NSArray arrayWithObject:@"app"] modalForWindow:[popup window] modalDelegate:self didEndSelector:@selector(chooseAppPanelDidEnd:returnCode:contextInfo:) contextInfo:NULL];	
}

- (void)chooseAppPanelDidEnd:(NSOpenPanel *)openPanel returnCode:(NSInteger)returnCode contextInfo:(void *)unused
{
	if (returnCode == NSOKButton)
	{
		NSString *path = [openPanel filename];

		NSBundle *bundle = [[NSBundle alloc] initWithPath:path];
		NSString *bundleID = [bundle bundleIdentifier];

		NSString *appName = [[NSFileManager defaultManager] displayNameAtPath:path];
		NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
		[icon setSize:kIconSize];		

		NSMenuItem *item = [self menuItemForApplicationWithID:bundleID name:appName icon:icon];
		
		[[popup menu] insertItem:item atIndex:[popup numberOfItems] - numberOfExtraItems];

		self.selectedBundleID = bundleID;
		[bundle release];
	}
	else
	{
		[popup selectItemAtIndex:[popup indexOfItemWithRepresentedObject:self.selectedBundleID]];
	}
}

@end
