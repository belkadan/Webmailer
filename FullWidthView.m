#import "FullWidthView.h"


@implementation FullWidthView
- (void)viewWillMoveToSuperview:(NSView *)newSuperview
{
	if (newSuperview)
	{
		NSRect frame = [self frame];
		NSRect fullFrame = [newSuperview bounds];
		frame.size.width = fullFrame.size.width;
		frame.origin.x = fullFrame.origin.x;
		[self setFrame:frame];
	}
}
@end
