#import "WebmailerConfiguration.h"
#import "WebmailerShared.h"

@implementation ComBelkadanWebmailer_Configuration
@synthesize name, destination, active;

- (id)initWithDictionaryRepresentation:(NSDictionary *)dict
{
	self = [super init];
	if (!self) return nil;

	self.name = [dict objectForKey:WebmailerDestinationNameKey];
	self.destination = [dict objectForKey:WebmailerDestinationURLKey];
	self.active = [[dict objectForKey:WebmailerDestinationIsActiveKey] boolValue];

	return self;
}

- (NSDictionary *)dictionaryRepresentation
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
		self.name, WebmailerDestinationNameKey,
		self.destination, WebmailerDestinationURLKey,
		self.active, WebmailerDestinationIsActiveKey,
		nil];
}

- (void)dealloc
{
	[name release];
	[destination release];
	[super dealloc];
}

#pragma mark -

- (NSScriptObjectSpecifier *)objectSpecifier
{
	return [[[NSNameSpecifier alloc] initWithContainerClassDescription:[NSScriptClassDescription classDescriptionForClass:[NSApp class]] containerSpecifier:nil key:@"destinations" name:self.name] autorelease];
}

@end
