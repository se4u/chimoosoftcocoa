//
//  CMSCommon.h
//  
//  Created by Ryan on 9/2/06.
//  Copyright 2006 Chimoosoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CMSCommon : NSObject {
}

// Operating System Information
+ (BOOL)systemIsTigerOrLater;
+ (BOOL)systemIsLeopardOrLater;
+ (NSString*)operatingSystemVersionString;
+ (NSString*)quickTimeVersionString;

+ (void)quitIfNotTiger;

// App Version Info
+ (NSString*)applicationVersionString;

// Name of current app.
+ (NSString*)applicationName;

// Emails
+ (void)composeEmailTo:(NSString*)to withSubject:(NSString*)subject andBody:(NSString*)body;
+ (void)sendFeedbackForProduct:(NSString*)productName;
+ (void)sendFeedbackForProduct:(NSString*)productName appendingString:(NSString*)string;

// Open URL's
+ (void)openURLFromString:(NSString *)urlString;
+ (void)openChimoosoftHomePage;
+ (void)openDonationPage;

// Warning dialogs
+ (void)runPreReleaseWarning;
+ (void)runModifiedOrMissingWarning;

// Note that this takes an MD5 hash to work correctly.
+ (NSAppleEventDescriptor*)runCompiledAppleScriptInBundle:(NSString*)name matching:(NSString*)original;

+ (void)runScriptFromString:(NSString*)source;

+ (double)nowInMilliseconds;

// Which application has the user selected to open URL's of this type?
+ (NSURL*)defaultApplicationForURL:(NSURL*)url;
+ (NSURL*)defaultWebBrowser;
+ (BOOL)defaultWebBrowserIsRunning;
+ (BOOL)defaultApplicationIsRunningForURL:(NSURL*)defaultApp;

// Only works properly for english at this point.
+ (NSString*)pluralizeWithBase:(NSString*)base andCount:(int)count;

// Works for anything.
+ (NSString*)pluralizeWithSingular:(NSString*)singular plural:(NSString*)plural andCount:(int)count;

@end
