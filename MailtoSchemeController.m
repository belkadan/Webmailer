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

//
//  MailtoSchemeController.m
//  Webmailer
//

#import "MailtoSchemeController.h"
#import "WebmailerShared.h"

static const NSSize emailAppIconSize = {16, 16};

@interface MailtoSchemeController (ComBelkadanWebmailer_Private)
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
	[self refreshEmailAppList:nil];
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
		// should only be called from the main thread, so don't worry about thread safety
		NSSortDescriptor *sortByTitle = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
		sortByTitleDescriptors = [[NSArray alloc] initWithObjects:sortByTitle, nil];
		[sortByTitle release];
	}

	NSMenu *menu = [[NSMenu alloc] init];
	NSMutableArray *menuItems = [[NSMutableArray alloc] init];
	NSMenuItem *item, *selectedItem = nil;

	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	NSString *currentIdentifier = (NSString *) LSCopyDefaultHandlerForURLScheme((CFStringRef) WebmailerMailtoScheme);
	NSArray *appIDs = (NSArray *) LSCopyAllHandlersForURLScheme((CFStringRef) WebmailerMailtoScheme);
	NSEnumerator *appIDEnum = [appIDs objectEnumerator];
	
	NSString *nextID, *nextPath, *nextName;
	NSImage *nextImage;
	
	while (nextID = [appIDEnum nextObject])
	{
		nextPath = [workspace absolutePathForAppBundleWithIdentifier:nextID];
		
		if (nextPath != nil)
		{
			nextName = [fileManager displayNameAtPath:nextPath];
			if (nextName == nil)
				nextName = nextID;
			
			nextImage = [workspace iconForFile:nextPath];
			[nextImage setSize:emailAppIconSize];
			
			item = [[NSMenuItem alloc] initWithTitle:nextName action:@selector(switchEmailApp:) keyEquivalent:@""];
			[item setRepresentedObject:nextID];
			[item setTarget:self];
			[item setImage:nextImage];
			
			[menuItems addObject:item];
			[item release];
			
			if ([nextID isEqual:currentIdentifier])
				selectedItem = item;
		}
	}
	
	[menuItems sortUsingDescriptors:sortByTitleDescriptors];
	NSEnumerator *menuItemEnum = [menuItems objectEnumerator];
	while (item = [menuItemEnum nextObject])
	{
		[menu addItem:item];
	}
	
	[menu addItem:[NSMenuItem separatorItem]];
	
	if (selectedItem == nil)
	{
		if (currentIdentifier != nil)
		{
			nextPath = [workspace absolutePathForAppBundleWithIdentifier:currentIdentifier];

			if (nextPath != nil)
			{
				nextName = [fileManager displayNameAtPath:nextPath];
				if (nextName == nil)
					nextName = currentIdentifier;
			
				nextImage = [workspace iconForFile:nextPath];
				[nextImage setSize:emailAppIconSize];
			}
			else
			{
				nextName = currentIdentifier;
				nextImage = nil;
			}
				
			selectedItem = [[NSMenuItem alloc] initWithTitle:nextName action:@selector(switchEmailApp:) keyEquivalent:@""];
			[selectedItem setRepresentedObject:nextID];
			[selectedItem setTarget:self];
			[selectedItem setImage:nextImage];
			
			[menu addItem:selectedItem];
			[selectedItem release];
		}
		else
		{
			selectedItem = [menu itemAtIndex:[menu indexOfItemWithRepresentedObject:AppleMailDomain]];
		}
	}
	
	NSMenuItem *chooseOtherItem = [[emailAppPopup lastItem] retain];
	[emailAppPopup removeItemAtIndex:([emailAppPopup numberOfItems] - 1)];
	[menu addItem:chooseOtherItem];
	[chooseOtherItem release];
	
	[emailAppPopup setMenu:menu];
	[emailAppPopup selectItem:selectedItem];
	
	[menu release];
	[menuItems release];
	
	CFRelease(appIDs);
	CFRelease(currentIdentifier);
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
	//NSLog(@"%@", [emailAppPopup selectedItem]);

	static NSArray *appTypes = nil; // no need to worry about thread-safety -- this method is only called from the main thread
	if (appTypes == nil) appTypes = [[NSArray alloc] initWithObjects:@"app", nil];

	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setTreatsFilePackagesAsDirectories:NO];
	[openPanel setResolvesAliases:YES];
	[openPanel setAllowsMultipleSelection:NO];
	
	[openPanel beginSheetForDirectory:nil file:nil types:appTypes modalForWindow:[emailAppPopup window] modalDelegate:self didEndSelector:@selector(chooseAppPanelDidEnd:returnCode:contextInfo:) contextInfo:NULL];
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
		NSString *bundleID = [bundle bundleIdentifier];
		LSSetDefaultHandlerForURLScheme((CFStringRef) WebmailerMailtoScheme, (CFStringRef) bundleID);
		
		NSURL *appURL = [openPanel URL];
		NSString *appName;
		LSCopyDisplayNameForURL((CFURLRef) appURL, (CFStringRef *) &appName);
		
		if (appName == nil) appName = [bundleID retain];
		NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:appName action:@selector(switchEmailApp:) keyEquivalent:@""];
		[item setRepresentedObject:bundleID];
		[item setTarget:self];
		
		NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
		[icon setSize:emailAppIconSize];
		[item setImage:icon];
		
		[[emailAppPopup menu] insertItem:item atIndex:[emailAppPopup numberOfItems] - 3];
		[emailAppPopup selectItem:item];
		
		[appName release];
		[item release];
		[bundle release];
	}
	else
	{
		NSString *currentIdentifier = (NSString *) LSCopyDefaultHandlerForURLScheme((CFStringRef) WebmailerMailtoScheme);
		[emailAppPopup selectItemAtIndex:[emailAppPopup indexOfItemWithRepresentedObject:currentIdentifier]];
		CFRelease(currentIdentifier);
	}
}
@end
