#import "WebmailerDaemon.h"

#import "DefaultsDomain.h"
#import "ImageForStateTransformer.h"
#import "NSString+PrototypeExpansion.h"
#import "WebmailerConfiguration.h"
#import "WebmailerShared.h"

#import "ScriptingBridgeApps.h"

// to stop warnings on pre-10.6 builds
@interface NSEvent (ComBelkadanWebmailer_NoWarn)
+ (NSUInteger)modifierFlags;
@end


@interface WebmailerDaemon ()
@property(readwrite,copy) NSString *mailtoURL;
@property(readwrite,copy) NSURL *sourceAppURL;
@property(readwrite,assign) ComBelkadanWebmailer_Configuration *activeConfiguration;

- (void)openURLString:(NSString *)mailtoURLString fromApplicationAtURL:(NSURL *)appURL;

- (void)launchShellScript:(NSString *)script;
- (void)launchTerminal:(NSString *)script;

- (NSURL *)chooseAppForOpeningURL:(NSURL *)url;
@end


/*!
 * Returns YES if the shift key is currently held, NO if not.
 */
BOOL isShiftKeyDown ()
{
	BOOL result;

#if defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_10_6 <= MAC_OS_X_VERSION_MAX_ALLOWED
# if MAC_OS_X_VERSION_10_6 <= MAC_OS_X_VERSION_MIN_REQUIRED
	result = (([NSEvent modifierFlags] & NSShiftKeyMask) != 0);

# else /* MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_6 */
	if ([NSEvent respondsToSelector:@selector(modifierFlags)])
	{
		result = (([NSEvent modifierFlags] & NSShiftKeyMask) != 0);
	}
	else
	{
		CGEventRef tempEvent = CGEventCreate(NULL /*default event source*/);
		result = ((CGEventGetFlags(tempEvent) & kCGEventFlagMaskShift) != 0);
		CFRelease(tempEvent);
	}

# endif

#else /* MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_6 */
	CGEventRef tempEvent = CGEventCreate(NULL /*default event source*/);
	result = ((CGEventGetFlags(tempEvent) & kCGEventFlagMaskShift) != 0);
	CFRelease(tempEvent);

#endif

	return result;
}

/*!
 * Returns the image used to represent the currently selected destination.
 */
NSImage *GetActiveDestinationImage ()
{
	NSImage *image;

	// If available, use the active state image that comes with Mac OS X.
#if defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_10_6 <= MAC_OS_X_VERSION_MAX_ALLOWED
	if (&NSImageNameStatusAvailable != NULL)
	{
		image = [NSImage imageNamed:NSImageNameStatusAvailable];
	}
	else
#endif
	{
		// Otherwise, use our own bundled image.
		image = [NSImage imageNamed:@"active"];
	}

	return image;
}

/*!
 * Finds the URL of a running application with a given process serial number.
 * If the URL cannot be found, for whatever reason (perhaps the application has
 * quit), returns nil.
 */
NSURL *GetURLForPSN (const ProcessSerialNumber *psn) {
	if (psn->highLongOfPSN == 0 && psn->lowLongOfPSN == 0)
		return nil;
	
	FSRef bundleLocation;
	OSStatus status = GetProcessBundleLocation(psn, &bundleLocation);
	if (status != noErr)
		return nil;
	
	NSURL *appURL = (NSURL *)CFURLCreateFromFSRef(NULL, &bundleLocation);
	return [appURL autorelease];
}

/*!
 * Returns YES if the application at the first URL can open the second URL.
 * Basically a wrapper around LSCanURLAcceptURL().
 */
BOOL CanOpenURLWithApplication (NSURL *url, NSURL *appURL) {
	Boolean canHandle;
	OSStatus status = LSCanURLAcceptURL((CFURLRef)url, (CFURLRef)appURL, kLSRolesViewer, kLSAcceptDefault, &canHandle);
	
	if (status != noErr)
		return NO;
	
	return canHandle ? YES : NO; // conversion from Boolean to BOOL...doesn't hurt!
}

/*!
 * Open a URL using the given application. 
 * Essentially a wrapper around LSOpenFromURLSpec().
 */
void OpenURLWithApplication(NSURL *url, NSURL *appURL)
{
	LSLaunchURLSpec launchSpec = {
		.appURL = (CFURLRef)appURL,
		.itemURLs = (CFArrayRef)[NSArray arrayWithObject:url],
		.launchFlags = kLSLaunchDefaults
	};
	(void)LSOpenFromURLSpec(&launchSpec, NULL);
}

/*!
 * Returns the URL of the application the Finder would use to open this URL.
 * If there is no application registered for the URL, returns nil.
 * Basically a wrapper around LSGetApplicationForURL().
 */
