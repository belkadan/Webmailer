#import "DefaultsDomain.h"

static NSMutableDictionary *domains = nil;

@interface ComBelkadanUtils_DefaultsDomain ()
- (id)initWithDomainName:(NSString *)domainName;
@end

@implementation ComBelkadanUtils_DefaultsDomain
@synthesize domain;

+ (void)initialize {
	if (self == [ComBelkadanUtils_DefaultsDomain class]) {
		domains = [[NSMutableDictionary alloc] init];
	}
}

+ (ComBelkadanUtils_DefaultsDomain *)domainForName:(NSString *)domainName {
	ComBelkadanUtils_DefaultsDomain *domain = [domains objectForKey:domainName];
	if (!domain) {
		domain = [[self alloc] initWithDomainName:domainName];
		[domains setObject:domain forKey:domainName];
		[domain release];
	}
	return domain;
}

- (id)init {
	return [self initWithDomainName:[[NSBundle mainBundle] bundleIdentifier]];
}

- (id)initWithDomainName:(NSString *)domainName {
	self = [super init];
	if (self) {
		domain = [domainName copy];
		values = [[NSMutableDictionary alloc] init];
		[self refresh];
	}
	
	return self;
}

- (void)dealloc {
	[domain release];
	[values release];
	[super dealloc];
}

- (void)refresh {
	[values setDictionary:[[NSUserDefaults standardUserDefaults] persistentDomainForName:self.domain]];
}

- (void)save {
	if (transactionCount == 0) {
		[[NSUserDefaults standardUserDefaults] setPersistentDomain:values forName:self.domain];
	}
}

- (void)beginTransaction {
	++transactionCount;
}

- (void)endTransaction {
	NSAssert(transactionCount > 0, @"Unbalanced transaction count (more ends than begins)");
	--transactionCount;
	if (transactionCount == 0) [self save];
}

#pragma mark -

- (id)objectForKey:(id)key {
	return [values objectForKey:key];
}

- (NSUInteger)count {
	return [values count];
}

- (NSEnumerator *)keyEnumerator {
	return [values keyEnumerator];
}

#pragma mark -

- (void)removeObjectForKey:(id)key {
	[values	removeObjectForKey:key];
	[self save];
}

- (void)setObject:(id)obj forKey:(id)key {
	[values setObject:obj forKey:key];
	[self save];
}

- (void)addEntriesFromDictionary:(NSDictionary *)otherDictionary {
	[values addEntriesFromDictionary:otherDictionary];
	[self save];
}

- (void)removeAllObjects {
	[values removeAllObjects];
	[[NSUserDefaults standardUserDefaults] removePersistentDomainForName:self.domain];
}

- (void)removeObjectsForKeys:(NSArray *)keyArray {
	[values removeObjectsForKeys:keyArray];
	[self save];
}

- (void)setDictionary:(NSDictionary *)otherDictionary {
	[values setDictionary:otherDictionary];
	[self save];
}

// TODO: setValue:forKeyPath:
@end
