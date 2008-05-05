//
//  CMSCommon.m
//
//  Created by Ryan on 9/2/06.
//  Copyright 2006-2008 Chimoosoft. All rights reserved.
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



#import "CMSCommon.h"
#import "CMSFileUtils.h"

@implementation CMSCommon


typedef enum {
	CMSYES = 1, CMSNO = 0, CMSUNKNOWN = 2
} CMSBoolType;

// Improve speed by caching this info.
static CMSBoolType __isLeopardOrHigher = CMSUNKNOWN;
static CMSBoolType __isTigerOrHigher = CMSUNKNOWN;


+ (void)openURLFromString:(NSString *)urlString {
	NSURL * url = [NSURL URLWithString:urlString];
	[[NSWorkspace sharedWorkspace] openURL:url];	
}

+ (NSString*)operatingSystemVersionString {
	return [[NSProcessInfo processInfo] operatingSystemVersionString];
}

// Returns true if true..
+ (BOOL)systemIsTigerOrLater {
	if (__isTigerOrHigher != CMSUNKNOWN) return (__isTigerOrHigher == CMSYES);
	
	SInt32 MacVersion;
	
	if (Gestalt(gestaltSystemVersion, &MacVersion) == noErr) {
		if (MacVersion < 0x1040) {
			return NO;
		}		
		__isTigerOrHigher = CMSYES;
		return YES;
	}
	return NO;
}	

// Returns true if true..
+ (BOOL)systemIsLeopardOrLater {
	if (__isLeopardOrHigher != CMSUNKNOWN) return (__isLeopardOrHigher == CMSYES);
	
	SInt32 MacVersion;
	
	if (Gestalt(gestaltSystemVersion, &MacVersion) == noErr) {
		if (MacVersion < 0x1050) {
			return NO;
		}
		__isTigerOrHigher = CMSYES;
		__isLeopardOrHigher = CMSYES;		
		return YES;
	}
	return NO;
}	


+ (void)quitIfNotTiger {
	if (![CMSCommon systemIsTigerOrLater]) {
		int result = NSRunAlertPanel(NSLocalizedStringFromTable(@"UnsupportedVersion", @"CMSCommonStrings", @""), 
									 [NSLocalizedStringFromTable(@"RequiresTiger", @"CMSCommonStrings", @"") stringByAppendingString:NSLocalizedStringFromTable(@"PleaseUpgrade", @"CMSCommonStrings", @"")],
									 NSLocalizedStringFromTable(@"Okay", @"CMSCommonStrings", @""), @"", @"", nil);
		
		result = 0;
		[[NSApplication sharedApplication] terminate:self];
	}	
}



