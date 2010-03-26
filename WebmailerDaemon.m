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
//  WebmailerDaemon.m
//  Webmailer
//

#import "WebmailerDaemon.h"
#import "WebmailerShared.h"
#import "ImageForStateTransformer.h"


#if defined(MAC_OS_X_VERSION_10_5) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5
#import <ScriptingBridge/ScriptingBridge.h>

#if defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6
@interface WebmailerDaemon () <SBApplicationDelegate>
@end
#endif

@interface SystemPreferencesApplication : SBApplication
- (void)setCurrentPane:(SBObject *)currentPane;
- (SBObject *)currentPane;
- (SBElementArray *)panes;
@end

@interface TerminalApplication : SBApplication
- (SBObject *)doScript:(NSString *)script in:(id)tabOrWindow;
@end
#endif


// to stop warnings on pre-10.6 builds
@interface NSEvent (ComBelkadanWebmailer_NoWarn)
+ (NSUInteger)modifierFlags;
@end


@interface WebmailerDaemon (ComBelkadanWebmailer_Private)
- (NSString *)replacePlaceholdersInDestinationPrototype:(NSString *)destinationPrototype;
@end

#pragma mark -

/*!
 * The central controller for the faceless Webmailer application, tucked away inside
 * the preference pane bundle. WebmailerDaemon's entire purpose is to launch, respond
 * to a single Apple Event (GetURL, with a mailto: URL), and quit. If the application
 * is launched before the preference pane has ever been opened (an unlikely event),
 * the preference pane is opened so that the user can configure the settings.
 * <br/>
 * However, should the shift key be held down when Webmailer launches, the user
 * gets to choose which destination URL to use, via a small window that pops up
 * in the center of the screen. After this choice, the evaluation of the URL
 * continues as before.
 * <br/>
 * Why does Webmailer quit, instead of just remaining open? Well, if it didn't,
 * the user might have some trouble if they wanted to uninstall it (hopefully that
 * wouldn't happen anyway). They'd have to log out and log back in first, because
 * there's no way to actually quit it (well, besides Activity Monitor or kill).
 * As far as I can tell there's no significant time lag. (This does make the name
 * "daemon" less applicable, but the behavior of a faceless app still applies).
 */
