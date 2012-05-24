#import "ExtraSettingsController.h"

#import <Sparkle/Sparkle.h>
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

	[browserController setScheme:kHTTPScheme fallbackBundleID:kAppleSafariID];
	browserController.selectedBundleID = [defaults objectForKey:WebmailerChosenBrowserIDKey];
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
	[savePanel beginSheetForDirectory:nil file:fileName modalForWindow:[mainWindowView window] modalDelegate:self didEndSelector:@selector(exportSettingsPanelDidEnd:returnCode:contextInfo:) contextInfo:NULL];	
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
	[[NSOpenPanel openPanel] beginSheetForDirectory:nil file:nil types:[NSArray arrayWithObject:@"plist"] modalForWindow:[mainWindowView window] modalDelegate:self didEndSelector:@selector(importSettingsPanelDidEnd:returnCode:contextInfo:) contextInfo:NULL];
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
		[sorry beginSheetModalForWindow:[mainWindowView window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
		
	} else if ([settingsVersion compare:@"2" options:NSCaseInsensitiveSearch|NSNumericSearch] != NSOrderedAscending) {
		NSBundle *bundle = [NSBundle bundleForClass:[ExtraSettingsController class]];
		
		NSAlert *sorry = [[[NSAlert alloc] init] autorelease];
		[sorry setIcon:GetWebmailerIcon()];
		[sorry setMessageText:NSLocalizedStringFromTableInBundle(@"Could not read settings file.", @"Localizable", bundle, @"Settings import/export")];
		[sorry setInformativeText:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"These settings are for Webmailer %@, but you have %@.", @"Localizable", bundle, @"Settings import/export"), settingsVersion, [bundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey]]];
		[sorry beginSheetModalForWindow:[mainWindowView window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];

	} else {
		ComBelkadanUtils_DefaultsDomain *defaults = [DefaultsDomain domainForName:WebmailerAppDomain];
		[defaults beginTransaction];

		NSMutableSet *existingDestinations = [NSMutableSet setWithArray:[[configurationController arrangedObjects] valueForKey:WebmailerDestinationURLKey]];

		// Change to the new selected destination.
		NSString *newActiveDestination = [settings objectForKey:WebmailerCurrentDestinationKey];
		if (newActiveDestination && ![[defaults objectForKey:WebmailerCurrentDestinationKey] isEqual:newActiveDestination]) {
			if ([existingDestinations containsObject:newActiveDestination]) {
				// Case 1: The selected destination already exists in the current set.
				// We have to (a) set the new active destination, and (b) clear the old one.
				BOOL foundOneAlready = NO;
				for (NSMutableDictionary *existing in [configurationController arrangedObjects]) {
					if ([newActiveDestination isEqual:[existing objectForKey:WebmailerDestinationURLKey]]) {
						[existing setObject:[NSNumber numberWithBool:YES] forKey:WebmailerDestinationIsActiveKey];
						if (foundOneAlready) break;
						foundOneAlready = YES;
					} else if ([[existing objectForKey:WebmailerDestinationIsActiveKey] boolValue]) {
						[existing removeObjectForKey:WebmailerDestinationIsActiveKey];
						if (foundOneAlready) break;
						foundOneAlready = YES;
					}
				}
			} else {
				// Case 2: The selected destination is new.
				// We only have to clear the old active flag.
				for (NSMutableDictionary *existing in [configurationController arrangedObjects]) {
					if ([[existing objectForKey:WebmailerDestinationIsActiveKey] boolValue]) {
						[existing removeObjectForKey:WebmailerDestinationIsActiveKey];
						break;
					}
				}
			}

			[defaults setObject:newActiveDestination forKey:WebmailerCurrentDestinationKey];
		}
		
		// Add any missing destination URLs. Unique by URL only -- if two destinations have the same name, keep the existing one.
		BOOL didChange = NO;
		for (NSDictionary *dict in destinations) {
			if (![existingDestinations containsObject:[dict objectForKey:WebmailerDestinationURLKey]]) {
				NSMutableDictionary *newConfiguration = [dict mutableCopy];
				if (!newActiveDestination) [newConfiguration removeObjectForKey:WebmailerDestinationIsActiveKey];
				[configurationController addObject:newConfiguration];
				[newConfiguration release];
				didChange = YES;
			}
		}
		if (didChange) [configurationController rearrangeObjects];

		// Set the browser choosing mode...
		NSNumber *browserChoosingMode = [settings objectForKey:WebmailerBrowserChoosingModeKey];
		if (!browserChoosingMode) {
			if (![defaults objectForKey:WebmailerBrowserChoosingModeKey]) {
				// Only fall back to the legacy key if we don't have an explicit setting here.
				browserChoosingMode = [settings objectForKey:WebmailerDisableAppChoosingKey];
			}
		}
		if (browserChoosingMode) self.browserChoosingMode = [browserChoosingMode unsignedIntegerValue];

		// ...and the selected browser.
		NSString *selectedBrowser = [settings objectForKey:WebmailerChosenBrowserIDKey];
		if (selectedBrowser) browserController.selectedBundleID = selectedBrowser;

		[defaults endTransaction];
	}
	
	[settings release];
}

#pragma mark -

- (NSArray *)dragTypesForDropOverlayView:(ComBelkadanUtils_DropOverlayView *)dropView {
	return [NSArray arrayWithObject:NSFilenamesPboardType];
}

- (NSDragOperation)dropOverlayView:(ComBelkadanUtils_DropOverlayView *)view validateDrop:(id <NSDraggingInfo>)info {
	NSPasteboard *pboard = [info draggingPasteboard];
	NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObject:NSFilenamesPboardType]];
	NSAssert([type isEqual:NSFilenamesPboardType], @"Only our drag type should be enabled.");
	
	NSArray *array = [pboard propertyListForType:type];
	if ([array count] != 1) return NSDragOperationNone;
	
	if (![[[array objectAtIndex:0] pathExtension] isEqual:@"plist"]) return NSDragOperationNone;
	
	return NSDragOperationCopy;
}

- (BOOL)dropOverlayView:(ComBelkadanUtils_DropOverlayView *)view acceptDrop:(id <NSDraggingInfo>)info {
	NSPasteboard *pboard = [info draggingPasteboard];
	NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObject:NSFilenamesPboardType]];
	NSAssert([type isEqual:NSFilenamesPboardType], @"Only our drag type should be enabled.");
	
	NSArray *array = [pboard propertyListForType:type];
	[self importSettingsFromURL:[NSURL fileURLWithPath:[array objectAtIndex:0]]];
	
	// Whether or not we succeeded in importing the file, the drag icon should
	// still not slide back.
	return YES;
}

#pragma mark -

- (IBAction)showAsSheet:(id)sender
{
	[NSApp beginSheet:[self window] modalForWindow:[mainWindowView window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
}

- (IBAction)endSheet:(id)sender
{
	[NSApp endSheet:[self window]];
	[self close];
}

@end
