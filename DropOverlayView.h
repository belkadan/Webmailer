#import <AppKit/AppKit.h>

@class ComBelkadanUtils_DropOverlayView;

@protocol ComBelkadanUtils_DropOverlayViewDelegate <NSObject>
- (BOOL)dropOverlayView:(ComBelkadanUtils_DropOverlayView *)dropView acceptDrop:(id <NSDraggingInfo>)info;

@optional
- (NSArray *)dragTypesForDropOverlayView:(ComBelkadanUtils_DropOverlayView *)dropView;
- (NSDragOperation)dropOverlayView:(ComBelkadanUtils_DropOverlayView *)dropView validateDrop:(id <NSDraggingInfo>)info;
@end


@interface ComBelkadanUtils_DropOverlayView : NSView {
	id <ComBelkadanUtils_DropOverlayViewDelegate> delegate;
}

@property(readwrite,assign) IBOutlet id <ComBelkadanUtils_DropOverlayViewDelegate> delegate;

@end
