#import <Cocoa/Cocoa.h>

@interface ComBelkadanWebmailer_AddRemoveButtonsController : NSObject {
	IBOutlet NSSegmentedControl *segmentedButtons;
	IBOutlet NSButton *addButton;
	IBOutlet NSButton *removeButton;
	IBOutlet NSView *leftAlignedView;
}
- (IBAction)segmentClicked:(NSSegmentedControl *)sender;
@end
