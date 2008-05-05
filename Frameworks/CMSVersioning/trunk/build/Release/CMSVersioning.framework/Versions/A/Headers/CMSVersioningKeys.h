/*
 *  CMSVersioningKeys.h
 *  CMSVersioning
 *
 *  Created by Ryan Poling on 12/12/07.
 *  Copyright 2007 Chimoosoft. All rights reserved.
 *
 */


//  CMSVersioning uses the user defaults system to keep track of the last version check date and whether
//  or not it should automatically check for new versions.  The following defaults keys are used:
//
//  CMS_Version								String; currently running application's version; CMSVersioning sets this value.
//  CMS_CheckForNewVersionsAutomatically	BOOL; check for new versions automatically?
//  CMS_LastVersionCheck					Date (archived); CMSVersioning sets this.
//  CMS_VersionCheckIntervalInDays			int; days between auto version checks.

static NSString * const kCMSVersionDefaultsKey			= @"CMSVersioning_Version";
static NSString * const kCMSAutoCheckDefaultsKey		= @"CMSVersioning_AutoCheck";
static NSString * const kCMSLastCheckDefaultsKey		= @"CMSVersioning_LastCheck";
static NSString * const kCMSCheckIntervalDefaultsKey	= @"CMSVersioning_CheckIntervalInDays";


// Keys for the versioning dictionary which is stored on the web.

static NSString * const kCMSVersionKey			= @"version";
static NSString * const kCMSMinOSXKey			= @"minosx";
static NSString * const kCMSMaxOSXKey			= @"maxosx";
static NSString * const kCMSProductURLKey		= @"home";
static NSString * const kCMSDownloadURLKey		= @"download";
static NSString * const kCMSReleaseDateKey		= @"released";
static NSString * const kCMSReleaseNotesKey		= @"notes";
static NSString * const kCMSBetaKey				= @"isbeta";
static NSString * const kCMSDownloadSizeKey		= @"size";
//static NSString * const kCMSFreeUpgradeFromKey	= @"freeupgradefrom";

// Bundle keys.

static NSString * const kCMSProductCodeKey		= @"CMSProductCode";

