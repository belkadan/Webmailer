#import <AppKit/AppKit.h>
#import <PreferencePanes/NSPreferencePane.h>

@class ComBelkadanWebmailer_URLHandlerController, ComBelkadanUtils_EditTrackingTableView, ComBelkadanUtils_DefaultsDomain;

@interface ComBelkadanWebmailer_PrefPane : NSPreferencePane
{
	ComBelkadanUtils_DefaultsDomain *defaults;
	NSMutableArray *configurations;

	IBOutlet NSArrayController *configurationController;
	IBOutlet ComBelkadanUtils_EditTrackingTableView *configurationTable;

	IBOutlet ComBelkadanWebmailer_URLHandlerController *mailtoController;
}
- (IBAction)apply:(id)sender;
- (IBAction)update:(id)sender;
- (IBAction)add:(id)sender;
@end

@compatibility_alias WebmailerPref ComBelkadanWebmailer_PrefPane;
