#import <Cocoa/Cocoa.h>


@interface ComBelkadanWebmailer_URLHandlerController : NSObject {
	IBOutlet NSPopUpButton *popup;
	NSInteger numberOfExtraItems;
	
	NSString *scheme;
	NSString *fallbackBundleID;
	NSString *selectedBundleID;

	BOOL shouldFullRefresh;
}

- (IBAction)refresh:(id)sender;
- (IBAction)chooseApp:(id)sender;
- (IBAction)chooseOther:(id)sender;

@property(readonly,copy) NSString *scheme;
@property(readonly,copy) NSString *fallbackBundleID;

- (void)setScheme:(NSString *)scheme fallbackBundleID:(NSString *)fallback;

@property(readonly,copy) NSString *selectedBundleID;
@property(readwrite) BOOL shouldFullRefresh;
@end

@compatibility_alias URLHandlerController ComBelkadanWebmailer_URLHandlerController;
