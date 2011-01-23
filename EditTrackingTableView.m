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

//
//  EditTrackingTableView.m
//  Webmailer
//

#import "EditTrackingTableView.h"

// to stop warnings on pre-10.5 builds
@interface NSTableView (ComBelkadanWebmailer_NoWarn)
- (NSCell *)preparedCellAtColumn:(NSInteger)column row:(NSInteger)row;
@end

/*!
 * A table view that sends an action when a text cell has finished editing. The
 * target and action are the cell's target and action.
 *
 * @truename ComBelkadanUtils_EditTrackingTableView
 */
@implementation EditTrackingTableView
- (void)textDidEndEditing:(NSNotification *)note
{
	NSCell *cell;
	if ([self respondsToSelector:@selector(preparedCellAtColumn:row:)])
	{
		cell = [self preparedCellAtColumn:[self editedColumn] row:[self editedRow]];
	}
	else
	{
		cell = _editingCell; // ivar of NSTableView, kinda brittle...
	}

	SEL action = [cell action];
	id target = [cell target];
	
	[super textDidEndEditing:note];
	
	if (action != NULL) [NSApp sendAction:action to:target from:self];
}
@end