NSURL *GetDefaultAppURLForURL(NSURL *url) {
	// TODO: in 10.6, replace this function with -[NSWorkspace URLForApplicationToOpenURL:]
	NSURL *appURL;
	OSStatus status = LSGetApplicationForURL((CFURLRef)url, kLSRolesAll, NULL, (CFURLRef*)&appURL);

	if (status != noErr) return nil;
	
	return [appURL autorelease];
}

NSURL *GetURLForApplicationWithBundleIdentifier (NSString *bundleID)
{
	// TODO: in 10.6, replace this function with -[NSWorkspace URLForApplicationWithBundleIdentifier:]
	NSURL *appURL;
	OSStatus status = LSFindApplicationForInfo(kLSUnknownCreator, (CFStringRef)bundleID, NULL, NULL, (CFURLRef *)&appURL);

	if (status != noErr) return nil;

	return [appURL autorelease];
}


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
@synthesize mailtoURL, sourceAppURL;

- (id)init
{
	self = [super init];
	if (!self) return nil;

	// Make sure the user has configured Webmailer before. 
	defaults = [[DefaultsDomain domainForName:WebmailerAppDomain] retain];
	if ([defaults count] == 0)
	{
		[self openPreferencePane:nil];
	}
	
	// Quit if no incoming event.
	[NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(quitIfInactive:) userInfo:nil repeats:YES];

	return self;
}

- (void)dealloc
{
	[defaults release];
	[mailtoURL release];
	[sourceAppURL release];
	[configurations release];
	[super dealloc];
}

- (void)quitIfInactive:(NSTimer *)timer
{
	if (!mailtoURL)
		[NSApp terminate:nil];
}

/*!
 * Set up the configuration chooser, then display it and bring the Webmailer app to the front.
 * The user can then choose which configuration to use for the URL that was clicked.
 */
