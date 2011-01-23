@interface MailtoFields : NSObject
{
	NSString *mailtoURL;
	NSUInteger questionMarkIndex, urlLength;
}
- (id)initWithURLString:(NSString *)mailtoURLString;
- (NSString *)valueForHeader:(NSString *)header escapeQuotes:(BOOL)shouldForceQuoteEscapes;
- (NSString *)rawValueForHeader:(NSString *)header;
@end
