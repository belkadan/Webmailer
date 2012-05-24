#import "ImageForStateTransformer.h"

/*!
 * Returns a different NSImage depending on whether the given value is true or false.
 *
 * @truename ComBelkadanUtils_ImageForStateTransformer
 */
@implementation ImageForStateTransformer
+ (Class)transformedValueClass
{
	return [NSImage class];
}

+ (BOOL)allowsReverseTransformation
{
	return YES;
}

- (id)transformedValue:(id)original
{
	if ([original respondsToSelector:@selector(boolValue)] && [original boolValue])
		return trueImage;
	else
		return falseImage;
}

- (id)reverseTransformedValue:(id)value
{
	if ([value isEqual:trueImage])
		return [NSNumber numberWithBool:YES];
	else
		return [NSNumber numberWithBool:NO];
}

/*!
 * The designated initializer; creates a transformer that shows <code>theTrueImage</code>
 * when given a true value and <code>theFalseImage</code> when given a false value.
 */
- (id)initWithTrueImage:(NSImage *)theTrueImage falseImage:(NSImage *)theFalseImage
{
	if (self = [super init])
	{
		trueImage  = [theTrueImage copy];
		falseImage = [theFalseImage copy];
	}
	return self;
}

- (void)dealloc
{
	[trueImage release];
	[falseImage release];
	[super dealloc];
}

@end
