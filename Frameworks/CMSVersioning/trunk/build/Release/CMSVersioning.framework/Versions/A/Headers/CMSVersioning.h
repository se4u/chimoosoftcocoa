//
//  CMSVersioning.h
//  CMSVersioning
//
//  Created by Ryan Poling on 12/5/07.
//  Copyright 2007 Chimoosoft. All rights reserved.
//
//  Public framework header file for Chimoosoft's CMSVersioning system.
//
//  To use this versioning system, add an instance of CMSVersioning to your main nib file in Interface Builder.  You will
//  have to drag the CMSVersioning.h header file into IB manually for it to see the methods available for connections.  
//  After doing this, you can connect up the checkForNewVersion: action to a menu item, button, or whatever you like.
// 
//  After an instance of CMSVersioning has been added to your nib, make sure to set a delegate object 
//  (in IB is fine) which implements the following two methods:
// 
//  (NSURL*)versioningURL;
//  (NSURL*)productURL;
//
//  CMSVersioning will ask the delegate object for these two URL's before it can check for new versions.
//  They are *not* stored in the info.plist to prevent someone from (easily) changing them after deployment.
//  If you don't implement the delegate methods, CMSVersioning will default to some pre-defined Chimoosoft values.
//
//  The info.plist for your app must contain the following two key value pairs:
// 
//  CMSProductCode		: a key into the versioning dictionary on the web.
//  CFBundleName		: the user readable name of the program.
//
//  CMSVersioning uses the user defaults system to keep track of the last version check date and whether
//  or not it should automatically check for new versions.  The following defaults keys are used (note that
//  these are defined in CMSVersioningKeys.h):
//
//  kCMSVersionDefaultsKey			String; currently running application's version; CMSVersioning sets this value.
//  kCMSAutoCheckDefaultsKey		BOOL; check for new versions automatically?
//  kCMSLastCheckDefaultsKey		Date (archived); CMSVersioning sets this.
//  kCMSCheckIntervalDefaultsKey	int; days between auto version checks.
//
//  Import CMSVersioningKeys.h to get access to the pre-defined constants for the keys listed above.

#import <Cocoa/Cocoa.h>


@interface CMSVersioning : NSObject {
	IBOutlet id delegate;
}

+ (void)finished;

- (void)awakeFromNib;

// Force a check for a new version of the software presenting the dialog box whether or not one is
// available. 
- (IBAction)checkForNewVersion:(id)sender;

- (IBAction)openProductWebPage:(id)sender;



@end