@implementation WebmailerDaemon
- (void)awakeFromNib
{
	NSAppleEventManager *aevtManager = [NSAppleEventManager sharedAppleEventManager];
	[aevtManager setEventHandler:self andSelector:@selector(handleGetURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
	
	showConfigurationList = NO;
	mailtoURL = nil;
	
	if ([[NSUserDefaults standardUserDefaults] objectForKey:WebmailerCurrentDestinationKey] == nil)
	{
		[self openPreferencePane:nil];
	}

	NSImage *activeImage;
#if defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_10_6 <= MAC_OS_X_VERSION_MAX_ALLOWED
	activeImage = [[NSImage imageNamed:@"NSStatusAvailable"] copy]; // don't use the constant to avoid crash on Tiger
	if (!activeImage)
#endif
	{
		activeImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForImageResource:@"active"]];
	}

	ImageForStateTransformer *transformer = [[ImageForStateTransformer alloc] initWithTrueImage:activeImage falseImage:nil];
	[NSValueTransformer setValueTransformer:transformer forName:@"ImageForState"];
	[transformer release];
	[activeImage release];

	NSSortDescriptor *sortByName = [[NSSortDescriptor alloc] initWithKey:WebmailerDestinationNameKey ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
	NSSortDescriptor *sortByDestination = [[NSSortDescriptor alloc] initWithKey:WebmailerDestinationURLKey ascending:YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortByName, sortByDestination, nil];
	[configurationController setSortDescriptors:sortDescriptors];
	[sortDescriptors release];
	[sortByName release];
	[sortByDestination release];
	
	[configurationTable setDoubleAction:@selector(confirmConfiguration:)];
	[configurationTable setTarget:self];
	
	// quit if no incoming event after 30s
	[NSTimer scheduledTimerWithTimeInterval:30 target:NSApp selector:@selector(terminate:) userInfo:nil repeats:NO];
}

/*!
 * Respond to a GetURL Apple Event. The URL (the direct object of the event) is
 * stored for now in an instance variable; it must have the mailto: scheme.
 * If the shift key is held down, the configuration-choosing window is opened;
 * otherwise the program progresses directly to launching the destination URL.
 * The reply event is unused.
 */
- (void)handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{	
	[mailtoURL release];
	mailtoURL = [[[event paramDescriptorForKeyword:keyDirectObject] stringValue] retain];
	
	BOOL showConfigurations;
	
#if !defined(MAC_OS_X_VERSION_10_6) || MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_6
	CGEventRef tempEvent = CGEventCreate(NULL /*default event source*/);
	showConfigurations = ((CGEventGetFlags(tempEvent) & kCGEventFlagMaskShift) != 0);
	CFRelease(tempEvent);
	
#elif MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_6
	if ([NSEvent respondsToSelector:@selector(modifierFlags)])
	{
		showConfigurations = (([NSEvent modifierFlags] & NSShiftKeyMask) != 0);
	}
	else
	{
		CGEventRef tempEvent = CGEventCreate(NULL /*default event source*/);
		showConfigurations = ((CGEventGetFlags(tempEvent) & kCGEventFlagMaskShift) != 0);
		CFRelease(tempEvent);
	}
	
#else
	showConfigurations = (([NSEvent modifierFlags] & NSShiftKeyMask) != 0);
	
#endif

	if (showConfigurations)
	{
		NSArray *configurations = [configurationController arrangedObjects];
		NSUInteger count = [configurations count];
		NSUInteger i;
		
		for (i = 0; i < count; i += 1)
		{
			if ([[[configurations objectAtIndex:i] objectForKey:WebmailerDestinationIsActiveKey] boolValue])
			{
				[configurationController setSelectionIndex:i];
				[configurationTable scrollRowToVisible:i];
				break;
			}
		}
		
		[NSApp activateIgnoringOtherApps:YES]; // needed because we're an NSUIElement
		[configurationWindow makeKeyAndOrderFront:self];
	}
	else
	{
		[self launchDestination:[[NSUserDefaults standardUserDefaults] objectForKey:WebmailerCurrentDestinationKey]];
	}
}

/*!
 * Opens the Webmailer preference pane, using a file open if Webmailer is in the pane's Resources,
 * and either Scripting Bridge or NSAppleScript if it is outside.
 */
- (IBAction)openPreferencePane:(id)sender
{
	NSString *prefPanePath = [[[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
	if ([prefPanePath hasSuffix:@".prefPane"])
	{
		[[NSWorkspace sharedWorkspace] openFile:prefPanePath];
	}
#if defined(MAC_OS_X_VERSION_10_5) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5
	else if (NSClassFromString(@"SBApplication"))
	{
		SystemPreferencesApplication *sysPrefs = [SBApplication applicationWithBundleIdentifier:@"com.apple.systempreferences"];
		[sysPrefs setDelegate:self];
		[sysPrefs activate];
		[sysPrefs setCurrentPane:[[sysPrefs panes] objectWithID:@"com.belkadan.Webmailer"]];
	}
#endif
	else
	{
		NSAppleScript *prefPaneOpenScript = [[NSAppleScript alloc] initWithSource:@"tell application \"System Preferences\"\nset current pane to pane \"com.belkadan.Webmailer\"\nactivate\nend tell"];
		[prefPaneOpenScript executeAndReturnError:NULL];
		[prefPaneOpenScript release];
	}
	[NSApp terminate:self];
}

/*!
 * Confirms the user's choice of destination configuration, and launches the
 * destination URL.
 */
- (IBAction)confirmConfiguration:(id)sender
{
	[configurationWindow orderOut:sender];
	[self launchDestination:[[configurationController selection] valueForKey:WebmailerDestinationURLKey]];
}

/*!
 * Replaces Webmailer placeholders in a destination URL string with the corresponding
 * values from the mailto URL. See the Read Me file for available placeholders.
 *
 * @todo Unit tests!
 */
- (NSString *)replacePlaceholdersInDestinationPrototype:(NSString *)destinationPrototype
{
	NSMutableString *destination = [[NSMutableString alloc] init];
	
	NSUInteger colonIndex = [mailtoURL rangeOfString:@":"].location;
	NSUInteger questionMarkIndex = [mailtoURL rangeOfString:@"?"].location;
	
	NSString *replaceStr;
	NSRange headerRange;
	BOOL shouldEscape, shouldCountCharsInstead;
	NSUInteger urlLength = [mailtoURL length];
	
	NSScanner *scanner = [NSScanner scannerWithString:destinationPrototype];
	if ([scanner scanUpToString:@"[" intoString:&replaceStr]) [destination appendString:replaceStr];
	
	while ([scanner scanString:@"[" intoString:NULL])
	{
		replaceStr = nil;
		if (![scanner scanUpToString:@"]" intoString:&replaceStr] || ![scanner scanString:@"]" intoString:NULL])
		{
			// treat as literal text
			[destination appendString:@"["];
			if (replaceStr) [destination appendString:replaceStr];
			
		}
		else
		{
			NSUInteger matchStart = 0;
			
			shouldCountCharsInstead = ([replaceStr characterAtIndex:matchStart] == '#');
			if (shouldCountCharsInstead) {
				shouldCountCharsInstead = YES;
				matchStart += 1;
			}
			
			shouldEscape = ([replaceStr characterAtIndex:matchStart] == '%');
			if (shouldEscape) {
				shouldEscape = YES;
				matchStart += 1;
			}
			
			NSString *header = (matchStart > 0) ? [replaceStr substringFromIndex:matchStart] : replaceStr;
			
			if ([@"?" isEqual:header])
			{
				if (questionMarkIndex != NSNotFound)
				{
					headerRange.location = questionMarkIndex + 1;
					headerRange.length = urlLength - headerRange.location;
				}
				else
				{
					headerRange.location = headerRange.length = 0;
				}
			}
			else if ([@"to" isEqual:header])
			{
				headerRange.location = colonIndex + 1;
				if (questionMarkIndex != NSNotFound)
				{
					headerRange.length = questionMarkIndex - headerRange.location;
				}
				else
				{
					headerRange.length = urlLength - headerRange.location;
				}
			}
			else
			{
				headerRange = [mailtoURL rangeOfString:[header stringByAppendingString:@"="]];
				if (headerRange.location == NSNotFound)
				{
					headerRange.location = headerRange.length = 0;
				}
				else
				{
					headerRange.location += headerRange.length;
					NSUInteger nextAmpersand = [mailtoURL rangeOfString:@"&" options:0 range:NSMakeRange(headerRange.location, urlLength - headerRange.location)].location;
					if (nextAmpersand != NSNotFound)
					{
						headerRange.length = nextAmpersand - headerRange.location;
					}
					else
					{
						headerRange.length = urlLength - headerRange.location;
					}
				}					
			}
			
			replaceStr = [mailtoURL substringWithRange:headerRange];
			
			if (shouldEscape) replaceStr = [replaceStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			if (shouldCountCharsInstead) replaceStr = [NSString stringWithFormat:@"%d", [replaceStr length]];
			
			[destination appendString:replaceStr];
		}
		
		if ([scanner scanUpToString:@"[" intoString:&replaceStr]) [destination appendString:replaceStr];
	}
	
	return [destination autorelease];
}

/*!
 * This method uses the given destination URL and rewrites it, using the rules
 * described in the Webmailer Read Me file. Then, it takes the appropriate action,
 * based on whether the result is a URL or a shell script. Non-interactive shell
 * scripts are run using NSTask if possible, defaulting back to NSAppleScript if 
 * not. Interactive shell scripts are launched in Terminal using Scripting Bridge
 * (if available) or NSAppleScript (if not).
 */
- (void)launchDestination:(NSString *)destinationPrototype
{
	NSString *destination = [self replacePlaceholdersInDestinationPrototype:destinationPrototype];
	NSURL *destinationURL = [[NSURL alloc] initWithString:destination];
	if (destinationURL != nil)
	{
		[[NSWorkspace sharedWorkspace] openURL:destinationURL];
		[destinationURL release];
	}
	else
	{
		if ([destination characterAtIndex:0] == '#')
		{
			NSString *userShell = [[[NSProcessInfo processInfo] environment] objectForKey:@"SHELL"];
			if ([userShell length] == 0) userShell = @"/bin/sh";
			
			NSString *tempFile = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
			if ([[destination substringFromIndex:1] writeToFile:tempFile atomically:NO encoding:NSUTF8StringEncoding error:NULL])
			{
				NSTask *task = [NSTask launchedTaskWithLaunchPath:userShell arguments:[NSArray arrayWithObject:tempFile]];
				[task waitUntilExit];
			}
			else
			{
				NSMutableString *scriptSource = [destination mutableCopy];
				
				[scriptSource replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:0 range:NSMakeRange(0, [destination length])];
				[scriptSource replaceCharactersInRange:NSMakeRange(0, 1) withString:@"do shell script \""];
				[scriptSource appendString:@"\""];
				
				NSAppleScript *runScript = [[NSAppleScript alloc] initWithSource:scriptSource];
				[runScript executeAndReturnError:NULL];
				[runScript release];
				[scriptSource release];
			}			
		}
		else
		{
#if defined(MAC_OS_X_VERSION_10_5) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5
			if (NSClassFromString(@"SBApplication"))
			{
				TerminalApplication *terminal = [SBApplication applicationWithBundleIdentifier:@"com.apple.Terminal"];
				[terminal setDelegate:self];
				[terminal activate];
				(void)[terminal doScript:destination in:nil];
			}
			else
#endif
			{
				NSMutableString *scriptSource = [destination mutableCopy];
				
				[scriptSource replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:0 range:NSMakeRange(0, [destination length])];
				[scriptSource replaceCharactersInRange:NSMakeRange(0, 0) withString:@"tell application \"Terminal\" to do script \""];
				[scriptSource appendString:@"\""];

				NSAppleScript *runScript = [[NSAppleScript alloc] initWithSource:scriptSource];
				[runScript executeAndReturnError:NULL];
				[runScript release];
				[scriptSource release];
			}
		}
	}
	
	[NSApp terminate:self]; // Don't want to just stick around, right?
}

- (void)dealloc
{
	[mailtoURL release];
	[super dealloc];
}

#pragma mark -

// For SBApplicationDelegate
- (id)eventDidFail:(const AppleEvent *)event withError:(NSError *)error
{
	return nil; // be stupid but forgiving
}
@end
