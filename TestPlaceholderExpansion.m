/*******************************************************************************
 Copyright (c) 2011 Jordy Rose
 
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

#import <SenTestingKit/SenTestingKit.h>
#import "NSString+PrototypeExpansion.h"

@interface TestPrototypeExpansion : SenTestCase
@end

static NSString * const testingURL = @"mailto:x@y.com?one=11&two=22";

@implementation TestPrototypeExpansion

- (void)testNoPlaceholders
{
	NSString *str = @"this is a string with %no placeholders%";
	STAssertEqualObjects(str, [str replaceWebmailerPlaceholdersUsingMailtoURLString:testingURL alwaysEscapeQuotes:NO], @"");
}

- (void)testEndsWithOpenBracket
{
	NSString *str = @"this ends with a [";
	STAssertEqualObjects(str, [str replaceWebmailerPlaceholdersUsingMailtoURLString:testingURL alwaysEscapeQuotes:NO], @"");
}

- (void)testIncompletePlaceholder
{
	NSString *str = @"this ends with an incomplete [placeholder";
	STAssertEqualObjects(str, [str replaceWebmailerPlaceholdersUsingMailtoURLString:testingURL alwaysEscapeQuotes:NO], @"");
}

- (void)testValidPlaceholders
{
	NSString *str = @"this has a [to] placeholder";
	NSString *expected = @"this has a x@y.com placeholder";
	STAssertEqualObjects(expected, [str replaceWebmailerPlaceholdersUsingMailtoURLString:testingURL alwaysEscapeQuotes:NO], @"");
	
	str = @"this has a [two] placeholder";
	expected = @"this has a 22 placeholder";
	STAssertEqualObjects(expected, [str replaceWebmailerPlaceholdersUsingMailtoURLString:testingURL alwaysEscapeQuotes:NO], @"");

	str = @"this ends with [one]";
	expected = @"this ends with 11";
	STAssertEqualObjects(expected, [str replaceWebmailerPlaceholdersUsingMailtoURLString:testingURL alwaysEscapeQuotes:NO], @"");

	str = @"[to] starts this one";
	expected = @"x@y.com starts this one";
	STAssertEqualObjects(expected, [str replaceWebmailerPlaceholdersUsingMailtoURLString:testingURL alwaysEscapeQuotes:NO], @"");
}

- (void)testInvalidPlaceholders
{
	NSString *str = @"this has a [random] placeholder";
	NSString *expected = @"this has a  placeholder";
	STAssertEqualObjects(expected, [str replaceWebmailerPlaceholdersUsingMailtoURLString:testingURL alwaysEscapeQuotes:NO], @"");
}

- (void)testEmpty
{
	NSString *str = @"";
	STAssertEqualObjects(str, [str replaceWebmailerPlaceholdersUsingMailtoURLString:testingURL alwaysEscapeQuotes:NO], @"");
}

- (void)testEmptyPlaceholder
{
	NSString *str = @"this has an empty [] placeholder";
	STAssertEqualObjects(str, [str replaceWebmailerPlaceholdersUsingMailtoURLString:testingURL alwaysEscapeQuotes:NO], @"");
}

- (void)testMultiplePlaceholders
{
	NSString *str = @"this has [one], [two], [three] placeholders";
	NSString *expected = @"this has 11, 22,  placeholders";
	STAssertEqualObjects(expected, [str replaceWebmailerPlaceholdersUsingMailtoURLString:testingURL alwaysEscapeQuotes:NO], @"");
}

- (void)testBasicModifiers
{
	NSString *emailWithPunctuation = @"mailto:0'^0";
	NSString *template = @"[to]: [%to] [#to] [%#to]";
	NSString *expected = @"0'^0: 0'%5E0 4 6";
	NSString *expectedQuotes = @"0%27^0: 0%27%5E0 6 8";
	
	NSString *actual = [template replaceWebmailerPlaceholdersUsingMailtoURLString:emailWithPunctuation alwaysEscapeQuotes:NO];
	NSString *actualQuotes = [template replaceWebmailerPlaceholdersUsingMailtoURLString:emailWithPunctuation alwaysEscapeQuotes:YES];
	STAssertEqualObjects(expected, actual, @"");
	STAssertEqualObjects(expectedQuotes, actualQuotes, @"");
}

@end
