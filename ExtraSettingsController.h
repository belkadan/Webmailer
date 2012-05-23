#import <AppKit/AppKit.h>
#import "WebmailerShared.h"
#import "DropOverlayView.h"

@class SUUpdater;
@class ComBelkadanWebmailer_URLHandlerController;

@interface ComBelkadanWebmailer_ExtraSettingsController : NSWindowController <ComBelkadanUtils_DropOverlayViewDelegate> {
	IBOutlet SUUpdater *updateController;
	IBOutlet NSArrayController *configurationController;
	IBOutlet NSView *mainWindowView;

	IBOutlet ComBelkadanWebmailer_URLHandlerController *browserController;
}

- (IBAction)showAsSheet:(id)sender;
- (IBAction)endSheet:(id)sender;

- (IBAction)checkForUpdates:(id)sender;
- (IBAction)exportSettings:(id)sender;
- (IBAction)importSettings:(id)sender;

- (void)importSettingsFromURL:(NSURL *)url;

@property(readwrite) BrowserChoice browserChoosingMode;
@end

@compatibility_alias ExtraSettingsController ComBelkadanWebmailer_ExtraSettingsController;
