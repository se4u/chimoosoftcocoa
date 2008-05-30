//
//  GPSController.h
//  GPSTest
//
//  Created by Ryan on Sat May 29 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

@class GarminSerial;
@class NMEASerial;
@class xmlElement;
@class NMEAPacket;
@class Location;

@interface GPSController : NSObject {

	IBOutlet NSTextView * outputTextView;
	
	IBOutlet id numSatellitesField;
	IBOutlet id fixField;
	IBOutlet id latField;
	IBOutlet id lonField;
	IBOutlet id elevationField;
	IBOutlet id magBearingField;
	IBOutlet id trueBearingField;
	IBOutlet id CMGField;
	IBOutlet id horizErrorField;
	IBOutlet id vertErrorField;
	
	IBOutlet id progressBar;
	IBOutlet id progressNameField;
	
	IBOutlet id baudMenu;
	
	IBOutlet id pvtButton;
	
	IBOutlet id portMenu;
	IBOutlet id protocolMenu;
	
	IBOutlet id connectButton;
	
	IBOutlet id transferTypeRadios;
	
	GarminSerial * garminCtl;
	NMEASerial * NMEACtl;	
}


#pragma mark -
#pragma mark Generic methods


- (IBAction)disconnect:(id)sender;
- (IBAction)connect:(id)sender;
- (IBAction)listDevices:(id)sender;
- (void)fillPopupMenu;

- (void)logMessage:(NSString*)msg;

#pragma mark -
#pragma mark Garmin methods

- (IBAction)download:(id)sender;
- (IBAction)abortTransfer:(id)sender;
- (IBAction)startPVT:(id)sender;
- (IBAction)stopPVT:(id)sender;
- (IBAction)tempSendWpt:(id)sender;

// delegate methods
- (void)GPSFinishedTracklogDownload:(xmlElement*)trackList;
- (void)GPSFinishedWaypointDownload:(NSArray*)waypointArray;
- (void)GPSDownloadProgress:(int)currentItem;
- (void)GPSLocationUpdated:(Location*)loc;

#pragma mark -
#pragma mark NMEA methods

- (void)NMEAStartOfNewPacket:(NMEAPacket*)packet;

@end
