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

//
//  MailtoSchemeController.m
//  Webmailer
//

#import "MailtoSchemeController.h"
#import "WebmailerShared.h"

static const NSSize emailAppIconSize = {16, 16};

@interface MailtoSchemeController ()
- (void)chooseAppPanelDidEnd:(NSOpenPanel *)openPanel returnCode:(NSInteger)returnCode contextInfo:(void *)unused;
@end

/*!
 * Manages the e-mail application selection. This handy feature unfortunately relies
 * on the Tiger version of LaunchServices and thus only appears in the Tiger version
 * of Webmailer. The class can display the possible choices for the mailto scheme and
 * allows the user to choose one of them, or another one not on the list.
 *
 * @truename ComBelkadanWebmailer_MailtoSchemeController
 * @since Mac OS X v10.4
 */
@implementation MailtoSchemeController
- (void)awakeFromNib
{
	numberOfExtraItems = [emailAppPopup numberOfItems];
	[self refreshEmailAppList:nil];
}

- (NSMenuItem *)menuItemForApplicationWithID:(NSString *)identifier name:(NSString *)name icon:(NSImage *)icon
{
	NSAssert(identifier, @"Must have an identifier.");
	if (!name) name = identifier;
	
	NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:name action:@selector(switchEmailApp:) keyEquivalent:@""];
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
		[icon setSize:emailAppIconSize];
	}
	else
	{
		name = identifier;
		icon = nil;
	}

	return [self menuItemForApplicationWithID:identifier name:name icon:icon];
}

/*!
 * Sets up the e-mail application list. This is accomplished using the LaunchServices
 * functions <code>LSCopyDefaultHandlerForURLScheme()</code> and <code>LSCopyAllHandlersForURLScheme()</code>.
 * Both of these functions return bundle identifiers, which are then looked up using
 * NSFileManager and NSWorkspace. The final menu item has the icon and display name
 * of the given application, and all the menu items are sorted and placed in a
 * popup button menu. At the bottom of the list is the "Other..." choice, allowing
 * the user to pick another option if they so choose.
 */
- (IBAction)refreshEmailAppList:(id)sender
{
	static NSArray *sortByTitleDescriptors = nil;
	if (sortByTitleDescriptors == nil)
	{
		// This is not thread-safe, but in 10.5 locking to protect this is overkill.
		// Currently IBActions are always called on the main thread anyway, but
		// if that changes we don't want to crash. The one-time leak is preferable.
		NSSortDescriptor *sortByTitle = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
		sortByTitleDescriptors = [[NSArray alloc] initWithObjects:sortByTitle, nil];
		[sortByTitle release];
	}
	
	NSMenu *menu = [[NSMenu alloc] init];
	NSMutableArray *menuItems = [[NSMutableArray alloc] init];
	NSMenuItem *selectedItem = nil;

	NSString *currentIdentifier = (NSString *) LSCopyDefaultHandlerForURLScheme((CFStringRef) WebmailerMailtoScheme);
	NSArray *appIDs = (NSArray *) LSCopyAllHandlersForURLScheme((CFStringRef) WebmailerMailtoScheme);
	
	if (!currentIdentifier)
	{
		currentIdentifier = (NSString *) CFRetain((CFStringRef) AppleMailDomain);
	}
	if (!appIDs)
	{
		appIDs = (NSArray *) CFArrayCreate(NULL, (const void **)&currentIdentifier, 1, &kCFTypeArrayCallBacks);
	}
	
	for (NSString *nextID in appIDs)
	{
		NSMenuItem *item = [self menuItemForApplicationWithID:nextID mustExist:YES];
		[menuItems addObject:item];

		if ([nextID isEqual:currentIdentifier])
			selectedItem = item;
	}
	CFRelease(appIDs);

	[menuItems sortUsingDescriptors:sortByTitleDescriptors];
	for (NSMenuItem *item in menuItems)
	{
		[menu addItem:item];
	}
	[menuItems release];
	
	[menu addItem:[NSMenuItem separatorItem]];
	
	if (selectedItem == nil)
	{
		selectedItem = [self menuItemForApplicationWithID:currentIdentifier mustExist:NO];
		[menu addItem:selectedItem];
	}
	CFRelease(currentIdentifier);

	NSInteger extraItemIndex = [emailAppPopup numberOfItems] - numberOfExtraItems;
	for (NSInteger i = 0; i < numberOfExtraItems; ++i) {
		NSMenuItem *extraItem = [[emailAppPopup itemAtIndex:extraItemIndex] retain];
		[emailAppPopup removeItemAtIndex:extraItemIndex];
		[menu addItem:extraItem];
		[extraItem release];
	}
	
	[emailAppPopup setMenu:menu];
	[emailAppPopup selectItem:selectedItem];
	
	[menu release];
}