+ (void)composeEmailTo:(NSString*)to withSubject:(NSString*)subject andBody:(NSString*)body {
	NSString * encodedSubject = [NSString stringWithFormat:@"SUBJECT=%@", 
		[subject stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
	NSString * encodedBody = [NSString stringWithFormat:@"BODY=%@", 
		[body stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
	NSString * encodedTo = [to stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];

	NSString * encodedURL = [NSString stringWithFormat:@"mailto:%@?%@&%@", encodedTo, encodedSubject, encodedBody];
	
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:encodedURL]];
}

+ (void)sendFeedbackForProduct:(NSString*)productName {	
	[self sendFeedbackForProduct:productName appendingString:nil];
}

+ (void)sendFeedbackForProduct:(NSString*)productName appendingString:(NSString*)string {
	NSString * toAppend = @"";
	if (nil != string) toAppend = string;
	
	NSString * body = [NSString stringWithFormat:@"%@ Version %@\nMac OS X %@%@", productName, [CMSCommon applicationVersionString], [CMSCommon operatingSystemVersionString], toAppend];
	
	[CMSCommon composeEmailTo:@"support@chimoosoft.com"
				  withSubject:[NSString stringWithFormat:@"%@ %@ Support", productName, [CMSCommon applicationVersionString]]
					  andBody:body];	
	
}


+ (NSString*)quickTimeVersionString {
	
	NSString * path = @"/System/Library/QuickTime/QuickTimeH264.component/";
	
	if (![CMSFileUtils pathExists:path]) {
		return nil;
	}
	
	NSBundle * bundle = [NSBundle bundleWithPath:path];
	if (!bundle) return nil;
	
	return [[bundle infoDictionary] objectForKey:@"CFBundleShortVersionString"];	
}


+ (void)openChimoosoftHomePage {
	[CMSCommon openURLFromString:@"http://www.chimoosoft.com/"];
}

+ (void)openDonationPage {
	[CMSCommon openURLFromString:@"http://www.chimoosoft.com/donations/"];
}

+ (NSString*)applicationName {
	return [[[NSBundle bundleForClass:[CMSCommon class]] infoDictionary] objectForKey:@"CFBundleName"];
}

+ (NSString*)applicationVersionString {
	return [[[NSBundle bundleForClass:[CMSCommon class]] infoDictionary] objectForKey:@"CFBundleVersion"];
}

+ (void)runPreReleaseWarning {
	int clickValue = NSRunAlertPanel(@"Pre-Release Warning", 
									 @"This is pre-release software and may behave unpredictably; proceed at your own risk.",
									 NSLocalizedStringFromTable(@"OK", @"CMSCommonStrings", @""), NSLocalizedStringFromTable(@"Quit", @"CMSCommonStrings", @""), nil);
	
	if (clickValue == NSCancelButton) {
		[[NSApplication sharedApplication] terminate:self];
	}
}

+ (void)runModifiedOrMissingWarning {
	int clickValue = NSRunAlertPanel(NSLocalizedStringFromTable(@"ComponentMissingTitle", @"CMSCommonStrings", @""), 
									 NSLocalizedStringFromTable(@"ComponentMissingBody", @"CMSCommonStrings", @""),
									 NSLocalizedStringFromTable(@"Quit", @"CMSCommonStrings", @""), nil, nil);
	
	if (clickValue == NSOKButton) {
		[[NSApplication sharedApplication] terminate:self];
	}
}


// Pass in an md5 in the original parameter.  Looks for script in MacOS folder inside bundle.
// Passing a script extension is optional - it will try to add one if you don't.
+ (NSAppleEventDescriptor*)runCompiledAppleScriptInBundle:(NSString*)name matching:(NSString*)original {
	NSFileManager * man = [NSFileManager defaultManager];
	
	NSString * path = [NSString stringWithFormat:@"%@/Contents/MacOS/%@", [[NSBundle mainBundle] bundlePath], name];	
	if (![man fileExistsAtPath:path]) {
		// try adding scpt extension.
		path = [path stringByAppendingPathExtension:@"scpt"];
	}
	if (![man fileExistsAtPath:path]) {
		return nil;		// oops!
	}
	
	// Security check to make sure nobody modified our script.
	if (![CMSFileUtils gallimaufryPath:path matches:original]) {
		[CMSCommon runModifiedOrMissingWarning];
		return nil;
	}
	
			
	//NSString* path = [[NSBundle mainBundle] pathForResource:name ofType:@"scpt" inDirectory:@"Scripts"];
	
	NSURL* url = [NSURL fileURLWithPath:path];
	if (url == nil) return nil;
	
	NSDictionary* errors = nil;
	NSAppleScript* appleScript = [[NSAppleScript alloc] initWithContentsOfURL:url error:&errors];
	if ([errors count] > 0) {
		NSLog([errors description]);
		return nil;
	}
	if (appleScript == nil) return nil;
	
	NSDictionary * executeErrors = nil;
	NSAppleEventDescriptor * descriptor = [appleScript executeAndReturnError:&executeErrors];
	if ([executeErrors count] > 0) {
		NSLog([executeErrors description]);
		return nil;
	}
	
	return descriptor;
}


+ (void)runScriptFromString:(NSString*)source {
	NSAppleScript * appleScript = [[NSAppleScript alloc] initWithSource:source];
						
	if (appleScript == nil) return;
	
	@try {		
		NSDictionary * executeErrors = nil;
		NSAppleEventDescriptor * descriptor = [appleScript executeAndReturnError:&executeErrors];
		if (!descriptor) NSLog(@"no descriptor");
		if ([executeErrors count] > 0) {
			NSLog([executeErrors description]);
		}	
	} @catch (NSException * e) {
		NSLog(@"Exception running applescript.");
	}
}
							 

+ (double)nowInMilliseconds {
	Nanoseconds nanosec = AbsoluteToNanoseconds(UpTime());
	return (double)UnsignedWideToUInt64(nanosec)/1000000.0;
}



// Figure out which web browser the user has set as default and return a URL to it or nil if not found.
+ (NSURL*)defaultWebBrowser {
	NSURL * urlToTest = [[NSURL alloc] initWithString:@"http://www.apple.com/"];
	NSURL * url = [CMSCommon defaultApplicationForURL:urlToTest];
	[urlToTest release];
	return url;
}

+ (BOOL)defaultWebBrowserIsRunning {
	return [CMSCommon defaultApplicationIsRunningForURL:[CMSCommon defaultWebBrowser]];
}

// Return the (filesystem) URL to the default application for the passed URL type.
+ (NSURL*)defaultApplicationForURL:(NSURL*)url {
	if (nil == url) return nil;
	
	NSURL * outURL = nil;
	OSStatus status =  LSGetApplicationForURL((CFURLRef)url, kLSRolesViewer, NULL, (CFURLRef*) &outURL);		
	
	if (status != 0) return nil;	
	
	return [outURL autorelease];
}


// Pass this the URL to a default application as returned from [CMSCommon defaultApplicationForURL].
// Returns YES if it's running, NO otherwise.
+ (BOOL)defaultApplicationIsRunningForURL:(NSURL*)defaultApp {
	NSString * defaultAppName = [[defaultApp absoluteString] lastPathComponent];
	NSArray * launchedApplications = [[NSWorkspace sharedWorkspace] launchedApplications];
	NSEnumerator * e = [launchedApplications objectEnumerator];
	id obj;
	BOOL appIsRunning = NO;
	while (obj = [e nextObject]) {
		if ([[[obj valueForKey:@"NSApplicationPath"] lastPathComponent] isEqualToString: defaultAppName]) {
			// found a match
			appIsRunning = YES;
		}
	}
	
	return appIsRunning;
}

+ (NSString*)pluralizeWithBase:(NSString*)base andCount:(int)count {
	if (count == 1) return base;
	else return [NSString stringWithFormat:@"%@s", base];
}

+ (NSString*)pluralizeWithSingular:(NSString*)singular plural:(NSString*)plural andCount:(int)count {
	if (count == 1) return singular;
	else return plural;
}


@end
