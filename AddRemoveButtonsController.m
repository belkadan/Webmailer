#import "AddRemoveButtonsController.h"


enum {
	AddButton = 0,
	RemoveButton
};

@implementation ComBelkadanWebmailer_AddRemoveButtonsController

- (void)awakeFromNib {
	[addButton addObserver:self forKeyPath:@"enabled" options:0 context:[ComBelkadanWebmailer_AddRemoveButtonsController class]];
	[removeButton addObserver:self forKeyPath:@"enabled" options:0 context:[ComBelkadanWebmailer_AddRemoveButtonsController class]];
}

- (IBAction)segmentClicked:(NSSegmentedControl *)sender {
	switch ([sender selectedSegment]) {
	case AddButton:
		[addButton performClick:sender];
		break;
	case RemoveButton:
		[removeButton performClick:sender];
		break;
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (context == [ComBelkadanWebmailer_AddRemoveButtonsController class]) {
		[segmentedButtons setEnabled:[object isEnabled] forSegment:[object tag]];
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

@end
