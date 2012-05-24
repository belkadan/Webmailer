#if defined(MAC_OS_X_VERSION_10_5) && MAC_OS_X_VERSION_10_5 <= MAC_OS_X_VERSION_MAX_ALLOWED
#import <ScriptingBridge/ScriptingBridge.h>

# if defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_10_6 <= MAC_OS_X_VERSION_MAX_ALLOWED
@interface WebmailerDaemon () <SBApplicationDelegate>
@end
# endif /* MAC_OS_X_VERSION_10_6 <= MAC_OS_X_VERSION_MAX_ALLOWED */

@interface SystemPreferencesApplication : SBApplication
- (void)setCurrentPane:(SBObject *)currentPane;
- (SBObject *)currentPane;
- (SBElementArray *)panes;
@end

@interface TerminalApplication : SBApplication
- (SBObject *)doScript:(NSString *)script in:(id)tabOrWindow;
@end
#endif /* MAC_OS_X_VERSION_10_5 <= MAC_OS_X_VERSION_MAX_ALLOWED */