/*!
 * Switches to the selected application, using <code>LSSetDefaultHandlerForURLScheme()</code>.
 * The application's bundle identifier must be the sender's <code>representedObject</code>.
 * If there is no represented object, the application chooser is opened.
 *
 * @see #chooseOtherEmailApp:
 */
- (IBAction)switchEmailApp:(id)sender
{
	NSString *bundleID = [sender representedObject];
	if (bundleID != nil)
		LSSetDefaultHandlerForURLScheme((CFStringRef) WebmailerMailtoScheme, (CFStringRef) bundleID);
	else
		[self chooseOtherEmailApp:sender];
}

/*!
 * Allows the user to choose a custom e-mail handler, using an open panel.
 *
 * @see #chooseAppPanelDidEnd:returnCode:contextInfo:
 */
- (IBAction)chooseOtherEmailApp:(id)sender
{

	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setTreatsFilePackagesAsDirectories:NO];
	[openPanel setResolvesAliases:YES];
	[openPanel setAllowsMultipleSelection:NO];
	
	[openPanel beginSheetForDirectory:nil file:nil types:[NSArray arrayWithObject:@"app"] modalForWindow:[emailAppPopup window] modalDelegate:self didEndSelector:@selector(chooseAppPanelDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

/*!
 * Called when the user selects an application (or cancels) from the open panel.
 * If the <code>returnCode</code> is "OK", then the application is added to the
 * popup menu and registered as the default handler with <code>LSSetDefaultHandlerForURLScheme()</code>.
 *
 * @see #chooseOtherEmailApp:
 */
- (void)chooseAppPanelDidEnd:(NSOpenPanel *)openPanel returnCode:(NSInteger)returnCode contextInfo:(void *)unused
{
	if (returnCode == NSOKButton)
	{
		NSString *path = [openPanel filename];
		NSBundle *bundle = [[NSBundle alloc] initWithPath:path];
		NSString *bundleID = [[bundle bundleIdentifier] copy];
		LSSetDefaultHandlerForURLScheme((CFStringRef) WebmailerMailtoScheme, (CFStringRef) bundleID);
		[bundle release];
		
		NSURL *appURL = [openPanel URL];
		NSString *appName;
		LSCopyDisplayNameForURL((CFURLRef) appURL, (CFStringRef *) &appName);

		NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
		[icon setSize:emailAppIconSize];

		NSMenuItem *item = [self menuItemForApplicationWithID:bundleID name:appName icon:icon];
		CFRelease(appName);
		
		[[emailAppPopup menu] insertItem:item atIndex:[emailAppPopup numberOfItems] - numberOfExtraItems];
		[emailAppPopup selectItem:item];
	}
	else
	{
		NSString *currentIdentifier = (NSString *) LSCopyDefaultHandlerForURLScheme((CFStringRef) WebmailerMailtoScheme);
		[emailAppPopup selectItemAtIndex:[emailAppPopup indexOfItemWithRepresentedObject:currentIdentifier]];
		CFRelease(currentIdentifier);
	}
}
@end
