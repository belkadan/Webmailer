#import "ExtraSettingsController.h"
#import "URLHandlerController.h"
#import "DefaultsDomain.h"

static NSString * const kHTTPScheme = @"http";
static NSString * const kAppleSafariID = @"com.apple.safari";
static NSString * const kWebmailerIconName = @"com.belkadan.Webmailer";

static NSImage *GetWebmailerIcon ()
{
	static NSImage *prefIcon = nil;
	if (!prefIcon) {
		prefIcon = [NSImage imageNamed:kWebmailerIconName];
		if (!prefIcon) {
			NSBundle *bundle = [NSBundle bundleForClass:[ExtraSettingsController class]];
			prefIcon = [[NSImage alloc] initByReferencingFile:[bundle pathForImageResource:@"icon"]];
			[prefIcon setName:kWebmailerIconName];
		}
	}
	return prefIcon;
}

@implementation ComBelkadanWebmailer_ExtraSettingsController

- (id)init
{
	return [self initWithWindowNibName:@"AdditionalSettings"];
}

- (void)windowDidLoad
{
	[super windowDidLoad];

	ComBelkadanUtils_DefaultsDomain *defaults = [ComBelkadanUtils_DefaultsDomain domainForName:WebmailerAppDomain];

	browserController.selectedBundleID = [defaults objectForKey:WebmailerChosenBrowserIDKey];
	[browserController setScheme:kHTTPScheme fallbackBundleID:kAppleSafariID];
	[browserController addObserver:self forKeyPath:@"selectedBundleID" options:0 context:[ExtraSettingsController class]];
}

#pragma mark -

- (BrowserChoice)browserChoosingMode
{
	ComBelkadanUtils_DefaultsDomain *defaults = [ComBelkadanUtils_DefaultsDomain domainForName:WebmailerAppDomain];
	NSNumber *modeObject = [defaults objectForKey:WebmailerBrowserChoosingModeKey];

	// Backwards compatibility
	if (!modeObject)
	{
		modeObject = [defaults objectForKey:WebmailerDisableAppChoosingKey];
		if (modeObject)
		{
			[defaults removeObjectForKey:WebmailerDisableAppChoosingKey];
			[defaults setObject:[NSNumber numberWithUnsignedInteger:[modeObject unsignedIntegerValue]] forKey:WebmailerBrowserChoosingModeKey];
		}
	}

	return [modeObject unsignedIntegerValue];
}

- (void)setBrowserChoosingMode:(BrowserChoice)mode
{
	NSAssert(mode <= BrowserChoiceLast, @"Invalid browser choice mode.");

	ComBelkadanUtils_DefaultsDomain *defaults = [ComBelkadanUtils_DefaultsDomain domainForName:WebmailerAppDomain];
	[defaults setObject:[NSNumber numberWithUnsignedInteger:mode] forKey:WebmailerBrowserChoosingModeKey];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == [ExtraSettingsController class])
	{
		NSAssert(object == browserController, @"No other objects should be observed.");
		ComBelkadanUtils_DefaultsDomain *defaults = [ComBelkadanUtils_DefaultsDomain domainForName:WebmailerAppDomain];
		[defaults setObject:browserController.selectedBundleID forKey:WebmailerChosenBrowserIDKey];
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark -

- (IBAction)checkForUpdates:(id)sender
{
	[updateController checkForUpdates:sender];
}

- (IBAction)exportSettings:(id)sender
{
	NSString *fileName = NSLocalizedStringFromTableInBundle(@"Webmailer Settings", @"Localizable", [NSBundle bundleForClass:[ExtraSettingsController class]], @"Settings import/export");

	NSSavePanel *savePanel = [NSSavePanel savePanel];
	[savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"plist"]];
	[savePanel setAllowsOtherFileTypes:NO];

	[self endSheet:nil];
	[savePanel beginSheetForDirectory:nil file:fileName modalForWindow:[NSApp mainWindow] modalDelegate:self didEndSelector:@selector(exportSettingsPanelDidEnd:returnCode:contextInfo:) contextInfo:NULL];	
}

