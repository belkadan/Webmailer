#import <AppKit/AppKit.h>

@class ComBelkadanUtils_DefaultsDomain;
@class ComBelkadanWebmailer_Configuration;

@interface WebmailerDaemon : NSObject
{
	ComBelkadanUtils_DefaultsDomain *defaults;

	NSString *mailtoURL;
	NSURL *sourceAppURL;
	
	NSArray *configurations;
	ComBelkadanWebmailer_Configuration *activeConfiguration;
	
	IBOutlet NSArrayController *configurationController;
	IBOutlet NSTableView *configurationTable;
	IBOutlet NSWindow *configurationWindow;
}

- (void)showConfigurationChooser;
- (IBAction)confirmConfiguration:(id)sender;
- (IBAction)openPreferencePane:(id)sender;

- (void)launchDestination:(NSString *)destinationPrototype;

@property(readonly) NSArray *configurations;
@property(readonly) ComBelkadanWebmailer_Configuration *activeConfiguration;
@end
