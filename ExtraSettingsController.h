#import <Cocoa/Cocoa.h>
#import <Sparkle/Sparkle.h>


@interface ComBelkadanWebmailer_ExtraSettingsController : NSWindowController {
	IBOutlet SUUpdater *updateController;
}

- (IBAction)showAsSheet:(id)sender;
- (IBAction)endSheet:(id)sender;

- (IBAction)checkForUpdates:(id)sender;
@end
