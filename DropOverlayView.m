#import "DropOverlayView.h"
#import <QuartzCore/QuartzCore.h>

static const double kBlurRadius = 1.0;

@interface ComBelkadanUtils_DropOverlayView ()
- (void)show;
- (void)hide;
@end

@implementation ComBelkadanUtils_DropOverlayView
@synthesize delegate;

- (void)awakeFromNib {
	[self retain];
	NSView *superview = [self superview];
	[self removeFromSuperview];
	[superview addSubview:self positioned:NSWindowAbove relativeTo:nil];
	[self release];

	if ([delegate respondsToSelector:@selector(dragTypesForDropOverlayView:)]) {
		[self registerForDraggedTypes:[delegate dragTypesForDropOverlayView:self]];
	}
}

- (void)show {
	[self setAlphaValue:1];

	CIFilter *blur = [CIFilter filterWithName:@"CIGaussianBlur"];
	[blur setValue:[NSNumber numberWithDouble:kBlurRadius] forKey:@"inputRadius"];
	[blur setValue:[NSNull null] forKey:@"inputImage"];
	[self setBackgroundFilters:[NSArray arrayWithObject:blur]];
}

- (void)hide {
	[self setBackgroundFilters:[NSArray array]];
	[self setAlphaValue:0];
}

#pragma mark -

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
	NSDragOperation result;
	if ([delegate respondsToSelector:@selector(dropOverlayView:validateDrop:)]) {
		result = [delegate dropOverlayView:self validateDrop:sender];
	} else {
		result = NSDragOperationGeneric;
	}

	if (result != NSDragOperationNone) {
		[self show];
	}
	return result;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
	[self hide];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
	[self hide];
	return [delegate dropOverlayView:self acceptDrop:sender];
}

@end
