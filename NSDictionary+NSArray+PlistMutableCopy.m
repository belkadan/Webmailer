#import "NSDictionary+NSArray+PlistMutableCopy.h"
#import <CoreFoundation/CFPropertyList.h>

/*!
 * Simple shortcut for deep mutable copying an NSDictionary.
 *
 * @see <a href="http://developer.apple.com/documentation/CoreFoundation/Reference/CFPropertyListRef/Reference/chapter_2.1_section_2.html" class="classLink">
 *			CFPropertyListCreateDeepCopy()</a>
 */
@implementation NSDictionary (ComBelkadanUtils_PlistMutableCopying)
/*!
 * Creates a deep mutable copy of this dictionary with a <code>retainCount</code> of 1.
 * Returns <code>nil</code> if an error occured, such as this method being called on
 * a dictionary containing non-property-list objects (i.e., anything besides NSArray, 
 * NSData, NSDate, NSDictionary, NSNumber, and NSString).
 *
 * @functiongroup Copying
 */
- (id)mutableDeepPropertyListCopy
{
	CFPropertyListRef plist = CFPropertyListCreateDeepCopy(NULL, (CFPropertyListRef) self, kCFPropertyListMutableContainersAndLeaves);
	if (plist) return (id)CFMakeCollectable(plist);
	else return nil;
}

@end

/*!
 * Simple shortcut for deep mutable copying an NSArray.
 *
 * @see <a href="http://developer.apple.com/documentation/CoreFoundation/Reference/CFPropertyListRef/Reference/chapter_2.1_section_2.html" class="classLink">
 *			CFPropertyListCreateDeepCopy()</a>
 */
@implementation NSArray (ComBelkadanUtils_PlistMutableCopying)
/*!
 * Creates a deep mutable copy of this array with a <code>retainCount</code> of 1.
 * Returns <code>nil</code> if an error occured, such as this method being called on
 * an array containing non-property-list objects (i.e., anything besides NSArray, NSData, 
 * NSDate, NSDictionary, NSNumber, and NSString).
 *
 * @functiongroup Copying
 */
- (id)mutableDeepPropertyListCopy
{
	CFPropertyListRef plist = CFPropertyListCreateDeepCopy(NULL, (CFPropertyListRef) self, kCFPropertyListMutableContainersAndLeaves);
	if (plist) return (id)CFMakeCollectable(plist);
	else return nil;
}

@end
