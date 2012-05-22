#import "ExtraSettingsController.h"
#import "DefaultsDomain.h"

@implementation ComBelkadanWebmailer_ExtraSettingsController

- (id)init
{
	return [self initWithWindowNibName:@"AdditionalSettings"];
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
