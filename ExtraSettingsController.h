#import <Cocoa/Cocoa.h>
#import <Sparkle/Sparkle.h>
#import "WebmailerShared.h"

@class ComBelkadanWebmailer_URLHandlerController;

@interface ComBelkadanWebmailer_ExtraSettingsController : NSWindowController {
	IBOutlet SUUpdater *updateController;
	IBOutlet ComBelkadanWebmailer_URLHandlerController *browserController;
}

- (IBAction)showAsSheet:(id)sender;
- (IBAction)endSheet:(id)sender;

- (IBAction)checkForUpdates:(id)sender;
- (IBAction)exportSettings:(id)sender;
- (IBAction)importSettings:(id)sender;

@property(readwrite) BrowserChoice browserChoosingMode;
@end

@compatibility_alias ExtraSettingsController ComBelkadanWebmailer_ExtraSettingsController;
