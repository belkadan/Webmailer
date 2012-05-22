#import <Cocoa/Cocoa.h>
#import <Sparkle/Sparkle.h>
#import <DBBackgroundView/DBBackgroundView.h>

@class SUUpdateAlert;

@interface ComBelkadanWebmailer_UpdateController : SUUpdater {
	IBOutlet NSImageView *updateIconView;
	IBOutlet DBBackgroundView *updateBar;
	IBOutlet NSView *mainView;

	SUAppcastItem *availableUpdate;
	SUUpdateAlert *updateAlert;
	BOOL hasPerformedInitialCheck;
}

- (IBAction)showReleaseNotes:(id)sender;
- (IBAction)installUpdate:(id)sender;
@end
