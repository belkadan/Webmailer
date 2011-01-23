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
//  AutosortArrayController.m
//  Webmailer
//

#import "AutosortArrayController.h"

/*!
 * An array controller that keeps its table view sorted after every change.
 * Must be both <code>delegate</code> and <code>dataSource</code> of the
 * table in question. This is most useful with Cocoa bindings, not for complicated
 * uses of a table.
 *
 * @truename ComBelkadanUtils_AutosortArrayController
 */
@implementation AutosortArrayController
// these two methods just stop console spam on Tiger; they are not actually used
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [[self arrangedObjects] count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	return nil;
}

#pragma mark -

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	isEditing = YES;
	return YES;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if (isEditing)
	{
		isEditing = NO;
		[self performSelector:@selector(rearrangeObjects) withObject:nil afterDelay:0];
	}
}

- (void)rearrangeObjects
{
	if (!isEditing) [super rearrangeObjects];
}

- (void)objectDidBeginEditing:(id)editor
{
	isEditing = YES;
}
@end
