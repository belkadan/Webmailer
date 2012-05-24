#define WebmailerAppDomain ComBelkadanWebmailer_AppDomain
/*! The domain "com.belkadan.Webmailer", used for all Webmailer defaults. */
extern NSString * const WebmailerAppDomain;

#define WebmailerMailtoScheme ComBelkadanWebmailer_MailtoScheme
/*! The URL scheme "mailto". */
extern NSString * const WebmailerMailtoScheme;

#define WebmailerConfigurationsKey ComBelkadanWebmailer_ConfigurationsKey
/*! The key used to retrieve the list of configurations from the defaults. */
extern NSString * const WebmailerConfigurationsKey;

#define WebmailerCurrentDestinationKey ComBelkadanWebmailer_CurrentDestinationKey
/*! The key used to retrieve the current destination from the defaults. */
extern NSString * const WebmailerCurrentDestinationKey;

#define WebmailerBrowserChoosingModeKey ComBelkadanWebmailer_BrowserChoosingModeKey
/*! The key used to retrieve the current browser choosing mode. */
extern NSString * const WebmailerBrowserChoosingModeKey;

enum {
	BrowserChoiceBestGuess = 0,
	BrowserChoiceSystemDefault,
	BrowserChoiceSpecific,
	
	BrowserChoiceLast = BrowserChoiceSpecific
};
typedef NSUInteger BrowserChoice;


#define WebmailerChosenBrowserIDKey ComBelkadanWebmailer_ChosenBrowserIDKey
/*! The key used to retrieve the current browser choosing mode. */
extern NSString * const WebmailerChosenBrowserIDKey;

#define WebmailerDisableAppChoosingKey ComBelkadanWebmailer_DisableAppChoosingKey
/*! The old key for whether or not the user wants smart app choosing. */
extern NSString * const WebmailerDisableAppChoosingKey;


#define WebmailerDestinationIsActiveKey ComBelkadanWebmailer_DestinationIsActiveKey
/*! The key in a destination dictionary for whether or not the destination is active. */
extern NSString * const WebmailerDestinationIsActiveKey;

#define WebmailerDestinationURLKey ComBelkadanWebmailer_DestinationURLKey
/*! The key in a destination dictionary for its URL. */
extern NSString * const WebmailerDestinationURLKey;

#define WebmailerDestinationNameKey ComBelkadanWebmailer_DestinationNameKey
/*! The key in a destination dictionary for its name. */
extern NSString * const WebmailerDestinationNameKey;
