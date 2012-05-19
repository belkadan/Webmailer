#import "WebmailerConfiguration.h"
#import "WebmailerShared.h"

@implementation ComBelkadanWebmailer_Configuration
@synthesize name, destination, active;

- (id)initWithName:(NSString *)givenName destination:(NSString *)givenDestination
{
	self = [super init];
	if (!self) return nil;

	self.name = givenName;
	self.destination = givenDestination;

	return self;
}

- (id)init
{
	return [self initWithName:@"" destination:@""];
}

- (id)initWithDictionaryRepresentation:(NSDictionary *)dict
{
	self = [self initWithName:[dict objectForKey:WebmailerDestinationNameKey] destination:[dict objectForKey:WebmailerDestinationURLKey]];
	if (!self) return nil;

	self.active = [[dict objectForKey:WebmailerDestinationIsActiveKey] boolValue];

	return self;
}

#pragma mark -

- (NSDictionary *)dictionaryRepresentation
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
		self.name, WebmailerDestinationNameKey,
		self.destination, WebmailerDestinationURLKey,
		(self.active ? [NSNumber numberWithBool:YES] : nil), WebmailerDestinationIsActiveKey,
		nil];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<WebmailerConfiguration: %@>", self.name];
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
