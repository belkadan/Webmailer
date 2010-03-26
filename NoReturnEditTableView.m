/*******************************************************************************
 Copyright (c) 2006-2009 Jordy Rose
 
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
//  NoReturnEditTableView.m
//  Webmailer
//

#import "NoReturnEditTableView.h"

/*!
 * A table view that ends editing when the Return key is pressed, instead of moving
 * to the next cell down. The Tab key still moves across the row.
 *
 * @truename ComBelkadanUtils_NoReturnEditTableView
 */
@implementation NoReturnEditTableView

- (void)textDidEndEditing:(NSNotification *)notification
{ 
	if ([[[notification userInfo] objectForKey:@"NSTextMovement"] intValue] == NSReturnTextMovement) { 
		// This is ugly, but just about the only way to do it. 
		// NSTableView is determined to select and edit something else, even the 
		// text field that it just finished editing, unless we mislead it about 
		// what key was pressed to end editing. 
		NSMutableDictionary *newUserInfo; 
		NSNotification *newNotification; 

		newUserInfo = [NSMutableDictionary dictionaryWithDictionary:[notification userInfo]]; 
		[newUserInfo setObject:[NSNumber numberWithInt:NSOtherTextMovement] forKey:@"NSTextMovement"]; 
		newNotification = [NSNotification notificationWithName:[notification name] object:[notification object] userInfo:newUserInfo]; 
		[super textDidEndEditing:newNotification]; 
		
		// For some reason we lose firstResponder status when when we do the above.
		[[self window] makeFirstResponder:self];
	} else { 
		[super textDidEndEditing:notification]; 
	} 
}

@end
