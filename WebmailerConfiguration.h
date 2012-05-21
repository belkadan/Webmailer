#import <Foundation/Foundation.h>


@interface ComBelkadanWebmailer_Configuration : NSObject {
	NSString *name;
	NSString *destinationURL;
	BOOL active;
}

- (id)initWithName:(NSString *)name destination:(NSString *)destination;

- (id)initWithDictionaryRepresentation:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

@property (readwrite,copy) NSString *name;
@property (readwrite,copy) NSString *destinationURL;
@property (readwrite,assign,getter=isActive) BOOL active;
@end
