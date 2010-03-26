#import "CTGradient.h"

@interface CTGradient (ComBelkadanUtils_NSGradientCompatibility)
- (id)initWithStartingColor:(NSColor *)startingColor endingColor:(NSColor *)endingColor;
- (id)initWithColors:(NSArray *)colorArray;
- (id)initWithColorsAndLocations:(NSColor *)firstColor, ...;

- (void)drawInRect:(NSRect)rect angle:(CGFloat)angle;
- (void)drawInRect:(NSRect)rect relativeCenterPosition:(NSPoint)relativeCenterPosition;

- (NSColor *)interpolatedColorAtLocation:(CGFloat)location;
@end
