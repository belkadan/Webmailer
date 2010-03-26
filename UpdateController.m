#import "UpdateController.h"
#import "CTGradient.h"

#import "SUHost.h"
#import "SUInstaller.h"
#import "SUStatusController.h"
#import "SUUpdateAlert.h"
#import "SUUIBasedUpdateDriver.h"

@interface SUUpdater ()
- (id)initForBundle:(NSBundle *)bundle;
- (void)checkForUpdatesWithDriver:(SUUpdateDriver *)updateDriver;
@end

@interface ComBelkadanWebmailer_KnownItemUpdateDriver : SUUIBasedUpdateDriver {
}
- (id)initWithUpdater:(SUUpdater *)updater updateItem:(SUAppcastItem *)updateItem;
@end

extern NSString * const SUSkippedVersionKey;

static const CGFloat kUpdateBarHeight = 29;


@interface ComBelkadanWebmailer_UpdateController ()
- (void)makeUpdateBarVisible:(BOOL)showUpdateBar;
- (void)getFramesForUpdateBarHeightChange:(CGFloat)deltaUpdateHeight updateBarFrame:(NSRect *)updateFrame mainFrame:(NSRect *)mainFrame;
@end

@implementation ComBelkadanWebmailer_UpdateController
+ (id)sharedUpdater {
    return [self updaterForBundle:[NSBundle bundleForClass:[self class]]];
}

- (id)init {
    return [self initForBundle:[NSBundle bundleForClass:[self class]]];
}

- (void)dealloc {
	[availableUpdate release];
	[updateAlert release];
	[super dealloc];
}

#pragma mark -

- (void)awakeFromNib {	
	// Hide update bar
	NSRect updateFrame, mainFrame;
	[self getFramesForUpdateBarHeightChange:-kUpdateBarHeight updateBarFrame:&updateFrame mainFrame:&mainFrame];
	[mainView setFrame:mainFrame];
	[updateBar setFrame:updateFrame];
	[updateBar setHidden:YES];
	
	// Set update bar gradient
	Class Gradient_class = NSClassFromString(@"NSGradient");
	if (Gradient_class == Nil) Gradient_class = [CTGradient class];
	
	id gradient = [[Gradient_class alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.19 alpha:1.0] endingColor:[NSColor colorWithCalibratedWhite:0.09 alpha:1.0]];
	[updateBar setBackgroundGradient:gradient];
	[gradient release];
	
	// Set update icon
	NSImage *image = [[NSImage alloc] initWithContentsOfFile:[[self hostBundle] pathForImageResource:@"download"]];
	[updateIconView setImage:image];
	[image release];
	
	// And check for updates
	[self setDelegate:self];
	[self checkForUpdateInformation];
}

- (void)getFramesForUpdateBarHeightChange:(CGFloat)deltaUpdateHeight updateBarFrame:(NSRect *)updateFrame mainFrame:(NSRect *)mainFrame {
	BOOL isFlipped = [[mainView superview] isFlipped];
	*updateFrame = [updateBar frame];
	*mainFrame = [mainView frame];

	updateFrame->size.height += deltaUpdateHeight;
	mainFrame->size.height -= deltaUpdateHeight;
	if (isFlipped) {
		mainFrame->origin.y += deltaUpdateHeight;
	} else {
		updateFrame->origin.y -= deltaUpdateHeight;
	}
}

- (void)makeUpdateBarVisible:(BOOL)showUpdateBar {
	if ([updateBar isHidden] != showUpdateBar) return;

	CGFloat deltaUpdateHeight = kUpdateBarHeight;
	if (!showUpdateBar) {
		deltaUpdateHeight *= -1;
	} else {
		[updateBar setHidden:NO];
	}

	NSRect updateFrame, mainFrame;
	[self getFramesForUpdateBarHeightChange:deltaUpdateHeight updateBarFrame:&updateFrame mainFrame:&mainFrame];

	NSViewAnimation *animation = [[NSViewAnimation alloc] initWithViewAnimations:
		[NSArray arrayWithObjects:
			[NSDictionary dictionaryWithObjectsAndKeys:
				updateBar, NSViewAnimationTargetKey,
				[NSValue valueWithRect:updateFrame], NSViewAnimationEndFrameKey,
				nil],
			[NSDictionary dictionaryWithObjectsAndKeys:
				mainView, NSViewAnimationTargetKey,
				[NSValue valueWithRect:mainFrame], NSViewAnimationEndFrameKey,
				nil],
			nil]
		];

	[animation setDuration:0.25];
	[animation startAnimation];
	
	[animation release];
}

