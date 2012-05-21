#import "WebmailerConfiguration.h"
#import "WebmailerShared.h"

@implementation ComBelkadanWebmailer_Configuration
@synthesize name, destinationURL, active;

- (id)initWithName:(NSString *)givenName destination:(NSString *)givenDestination
{
	self = [super init];
	if (!self) return nil;

	self.name = givenName;
	self.destinationURL = givenDestination;

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
		self.destinationURL, WebmailerDestinationURLKey,
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
	[destinationURL release];
	[super dealloc];
}

#pragma mark -

- (NSScriptObjectSpecifier *)objectSpecifier
{
	return [[[NSNameSpecifier alloc] initWithContainerClassDescription:[NSScriptClassDescription classDescriptionForClass:[NSApp class]] containerSpecifier:nil key:@"destinations" name:self.name] autorelease];
}

@end
