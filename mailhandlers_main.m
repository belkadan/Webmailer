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