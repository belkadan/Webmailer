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

#import "NSString+PrototypeExpansion.h"
#import "NSString+PrototypeExpansionPrivate.h"

@implementation NSString (ComBelkadanWebmailer_PrototypeExpansion)

/*!
 * Replaces any placeholders of the form "[header]" in the string, using the given
 * mailto URL as the source of the values for the placeholders. Headers can be
 * prefixed with "#" to insert a character count instead of the header value, or
 * "%" to percent-escape (using UTF-8) any non-URL characters. In addition, the
 * shouldForceQuoteEscapes parameter allows you to conditionally force escaping
 * of all single and double quotes in the receiver, regardless of "%" annotations.
 */
- (NSString *)replaceWebmailerPlaceholdersUsingMailtoURLString:(NSString *)mailtoURL alwaysEscapeQuotes:(BOOL)shouldForceQuoteEscapes
{
	MailtoFields *mailto = [[MailtoFields alloc] initWithURLString:mailtoURL];
	
	NSMutableString *result = [[NSMutableString alloc] init];
	NSString *replaceStr;
	BOOL lastScanWasQuestionMark = NO;
	
	NSScanner *scanner = [NSScanner scannerWithString:self];
	[scanner setCharactersToBeSkipped:nil];

	// Take care of anything before the first placeholder.
	if ([scanner scanUpToString:@"[" intoString:&replaceStr]) {
		if ([replaceStr isEqual:@"?"]) lastScanWasQuestionMark = YES;
		[result appendString:replaceStr];
	}
	
	// While we still have placeholders to scan...
	while ([scanner scanString:@"[" intoString:NULL])
	{
		replaceStr = nil;
		
		// Find the end of the placeholder (the matching "]")
		if (![scanner scanUpToString:@"]" intoString:&replaceStr] || ![scanner scanString:@"]" intoString:NULL])
		{
			// Treat unmatched brackets as literal text.
			[result appendString:@"["];
			if (replaceStr) [result appendString:replaceStr];
		}
		else
		{
			// Substitute using the mailto fields.
			NSString *value = [mailto valueForHeader:replaceStr escapeQuotes:shouldForceQuoteEscapes];

			if (lastScanWasQuestionMark && [replaceStr hasSuffix:@"?"] && [value isEqual:@""])
			{
				// Special case for [?] following a single (literal) "?".
				[result deleteCharactersInRange:NSMakeRange([result length]-1, 1)];
			}
			else
			{
				[result appendString:value];
			}
		}
		
		// Continue scanning until we get to the next placeholder.
		// Treat what we scanned as literal text.
		lastScanWasQuestionMark = NO;
		if ([scanner scanUpToString:@"[" intoString:&replaceStr]) {
			if ([replaceStr isEqual:@"?"]) lastScanWasQuestionMark = YES;
			[result appendString:replaceStr];
		}
	}
	
	[mailto release];
	return [result autorelease];
}

@end


@implementation MailtoFields

/*!
 * Creates a new field-accessor with the given URL. The URL should have the
 * form of a mailto: URL (with or without the URL scheme present).
 */
- (id)initWithURLString:(NSString *)mailtoURLString
{
	self = [super init];
	if (self)
	{
		NSUInteger colonIndex = [mailtoURLString rangeOfString:@":"].location;
		if (colonIndex == NSNotFound)
		{
			// Assume the mailto: has been stripped already.
			mailtoURL = [mailtoURLString copy];
		}
		else
		{
			mailtoURL = [[mailtoURLString substringFromIndex:colonIndex+1] copy];
		}

		
		questionMarkIndex = [mailtoURL rangeOfString:@"?"].location;
		urlLength = [mailtoURL length];
	}
	return self;
}

- (void)dealloc
{
	[mailtoURL release];
	[super dealloc];
}

/*!
 * Returns the value for a given header, subject to certain transformations.
 * There are two special headers:
 *   @"to" returns the recipient (the "user and host" part of the URL)
 *   @"?" returns the query (everything after the "?" in the URL)
 * Header names can also be prefixed:
 *   @"#" returns the number of characters in a value instead of the value itself.
 *   @"%" replaces non-URL characters (and ampersands) with their percent-escaped
 *        equivalents.
 * Finally, the shouldForceQuoteEscapes flag will make sure single and double
 * quotes are escaped (such as for use in shell scripts).
 * If a certain header is not in the URL, @"" is returned. The character count
 * for a missing header is @"0".
 */
