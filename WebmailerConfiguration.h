#import <Cocoa/Cocoa.h>


@interface ComBelkadanWebmailer_Configuration : NSObject {
	NSString *name;
	NSString *destination;
	BOOL active;
}

- (id)initWithDictionaryRepresentation:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

@property (readwrite,copy) NSString *name;
@property (readwrite,copy) NSString *destination;
@property (readwrite,assign,getter=isActive) BOOL active;
@end
