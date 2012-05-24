#import <AppKit/AppKit.h>

#define ImageForStateTransformer ComBelkadanUtils_ImageForStateTransformer

@interface ImageForStateTransformer : NSValueTransformer {
	NSImage *trueImage;
	NSImage *falseImage;
}
- (id)initWithTrueImage:(NSImage *)image falseImage:(NSImage *)image;
@end