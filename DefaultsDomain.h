#import <Foundation/Foundation.h>

@interface ComBelkadanUtils_DefaultsDomain : NSMutableDictionary {
	NSString *domain;
	NSMutableDictionary *values;
	NSUInteger transactionCount;
}

+ (ComBelkadanUtils_DefaultsDomain *)domainForName:(NSString *)domainName;

@property(readonly,copy) NSString *domain;

- (void)refresh;

- (void)beginTransaction;
- (void)endTransaction;
@end

@compatibility_alias DefaultsDomain ComBelkadanUtils_DefaultsDomain;
