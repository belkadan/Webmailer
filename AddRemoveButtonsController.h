#import <AppKit/AppKit.h>

@interface ComBelkadanWebmailer_AddRemoveButtonsController : NSObject {
	IBOutlet NSSegmentedControl *segmentedButtons;
	IBOutlet NSButton *addButton;
	IBOutlet NSButton *removeButton;
}
- (IBAction)segmentClicked:(NSSegmentedControl *)sender;
@end