- (NSString *)valueForHeader:(NSString *)header escapeQuotes:(BOOL)shouldForceQuoteEscapes
{
	// Figure out what kind of placeholder this is.
	NSUInteger matchStart = 0;
	
	BOOL shouldCountCharsInstead = ([header characterAtIndex:matchStart] == '#');
	if (shouldCountCharsInstead) matchStart += 1;
	
	BOOL shouldEscape = ([header characterAtIndex:matchStart] == '%');
	if (shouldEscape) matchStart += 1;
	
	// Handle either order of special operation markers.
	if (!shouldCountCharsInstead)
	{
		shouldCountCharsInstead = ([header characterAtIndex:matchStart] == '#');
		if (shouldCountCharsInstead) matchStart += 1;
	}
	
	// Find the header value!
	header = [header substringFromIndex:matchStart];
	NSString *result = [self rawValueForHeader:header];
	
	// Apply any additional operations.
	// The order of operations here is important!
	// 1. Percent-escape for URLs BEFORE counting characters.
	// 2. Only shell-escape if percent-escaping /didn't/ happen.
	if (shouldEscape)
	{
		CFStringRef extraEscapes = shouldForceQuoteEscapes ? CFSTR("&'") : CFSTR("&");
		CFStringRef escaped = CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)result, NULL, extraEscapes, kCFStringEncodingUTF8);
		result = [NSMakeCollectable(escaped) autorelease];
	}
	else if (shouldForceQuoteEscapes)
	{
		NSMutableString *replaceable = [result mutableCopy];
		[replaceable replaceOccurrencesOfString:@"\"" withString:@"%22" options:0 range:NSMakeRange(0, [replaceable length])];
		[replaceable replaceOccurrencesOfString:@"\'" withString:@"%27" options:0 range:NSMakeRange(0, [replaceable length])];
		result = [replaceable autorelease];
	}
	
	if (shouldCountCharsInstead)
	{
		result = [NSString stringWithFormat:@"%lu", (long unsigned)[result length]];
	}
	
	return result;
}

/*!
 * Returns the value of the given header in the URL. If the header is not in the
 * URL, returns the empty string. There are two special cases:
 *  @"to" will return the recipient (the part before the question mark)
 *  @"?" will return everything following the query delimiter (names and values)
 */
- (NSString *)rawValueForHeader:(NSString *)header
{
	// Special case for "all additional headers in the query part of the URL".
	if ([@"?" isEqual:header])
	{
		// mailto:recipient?subject=hello&cc=me
		//                  ^^^^^^^^^^^^^^^^^^^
		if (questionMarkIndex != NSNotFound)
		{
			return [mailtoURL substringFromIndex:questionMarkIndex+1];
		}
		else
		{
			return @"";
		}
	}
	
	// Special case for the recipient.
	// Fall back to the query part of the URL if the recipient part is empty.
	if ([@"to" isEqual:header])
	{
		if (questionMarkIndex == NSNotFound)
		{
			// mailto:recipient
			//        ^^^^^^^^^
			return mailtoURL;
		}
		else if (questionMarkIndex > 0)
		{
			// mailto:recipient?subject=hello&cc=me
			//        ^^^^^^^^^
			return [mailtoURL substringToIndex:questionMarkIndex];
		}
	}

	// Search for "header=", rather than just "header"
	header = [header stringByAppendingString:@"="];
	NSRange headerRange = [mailtoURL rangeOfString:header options:NSCaseInsensitiveSearch];
	while (headerRange.location != NSNotFound)
	{
		// Find where the header value ends.
		NSRange restOfString;
		restOfString.location = NSMaxRange(headerRange);
		restOfString.length = urlLength - restOfString.location;

		// Make sure we're not looking at the suffix of another header, i.e. longheader=
		if (headerRange.location == 0 || headerRange.location-1 == questionMarkIndex ||
			[mailtoURL characterAtIndex:headerRange.location-1] == '&')
		{			
			NSUInteger nextAmpersand = [mailtoURL rangeOfString:@"&" options:0 range:restOfString].location;
			if (nextAmpersand != NSNotFound)
			{
				// mailto:recipient?subject=hello&cc=me
				//                          ^^^^^
				NSRange valueRange;
				valueRange.location = restOfString.location;
				valueRange.length = nextAmpersand - valueRange.location;
				return [mailtoURL substringWithRange:valueRange];
			}
			else
			{
				// mailto:recipient?subject=hello&cc=me
				//                                   ^^
				return [mailtoURL substringFromIndex:restOfString.location];
			}
		}

		headerRange = [mailtoURL rangeOfString:header options:NSCaseInsensitiveSearch range:restOfString];
	}

	return @"";
}

@end

