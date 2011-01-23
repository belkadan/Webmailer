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

#import <AppKit/AppKit.h>

static NSString * const kRelativeWebmailerPath = @"PreferencePanes/Webmailer.prefPane/Contents/Resources/Webmailer.app";

int main(int argc, char *argv[])
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	NSFileManager *fileManager = [NSFileManager defaultManager];

	NSEnumerator *libraryEnum = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask, YES) objectEnumerator];
	NSString *nextPath;
	
	while ((nextPath = [[libraryEnum nextObject] stringByAppendingPathComponent:kRelativeWebmailerPath]))
	{
		if ([fileManager fileExistsAtPath:nextPath])
			break;
	}

	OSStatus returnCode;
	if (nextPath != nil)
	{
		returnCode = LSRegisterURL((CFURLRef) [[[NSURL alloc] initFileURLWithPath:nextPath] autorelease], NO);
		if (returnCode != 0)
		{
			if ([[NSWorkspace sharedWorkspace] launchApplication:nextPath])
				returnCode = 0;
			else
			{
				NSBeep();
				NSLog(@"Unable to add Webmailer as a mail handler. Please e-mail webmailer@belkadan.com with this error code: %d", returnCode);
			}
		}
	}
	else
	{
		NSBeep();
		NSLog(@"Webmailer does not seem to be installed on your system.");
		returnCode = -1;
	}
	[pool release];
	
	return returnCode;
}