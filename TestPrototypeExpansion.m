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

static NSString * const FullMailto = @"mailto:webmailer@belkadan.com?subject=Help!&cc=support@belkadan.com";


@interface TestPrototypeExpansion : SenTestCase
@end


@implementation TestPrototypeExpansion

- (void)testBasic
{
	STAssertEqualObjects(@"", [@"" replaceWebmailerPlaceholdersUsingMailtoURLString:@"" alwaysEscapeQuotes:NO], @"");
	STAssertEqualObjects(@"abc", [@"abc" replaceWebmailerPlaceholdersUsingMailtoURLString:@"" alwaysEscapeQuotes:NO], @"");
	STAssertEqualObjects(@"?", [@"?" replaceWebmailerPlaceholdersUsingMailtoURLString:@"" alwaysEscapeQuotes:NO], @"");
	STAssertEqualObjects(@"to", [@"to" replaceWebmailerPlaceholdersUsingMailtoURLString:@"" alwaysEscapeQuotes:NO], @"");
	
	STAssertEqualObjects(@"", [@"" replaceWebmailerPlaceholdersUsingMailtoURLString:FullMailto alwaysEscapeQuotes:NO], @"");
	STAssertEqualObjects(@"abc", [@"abc" replaceWebmailerPlaceholdersUsingMailtoURLString:FullMailto alwaysEscapeQuotes:NO], @"");
	STAssertEqualObjects(@"?", [@"?" replaceWebmailerPlaceholdersUsingMailtoURLString:FullMailto alwaysEscapeQuotes:NO], @"");
	STAssertEqualObjects(@"to", [@"to" replaceWebmailerPlaceholdersUsingMailtoURLString:FullMailto alwaysEscapeQuotes:NO], @"");
}

@end
