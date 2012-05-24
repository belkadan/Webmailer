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
