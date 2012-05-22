#import <Cocoa/Cocoa.h>
#import <Sparkle/Sparkle.h>

enum {
	BrowserChoiceBestGuess = 0,
	BrowserChoiceSystemDefault,
	BrowserChoiceSpecific,

	BrowserChoiceLast = BrowserChoiceSpecific
};
typedef NSUInteger BrowserChoice;

@interface ComBelkadanWebmailer_ExtraSettingsController : NSWindowController {
	IBOutlet SUUpdater *updateController;
}

- (IBAction)showAsSheet:(id)sender;
- (IBAction)endSheet:(id)sender;

- (IBAction)checkForUpdates:(id)sender;

@property(readwrite) BrowserChoice browserChoosingMode;
@end