#pragma mark -

- (void)updater:(SUUpdater *)updater didFindValidUpdate:(SUAppcastItem *)update {	
	[self willChangeValueForKey:@"availableUpdateVersion"];
	availableUpdate = [update retain];
	[self didChangeValueForKey:@"availableUpdateVersion"];

	[self makeUpdateBarVisible:YES];
}

- (IBAction)showReleaseNotes:(id)sender {
	if (availableUpdate) {
		updateAlert = [[SUUpdateAlert alloc] initWithAppcastItem:availableUpdate host:host];
		[updateAlert setDelegate:self];
		[NSApp beginSheet:[updateAlert window] modalForWindow:[updateBar window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
	} else {
		NSBeep();
	}
}

- (void)updateAlert:(SUUpdateAlert *)alert finishedWithChoice:(SUUpdateAlertChoice)updateChoice {
	[NSApp endSheet:[alert window]];

	switch (updateChoice) {
	case SUInstallUpdateChoice:
		[self installUpdate:nil];
		break;
	case SUSkipThisVersionChoice:
		[host setObject:[availableUpdate versionString] forUserDefaultsKey:SUSkippedVersionKey];
		// no break
	default:
		; // no action necessary
	}
	
	[updateAlert release];
	updateAlert = nil;
}

- (IBAction)installUpdate:(id)sender {
	if (availableUpdate) {
		[self checkForUpdatesWithDriver:[[[ComBelkadanWebmailer_KnownItemUpdateDriver alloc] initWithUpdater:self updateItem:availableUpdate] autorelease]];
	} else {
		NSBeep();
	}
}

- (NSString *)currentVersion {
	NSString *versionString = [[self hostBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	if (!versionString) {
		versionString = [[self hostBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
	}
	return versionString;
}

- (NSString *)availableUpdateVersion {
	return [availableUpdate displayVersionString];
}

@end

// From Sparkle.pch
#define SPARKLE_BUNDLE [NSBundle bundleWithIdentifier:@"org.andymatuschak.Sparkle"]
#define SULocalizedString(key,comment) NSLocalizedStringFromTableInBundle(key, @"Sparkle", SPARKLE_BUNDLE, comment)

@interface SUBasicUpdateDriver ()
- (BOOL)shouldInstallSynchronously;
- (id <SUVersionComparison>)_versionComparator;
@end

@implementation ComBelkadanWebmailer_KnownItemUpdateDriver

- (id)initWithUpdater:(SUUpdater *)givenUupdater updateItem:(SUAppcastItem *)item {
	self = [super initWithUpdater:givenUupdater];
	if (self) {
		updateItem = [item retain];
	}
	return self;
}

- (void)checkForUpdatesAtURL:(NSURL *)givenURL host:(SUHost *)givenHost {
	// skip the checking stage
	appcastURL = [givenURL copy];
	host = [givenHost retain];

	statusController = [[SUStatusController alloc] initWithHost:host];
	[statusController beginActionWithTitle:SULocalizedString(@"Downloading update...", @"Take care not to overflow the status window.") maxProgressValue:0 statusText:nil];
	[statusController setButtonTitle:SULocalizedString(@"Cancel", nil) target:self action:@selector(cancelDownload:) isDefault:NO];
	
	[NSApp beginSheet:[statusController window] modalForWindow:[NSApp mainWindow] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];

	[self downloadUpdate];
}

- (BOOL)shouldInstallSynchronously { return YES; }

- (void)unarchiverDidFinish:(SUUnarchiver *)ua {
	[self installUpdate]; // since we're running a sheet, don't wait to confirm
}

- (void)cleanUp {
	if (statusController) {
		[NSApp endSheet:[statusController window]];
		[[statusController window] orderOut:self];
	}
	[super cleanUp];
}

- (void)abortUpdate {
	if (statusController) {
		[NSApp endSheet:[statusController window]];
	}
	[super abortUpdate];
}

- (void)showModalAlert:(NSAlert *)alert {
	[alert setIcon:[host icon]];
	[self performSelector:@selector(runAlert:) withObject:alert afterDelay:0];
}

- (void)runAlert:(NSAlert *)alert {
	[alert beginSheetModalForWindow:[NSApp mainWindow] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
}

@end

