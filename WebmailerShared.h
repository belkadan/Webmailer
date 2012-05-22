/*******************************************************************************
 Copyright (c) 2006-2011 Jordy Rose
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 
 Except as contained in this notice, the name(s) of the above copyright holders
 shall not be used in advertising or otherwise to promote the sale, use or other
 dealings in this Software without prior authorization.
*******************************************************************************/

#define AppleMailDomain ComBelkadanWebmailer_AppleMailDomain
/*! The domain "com.apple.mail", used to select a default Mail app if the user has not. */
extern NSString * const AppleMailDomain;

#define WebmailerAppDomain ComBelkadanWebmailer_AppDomain
/*! The domain "com.belkadan.Webmailer", used for all Webmailer defaults. */
extern NSString * const WebmailerAppDomain;

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

#define WebmailerMailtoScheme ComBelkadanWebmailer_MailtoScheme
/*! The mailto URL scheme, i.e. <code>@"mailto"</code> */
extern NSString * const WebmailerMailtoScheme;


#define WebmailerDestinationIsActiveKey ComBelkadanWebmailer_DestinationIsActiveKey
/*! The key in a destination dictionary for whether or not the destination is active. */
extern NSString * const WebmailerDestinationIsActiveKey;

#define WebmailerDestinationURLKey ComBelkadanWebmailer_DestinationURLKey
/*! The key in a destination dictionary for its URL. */
extern NSString * const WebmailerDestinationURLKey;

#define WebmailerDestinationNameKey ComBelkadanWebmailer_DestinationNameKey
/*! The key in a destination dictionary for its name. */
extern NSString * const WebmailerDestinationNameKey;
