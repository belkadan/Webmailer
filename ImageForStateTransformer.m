/*******************************************************************************
 Copyright (c) 2006-2011 Jordy Rose
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 
 Except as contained in this notice, the name(s) of the above copyright holders
 shall not be used in advertising or otherwise to promote the sale, use or other
 dealings in this Software without prior authorization.
*******************************************************************************/

//
//  ImageForStateTransformer.m
//  Webmailer
//

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
