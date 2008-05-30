//
//  GPSController.m
//  GPSTest
//
//  Created by Ryan on Sat May 29 2004.
//  Copyright (c) 2004 Chimoosoft. All rights reserved.
//

#import "GPSController.h"
#import "AMSerialPortList.h"
#import "AMSerialPortAdditions.h"

#import "NMEAPacket.h"
#import "Location.h"
#import "Waypoint.h"
#import "xmlElement.h"
#import "GarminSerial.h"
#import "NMEASerial.h"

@implementation GPSController


#pragma mark -
#pragma mark Generic methods

- (void)awakeFromNib {	
	[self fillPopupMenu];
	
	garminCtl = [[GarminSerial alloc] init];
	NMEACtl = [[NMEASerial alloc] init];
	
	[garminCtl setDelegate:self];
	[NMEACtl setDelegate:self];
}


- (IBAction)connect:(id)sender {
	int tag = [protocolMenu selectedTag];
	
	[connectButton setAction:@selector(disconnect:)];
	[connectButton setTarget:self];
	[connectButton setTitle:@"Disconnect"];
	
	[NMEACtl setPortName:[portMenu titleOfSelectedItem]];
	[garminCtl setPortName:[portMenu titleOfSelectedItem]];
	
	if (tag == 0) { // NMEA
		[NMEACtl connect];
	} else if (tag == 1) { // Garmin
		[garminCtl connect];
	}
}


- (IBAction)disconnect:(id)sender {
	int tag = [portMenu selectedTag];

	[connectButton setAction:@selector(connect:)];
	[connectButton setTarget:self];
	[connectButton setTitle:@"Connect"];
	
	if (tag == 0) { // NMEA
		[NMEACtl disconnect];
	} else if (tag == 1) { // Garmin
		[garminCtl disconnect];
	}
}

- (IBAction)listDevices:(id)sender {	
	[self fillPopupMenu];
}


// fill the popup menu with a listing of serial ports
- (void)fillPopupMenu {
	NSEnumerator * enumerator = [AMSerialPortList portEnumerator];
	AMSerialPort * aPort;
	NSString * title;
	
	int i = 0;
	int indexToSelect = 0;
	while (aPort = [enumerator nextObject]) {
		title = [aPort bsdPath];
		
		// see if it's the keyspan adapter
		NSRange range = [title rangeOfString:@"USA"];
		if (range.location != NSNotFound) {
			indexToSelect = i;
		}
		
		[portMenu addItemWithTitle:title];
		//[outputTextView insertText:[aPort name]];
		
		i++;
	}
	
	[portMenu removeItemAtIndex:0];
	[portMenu selectItemAtIndex:indexToSelect];
}


#pragma mark -
#pragma mark Garmin methods


- (IBAction)download:(id)sender {
	
	id radio = [transferTypeRadios selectedCell];
	switch ([radio tag]) {
		case 0:
			[garminCtl downloadWaypoints];	
			break;
		case 1:
			[garminCtl downloadTracks];
			break;
		case 2:
			[garminCtl downloadRoutes];
			break;
	}
	
}

- (IBAction)abortTransfer:(id)sender {
	[garminCtl abortTransfer];
}

- (IBAction)startPVT:(id)sender {
	[pvtButton setTitle:@"Stop PVT"];
	[pvtButton setAction:@selector(stopPVT:)];
	[garminCtl startPVTMode];
}

- (IBAction)stopPVT:(id)sender {
	[pvtButton setTitle:@"Start PVT"];
	[pvtButton setAction:@selector(startPVT:)];
	[garminCtl stopPVTMode];
}


- (IBAction)tempSendWpt:(id)sender {
	Waypoint * wpt = [Waypoint waypointWithDoubleLatitude:30.12345 
										  doubleLongitude:-120.12345];
	[wpt setName:@"AATEST"];
	[wpt setSymbolName:@"Residence"];
	[wpt setElevation:[NSNumber numberWithFloat:155.1234]];
	
	Waypoint * wpt2 = [Waypoint waypointWithDoubleLatitude:12.12345 
										   doubleLongitude:123.12345];
	
	[wpt2 setName:@"AATEST2"];
	[wpt2 setSymbolName:@"Fishing"];
	[wpt2 setElevation:[NSNumber numberWithFloat:10.0]];
	
	NSArray * array = [NSArray arrayWithObjects:wpt, wpt2, nil];
	
	[garminCtl uploadWaypoints:array];
}


// add a message to the log
- (void)logMessage:(NSString*)msg {
	[outputTextView insertText:msg];
}



#pragma mark -
#pragma mark Garmin delegate methods
- (void)GPSLocationUpdated:(Location*)loc {
	NSLog(@"location updated called, loc = %f, %f.", [loc doubleLatitude], [loc doubleLongitude]);
	
	[latField setFloatValue:[loc doubleLatitude]];
	[lonField setDoubleValue:[loc doubleLongitude]];
}


- (void)GPSDownloadProgress:(int)currentItem
					  outOf:(int)numItems 
				currentName:(int)itemName {
	
	[progressBar setMaxValue:numItems];
	[progressBar setDoubleValue:currentItem];
//	[progressBar setNeedsDisplay:YES];
	
	[progressNameField setStringValue:itemName];
	
	//NSLog(@"GPSDownloadProgress, %d out of %d, name = %@", currentItem, numItems, itemName);
	
}


- (void)GPSFinishedWaypointDownload:(NSArray*)waypointArray {
	NSLog(@"Finished waypoint download");
}

- (void)GPSFinishedTracklogDownload:(xmlElement*)trackList {
	NSLog(@"Finished tracklog download");
}



#pragma mark -
#pragma mark NMEA methods


// called when we receive a new packet
- (void)NMEAStartOfNewPacket:(NMEAPacket*)packet {
	[fixField setStringValue:[NSString stringWithFormat:@"%dD", [packet gpsFix]]];
	[numSatellitesField setIntValue:[packet numSatellites]];	
	[elevationField setFloatValue:[packet elevation]];	
	[magBearingField setFloatValue:[packet magneticBearing]];	
	[trueBearingField setFloatValue:[packet trueBearing]];	
	[CMGField setFloatValue:[packet courseMadeGood]];	
	[horizErrorField setFloatValue:[packet horizontalError]];	
	[vertErrorField setFloatValue:[packet verticalError]];	
}




- (void)dealloc {
	[garminCtl release];
	[NMEACtl release];
	
	[super release];
}

@end
