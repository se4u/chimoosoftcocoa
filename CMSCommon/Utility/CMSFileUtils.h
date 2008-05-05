//
//  CMSFileUtils.h
//
//  Created by Ryan on 6/20/07.
//  Copyright 2007 Chimoosoft. All rights reserved.
//
//  Common operations related to files.

#import <Cocoa/Cocoa.h>

@interface CMSFileUtils : NSObject {

}

+ (void)revealPathInFinder:(NSString*)path;
+ (BOOL)pathExists:(NSString *)aFilePath;
+ (BOOL)folderIsWriteable:(NSString*)path;

// Returns path to application support directory for the current program, creating it if it doesn't already exist.
+ (NSString*)applicationSupportPath;

// Same as above, but specify the name of the subfolder (i.e. the program name).
+ (NSString*)applicationSupportPathForName:(NSString*)name;


+ (NSString*)folderSelectionFromUser;

+ (void)openFileInBundle:(NSString*)fileName;

+ (NSString*)incrementalPathForDirectory:(NSString*)directoryPath andFileName:(NSString *)fileName;
+ (NSString*)safeFileNameForString:(NSString*)inName;

// Hashing for security reasons.
// -----------------------------
// Returns MD5 hash of file at path.
+ (NSString*)gallimaufryPath:(NSString*)path;

// Compare md5 of path with original md5.
+ (BOOL)gallimaufryPath:(NSString*)path matches:(NSString*)original;

@end