- (void)exportSettingsPanelDidEnd:(NSSavePanel *)savePanel returnCode:(NSInteger)returnCode contextInfo:(void *)unused
{
	if (returnCode == NSCancelButton) return;
	
	NSMutableDictionary *settings = [[ComBelkadanUtils_DefaultsDomain domainForName:WebmailerAppDomain] mutableCopy];

	NSBundle *bundle = [NSBundle bundleForClass:[ExtraSettingsController class]];
	NSString *bundleVersion = [bundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
	[settings setObject:bundleVersion forKey:WebmailerAppDomain];
	 
	[settings writeToURL:[savePanel URL] atomically:YES];
	[settings release];
}

- (IBAction)importSettings:(id)sender {
	[self endSheet:nil];
	[[NSOpenPanel openPanel] beginSheetForDirectory:nil file:nil types:[NSArray arrayWithObject:@"plist"] modalForWindow:[NSApp mainWindow] modalDelegate:self didEndSelector:@selector(importSettingsPanelDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)importSettingsPanelDidEnd:(NSOpenPanel *)openPanel returnCode:(NSInteger)returnCode contextInfo:(void *)unused {
	if (returnCode == NSCancelButton) return;
	[openPanel orderOut:nil];
	
	[self importSettingsFromURL:[openPanel URL]];
}

- (void)importSettingsFromURL:(NSURL *)url {
	NSDictionary *settings = [[NSDictionary alloc] initWithContentsOfURL:url];
	NSString *settingsVersion = [settings objectForKey:WebmailerAppDomain];
	NSArray *destinations = [settings objectForKey:WebmailerConfigurationsKey];
	
	if (!settingsVersion && !destinations) {
		NSBundle *bundle = [NSBundle bundleForClass:[ExtraSettingsController class]];
		
		NSAlert *sorry = [[[NSAlert alloc] init] autorelease];
		[sorry setIcon:GetWebmailerIcon()];
		[sorry setMessageText:NSLocalizedStringFromTableInBundle(@"Could not read settings file.", @"Localizable", bundle, @"Settings import/export")];
		[sorry setInformativeText:NSLocalizedStringFromTableInBundle(@"This does not appear to be a Webmailer settings file.", @"Localizable", bundle, @"Settings import/export")];
		[sorry beginSheetModalForWindow:[NSApp mainWindow] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
		
	} else if ([settingsVersion compare:@"2" options:NSCaseInsensitiveSearch|NSNumericSearch] != NSOrderedAscending) {
		NSBundle *bundle = [NSBundle bundleForClass:[ExtraSettingsController class]];
		
		NSAlert *sorry = [[[NSAlert alloc] init] autorelease];
		[sorry setIcon:GetWebmailerIcon()];
		[sorry setMessageText:NSLocalizedStringFromTableInBundle(@"Could not read settings file.", @"Localizable", bundle, @"Settings import/export")];
		[sorry setInformativeText:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"These settings are for Webmailer %@, but you have %@.", @"Localizable", bundle, @"Settings import/export"), settingsVersion, [bundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey]]];
		[sorry beginSheetModalForWindow:[NSApp mainWindow] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];

	} else {
//		BOOL changed = NO;
//		for (NSDictionary *dict in completions) {
//			ComBelkadanKeystone_QueryCompletionItem *item = [[ComBelkadanKeystone_QueryCompletionItem alloc] initWithDictionary:dict];
//			NSUInteger index = [sortedCompletionPossibilities indexOfObjectWithPrimarySortValue:item.keyword];
//			NSUInteger count = [sortedCompletionPossibilities count];
//			BOOL found = NO;
//			while (index < count) {
//				ComBelkadanKeystone_QueryCompletionItem *existing = [sortedCompletionPossibilities objectAtIndex:index];
//				if (![existing.keyword isEqual:item.keyword]) {
//					break;
//				} else if ([existing.URL isEqual:item.URL]) {
//					found = YES;
//					break;
//				}
//				++index;
//			}
//			
//			if (!found) {
//				[sortedCompletionPossibilities addObject:item];
//				changed = YES;
//			}
//			
//			[item release];
//		}
//		
//		if (changed) {
//			[self save];
//			[completionTable reloadData];
//		}
//		
//		// Even though this is a secret setting right now, we should handle it.
//		NSNumber *autocompletionMode = [settings objectForKey:kPreferencesAutocompletionModeKey];
//		if (autocompletionMode) {
//			ComBelkadanUtils_DefaultsDomain *defaults = [ComBelkadanUtils_DefaultsDomain domainForName:kKeystonePreferencesDomain];
//			if (![autocompletionMode isEqual:[defaults objectForKey:kPreferencesAutocompletionModeKey]]) {
//				[defaults setObject:autocompletionMode forKey:kPreferencesAutocompletionModeKey];
//			}
//		}
	}
	
	[settings release];
}

#pragma mark -

- (IBAction)showAsSheet:(id)sender
{
	[NSApp beginSheet:[self window] modalForWindow:[NSApp mainWindow] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
}

- (IBAction)endSheet:(id)sender
{
	[NSApp endSheet:[self window]];
	[self close];
}

@end
