//
//  GarminSerial.h
//
//  Created by Ryan on Sat May 29 2004.
//  Copyright (c) 2004 Chimoosoft. All rights reserved.
//
//  Implements the Garmin serial protocol (binary) to 
//  communicate with Garmin branded GPS receivers.  So far,
//  only supports waypoint upload/download, tracklog download,
//  and live tracking (PVT) with lat/lon only.
//
//  In the future, will be expanded to support route upload/download
//  and tracklog upload.
//
//  ********
//  Disclaimer: Terrabrowser was one of the first Cocoa programs I wrote and
//  as such, it is in no way representative of my current coding style! ;-) 
//  Many things are done incorrectly in this code base but I have not taken the
//  time to revise them for the open source release. There are also many compile
//  time warnings which should be corrected as some of them hint at serious problems.
//  If you work for a company looking to hire me, don't look too critically at this old code!
//  Similarly, if you're trying to learn Cocoa / Objective-C, keep this in mind.
//  ********

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


#import <Foundation/Foundation.h>
#import "SerialController.h"

#import "GarminConstants.h"
#import "GPSConstants.h"

@class XMLElement;
@class Location;

@interface GarminSerial : SerialController {
	id delegate;
	
	NSMutableData * buffer;
	
	GPSMode mode;
	BOOL pvtModeActive;		// is PVT mode currently enabled?
	Location * lastLocation;
	
	
	GPSTransferType transferType;
	int numRetries;
	int downloadCounter;
	int numRecords;

	// gps information
	int GPSIDNum;
	float GPSVersion;
	NSString * GPSName;


	
	// supported protocol information
	NSMutableArray * protocolArray;
	BOOL protocolArrayExists;

	int wptProtocol;
	int trkProtocol;
	int pvtProtocol;

	BOOL wptProtocolSupported;
	BOOL trkProtocolSupported;
	
	
	// uploading waypoints
	int wptUploadCounter, wptUploadIndex, numWptsToUpload;
	BOOL waitingForWptResponse;
	NSArray * wptsToUpload;
	
	int uploadType;
	
	BOOL tempbool;
	
	NSDictionary * iconConversionDict;
	
	// downloading waypoints
	XMLElement * waypointList;

	// downloading tracklogs
	BOOL firstTrack;
	XMLElement * trackList;
	XMLElement * currentTrk;
	XMLElement * currentTrkSeg;
	
	// for the timeout timer
	NSTimer * timer;
	GarminPid lastPacketID;
	GarminPid expectingPacket;
	int numFires;
}

////////////////
// Setup methods
////////////////

- (id)delegate;
- (void)setDelegate:(id)aDelegate;

///////////////////
// Control methods
///////////////////

- (void)connect;
- (void)disconnect;

// real time tracking
- (void)startPVTMode;
- (void)stopPVTMode;

// downloading
- (void)downloadWaypoints;
- (void)downloadTracks;
- (void)downloadRoutes;

// uploading
- (void)uploadWaypoints:(NSArray*)wpts;

// for either downloading or uploading
- (void)abortTransfer;

////////////////////
// Accessors
////////////////////

- (float)GPSVersion;
- (NSString*)GPSName;

- (XMLElement*)waypointList;
- (XMLElement*)trackList;
- (XMLElement*)routeList;


///////////////////
// Private methods (not all listed)
///////////////////

- (void)serialPortReadData:(NSDictionary *)dataDictionary;
- (void)parseSerialData:(NSData*)d;

- (double)semicirclesToDegrees:(SInt32)semi;
- (double)radiansToDegrees:(double)rad;

- (void)dealloc;	

@end




// This informal protocol is declared for the delegate
// methods.  Delegates should implement at least some of this
// protocol.

@interface NSObject (CMSGarminSerialDelegate)

// delegate method which is called when the location (lat/lon) changes to a different value
// if pvt mode is active
- (void)GPSLocationUpdated:(Location*)loc;

// updates with an undefined frequency and lets the delegate know how
// the download is progressing and the name of the current item.
- (void)GPSDownloadProgress:(int)currentItem
					  outOf:(int)numItems 
				currentName:(int)itemName;

- (void)GPSFinishedWaypointDownload:(XMLElement*)waypointList;
- (void)GPSFinishedTracklogDownload:(XMLElement*)trackList;
- (void)GPSFinishedRouteDownload:(XMLElement*)routeList;

// called when finished connecting to GPS
- (void)GPSConnected;

// a message which might be displayed in a logfile or console window
- (void)logMessage:(NSString*)msg;

@end


