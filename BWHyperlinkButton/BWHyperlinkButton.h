//
//  BWHyperlinkButton.h
//  BWToolkit
//
//  Created by Brandon Walkin (www.brandonwalkin.com)
//  All code is provided under the New BSD license.
//

#import <Cocoa/Cocoa.h>

@interface BWHyperlinkButton : NSButton 
{
	NSString *urlString;
}

- (void)setUrlString:(NSString *)newURLString;
- (NSString *)urlString;
@end
