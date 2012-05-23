#import "ExtraSettingsController.h"
#import "URLHandlerController.h"
#import "DefaultsDomain.h"

static NSString * const kHTTPScheme = @"http";
static NSString * const kAppleSafariID = @"com.apple.safari";

@implementation ComBelkadanWebmailer_ExtraSettingsController

- (id)init
{
	return [self initWithWindowNibName:@"AdditionalSettings"];
}

- (void)windowDidLoad
{
	[super windowDidLoad];

	ComBelkadanUtils_DefaultsDomain *defaults = [ComBelkadanUtils_DefaultsDomain domainForName:WebmailerAppDomain];

	browserController.selectedBundleID = [defaults objectForKey:WebmailerChosenBrowserIDKey];
	[browserController setScheme:kHTTPScheme fallbackBundleID:kAppleSafariID];
	[browserController addObserver:self forKeyPath:@"selectedBundleID" options:0 context:[ExtraSettingsController class]];
}

#pragma mark -

- (BrowserChoice)browserChoosingMode
{
	ComBelkadanUtils_DefaultsDomain *defaults = [ComBelkadanUtils_DefaultsDomain domainForName:WebmailerAppDomain];
	NSNumber *modeObject = [defaults objectForKey:WebmailerBrowserChoosingModeKey];

	// Backwards compatibility
	if (!modeObject)
	{
		modeObject = [defaults objectForKey:WebmailerDisableAppChoosingKey];
		if (modeObject)
		{
			[defaults removeObjectForKey:WebmailerDisableAppChoosingKey];
			[defaults setObject:[NSNumber numberWithUnsignedInteger:[modeObject unsignedIntegerValue]] forKey:WebmailerBrowserChoosingModeKey];
		}
	}

	return [modeObject unsignedIntegerValue];
}

- (void)setBrowserChoosingMode:(BrowserChoice)mode
{
	NSAssert(mode <= BrowserChoiceLast, @"Invalid browser choice mode.");

	ComBelkadanUtils_DefaultsDomain *defaults = [ComBelkadanUtils_DefaultsDomain domainForName:WebmailerAppDomain];
	[defaults setObject:[NSNumber numberWithUnsignedInteger:mode] forKey:WebmailerBrowserChoosingModeKey];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == [ExtraSettingsController class])
	{
		NSAssert(object == browserController, @"No other objects should be observed.");
		ComBelkadanUtils_DefaultsDomain *defaults = [ComBelkadanUtils_DefaultsDomain domainForName:WebmailerAppDomain];
		[defaults setObject:browserController.selectedBundleID forKey:WebmailerChosenBrowserIDKey];
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark -

- (IBAction)checkForUpdates:(id)sender
{
	[updateController checkForUpdates:sender];
}

#pragma mark -

- (IBAction)showAsSheet:(id)sender
{
	[NSApp beginSheet:[self window] modalForWindow:[NSApp mainWindow] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
}

- (IBAction)endSheet:(id)sender
{
	[NSApp endSheet:[self window]];
	[self close];
}

@end
