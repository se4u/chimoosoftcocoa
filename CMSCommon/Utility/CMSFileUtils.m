
#import "CMSFileUtils.h"
#import "CMSCommon.h"

@implementation CMSFileUtils

// returns YES if the file specified by path exists, NO otherwise
+ (BOOL)pathExists:(NSString *)aFilePath {
	NSFileManager *defaultMgr = [NSFileManager defaultManager]; 
	
	return [defaultMgr fileExistsAtPath:aFilePath];
}

// Returns YES if path is a writeable folder which exists.
+ (BOOL)folderIsWriteable:(NSString*)path {
	NSFileManager * manager = [NSFileManager defaultManager];
	BOOL isDir;
	BOOL exists = [manager fileExistsAtPath:path isDirectory:&isDir];
	BOOL writeable = [manager isWritableFileAtPath:path];
	
	return (isDir && exists && writeable);
}

+ (void)revealPathInFinder:(NSString*)path {
		
	NSFileManager *defaultMgr = [NSFileManager defaultManager];		
	if (![defaultMgr fileExistsAtPath:path]) return;
	
	NSString * source = [NSString stringWithFormat:@"set posix_path to \"%@\"\n set mac_reference to posix_path as POSIX file as alias\n tell application \"Finder\"\n activate\nreveal mac_reference\n end tell", path];
	
	NSAppleScript * script = [[NSAppleScript alloc] initWithSource:source];
	NSDictionary * dict;
	if (![script executeAndReturnError:&dict]) {
		NSLog(@"Problem executing applescript.");
	}
	
	[script release];
}

+ (NSString*)applicationSupportPathForName:(NSString*)name {
	
	NSArray * paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	
	if ((!paths) || ([paths count] < 1)) return nil;
	
	NSString * path = [paths objectAtIndex:0];
	path = [path stringByAppendingPathComponent:name];
	
	id man = [NSFileManager defaultManager];
	BOOL isDir;
	BOOL exists = [man fileExistsAtPath:path isDirectory:&isDir];
	if (!(isDir && exists)) {
		// then create
		[man createDirectoryAtPath:path attributes:nil];
	}
	return path;	
}

+ (NSString*)applicationSupportPath {	
	return [CMSFileUtils applicationSupportPathForName:[CMSCommon applicationName]];
}

// Presents the user with a dialog to choose a folder, and returns the folder path.
+ (NSString*)folderSelectionFromUser {	
	NSOpenPanel * openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseFiles:NO];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setResolvesAliases:YES];
	[openPanel setAllowsMultipleSelection:NO];
	
	[openPanel runModalForDirectory:nil file:nil types:nil];
	
	NSArray * fileNames = [openPanel filenames];
	
	if ([fileNames count] <= 0) return nil;
	
	NSMutableString * path = [fileNames objectAtIndex:0];
	return path;
}


// Returns MD5 hash of file at path.
+ (NSString*)gallimaufryPath:(NSString*)path {
	NSTask * task = [[NSTask alloc] init];
	[task setLaunchPath:@"/sbin/md5"];
	
	NSArray * args = [NSArray arrayWithObjects:@"-q", path, nil];
	[task setArguments:args];
	NSPipe * pipe = [NSPipe pipe];
	NSFileHandle * handle = [pipe fileHandleForReading];	
	[task setStandardOutput:pipe];
	
	[task launch];
	[task waitUntilExit];
	
	NSData * data = [handle readDataToEndOfFile];
	NSString * result = [[NSString alloc] initWithData:data
											  encoding:NSMacOSRomanStringEncoding];
	
	[result autorelease];
	[task release];
		
	// has a \n at the end, so remove it.
	return [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}


// MD5 hash the path, compare it with original, and return a boolean indicating equality.
// Useful for preventing modification of scripts in bundles.
+ (BOOL)gallimaufryPath:(NSString*)path matches:(NSString*)original {
	NSString * gallum = [CMSFileUtils gallimaufryPath:path];
	BOOL b = [original isEqualToString:gallum];
	if (!b) NSLog(@"Problem with helper %@ - aborting.", path);
	return b;
}


// Returns the next available numerical name path for passed path, ie, 
// pass it (@"/Users/ryan/Desktop/", and @"CM Capture.jpg".
// 
// The fileName can have an extension or not - it doesn't matter.
+ (NSString*)incrementalPathForDirectory:(NSString*)directoryPath andFileName:(NSString *)fileName {
	
	if (![CMSFileUtils pathExists:directoryPath]) return nil;	// No directory here!

	NSFileManager * manager = [NSFileManager defaultManager];
	
	NSString * oldName = [fileName stringByDeletingPathExtension];	
	int nameLength = [oldName length];
		
	NSMutableDictionary * usedNumbers = [NSMutableDictionary dictionaryWithCapacity:4];

	// Build up a dictionary of used numbers 
	NSString * number;
	NSString * aName;
	NSDirectoryEnumerator * dirEnumerator = [manager enumeratorAtPath:directoryPath];
	while (nil != (aName = [dirEnumerator nextObject])) {
		if ([aName hasPrefix:oldName]) {
			number = [[aName substringFromIndex:nameLength + 1] stringByDeletingPathExtension];
			[usedNumbers setValue:aName forKey:number];
		}
	}
	
	int num = 1;
	BOOL foundSpace = NO;
	while (!foundSpace) {
		if (nil != [usedNumbers valueForKey:[NSString stringWithFormat:@"%d", num]]) {
			num++;			
		} else {
			foundSpace = YES;
		}
	}
	
	NSString * newName = [NSString stringWithFormat:@"%@ %d", oldName, num];
	NSString * newPath = [[directoryPath stringByAppendingPathComponent:newName] stringByAppendingPathExtension:[fileName pathExtension]];

	if ([manager fileExistsAtPath:newPath]) {
		NSLog(@"Error selecting unique path.");
		return nil;
	}
	return newPath;
}


// Returns a 'safe' file name for the passed name by removing characters
// which could cause problems (/, :, etc.) and limiting the maximum length.
+ (NSString*)safeFileNameForString:(NSString*)inName {
	if (nil == inName) return nil;
	
	// Remove hazardous characters like "/" and ":".
	NSMutableString * mutable = [NSMutableString stringWithString:inName];
	int len = [mutable length];
	NSRange fullRange = NSMakeRange(0, len);
	
	[mutable replaceOccurrencesOfString:@"." 
							 withString:@"_" 
								options:0 
								  range:NSMakeRange(0,1)];
	
	[mutable replaceOccurrencesOfString:@"/" 
							 withString:@"-" 
								options:0 
								  range:fullRange];
	
	[mutable replaceOccurrencesOfString:@":" 
							 withString:@"-" 
								options:0 
								  range:fullRange];

	[mutable replaceOccurrencesOfString:@"~" 
							 withString:@"-" 
								options:0 
								  range:fullRange];
	
	if (len >= 255) {
		// HFS Plus maximum file length
		return [mutable substringWithRange:NSMakeRange(0, 254)];
	}
		
	return (NSString*)mutable;
}


// opens named file inside the main application bundle
+ (void)openFileInBundle:(NSString*)fileName {
	NSString * path = nil;
	if (path = [[NSBundle mainBundle] pathForResource:[fileName stringByDeletingPathExtension] 
											   ofType:[fileName pathExtension]
										  inDirectory:nil])  {
				
		NSURL * url = [NSURL fileURLWithPath: path];
		[[NSWorkspace sharedWorkspace] openURL: url];
	}
}




@end
