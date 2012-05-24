#import "EditTrackingTableView.h"

/*!
 * A table view that sends an action when a text cell has finished editing. The
 * target and action are the cell's target and action.
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
