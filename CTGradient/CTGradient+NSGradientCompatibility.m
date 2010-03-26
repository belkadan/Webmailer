#import "CTGradient+NSGradientCompatibility.h"

@implementation CTGradient (ComBelkadanUtils_NSGradientCompatibility)
- (id)initWithStartingColor:(NSColor *)startingColor endingColor:(NSColor *)endingColor
{
	self = [super init];
	if (self)
	{
		CTGradient *oldSelf = self;
		self = [[[self class] gradientWithBeginningColor:startingColor endingColor:endingColor] retain];
		[oldSelf release];
	}
	return self;
}

- (id)initWithColors:(NSArray *)colorArray
{
	self = [self init];
	if (self)
	{
		[self autorelease];
	
		NSEnumerator *colorEnum = [colorArray objectEnumerator];
		float delta = 1.0 / ([colorArray count] - 1);
		
		float position = 0.0;
		NSColor *nextColor;
		while (nextColor = [colorEnum nextObject])
		{
			self = [self addColorStop:nextColor atPosition:position];
			position += delta;
		}
		
		[self retain];
	}
	return self;
}

- (id)initWithColorsAndLocations:(NSColor *)firstColor, ...
{
	self = [self init];
	if (self)
	{
		[self autorelease];
	
		va_list args;
		va_start(args, firstColor);
		
		float position;
		NSColor *nextColor = firstColor;
		while (nextColor != nil)
		{
			position = va_arg(args, double);
			
			self = [self addColorStop:nextColor atPosition:position];
			nextColor = va_arg(args, NSColor *);
		}
		
		[self retain];
	}
	return self;
}

- (void)drawInRect:(NSRect)rect angle:(CGFloat)angle
{
	[self fillRect:rect angle:angle];
}

- (void)drawInRect:(NSRect)rect relativeCenterPosition:(NSPoint)relativeCenterPosition
{
	NSAffineTransform *transform = [NSAffineTransform transform];
	[transform translateXBy:-relativeCenterPosition.x yBy:-relativeCenterPosition.y];
	[transform concat];
	
	[self radialFillRect:rect];
	
	[transform invert];
	[transform concat];
}

- (NSColor *)interpolatedColorAtLocation:(CGFloat)location
{
	return [self colorAtPosition:(float)location];
}

@end
