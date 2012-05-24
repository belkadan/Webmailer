//
//  DBBackgroundView.h
//  16 January 2007
//
//  Created by Dave Batton
//  http://www.Mere-Mortal-Software.com/
//
//  Documentation for this class is available here:
//  http://www.mere-mortal-software.com/blog/details.php?d=2007-01-17
//
//  Copyright 2007. Some rights reserved.
//  This work is licensed under a Creative Commons license:
//  http://creativecommons.org/licenses/by/2.5/
//


#import <Cocoa/Cocoa.h>

@class CTGradient;


@interface DBBackgroundView : NSView {
	NSColor *_backgroundColor;
	NSColor *_backgroundPatternColor;
	id _backgroundGradient;
	float _gradientAngle;
	float _backgroundAlpha;
	NSImage *_backgroundImage;
	float _backgroundImageAlpha;
	float _cornerRadius;
}


- (void)clearBackground;

- (void)setBackgroundColor:(NSColor *)aColor;
- (void)setBackgroundPattern:(NSImage *)anImage;
- (void)setBackgroundGradient:(id)gradient;
- (void)setBackgroundGradient:(id)aGradient withAngle:(float)anAngle;
- (void)setBackgroundAlpha:(float)anAlpha;
- (void)setBackgroundImage:(NSImage *)anImage;
- (void)setBackgroundImageAlpha:(float)anAlpha; // ADDED
- (void)setBackgroundImage:(NSImage *)anImage withAlpha:(float)anAlpha;
- (void)setBackgroundCornerRadius:(float)aRadius;

- (NSBezierPath *)createBezierPathForRect:(NSRect)rect;

- (void)drawColor:(NSBezierPath *)path;
- (void)drawPattern:(NSBezierPath *)path;
- (void)drawGradient:(NSBezierPath *)path;
- (void)drawImage:(NSBezierPath *)path;
- (void)drawImage:(NSImage *)anImage alpha:(float)anAlpha clippingPath:(NSBezierPath *)aPath;

// ADDED
- (NSImage *)backgroundImage;
- (NSImage *)backgroundPattern;
- (float)backgroundImageAlpha;
- (float)backgroundAlpha;
- (NSColor *)backgroundColor;
- (float)backgroundCornerRadius;
- (float)backgroundGradientAngle;
- (id)backgroundGradient;

@end




@interface  NSObject (IdMethods)
- (void)fillRect:(NSRect)rect angle:(float)angle;
@end
