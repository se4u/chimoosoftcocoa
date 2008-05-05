//
//  CMSFileUtils.h
//
//  Created by Ryan on 6/20/07.
//  Copyright 2007 Chimoosoft. All rights reserved.
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