- (void)showConfigurationChooser {
	// Create a new value transformer that shows an active icon for true values.
	ImageForStateTransformer *transformer = [[ImageForStateTransformer alloc] initWithTrueImage:GetActiveDestinationImage() falseImage:nil];
	[NSValueTransformer setValueTransformer:transformer forName:@"ImageForState"];
	[transformer release];

	// Select the active destination.
	NSArray *configs = self.configurations;
	NSUInteger count = [configs count];
	NSUInteger i;

	for (i = 0; i < count; i += 1)
	{
		if ([[configs objectAtIndex:i] isActive])
		{
			[configurationController setSelectionIndex:i];
			[configurationTable scrollRowToVisible:i];
			break;
		}
	}

	// Set the table to fire an action on double-click.
	[configurationTable setDoubleAction:@selector(confirmConfiguration:)];
	[configurationTable setTarget:self];

	// Bring up the configuration window.
	[NSApp activateIgnoringOtherApps:YES]; // needed because we're an NSUIElement
	[configurationWindow makeKeyAndOrderFront:self];
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
	else
	{
		SystemPreferencesApplication *sysPrefs = [SBApplication applicationWithBundleIdentifier:@"com.apple.systempreferences"];
		[sysPrefs setDelegate:self];
		[sysPrefs activate];
		[sysPrefs setCurrentPane:[[sysPrefs panes] objectWithID:WebmailerAppDomain]];
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

#pragma mark -

- (NSArray *)configurations
{
	if (!configurations) {
		if (![NSThread isMainThread]) {
			[self performSelectorOnMainThread:_cmd withObject:nil waitUntilDone:YES];			
		} else {
			// Set up sort descriptors for destination URLs.
			NSSortDescriptor *sortByName = [[NSSortDescriptor alloc] initWithKey:WebmailerDestinationNameKey ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
			NSSortDescriptor *sortByDestination = [[NSSortDescriptor alloc] initWithKey:WebmailerDestinationURLKey ascending:YES];
			NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortByName, sortByDestination, nil];
			[sortByName release];
			[sortByDestination release];

			// Sort the configurations.
			NSArray *sortedDictionaries = [[defaults objectForKey:WebmailerConfigurationsKey] sortedArrayUsingDescriptors:sortDescriptors];
			[sortDescriptors release];

			NSMutableArray *allConfigurations = [[NSMutableArray alloc] initWithCapacity:[sortedDictionaries count]];
			for (NSDictionary *dict in sortedDictionaries) {
				id next = [[ComBelkadanWebmailer_Configuration alloc] initWithDictionaryRepresentation:dict];
				[next addObserver:self forKeyPath:WebmailerDestinationNameKey options:0 context:(void *)[WebmailerDaemon class]];
				[next addObserver:self forKeyPath:WebmailerDestinationURLKey options:0 context:(void *)[WebmailerDaemon class]];
				[allConfigurations addObject:next];
				[next release];
			}

			configurations = allConfigurations;
		}
	}

	return configurations;
}

- (ComBelkadanWebmailer_Configuration *)activeConfiguration
{
	if (!activeConfiguration) {
		if (![NSThread isMainThread]) {
			[self performSelectorOnMainThread:_cmd withObject:nil waitUntilDone:YES];			
		} else {
			for (ComBelkadanWebmailer_Configuration *next in self.configurations) {
				if (next.active) {
					activeConfiguration = next;
					break;
				}
			}
			NSAssert(activeConfiguration != nil, @"No active configuration found.");
		}
	}

	return activeConfiguration;
}

- (void)setActiveConfiguration:(ComBelkadanWebmailer_Configuration *)newActive
{
	activeConfiguration.active = NO;
	newActive.active = YES;
	activeConfiguration = newActive;

	[defaults beginTransaction];
	[defaults setObject:[configurations valueForKey:@"dictionaryRepresentation"] forKey:WebmailerConfigurationsKey];
	[defaults setObject:newActive.destinationURL forKey:WebmailerCurrentDestinationKey];
	[defaults endTransaction];
}

- (BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)key
{
	return [key isEqual:@"configurations"] || [key isEqual:@"activeConfiguration"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == (void *)[WebmailerDaemon class]) {
		[defaults beginTransaction];
		ComBelkadanWebmailer_Configuration *changedConfiguration = object;
		if (changedConfiguration.active && [keyPath isEqual:WebmailerDestinationURLKey]) {
			[defaults setObject:changedConfiguration.destinationURL forKey:WebmailerCurrentDestinationKey];
		}
		[defaults setObject:[configurations valueForKey:@"dictionaryRepresentation"] forKey:WebmailerConfigurationsKey];
		[defaults endTransaction];
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark -

- (void)openURLString:(NSString *)mailtoURLString fromApplicationAtURL:(NSURL *)appURL;
{
	self.mailtoURL = mailtoURLString;
	self.sourceAppURL = appURL;

	[defaults refresh];

	BOOL shouldShowConfigurations = isShiftKeyDown();
	if (shouldShowConfigurations)
	{
		[self showConfigurationChooser];
	}
	else
	{
		[self launchDestination:[defaults objectForKey:WebmailerCurrentDestinationKey]];
	}
}

- (void)launchDestination:(NSString *)destinationPrototype
{
	if ([destinationPrototype characterAtIndex:0] == '#')
	{
		// It's a background shell script!
		destinationPrototype = [destinationPrototype substringFromIndex:1];
		NSString *script = [destinationPrototype replaceWebmailerPlaceholdersUsingMailtoURLString:mailtoURL alwaysEscapeQuotes:YES];
		[self launchShellScript:script];
	}
	else
	{
		NSString *destination = [destinationPrototype replaceWebmailerPlaceholdersUsingMailtoURLString:mailtoURL alwaysEscapeQuotes:NO];
		NSURL *destinationURL = [[NSURL alloc] initWithString:destination];
		
		if (destinationURL)
		{
			// It's a valid URL
			NSURL *appURL = [self chooseAppForOpeningURL:destinationURL];
			if (appURL)
			{
				OpenURLWithApplication(destinationURL, appURL);
			}
			else
			{
				// Fall back to default URL handler.
				[[NSWorkspace sharedWorkspace] openURL:destinationURL];
			}
			[destinationURL release];
		}
		else
		{
			// It's not a valid URL; must be an "open Terminal" shell script.
			NSString *script = [destinationPrototype replaceWebmailerPlaceholdersUsingMailtoURLString:mailtoURL alwaysEscapeQuotes:YES];
			[self launchTerminal:script];
		}
	}

	self.mailtoURL = nil;
}


/*!
 * Returns the URL of the application Webmailer should use to open the given
 * destination URL. If smart app choosing is disabled in the preferences, or
 * if no good applications can be found, returns nil.
 *
 * 1. If the user has explicitly chosen an app, pick that (if it can handle the destination).
 * 2. If the app that sent us the mailto URL can handle the destination, pick that.
 * 3. If the default app for the destination URL is open, pick that.
 * 4. If any app that can handle the destination URL is open, pick one of them.
 * 5. Otherwise, give up and return nil.
 */
- (NSURL *)chooseAppForOpeningURL:(NSURL *)url
{
	NSNumber *choosingMode = [defaults objectForKey:WebmailerBrowserChoosingModeKey];
	if (!choosingMode) choosingMode = [defaults objectForKey:WebmailerDisableAppChoosingKey];

	BrowserChoice mode = [choosingMode unsignedIntegerValue];

	switch (mode) {
	case BrowserChoiceSystemDefault:
		return nil;
	case BrowserChoiceSpecific: {
		NSString *identifier = [defaults objectForKey:WebmailerChosenBrowserIDKey];
		if (identifier)
		{
			NSURL *chosenAppURL = GetURLForApplicationWithBundleIdentifier(identifier);
			if (chosenAppURL && CanOpenURLWithApplication(url, chosenAppURL)) return chosenAppURL;
		}
		break;
	case BrowserChoiceBestGuess:
		break;
	}
	}
	
	// If the app that sent us the mailto URL can handle the destination, pick that.
	if (sourceAppURL && CanOpenURLWithApplication(url, sourceAppURL)) return sourceAppURL;
	
	// Otherwise, start scanning the list of open applications.
	NSURL *defaultAppURL = GetDefaultAppURLForURL(url);
	
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	NSURL *currentChoice = nil;
	
#if defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6
	if ([workspace respondsToSelector:@selector(runningApplications)])
	{
		for (NSRunningApplication *nextApp in [workspace runningApplications])
		{
			NSURL *nextAppURL = nextApp.bundleURL;
			if ([nextAppURL isEqual:defaultAppURL])
			{
				return defaultAppURL;
			}
			else if (!currentChoice && CanOpenURLWithApplication(url, nextAppURL))
			{
				currentChoice = nextAppURL;
			}
		}
	}
	else
#endif
	{
		for (NSDictionary *nextAppInfo in [workspace launchedApplications])
		{
			NSURL *nextAppURL = [NSURL fileURLWithPath:[nextAppInfo objectForKey:@"NSApplicationPath"]];
			if ([nextAppURL isEqual:defaultAppURL])
			{
				return defaultAppURL;
			}
			else if (!currentChoice && CanOpenURLWithApplication(url, nextAppURL))
			{
				currentChoice = nextAppURL;
			}
		}
	}
	
	return currentChoice;
}

/*!
 * Run the given script in the user's preferred shell. The output goes to stdout.
 */
- (void)launchShellScript:(NSString *)script
{
	// Find out the user's preferred shell. Default to /bin/sh.
	NSString *userShell = [[[NSProcessInfo processInfo] environment] objectForKey:@"SHELL"];
	if ([userShell length] == 0) userShell = @"/bin/sh";
	
	// Launch the shell.
	NSTask *task = [[NSTask alloc] init];
	NSPipe *pipe = [NSPipe pipe];
	[task setStandardInput:[pipe fileHandleForReading]];
	[task setLaunchPath:userShell];
	[task launch];
	
	// Write the script.
	NSFileHandle *input = [pipe fileHandleForWriting];
	[input writeData:[script dataUsingEncoding:NSUTF8StringEncoding]];
	[input writeData:[NSData dataWithBytesNoCopy:"\n" length:1 freeWhenDone:NO]];
	[input closeFile];
	[task waitUntilExit];
	[task release];
}

/*!
 * Run the given script in the Terminal, so it can be used interactively.
 *
 * TODO: use handler for com.apple.Terminal.shell-script ?
 */
- (void)launchTerminal:(NSString *)script
{
	TerminalApplication *terminal = [SBApplication applicationWithBundleIdentifier:@"com.apple.Terminal"];
	[terminal setDelegate:self];
	[terminal activate];
	(void)[terminal doScript:script in:nil];
}

#pragma mark -

// For SBApplicationDelegate
- (id)eventDidFail:(const AppleEvent *)event withError:(NSError *)error
{
	return nil; // be stupid but forgiving
}
@end


@implementation NSApplication (ComBelkadanWebmailer)

/*!
 * Handles an 'open URL' AppleScript event. Application-targeted commands can't be
 * passed off for free to delegates like properties can, so this method on NSApplication
 * handles the nasty bits of Cocoa Scripting and passes clean URLs to the main controller.
 *
 * See -[WebmailerDaemon openURLString:fromApplicationAtURL:]
 */
- (void)ComBelkadanWebmailer_openURL:(NSScriptCommand *)command {
	NSAppleEventDescriptor *event = [command appleEvent];
	NSString *directObject = [command directParameter];

	// Check that we really have a mailto URL.
	NSURL *mailtoURLObject = [NSURL URLWithString:directObject];
	if (!mailtoURLObject || ![WebmailerMailtoScheme isEqual:[mailtoURLObject scheme]]) {
		[command setScriptErrorNumber:paramErr];
		[command setScriptErrorString:@"not a valid mailto URL"];
		
		NSAppleEventDescriptor *directObjectDesc = [event paramDescriptorForKeyword:keyDirectObject];
		[command setScriptErrorOffendingObjectDescriptor:directObjectDesc];
		return;
	}

	ProcessSerialNumber psn;

	NSData *data = [[[event attributeDescriptorForKeyword:keyAddressAttr] coerceToDescriptorType:typeProcessSerialNumber] data];
	NSAssert([data length] <= sizeof(psn), @"PSN key is too big!");
	[data getBytes:&psn];

	WebmailerDaemon *delegate = (WebmailerDaemon *)[self delegate];
	[delegate openURLString:directObject fromApplicationAtURL:GetURLForPSN(&psn)];
}

@end

