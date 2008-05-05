//
//  CMSCommon.h
//  
//  Created by Ryan on 9/2/06.
//  Copyright 2006 Chimoosoft. All rights reserved.
//
//  Common operations related to files.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.



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
