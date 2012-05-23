/*******************************************************************************
 Copyright (c) 2005-2011 Jordy Rose
 
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
//  NSDictionary+NSArray+PlistMutableCopy.m
//  Dockyard
//

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
