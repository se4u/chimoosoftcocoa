//
//  GarminController.m
//  GPSTest
//
//  Created by Ryan on Sat May 29 2004.
//  Copyright (c) 2004 Chimoosoft. All rights reserved.
//

////////////////////////////////////////////////////////////////////////
// Note, in REALBasic, these types are used in the MemoryBlock:
// REALBasic ----------------------------------		C -----------------
// Short			signed integer		2 bytes		SInt16		2 bytes
// UShort			unsigned integer	2 bytes		UInt16		2 bytes
// Long				signed integer		4 bytes		SInt32		4 bytes
// Byte				signed integer		4 bytes		SInt8		1 byte
// SingleValue		float				4 bytes		Float32		4 bytes
/////////////////////////////////////////////////////////////////////////

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

#import "GarminSerial.h"
#import "SerialController.h"

#import "AMSerialPortList.h"
#import "AMSerialPortAdditions.h"

#import "GarminPacket.h"
#import "DataAdditions.h"
#import "MutableDataAdditions.h"

#import "Waypoint.h"
#import "Location.h"
#import "LatLon.h"

#import "Constants.h"




@implementation GarminSerial


- (id)init {		
	if (self = [super init]) {
		mode = DOWNLOAD_MODE;
		protocolArrayExists = NO;
		wptProtocol = 0;
		wptProtocolSupported = NO;
		
		trkProtocol = 0;
		trkProtocolSupported = NO;
		
		firstTrack = YES;
		
		pvtModeActive = NO;
		
		numFires = 0;
		
		[self createIconConversionDict];
		
	}	

	return self;
}



#pragma mark -
#pragma mark Control methods

- (void)startPVTMode {
	[self sendCommand:Cmnd_Abort_Transfer];
	[self sendCommand:Cmnd_Start_Pvt_Data];
	pvtModeActive = YES;	
}

- (void)stopPVTMode {
	[self sendCommand:Cmnd_Stop_Pvt_Data];
	pvtModeActive = NO;	
}


- (void)downloadWaypoints {
	if (pvtModeActive) {
		[self stopPVTMode];
	}
	
	if (wptProtocolSupported) {
		// record what we're trying to transfer so we can respond to the
		// Pid_Records appropriately when it arrives.
		transferType = Wpt_Transfer;
		
		expectingPacket = Pid_Records;
		
		[self sendCommand:Cmnd_Transfer_Wpt];
	} else {
		[self displayNotSupportedMessage];
	}
}


- (void)downloadTracks {
	if (pvtModeActive) {
		[self stopPVTMode];
	}
	
	if (trkProtocolSupported) {
		// record what we're trying to transfer so we can respond to the
		// Pid_Records appropriately when it arrives.
		transferType = Trk_Transfer;
		
		firstTrack = YES;  // helps with putting the current track into 
		// the track list
		[self sendCommand:Cmnd_Transfer_Trk];
	} else {
		[self displayNotSupportedMessage];
	}
}


- (void)downloadRoutes {
	if (pvtModeActive) {
		[self stopPVTMode];
	}
	
	if (wptProtocolSupported) {
		// record what we're trying to transfer so we can respond to the
		// Pid_Records appropriately when it arrives.
		transferType = Rte_Transfer;
		
		[self sendCommand:Cmnd_Transfer_Rte];
	} else {
		[self displayNotSupportedMessage];
	}
}



// pass this an array of waypoints to upload and it starts the process
- (void)uploadWaypoints:(NSArray*)wpts {
	
	if ([wpts count] <= 0) {
		return;
	}
	
	NSEnumerator * enumerator = [wpts objectEnumerator];
	id wpt;
	int count = 0;
	
	while (wpt = [enumerator nextObject]) {
		if (wpt != nil) count++;
	}
	
	//make sure we're going to send some waypoints
	if (count <= 0) {
		return;
	}
	
	if (! wptProtocolSupported) {
		[self displayNotSupportedMessage];
		return;
	}
	
	if (pvtModeActive) {
		[self stopPVTMode];
	}
	
	//how many waypoints are remaining to be sent?
	numWptsToUpload = count; 
	
	waitingForWptResponse = NO;
	tempbool = NO;
	
	//change the mode to uploadMode so we parse the GPS response properly.
	mode = UPLOAD_MODE;
	uploadType = UPLOAD_WAYPOINT_TYPE; //so we know that we're trying to upload a waypoint
	
	//save the passed array for future access.
	wptsToUpload = [wpts retain];
	
	wptUploadIndex = 0;		//start with the zeroth one.
	wptUploadCounter = 0;   //how many we've actually sent
	
	//inform the GPS that we're going to send it some waypoints
	[self sendPidRecords:numWptsToUpload];  
}



- (void)abortTransfer {
	[self sendAbortTransfer];
}


#pragma mark -
#pragma mark Timeout methods


- (void)stopTimer {
	
	if ([timer isValid]) {
		[timer invalidate]; //stop it
	}
	
	if (timer != nil) {
		[timer release];
		timer = nil;
	}
	
	numFires = 0;
}


- (void)startTimer:(GarminPid)packetID {
	[self stopTimer];
	
	lastPacketID = packetID;
	
	// timeout in 2 seconds
	
	if (!timer) {  //then create it
		timer = [[NSTimer scheduledTimerWithTimeInterval:2.0
												  target:self
												selector:@selector(timerTimeout)
												userInfo:0
												 repeats:NO] retain];
	}	
}


- (void)timerTimeout {
	numFires++;

	[self sendNAK:lastPacketID];
}


#pragma mark -
#pragma mark Serial methods


- (void)connect {
	[buffer release];
	buffer = nil;
	[self initPort];
	
	[self sendRequestGPSID];
}

- (void)disconnect {
	if (port) {
		[port free];
		[port release];
		port = nil;
	}
}



- (void)initPort {
	
	if (![portName isEqualToString:[port bsdPath]]) {
		[port close];
		
		[self setPort:[[[AMSerialPort alloc] init:portName withName:portName] autorelease]];
		
		// register as self as delegate for port
		[port setDelegate:self];
				
		// open port - may take a few seconds ...
		if ([port open]) {
				
			[port setSpeed:9600];
			[port setDataBits:8];
			[port setParityNone];
			[port setStopBits2:NO];
			BOOL b = [port commitChanges];
			
			// listen for data in a separate thread
			[port readDataInBackground];
						
		} else { // an error occured while creating port
			NSLog(@"couldn't open port for device");
			[self setPort:nil];
		}
	}
}

- (void)serialPortWriteProgress:(NSDictionary *)dataDictionary {
	NSLog(@"write progress...");
}



// meant to be overridden by subclasses
- (void)serialPortReadData:(NSDictionary *)dataDictionary {
	// this method is called if data arrives 
	// @"data" is the actual data, @"serialPort" is the sending port
	
	//	NSLog(@"received some data");
	
	AMSerialPort *sendPort = [dataDictionary objectForKey:@"serialPort"];
	NSData *data = [dataDictionary objectForKey:@"data"];
			
	if ([data length] > 0) {
		
		[self parseSerialData:data];
		
		// continue listening
		[sendPort readDataInBackground];
	} else { // port closed
		
	}
}

#pragma mark -
#pragma mark Parsing methods


// parses a chunk of data from the GPS storing it in a buffer
// and pulling out the data packets.
- (void)parseSerialData:(NSData*)data {
	
//	NSString * debug = [self printDataAsHex:data];

	if (buffer == nil) { buffer = [[NSMutableData alloc] init]; }
	
//	debug = [self printDataAsHex:buffer];
	
	// add the new data on to the buffer
	[buffer appendData:data];
	
//	debug = [self printDataAsHex:buffer];
		
	//we're going to wait until we have an entire packet in the buffer 
	//before we actually read it.. 
	
	BOOL foundStart = NO;
	BOOL foundEnd = NO;
	
	int size = [buffer length];
		
	int startPos, endPos;
	
	endPos = -1;
	
	//search for the start of a packet
	while (([port isOpen]) && (foundStart = [self findPacketStartPosStartingAt:(endPos + 1) startPosition: &startPos])) {
	
		if (! foundStart) {  
			return;		//wait for more data to come in...
		}

		//search for the end position directly following the start position..
		foundEnd = [self findPacketEndPosStartingAt:(startPos+1) endPosition:&endPos];


		//only read the packet if we have found BOTH the start and end of it.
		if (! (foundStart && foundEnd) ) { return; }
	
			
		//if we make it to here, then we can read the packet
		////////////////////////////////////////////////////
	
		int numMessageBytes, packetSize;
			
		//NSMutableData * packet;
		packetSize = endPos - startPos + 1;	

		//the startPos number is the index, but it also represents how many 
		//bytes we have to read to get to the start.
		//For example, if startPos = 2 then we have to discard the first two bytes
		//before we can start reading our message
		
		NSRange range;
		range.length = packetSize;
		range.location = startPos;
		
		GarminPacket * packet = [GarminPacket garminPacketWithRawPacketData:[buffer subdataWithRange:range]];
		//packet = [buffer subdataWithRange:range];
		
		// now we have to delete this from the buffer.
		// so copy all of the data we haven't read yet
		range.location = range.location + range.length;
		range.length = [buffer length] - range.location;
		
		// this is the remaining data in the buffer that we haven't read yet
		[buffer setData:[buffer subdataWithRange:range]];

		// parse this packet of data
		[self parsePacket: packet];
	}
}


- (void) parsePacket:(GarminPacket*)packet {
	// called when we receive an ENTIRE packet from the GPS

	// if we're downloading data from the GPS, then we need to do this in 
	// a different way than if we're uploading.. It seemed easier to break
	// these up into two separate methods.
		
/*	
	if (![packet checksumIsValid]) {
		NSLog(@"Packet is invalid.");
		[self sendACK:[packet packetID]];
		return;  //invalid
	}
*/		
	if ([packet packetID] != Pid_Ack_Byte) {
		[self stopTimer];		// stop the timeout
	}
	
	switch (mode) {
		case UPLOAD_MODE:
			[self parsePacketUploadMode:packet];
			
			break;
		case DOWNLOAD_MODE:
			[self parsePacketDownloadMode:packet];
			
			break;
	}					
}




- (void) parsePacketDownloadMode:(GarminPacket*)packet {
	//called when we receive an ENTIRE packet from the GPS
	
	Waypoint * wpt;
	
	Location* loc;
	
	int i;
	GarminPid mesgType;			// defined in GarminConstants.h
	int numMesgBytes;
	
	NSData * data = [packet packetData];
	SInt8 * bytes = [data bytes];
	
	mesgType = [packet packetID];		//type of packet (garmin code)
	numMesgBytes = [data length];		//number of bytes in the message
	
	NSString * testString;
	
	//only send an ACK or NAK if the GPS didn't send us one of those..
	
	if (mesgType != Pid_Ack_Byte) {
		if (! [packet checksumIsValid]) {
			NSLog(@"checksum didn't match!");
			NSLog(@"Packet = \n %@\nmesgType = %d", [packet hexString], mesgType);
			
			[port flushInput:YES Output:YES];
			[port stopReadInBackground];
			
			[buffer release];
			buffer = nil;
		
			[port readDataInBackground];
			[self sendNAK:mesgType];
				
			/*
			//ask for the packet again...
			numRetries++;
			
			if (numRetries < 4) {
				[self sendNAK:mesgType];
			} else {
				NSLog(@"too many retries - giving up.");
				numRetries = 0;
				[self sendACK:mesgType]; //just ignore the error and go on..
			}
			*/			
			
			//**** this line is very important!!**************
			return;
			//************************************************
			
		} else {  // checksum *IS* valid
		
			numRetries = 0;
			
			// don't send ACK here for waypoint or track data type
			// send it in the waypoint parse method instead
			// Note...  Why is this done??
			if ((mesgType != Pid_Wpt_Data) && (mesgType != Pid_Trk_Data)) {
				[self sendACK:mesgType];  //send an ACK packet back to the GPS.
			}
																
		}
	}
		
	
	
	switch (mesgType) {
		
		case Pid_Ack_Byte:			//ACK packet
			//ignore
			NSLog(@"received ack packet");
			break;
		
		case Pid_Product_Data:		//GPS ID Packet
			NSLog(@"received GPS ID Packet");
			[self parseGPSIDPacket:packet];
			break;
		
		case Pid_Records:		
			// this is sent at the begining of a tranfer for
			// waypoints, tracklogs, routes, etc.
			
			numRecords = (int)[data sInt16AtIndex:0 dataIsLittleEndian:YES];
			NSLog(@"received Pid_Records packet, %d records.", numRecords);

			downloadCounter = 0;
			
			switch (transferType) {
				case Wpt_Transfer:  
					// this packet tells us how many waypoints to expect				
					
					[waypointList release];
					waypointList = [[XMLElement alloc] init];
					break;
					
				case Trk_Transfer:
					[trackList release];
					trackList = [[XMLElement alloc] init];
					
					break;
					
				case Rte_Transfer:
					break;
			}
				
			//NSLog(@"Downloading %d records...", numRecords);
		
			break;
			
		case Pid_Wpt_Data:		// waypoint
			wpt = [self parseWaypointPacket:packet];
		
			if (wpt != nil) {
				[waypointList addElementToList:wpt];  // add this waypoint onto the array.
			}
								
			//NSLog(@"downloaded waypoint %@", [wpt name]);
			//NSLog(@"  %f, %f", [wpt doubleLongitude], [wpt doubleLatitude]);

			downloadCounter++;
			
			
			// call the delegate method
			[self GPSDownloadProgress:downloadCounter 
								outOf:numRecords 
						  currentName:[wpt name]];
			
				
			//now, send the ack packet
			[self sendACK:Pid_Wpt_Data];
				
			break;	
			
		case Pid_Trk_Data:		// trackpoint
			[self parseTracklogPacket_D301:packet];
			
			downloadCounter++;
			
			// call the delegate method
			[self GPSDownloadProgress:downloadCounter 
								outOf:numRecords 
						  currentName:@""];
			
			
			//now, send the ack packet
			[self sendACK:Pid_Trk_Data];


			break;
			
		case Pid_Trk_Hdr:		// header sent before tracklog transfer begins
			
			[self parseTracklogHeaderPacket_D310:packet];
			
			break;
				
		case Pid_Xfer_Cmplt:
			
			NSLog(@"received Pid_Xfer_Cmplt packet.");

			switch (transferType) {
				case Wpt_Transfer:  

					// call the delegate method
					[self GPSFinishedWaypointDownload:waypointList];
					break;
			
				case Trk_Transfer:
				
					// call the delegate method
					[self GPSFinishedTracklogDownload:trackList];
					break;
					
				case Rte_Transfer:
					// call the delegate method
					[self GPSFinishedRouteDownload:nil];
					break;
			}
			
			break;
					
		
		case Pid_Protocol_Array:
			NSLog(@"received Pid_Protocol_Array");
			[self parsePidProtocolArray:packet];
			break;
			
		case Pid_Date_Time_Data:
			NSLog(@"received time from GPS");
			[self parseDateTimePacket_D600:packet];
			break;
			
		case Pid_Position_Data:
			NSLog(@"received position data from GPS");
			[self parsePositionPacket:packet];
			break;
			
		case Pid_Pvt_Data:
			NSLog(@"received PVT data");
			
			switch (pvtProtocol) {
				case 700:
					loc = [self parsePositionPacket_D700:packet];
					break;
				case 800: 
					loc = [self parsePositionPacket_D800:packet];
					break;
			}
			
			
			if (([lastLocation doubleLatitude] != [loc doubleLatitude]) ||
				([lastLocation doubleLongitude] != [loc doubleLongitude])) {
				
					// let the delegate know the new position
					[self GPSLocationUpdated:loc];
			}
			
			[lastLocation release];
			lastLocation = [loc retain];
				
			break;
			
		default:
			NSLog(@"unknown packet type received from GPS.");

			break;		
	}
}


- (void) parsePacketUploadMode:(GarminPacket*)packet {
	
	//This is for the uploadMode, eg. if we're sending a waypoint TO the GPS.
	//called when we receive an ENTIRE packet from the GPS
	
	int numwpts, i, numMesgBytes;
	GarminPid mesgType;
	
	NSData * data = [packet packetData];
		
	mesgType = [packet packetID];	//type of packet (garmin code)
	numMesgBytes = [data length];   //number of bytes in the message
	
	switch(mesgType) {
		
		case Pid_Nak_Byte:		//NAK packet
			NSLog(@"received nak packet");
		
			if (waitingForWptResponse) {
				//try to resend the packet
				//beep
			
				if ((wptUploadIndex >=0) && (wptUploadIndex < [wptsToUpload count])) {
					[self sendWaypoint:[wptsToUpload objectAtIndex:wptUploadIndex]];
				}
			}
			break;	
			
		case Pid_Ack_Byte:		//ACK packet
			NSLog(@"received ack packet");
					
			if (uploadType == UPLOAD_WAYPOINT_TYPE) {

				//actually send the waypoint now...
				
				if (wptUploadCounter >= numWptsToUpload) { 
					//we're done sending waypoints
					if (!tempbool) {
						//send the last XferCmplte packet.
						
						[self sendXferComplete:Cmnd_Transfer_Wpt];
						//********************
						
						mode = DOWNLOAD_MODE;  //reset the mode
						tempbool = YES;
						
					} 
				} else {
								
					if ((wptUploadIndex >= 0) &&
						(wptUploadIndex < [wptsToUpload count])) {
							waitingForWptResponse = YES;
							[self sendWaypoint:[wptsToUpload objectAtIndex:wptUploadIndex]];
								
							wptUploadCounter++;		//since we just sent one
							wptUploadIndex++;
					}
									
				}
					
	
			}
			break;
										
		case Pid_Records:   //this is sent at the begining of a waypoint transfer
			break;					
									
									
		case Pid_Wpt_Data:  //waypoint
			break;						
									
		case Pid_Xfer_Cmplt:
			break;

	}
			
}


// searches through the buffer for the start position of a data packet
// starting at the passed start value
// returns YES if it finds one
- (BOOL) findPacketStartPosStartingAt:(int)start startPosition: (int*)startPos {
	
	// a packet starts with 10 (in hex), but note that:
	// "If any byte in the Size, Packet Data, or Checksum fields is equal to DLE, then 
	// a second DLE is inserted immediately following the byte.  This extra DLE is not
	// included in the size or checksum calculation.  This procedure allows the DLE
	// character to be used to delimit thhe boundaries of a packet."
	// 
	// DLE is ASCII 10 (hex)
	//
	// Therefore, two 10's in a row is *not* the start of a packet, and neither is a 10 followed 
	// by a 03 (since that's the end of a packet).
	
	int size = [buffer length];	
	int i = start;
	
	if ((start < 0) || (start >= size)) {
		return NO;
	}
		
	UInt8 * bytes = (UInt8*)[buffer bytes];
	
	for (i = start; i < size; i++) {
	
		if ( bytes[i] == 0x10) {
			// we found something promising for a packet start
		
			// now, make sure that it's not followed immediately by 
			// a 0x10 or a 0x03.
			if ( (i + 1) < size) {
				
				if (( bytes[i+1] == 0x03) || ( bytes[i+1] == 0x10)) {
					// it can't be the start of a packet.
					return NO;
				} else {
				
					//we found a start pos since it's not an end position
					//and it doesn't occur in the very last spot of the packet..
					*startPos = i;
					return YES;
				}
			}
		}
	}
	
	return NO;
}


// same as findPacketStartPos, but for the end.
- (BOOL)findPacketEndPosStartingAt:(int)start endPosition:(int*)endPos {

	// a packet always ends with 10 03 (in hex).  See page 8 in the Garmin manual.
	
	int size = [buffer length];	
	int i = start;
	
	if ((start < 0) || (start >= size)) {
		return NO;
	}
	
	UInt8 * bytes = (UInt8*)[buffer bytes];
	
	for (i = start; i < size; i++) {
	
		if ( bytes[i] == 0x03) {
			//we found something promising
			
			if (i > 0) {  // to make sure we don't read out of bounds
				
				if ( bytes[i-1] == 0x10) {
					// we found an end position
					*endPos = i;
					return YES;
				}
			}
		}
	}
	
	return NO;
}


- (void) parseGPSIDPacket:(GarminPacket*)packet {
	
	//the following variables are parsed out of this data:
	NSMutableString * product_description = [NSMutableString stringWithCapacity:10];
	//***************************************************
	
	//note, newer GPS units can identify which protocols they use (the protocolArray),
	//however, older units (see pg. 50) need to be looked up in a table based
	//on their software_version and product_ID to figure out which protocols they support
	
	NSData * data = [packet packetData];
	SInt8 * bytes = [data bytes];
	
	int i;
	NSRange range;
			
	//SInt16 num = (int)[packet sInt16AtIndex:5 dataIsLittleEndian:YES];  
	SInt16 num = (int)[data sInt16AtIndex:2 dataIsLittleEndian:YES];  
	GPSVersion = (float)num / 100.0;  //grab the software version
		
	//grab the product ID number
	//GPSIDNum = (int)[packet sInt16AtIndex:3 dataIsLittleEndian:YES];  
	GPSIDNum = (int)[data sInt16AtIndex:0 dataIsLittleEndian:YES];  
		
	
	//now, we'll figure out what the description string is...
	//there may be zero or more null terminated strings
	
	int startpos, endpos;
	
	//if ([packet packetDataLength] > 10) {
	if ([data length] > 4) {
		//we have at least one null terminated string...
		
		//i = 7;  //this is the start position of the first string
		i = 4;  //this is the start position of the first string
		
		while (i < [data length]) {
			//while we're within the string section of the packet
		
			startpos = i;		//start pos of the string
			
			//find the first null terminator
			while (bytes[i] != 0x00) {
				i++;
			}
					
			endpos = i;
			range.length = endpos - startpos;
			range.location = startpos;
			
			NSString * temp = [[NSString alloc] initWithData:[data subdataWithRange:range]
												encoding:   NSASCIIStringEncoding];
			[product_description appendString: temp];
					
			i++; //for the next string
		}
	}		
	
	
//	NSArray * comp = [product_description componentsSeparatedByString:@" "];
	
//	GPSName = [comp objectAtIndex:1];
	GPSName = [product_description retain];
	
	// let the delegate know that we're connected
	[self GPSConnected];
	
	NSLog(@"Found Garmin %@", product_description);

	[self logMessage:[NSString stringWithFormat:@"Found Garmin %@.\n", product_description]];
					
	//note, we're going to call this TWICE.  We'll call it now in case the GPS doesn't
	//send a protocolArray.  Then, we'll call it again if we receive a protocolArray
	//and this will overwrite the value calculated now.
	
	[self determineProtocolsToUse];
					
}


- (void) parsePidProtocolArray:(GarminPacket*)packet {
	//this method fills the protocolArray with strings 
	//representing the protocols found on pg.16 of the Garmin manual.
	//***************************************************
	
	//see pages 15 and 16 of the manual for descriptions of this
	//basically, the GPS (if it's a new enough model) reports which 
	//protocols it supports and which data types it uses for them.
	
	//**************
	//DON'T FORGET TO ADD THIS LOOKUP TABLE for compatibility with GPS 12, etc.
	//Note, older GPS units (see pg. 50) need to be looked up in a table based
	//on their software_version and product_ID to figure out which protocols they support
	//**************
	
	//word is a 16-bit unsigned integer
	
	//byte   tag     /*a letter such as P, L, A, or D
	//word   data    /*a number such as 100, 200, etc.
	
	NSData * data = [packet packetData];
	int size = [data length];
	
	if (size < 3) { 
		return;		//packet is malformed
	}
	
	UInt8 * bytes = [data bytes];
	
	//figure out how many elements are in the protocol array
	//each element is 3 bytes, so just divide the size of the message by 
	//int numElements = (int)floor((float)bytes[2] / 3.0); 
	int numElements = (int)floor((float)size / 3.0); 
	
	if (numElements <= 0) {
		return; 
	}
	
	[protocolArray release];
	protocolArray = [[NSMutableArray arrayWithCapacity:numElements] retain];
	
				
	int i;
	NSString * tag;
	//UInt16 data;
	NSRange range;
	
	for (i = 0; i < numElements; i++) {
		if ((4 + (i*3)) < size) {
			
			range.length = 1;
			range.location = (i*3);
			
			tag = [[NSString alloc] initWithData: [data subdataWithRange:range]
										encoding:   NSASCIIStringEncoding];
						
			int swapped = (int)[data sInt16AtIndex:1 + (i*3)
								  dataIsLittleEndian:YES];  
			
			NSString * str = [NSString stringWithFormat:@"%@%d", tag, swapped];
			
			[protocolArray addObject:str];
			
			//app.writeDebugLine(tag + str(data))
		}
	}
	
	protocolArrayExists = YES;
	
	
	//now, we should go ahead and figure out which type of protocol to use for waypoints, etc.
	
	//note, we also call this method in the parseGPSIDPacket method.  That way, if the GPS
	//doesn't send a protocolArray, we will still have a chance to figure out what type it is.
	
	[self determineProtocolsToUse];
	
}


- (void) parseDateTimePacket_D600:(GarminPacket*)packet {
	// used on all products (?)

	int size, i;
	NSData * data = [packet packetData];
	size = [data length];
		
	if (size < 10) {
		return nil;		//packet is malformed
		NSLog(@"received malformed datetime packet");
	}
	
	UInt8 * bytes = [data bytes];
	
	int month;		// 1 - 12
	int day;		// 1 - 31
	int year;		// ie, 1990
	int hour;		// 0 - 23
	int minute;		// 0 - 59
	int second;		// 0 - 59
	
	month = (int)bytes[0];
	day = (int)bytes[1];
	year = (int)[data uInt32AtIndex:2 dataIsLittleEndian:YES];
	hour = (int)[data sInt32AtIndex:4 dataIsLittleEndian:YES];
	minute = (int)bytes[8];
	second = (int)bytes[9];
	
	
}


- (Location*)parsePositionPacket_D700:(GarminPacket*)packet {
	// older GPS models use this

	double lat, lon;

	int size, i;
	NSData * data = [packet packetData];
	size = [data length];
	
	if (size < 16) {
		return nil;		//packet is malformed
		NSLog(@"received malformed position packet");
	}
	
	UInt8 * bytes = [data bytes];
	
	// ** note, lat an lon are in radians for this type!
	lat = (double)[data float64AtIndex:0 dataIsLittleEndian:YES];
	lat = [self radiansToDegrees:lat];
	lon = (double)[data float64AtIndex:8 dataIsLittleEndian:YES];	
	lon = [self radiansToDegrees:lon];
	
	return ((Location*) [Location locationWithDoubleLatitude:lat
										  doubleLongitude:lon]);
}


- (Location*)parsePositionPacket_D800:(GarminPacket*)packet {
	// GPS III, StreetPilot, eMap
	
	/*
	float ele;		// altitude above WGS 84 ellipsoid (meters)
	float epe;		// estimated position error, 2 sigma (meters)
	float eph;		// epe, but horizontal only (meters)
	float epv;		// epe, but vertical only (meters)
	*/
	
	double lat, lon;

	GarminFixType fix;
	
	//float velocityEast, velocityNorth, velocityUp;
	
	NSRange range;
	int size, i;
	NSData * data = [packet packetData];
	size = [data length];
	
	if (size < 64) {	// note, something's weird here - this should be 68.
						// but the GPS sends a packet with only 64.
		return nil;		//packet is malformed
		NSLog(@"received malformed position packet");
	}
	
	UInt8 * bytes = [data bytes];
	
	// note, there's something weird about this..  The latitude and
	// longitude should have been at 28 and 36, but instead they are really
	// at 26 and 34..  Also, I can't seem to find any of the other fields,
	// so for now, we're stuck with lat and lon.
	
	
/*
	ele = [data float32AtIndex:0 dataIsLittleEndian:YES];
	epe = [data float32AtIndex:4 dataIsLittleEndian:YES];
	eph = [data float32AtIndex:8 dataIsLittleEndian:YES];
	epv = [data float32AtIndex:12 dataIsLittleEndian:YES];

	fix = (GarminFixType)[data sInt32AtIndex:16 dataIsLittleEndian:YES];
*/
	
	// ** note, lat an lon are in radians for this type!
	lat = (double)[data float64AtIndex:26 dataIsLittleEndian:YES];
	lat = [self radiansToDegrees:lat];
	lon = (double)[data float64AtIndex:34 dataIsLittleEndian:YES];
	lon = [self radiansToDegrees:lon];

/*
	velocityEast = [data float32AtIndex:44 dataIsLittleEndian:YES];
	velocityNorth = [data float32AtIndex:48 dataIsLittleEndian:YES];
	velocityUp = [data float32AtIndex:52 dataIsLittleEndian:YES];
*/

	
	return ((Location*) [Location locationWithDoubleLatitude:lat
											 doubleLongitude:lon]);
}




#pragma mark -
#pragma mark Parsing waypoint methods


- (Waypoint*) parseWaypointPacket:(GarminPacket*)packet {
	// This method figures out which waypoint protocol specific method to call
	// during a waypoint download.
	// Note, the determineProtocolsToUse method figures out the value of the wptProtocol parameter
	
	switch(wptProtocol) {
		case 109:
			return [self parseWaypointPacket_D109:packet];
			break;
		case 108:
			return [self parseWaypointPacket_D108:packet];
			break;
		case 107:
			return [self parseWaypointPacket_D107:packet];
			break;
		case 105:
			return [self parseWaypointPacket_D105:packet];
			break;
		case 104:
			return [self parseWaypointPacket_D104:packet];
			break;
		case 103:
			return [self parseWaypointPacket_D103:packet];
			break;
		case 102:
			return [self parseWaypointPacket_D102:packet];
			break;
		case 101:
			return [self parseWaypointPacket_D101:packet];
			break;
		case 100:
			return [self parseWaypointPacket_D100:packet];
			break;
	}
		
	//default
	return nil;
}




- (Waypoint*) parseWaypointPacket_D109:(GarminPacket*)packet {
	//only works for D109 waypoint format
	//note, this is the protocol that the eMap uses.
	//this protocol is defined in the textfile d109.txt

	//the following variables are all of the things I currently parse out of the waypoint data:
	double lat, lon, ele;
	double dpth, dist;
	NSString *wptName, *cmnt;
	int waypointIconNum;
	//*******************************

	NSRange range;
	int size, i;
	NSData * data = [packet packetData];
	size = [data length];
	
	if (size < 55) {
		return nil;		//packet is malformed
		NSLog(@"received malformed waypoint");
	}
	
	UInt8 * bytes = [data bytes];
	
	//symbol for the waypoint picture (look this up in a table)
	waypointIconNum = (int)[data sInt16AtIndex:4 dataIsLittleEndian:YES];  
	
	//lat should start at index 24
	//it's a long, so that's 4 bytes		
	SInt32 tempNum = [data sInt32AtIndex:24 dataIsLittleEndian:YES];
	lat = [self semicirclesToDegrees:tempNum];
	
	//lon should start at index 24 + 4 = 28
	//it's also a long.
	tempNum = [data sInt32AtIndex:28 dataIsLittleEndian:YES];
	lon = [self semicirclesToDegrees:tempNum];
			
	ele = (double)floor([data float32AtIndex:32 dataIsLittleEndian:YES]);
	if (ele > 1E24) {
		//this means that it wasn't set by the user.
		ele = 0.0;
	}
	
		
	dpth = (double)[data float32AtIndex:36 dataIsLittleEndian:YES];  //depth
	dist = (double)[data float32AtIndex:40 dataIsLittleEndian:YES];  //proximity distance
		
	int nameStartIndex = 52;
	int endPos = 52;
	
	if (size > nameStartIndex + 1) { 
		//we might have a name included...
	
		wptName = [data cStringAtIndex:nameStartIndex endPos:&endPos];
		
		if (wptName == nil) {
			wptName = [NSString stringWithString:@"ERROR"];
		}
	}
								
	int cmntStartIndex = endPos + 1;
	endPos = cmntStartIndex;
	
	if (size > cmntStartIndex + 1) {
		//we might have a comment included...

		cmnt = [data cStringAtIndex:cmntStartIndex endPos:&endPos];
		
		if (cmnt == nil) {
			cmnt = [NSString stringWithString:@""];
		}
	}
		
						
	Waypoint * wpt = [Waypoint waypointWithDoubleLatitude:lat
										  doubleLongitude:lon];
	
	[wpt setName:wptName];
	[wpt setElevation:[NSNumber numberWithDouble:ele]];
	[wpt setSymbolName:[self iconNameFromNum:waypointIconNum]];
	[wpt setComment:cmnt];
		
	return wpt;
}


- (Waypoint*) parseWaypointPacket_D108:(GarminPacket*)packet {
	// only works for D108 waypoint format
	// GPSMAP 162/168, eMap, GPSMAP 295
	
	// the following variables are all of the things I currently parse out of the waypoint data:
	double lat, lon, ele;
	double dpth, dist;
	NSString *wptName, *cmnt;
	int waypointIconNum;
	//*******************************
	
	NSRange range;
	int size, i;
	NSData * data = [packet packetData];
	size = [data length];
	
	if (size < 48) {
		return nil;		//packet is malformed
		NSLog(@"received malformed waypoint");
	}
	
	UInt8 * bytes = [data bytes];
	
	//symbol for the waypoint picture (look this up in a table)
	waypointIconNum = (int)[data sInt16AtIndex:4 dataIsLittleEndian:YES];  
	
	lat = (double)[data sInt32AtIndex:24 dataIsLittleEndian:YES];
	lat = [self semicirclesToDegrees:lat];
	
	lon = (double)[data sInt32AtIndex:28 dataIsLittleEndian:YES];
	lon = [self semicirclesToDegrees:lon];
	
	ele = (double)[data float32AtIndex:32 dataIsLittleEndian:YES];
	if (ele > 1E24) {
		ele = 0.0;  //this means that it wasn't set by the user.
	}
	
	dpth = (double)[data float32AtIndex:36 dataIsLittleEndian:YES];  //depth
	dist = (double)[data float32AtIndex:40 dataIsLittleEndian:YES];  //proximity distance
	
	int nameStartIndex = 47;
	int endPos = 47;
	
	if (size > nameStartIndex + 1) { 
		//we might have a name included...
		
		wptName = [data cStringAtIndex:nameStartIndex endPos:&endPos];
		
		if (wptName == nil) {
			wptName = [NSString stringWithString:@"ERROR"];
		}
	}
	
	int cmntStartIndex = endPos + 1;
	endPos = cmntStartIndex;
	
	if (size > cmntStartIndex + 1) {
		//we might have a comment included...
		
		cmnt = [data cStringAtIndex:cmntStartIndex endPos:&endPos];
		
		if (cmnt == nil) {
			cmnt = [NSString stringWithString:@""];
		}
	}
	
	
	Waypoint * wpt = [Waypoint waypointWithDoubleLatitude:lat
										  doubleLongitude:lon];
	
	[wpt setName:wptName];
	[wpt setElevation:[NSNumber numberWithDouble:ele]];
	[wpt setSymbolName:[self iconNameFromNum:waypointIconNum]];
	[wpt setComment:cmnt];
	
	return wpt;
}


- (Waypoint*) parseWaypointPacket_D107:(GarminPacket*)packet {
	// only works for D107 waypoint format
	// GPS 12CX
	
	// the following variables are all of the things I currently parse out of the waypoint data:
	double lat, lon;
	NSString *wptName, *cmnt;
	int waypointIconNum;
	//*******************************
	
	NSRange range;
	int size, i;
	NSData * data = [packet packetData];
	size = [data length];
	
	if (size < 65) {
		return nil;		//packet is malformed
		NSLog(@"received malformed waypoint");
	}
	
	UInt8 * bytes = [data bytes];
	
	//symbol for the waypoint picture (look this up in a table)
	waypointIconNum = (int)[data sInt16AtIndex:58 dataIsLittleEndian:YES];  
	
	lat = (double)[data sInt32AtIndex:6 dataIsLittleEndian:YES];
	lat = [self semicirclesToDegrees:lat];
	
	lon = (double)[data sInt32AtIndex:10 dataIsLittleEndian:YES];
	lon = [self semicirclesToDegrees:lon];
		
	range.length = 6;
	range.location = 0;
	wptName = [[NSString alloc] initWithData:[data subdataWithRange:range] encoding:NSASCIIStringEncoding];
	
	range.length = 40;
	range.location = 18;
	cmnt = [[NSString alloc] initWithData:[data subdataWithRange:range] encoding:NSASCIIStringEncoding];
	
	
	Waypoint * wpt = [Waypoint waypointWithDoubleLatitude:lat
										  doubleLongitude:lon];
	
	[wpt setName:wptName];
	[wpt setSymbolName:[self iconNameFromNum:waypointIconNum]];
	[wpt setComment:cmnt];
	
	return wpt;
}

- (Waypoint*) parseWaypointPacket_D105:(GarminPacket*)packet {
	// only works for D105 waypoint format
	// StreetPilot (user waypoints)
	
	// the following variables are all of the things I currently parse out of the waypoint data:
	double lat, lon;
	NSString *wptName;
	int waypointIconNum;
	//*******************************
	
	NSRange range;
	int size, i;
	NSData * data = [packet packetData];
	size = [data length];
	
	if (size < 10) {
		return nil;		//packet is malformed
		NSLog(@"received malformed waypoint");
	}
	
	UInt8 * bytes = [data bytes];
	
	//symbol for the waypoint picture (look this up in a table)
	waypointIconNum = (int)[data sInt16AtIndex:8 dataIsLittleEndian:YES];  
	
	lat = (double)[data sInt32AtIndex:0 dataIsLittleEndian:YES];
	lat = [self semicirclesToDegrees:lat];
	
	lon = (double)[data sInt32AtIndex:4 dataIsLittleEndian:YES];
	lon = [self semicirclesToDegrees:lon];
	
	int nameStartIndex = 10;
	int endPos = 10;
	
	if (size > nameStartIndex + 1) { 
		// we might have a name included...
		// it's optional for this waypoint type
		
		wptName = [data cStringAtIndex:nameStartIndex endPos:&endPos];
		
		if (wptName == nil) {
			wptName = [NSString stringWithString:@""];  
		}
	}
	
	Waypoint * wpt = [Waypoint waypointWithDoubleLatitude:lat
										  doubleLongitude:lon];
	
	[wpt setName:wptName];
	[wpt setSymbolName:[self iconNameFromNum:waypointIconNum]];
	
	return wpt;
}


- (Waypoint*) parseWaypointPacket_D104:(GarminPacket*)packet {
	// only works for D104 waypoint format
	// GPS III
	
	// the following variables are all of the things I currently parse out of the waypoint data:
	double lat, lon;
	NSString *wptName, *cmnt;
	int waypointIconNum;
	//*******************************
	
	NSRange range;
	int size, i;
	NSData * data = [packet packetData];
	size = [data length];
	
	if (size < 65) {
		return nil;		//packet is malformed
		NSLog(@"received malformed waypoint");
	}
	
	UInt8 * bytes = [data bytes];
	
	//symbol for the waypoint picture (look this up in a table)
	waypointIconNum = (int)[data sInt16AtIndex:62 dataIsLittleEndian:YES];  
	
	lat = (double)[data sInt32AtIndex:6 dataIsLittleEndian:YES];
	lat = [self semicirclesToDegrees:lat];
	
	lon = (double)[data sInt32AtIndex:10 dataIsLittleEndian:YES];
	lon = [self semicirclesToDegrees:lon];
	
	range.length = 6;
	range.location = 0;
	wptName = [[NSString alloc] initWithData:[data subdataWithRange:range] encoding:NSASCIIStringEncoding];
	
	range.length = 40;
	range.location = 18;
	cmnt = [[NSString alloc] initWithData:[data subdataWithRange:range] encoding:NSASCIIStringEncoding];
	
	
	Waypoint * wpt = [Waypoint waypointWithDoubleLatitude:lat
										  doubleLongitude:lon];
	
	[wpt setName:wptName];
	[wpt setSymbolName:[self iconNameFromNum:waypointIconNum]];
	[wpt setComment:cmnt];
	
	return wpt;
}


- (Waypoint*) parseWaypointPacket_D103:(GarminPacket*)packet {
	// only works for D103 waypoint format
	// GPS 12, GPS 12 XL, GPS 48, GPS II Plus
	
	// the following variables are all of the things I currently parse out of the waypoint data:
	double lat, lon;
	NSString *wptName, *cmnt;
	int waypointIconNum;
	//*******************************
	
	NSRange range;
	int size, i;
	NSData * data = [packet packetData];
	size = [data length];
	
	if (size < 60) {
		return nil;		//packet is malformed
		NSLog(@"received malformed waypoint");
	}
	
	UInt8 * bytes = [data bytes];
	
	//symbol for the waypoint picture (look this up in a table)
	waypointIconNum = (int)[data sInt16AtIndex:58 dataIsLittleEndian:YES];  
	
	lat = (double)[data sInt32AtIndex:6 dataIsLittleEndian:YES];
	lat = [self semicirclesToDegrees:lat];
	
	lon = (double)[data sInt32AtIndex:10 dataIsLittleEndian:YES];
	lon = [self semicirclesToDegrees:lon];
	
	range.length = 6;
	range.location = 0;
	wptName = [[NSString alloc] initWithData:[data subdataWithRange:range] encoding:NSASCIIStringEncoding];
	
	range.length = 40;
	range.location = 18;
	cmnt = [[NSString alloc] initWithData:[data subdataWithRange:range] encoding:NSASCIIStringEncoding];
	
	
	Waypoint * wpt = [Waypoint waypointWithDoubleLatitude:lat
										  doubleLongitude:lon];
	
	[wpt setName:wptName];
	[wpt setSymbolName:[self iconNameFromNum:waypointIconNum]];
	[wpt setComment:cmnt];
	
	return wpt;
}

- (Waypoint*) parseWaypointPacket_D102:(GarminPacket*)packet {
	// only works for D102 waypoint format
	// GPSMAP 175, GPSMAP 210, GPSMAP 220
	
	// the following variables are all of the things I currently parse out of the waypoint data:
	double lat, lon;
	NSString *wptName, *cmnt;
	int waypointIconNum;
	//*******************************
	
	NSRange range;
	int size, i;
	NSData * data = [packet packetData];
	size = [data length];
	
	if (size < 64) {
		return nil;		//packet is malformed
		NSLog(@"received malformed waypoint");
	}
	
	UInt8 * bytes = [data bytes];
	
	//symbol for the waypoint picture (look this up in a table)
	waypointIconNum = (int)[data sInt16AtIndex:62 dataIsLittleEndian:YES];  
	
	lat = (double)[data sInt32AtIndex:6 dataIsLittleEndian:YES];
	lat = [self semicirclesToDegrees:lat];
	
	lon = (double)[data sInt32AtIndex:10 dataIsLittleEndian:YES];
	lon = [self semicirclesToDegrees:lon];
	
	range.length = 6;
	range.location = 0;
	wptName = [[NSString alloc] initWithData:[data subdataWithRange:range] encoding:NSASCIIStringEncoding];
	
	range.length = 40;
	range.location = 18;
	cmnt = [[NSString alloc] initWithData:[data subdataWithRange:range] encoding:NSASCIIStringEncoding];
	
	
	Waypoint * wpt = [Waypoint waypointWithDoubleLatitude:lat
										  doubleLongitude:lon];
	
	[wpt setName:wptName];
	[wpt setSymbolName:[self iconNameFromNum:waypointIconNum]];
	[wpt setComment:cmnt];
	
	return wpt;
}


- (Waypoint*) parseWaypointPacket_D101:(GarminPacket*)packet {
	// only works for D101 waypoint format
	// GPSMAP 210, GPSMAP 220 (both prior to version 4.00)
	
	// the following variables are all of the things I currently parse out of the waypoint data:
	double lat, lon;
	NSString *wptName, *cmnt;
	int waypointIconNum;
	//*******************************
	
	NSRange range;
	int size, i;
	NSData * data = [packet packetData];
	size = [data length];
	
	if (size < 63) {
		return nil;		//packet is malformed
		NSLog(@"received malformed waypoint");
	}
	
	UInt8 * bytes = [data bytes];
	
	//symbol for the waypoint picture (look this up in a table)
	waypointIconNum = (int)[data sInt16AtIndex:62 dataIsLittleEndian:YES];  
	
	lat = (double)[data sInt32AtIndex:6 dataIsLittleEndian:YES];
	lat = [self semicirclesToDegrees:lat];
	
	lon = (double)[data sInt32AtIndex:10 dataIsLittleEndian:YES];
	lon = [self semicirclesToDegrees:lon];
	
	range.length = 6;
	range.location = 0;
	wptName = [[NSString alloc] initWithData:[data subdataWithRange:range] encoding:NSASCIIStringEncoding];
	
	range.length = 40;
	range.location = 18;
	cmnt = [[NSString alloc] initWithData:[data subdataWithRange:range] encoding:NSASCIIStringEncoding];
	
	
	Waypoint * wpt = [Waypoint waypointWithDoubleLatitude:lat
										  doubleLongitude:lon];
	
	[wpt setName:wptName];
	[wpt setSymbolName:[self iconNameFromNum:waypointIconNum]];
	[wpt setComment:cmnt];
	
	return wpt;
}

- (Waypoint*) parseWaypointPacket_D100:(GarminPacket*)packet {
	// only works for D100 waypoint format
	// GPS 38, GPS 40, GPS 45, GPS 75, GPS II
	
	// the following variables are all of the things I currently parse out of the waypoint data:
	double lat, lon;
	NSString *wptName, *cmnt;
	//*******************************
	
	NSRange range;
	int size, i;
	NSData * data = [packet packetData];
	size = [data length];
	
	if (size < 58) {
		return nil;		//packet is malformed
		NSLog(@"received malformed waypoint");
	}
	
	UInt8 * bytes = [data bytes];
		
	lat = (double)[data sInt32AtIndex:6 dataIsLittleEndian:YES];
	lat = [self semicirclesToDegrees:lat];
	
	lon = (double)[data sInt32AtIndex:10 dataIsLittleEndian:YES];
	lon = [self semicirclesToDegrees:lon];
	
	range.length = 6;
	range.location = 0;
	wptName = [[NSString alloc] initWithData:[data subdataWithRange:range] encoding:NSASCIIStringEncoding];
	
	range.length = 40;
	range.location = 18;
	cmnt = [[NSString alloc] initWithData:[data subdataWithRange:range] encoding:NSASCIIStringEncoding];
	
	
	Waypoint * wpt = [Waypoint waypointWithDoubleLatitude:lat
										  doubleLongitude:lon];
	
	[wpt setName:wptName];
	[wpt setComment:cmnt];
	
	return wpt;
}


#pragma mark -
#pragma mark Parsing tracklog methods

- (void)parseTracklogHeaderPacket_D310:(GarminPacket*)packet {
	// GPSMAP 162/168, eMap, GPSMAP 295
	
	// this should be called each time we receive a new named tracklog
	
	BOOL dspl;
	NSString *trkName;

	NSRange range;
	int size, i;
	NSData * data = [packet packetData];
	size = [data length];
	
	if (size < 2) {
		return nil;		//packet is malformed
		NSLog(@"received malformed track header");
	}
	
	UInt8 * bytes = [data bytes];
		
	int nameStartIndex = 2;
	int endPos = 2;
	
	if (size > nameStartIndex + 1) { 
		//we might have a name included...
		
		trkName = [data cStringAtIndex:nameStartIndex endPos:&endPos];
	}
	
	[self GPSDownloadProgress:downloadCounter outOf:numRecords currentName:trkName];
	[self logMessage:[NSString stringWithFormat:@"Found track named %@\n", trkName]];
	
	if ((!firstTrack) && (currentTrk != nil)) {
		// then we've already downloaded at least one.
		[trackList addElementToList:currentTrk];
	}
	
	firstTrack = NO;
	
	[currentTrk release];
	currentTrk = [[XMLElement XMLElementWithName:@"trk"] retain];
	[currentTrk setElement:trkName forKey:@"name"];

}

- (void)parseTracklogPacket_D301:(GarminPacket*)packet {
	// GPSMAP 162/168, eMap, GPSMAP 295
	
	double lat, lon, ele, dpth;
	UInt32 time;
	BOOL new_trk;		// is this the start of a new track segment?
	
	NSRange range;
	int size, i;
	NSData * data = [packet packetData];
	size = [data length];
	
	if (size < 21) {
		return nil;		//packet is malformed
		NSLog(@"received malformed trkpt");
	}
	
	UInt8 * bytes = [data bytes];
		
	SInt32 tempNum;
	
	// lat
	tempNum = [data sInt32AtIndex:0 dataIsLittleEndian:YES];
	lat = [self semicirclesToDegrees:tempNum];
	
	// lon
	tempNum = [data sInt32AtIndex:4 dataIsLittleEndian:YES];
	lon = [self semicirclesToDegrees:tempNum];
	
	// time
	// this is the number of seconds since UTC 12:00 AM on December 31st 1989.
	time = [data uInt32AtIndex:8 dataIsLittleEndian:YES];
	
	// elevation
	ele = (double)floor([data float32AtIndex:12 dataIsLittleEndian:YES]);
	if (ele == 1.0e25) { ele = 0.0; }   // not supported
		
	// depth 
	dpth = (double)[data float32AtIndex:16 dataIsLittleEndian:YES];  
	if (dpth == 1.0e25) { dpth = 0.0; }   // not supported
	
	// is this the start of a new track segment?
	new_trk = (BOOL)bytes[20];
	
	Waypoint * wpt = [Waypoint waypointWithDoubleLatitude:lat
										  doubleLongitude:lon];
	
	[wpt setElevation:[NSNumber numberWithDouble:ele]];
	
//	NSLog(@"trkpt: %f, %f, %u, %f", lat, lon, time, ele);
	
	if (new_trk) {
		// it's the start of a new track segment
		
		if (currentTrkSeg != nil) {
			// add the last segment to the current track
			[currentTrk addElementToList:currentTrkSeg];
		}
		
		[currentTrkSeg release];
		currentTrkSeg = [[XMLElement alloc] init];
	}
	
	
	Waypoint * trkpt = [Waypoint waypointWithDoubleLatitude:lat
										  doubleLongitude:lon];
	
	[trkpt setElevation:[NSNumber numberWithDouble:ele]];
	
	// add this track point to the current track segment.
	[currentTrkSeg addElementToList:trkpt];
	
}

- (void)parseTracklogPacket_D300:(GarminPacket*)packet {
	// all older GPS models use this protocol
}


#pragma mark -
#pragma mark Parsing route methods



#pragma mark -
#pragma mark Sending methods



- (void)sendPacket:(GarminPacket*)packet {
	if (!port) {
		// open a new port if we don't already have one
		[self initPort];
	}

	if ([port isOpen]) { // in case an error occured while opening the port
		[port writeDataInBackground:[packet packetForSending]];
		
		// timeout timer
		// don't bother timing out when we send an Ack byte, or if we've already
		// tried sending it 4 times.
		if ((numFires < 4) &&
			([packet packetID] != Pid_Ack_Byte)) {
			
				[self startTimer:[packet packetID]];
		}
	}

}


// sends the passed command code to the GPS
- (void)sendCommand:(GarminCmnd)command {
	//pass it one of the commands which are defined as constants

	UInt8 bytes[2];
	
	bytes[0] = (UInt8)command;
	bytes[1] = 0x00;					
		
	NSData * data = [NSData dataWithBytes:(void*)bytes length:2];

	GarminPacket * p = [GarminPacket garminPacketWithPacketId:(UInt8)Pid_Command_Data
												   packetData:data];
	
	
	NSLog(@"sending command to GPS");
	
	[self sendPacket:p];	
}


- (void)sendPidRecords:(int)numRecords {
	
	NSMutableData * d = [NSMutableData dataWithLength:2];
	[d setSInt16:numRecords
		 AtIndex:0 dataIsLittleEndian:YES];
	
	GarminPacket * packet = [GarminPacket garminPacketWithPacketId:Pid_Records
														packetData:d];
	
	NSLog(@"sending Pid_Records packet to GPS");
	
	[self sendPacket:packet];

}

- (void)sendAbortTransfer {
	[self sendCommand:Cmnd_Abort_Transfer];		
}

- (void)sendGetTimeRequest {
	mode = DOWNLOAD_MODE;
	[self sendCommand:Cmnd_Transfer_Time];	
}

- (void)sendRequestPosition {
	mode = DOWNLOAD_MODE;
	[self sendCommand:Cmnd_Transfer_Posn];
}


- (void)sendRequestGPSID {
	//sends a request to the GPS for it to identify itself.
	// should be 10 FE 00 02 10 03
		
	GarminPacket * p = [GarminPacket garminPacketWithPacketId:(UInt8)Pid_Product_Rqst
												   packetData:nil];
	
	NSLog(@"sending GPSIdentify request");
	
	[self sendPacket:p];
}


- (void)sendXferComplete:(GarminPid)packetID {

	UInt8 bytes[2];
	
	bytes[0] = (UInt8)packetID;
	bytes[1] = 0x00;					
	
	NSData * data = [NSData dataWithBytes:(void*)bytes length:2];
	
	GarminPacket * p = [GarminPacket garminPacketWithPacketId:(UInt8)Pid_Xfer_Cmplt
												   packetData:data];
	
	NSLog(@"sending XferCmplt packet");
	
	[self sendPacket:p];
	
}



- (void)sendNAK:(GarminPid)packetID {
	//note, for some reason, the GPS seems to like it better if you send a two byte NAK
	//even though the manual says that one byte is sufficient...

	// NAK packetID = 0x15
	
	UInt8 bytes[2];
	
	bytes[0] = (UInt8)packetID;
	bytes[1] = 0x00;					
	
	NSData * data = [NSData dataWithBytes:(void*)bytes length:2];
	
	GarminPacket * p = [GarminPacket garminPacketWithPacketId:(UInt8)Pid_Nak_Byte
												   packetData:data];
	
	NSLog(@"sending NAK packet");
	
	[self sendPacket:p];
	
}

- (void)sendACK:(GarminPid)packetID {
	//note, for some reason, the GPS seems to like it better if you send a two byte ACK
	//even though the manual says that one byte is sufficient...

	UInt8 bytes[2];
	
	bytes[0] = (UInt8)packetID;
	bytes[1] = 0x00;					
	
	NSData * data = [NSData dataWithBytes:(void*)bytes length:2];
	
	GarminPacket * p = [GarminPacket garminPacketWithPacketId:(UInt8)Pid_Ack_Byte
												   packetData:data];
	
//	NSLog(@"sending ACK packet");
	
	[self sendPacket:p];
}


#pragma mark -
#pragma mark Sending waypoint methods

- (void)sendWaypoint:(Waypoint*)wpt {
	//this method figures out which waypoint protocol specific method to call
	//note, the determineProtocolsToUse method figures out the value of the wptProtocol parameter
	
	if (wpt == nil) {
		return;
	}
	
	if ([[wpt name] length] == 0) {
		return;
		NSLog(@"Can't upload unnamed waypoint.");
	}
		
	switch(wptProtocol) {
		case 109:
			[self sendWaypoint_D109:wpt];
			break;
		case 108:
			[self sendWaypoint_D108:wpt];
			break;
		case 107:
			[self sendWaypoint_D107:wpt];
			break;
		case 105:
			[self sendWaypoint_D105:wpt];
			break;
		case 104:
			[self sendWaypoint_D104:wpt];
			break;
		case 103:
			[self sendWaypoint_D103:wpt];
			break;
		case 102:
			[self sendWaypoint_D102:wpt];
			break;
		case 101:
			[self sendWaypoint_D101:wpt];
			break;
		case 100:
			[self sendWaypoint_D100:wpt];
			break;
	}			
}


- (void)sendWaypoint_D109:(Waypoint*)wpt {
	//note, this only works for the D109_Wpt_Type
	//eMap, newer units (eTrex??)
	
	//note, see text document d109.txt in the same folder as the pdf file.
	//this protocol is the same as D108 except for the following:

	//dtyp - Data packet type, must be 0x01 for D109.
	//
	//dsp_color - The 'dspl_color' member contains three fields; bits 0-4 specify
	//the color, bits 5-6 specify the waypoint display attribute and bit 7 is unused
	//and must be 0. Color values are as specified for D108 except that the default
	//value is 0x1f. Display attribute values are as specified for D108.
	//
	//attr - Attribute. Must be 0x70 for D109.
	//
	//ete - Estimated time en route in seconds to next waypoint. Default value is
	//0xffffffff.
		
	int i;
	int nameLength = [[wpt name] length] + 1;   // + 1 to account for null terminator

	int cmntLength = [[wpt comment] length];
	if (cmntLength > 0) { cmntLength += 1; }
	
	int dataSize = 52 + nameLength + cmntLength;
	
	NSMutableData * data = [NSMutableData dataWithLength:dataSize];
	UInt8 * bytes = (UInt8*)[data mutableBytes];

	bytes[0] = 0x01;  //dtyp, must be 0x01
	bytes[1] = 0x00;  //wpt class, 0x00 means "user waypoint"
	bytes[2] = 0x1f;  //dspl_color (note, this is different from D108)
	bytes[3] = 0x70;  //attr must be 0x70 for D109
	
	//symbol num for the waypoint icon
	[data setSInt16:(SInt16)[self iconNumFromName:[wpt symbolName]] 
			AtIndex:4 dataIsLittleEndian:YES];
	
	//note, skip an index number because the short is 2 bytes...
	
	//this section is 18 bytes of "subclass"
	
	//(not used unless it's a map waypoint)
	//we need 6 bytes of zero
	for (i = 6; i < 12; i++) {
		bytes[i] = 0x00;
	}
			
	//follwed by 12 bytes of &hff
	for (i = 12; i < 24; i++) {
		bytes[i] = 0xff;
	}
	
	//latitude
	[data setSInt32:[self degreesToSemicircles:[wpt doubleLatitude]]
			AtIndex:24 dataIsLittleEndian:YES];

	//longitude
	[data setSInt32:[self degreesToSemicircles:[wpt doubleLongitude]]
			AtIndex:28 dataIsLittleEndian:YES];

	//altitude (meters)
	[data setFloat32:(Float32)[[wpt elevation] floatValue]
			 AtIndex:32 dataIsLittleEndian:YES];

	//depth (meters)
	[data setFloat32:(Float32)0.0
			 AtIndex:36 dataIsLittleEndian:YES];
	
	//proximity distance (meters)
	[data setFloat32:(Float32)0.0
			 AtIndex:40 dataIsLittleEndian:YES];
					
	//state (don't bother with this)
	bytes[44] = 0x00;
	bytes[45] = 0x00;
	
	//country code (don't bother with this)
	bytes[46] = 0x00;
	bytes[47] = 0x00;

	//ete is a longword which is a 4 byte unsigned integer
	bytes[48] = 0xff;  //ff is the default for all of these
	bytes[49] = 0xff;
	bytes[50] = 0xff;
	bytes[51] = 0xff;
	
	[data setCString:[self makeStringGPSSafe:[wpt name] maxLength:51 allowSpaces:YES]
			 atIndex:52];
	
	[data setCString:[self makeStringGPSSafe:[wpt comment] maxLength:51 allowSpaces:YES]
			 atIndex:52 + nameLength];
					
	//should be other stuff, but let's skip it and see what happens...

	// actually form the packet to send
	GarminPacket * packet = [GarminPacket garminPacketWithPacketId:Pid_Wpt_Data
														packetData:(NSData*)data];
					
	//now, send this packet to the GPS
	[self sendPacket:packet];					
}


- (void)sendWaypoint_D108:(Waypoint*)wpt {
	// note, this only works for the D108_Wpt_Type
	// GPSMAP 162/168, eMap, GPSMAP 295
	
	int i;
	int nameLength = [[wpt name] length] + 1;   // + 1 to account for null terminator
	
	int cmntLength = [[wpt comment] length];
	if (cmntLength > 0) { cmntLength += 1; }

	int dataSize = 48 + nameLength + cmntLength;
	
	NSMutableData * data = [NSMutableData dataWithLength:dataSize];
	UInt8 * bytes = (UInt8*)[data mutableBytes];
	
	bytes[0] = 0x00;		// wpt class
	bytes[1] = 0xFF;		// color
	bytes[2] = 0x00;		// dspl
	bytes[3] = 0x60;		// attr
	
	//symbol num for the waypoint icon
	[data setSInt16:(SInt16)[self iconNumFromName:[wpt symbolName]] 
			AtIndex:4 dataIsLittleEndian:YES];
	
	//note, skip an index number because the short is 2 bytes...
	
	//this section is 18 bytes of "subclass"
	
	//(not used unless it's a map waypoint)
	//we need 6 bytes of zero
	for (i = 6; i < 12; i++) {
		bytes[i] = 0x00;
	}
	
	//follwed by 12 bytes of &hff
	for (i = 12; i < 24; i++) {
		bytes[i] = 0xff;
	}
	
	//latitude
	[data setSInt32:[self degreesToSemicircles:[wpt doubleLatitude]]
			AtIndex:24 dataIsLittleEndian:YES];
	
	//longitude
	[data setSInt32:[self degreesToSemicircles:[wpt doubleLongitude]]
			AtIndex:28 dataIsLittleEndian:YES];
	
	//altitude (meters)
	[data setFloat32:(Float32)[[wpt elevation] floatValue]
			 AtIndex:32 dataIsLittleEndian:YES];
	
	//depth (meters)
	[data setFloat32:(Float32)0.0
			 AtIndex:36 dataIsLittleEndian:YES];
	
	//proximity distance (meters)
	[data setFloat32:(Float32)0.0
			 AtIndex:40 dataIsLittleEndian:YES];
	
	//state (don't bother with this)
	bytes[44] = 0x00;
	bytes[45] = 0x00;
	
	//country code (don't bother with this)
	bytes[46] = 0x00;
	bytes[47] = 0x00;
		
	[data setCString:[self makeStringGPSSafe:[wpt name] maxLength:51 allowSpaces:YES]
			 atIndex:48];
	
	[data setCString:[self makeStringGPSSafe:[wpt comment] maxLength:51 allowSpaces:YES]
			 atIndex:48 + nameLength];
	
	//should be other stuff, but let's skip it and see what happens...
	
	// actually form the packet to send
	GarminPacket * packet = [GarminPacket garminPacketWithPacketId:Pid_Wpt_Data
														packetData:(NSData*)data];
	
	//now, send this packet to the GPS
	[self sendPacket:packet];					
}


- (void)sendWaypoint_D107:(Waypoint*)wpt {
	// note, this only works for the D107_Wpt_Type
	// GPS 12CX
	
	int i;
	int dataSize = 65;
	
	NSMutableData * data = [NSMutableData dataWithLength:dataSize];
	UInt8 * bytes = (UInt8*)[data mutableBytes];
	
	//symbol num for the waypoint icon
	[data setSInt16:(SInt16)[self iconNumFromName:[wpt symbolName]] 
			AtIndex:58 dataIsLittleEndian:YES];
			
	//latitude
	[data setSInt32:[self degreesToSemicircles:[wpt doubleLatitude]]
			AtIndex:6 dataIsLittleEndian:YES];
	
	//longitude
	[data setSInt32:[self degreesToSemicircles:[wpt doubleLongitude]]
			AtIndex:10 dataIsLittleEndian:YES];
		
	NSRange range;
	range.length = 6;
	range.location = 0;
	
	[data setNonTerminatedString:[self makeStringGPSSafe:[wpt name] maxLength:6 allowSpaces:NO]
			 range:range];
	
	range.length = 40;
	range.location = 18;
	[data setNonTerminatedString:[self makeStringGPSSafe:[wpt comment] maxLength:40 allowSpaces:NO]
			 range:range];
	
	// actually form the packet to send
	GarminPacket * packet = [GarminPacket garminPacketWithPacketId:Pid_Wpt_Data
														packetData:(NSData*)data];
	
	//now, send this packet to the GPS
	[self sendPacket:packet];					
	
}


- (void)sendWaypoint_D105:(Waypoint*)wpt {
	// note, this only works for the D105_Wpt_Type
	// StreetPilot
	
	int i;
	int nameLength = [[wpt name] length] + 1;   // + 1 to account for null terminator
	int dataSize = 10 + nameLength;
	
	NSMutableData * data = [NSMutableData dataWithLength:dataSize];
	UInt8 * bytes = (UInt8*)[data mutableBytes];
	
	//symbol num for the waypoint icon
	[data setSInt16:(SInt16)[self iconNumFromName:[wpt symbolName]] 
			AtIndex:8 dataIsLittleEndian:YES];
	
	//latitude
	[data setSInt32:[self degreesToSemicircles:[wpt doubleLatitude]]
			AtIndex:0 dataIsLittleEndian:YES];
	
	//longitude
	[data setSInt32:[self degreesToSemicircles:[wpt doubleLongitude]]
			AtIndex:4 dataIsLittleEndian:YES];

	// name
	[data setCString:[self makeStringGPSSafe:[wpt name] maxLength:51 allowSpaces:YES]
			 atIndex:10];

	
	// actually form the packet to send
	GarminPacket * packet = [GarminPacket garminPacketWithPacketId:Pid_Wpt_Data
														packetData:(NSData*)data];
	
	//now, send this packet to the GPS
	[self sendPacket:packet];					
	
}



- (void)sendWaypoint_D104:(Waypoint*)wpt {
	// note, this only works for the D104_Wpt_Type
	// GPS III
	
	int i;
	int dataSize = 65;
	
	NSMutableData * data = [NSMutableData dataWithLength:dataSize];
	UInt8 * bytes = (UInt8*)[data mutableBytes];
	
	//symbol num for the waypoint icon
	[data setSInt16:(SInt16)[self iconNumFromName:[wpt symbolName]] 
			AtIndex:58 dataIsLittleEndian:YES];
	
	//latitude
	[data setSInt32:[self degreesToSemicircles:[wpt doubleLatitude]]
			AtIndex:6 dataIsLittleEndian:YES];
	
	//longitude
	[data setSInt32:[self degreesToSemicircles:[wpt doubleLongitude]]
			AtIndex:10 dataIsLittleEndian:YES];
	
	NSRange range;
	range.length = 6;
	range.location = 0;
	
	[data setNonTerminatedString:[self makeStringGPSSafe:[wpt name] maxLength:6 allowSpaces:NO]
						   range:range];
	
	range.length = 40;
	range.location = 18;
	[data setNonTerminatedString:[self makeStringGPSSafe:[wpt comment] maxLength:40 allowSpaces:NO]
						   range:range];
	
	// actually form the packet to send
	GarminPacket * packet = [GarminPacket garminPacketWithPacketId:Pid_Wpt_Data
														packetData:(NSData*)data];
	
	//now, send this packet to the GPS
	[self sendPacket:packet];					
	
}


- (void)sendWaypoint_D103:(Waypoint*)wpt {
	// note, this only works for the D103_Wpt_Type
	// GPS 12, GPS 12 XL, GPS 48, GPS II Plus
	
	int i;
	int dataSize = 60;
	
	NSMutableData * data = [NSMutableData dataWithLength:dataSize];
	UInt8 * bytes = (UInt8*)[data mutableBytes];
	
	//symbol num for the waypoint icon
	[data setSInt16:(SInt16)[self iconNumFromName:[wpt symbolName]] 
			AtIndex:58 dataIsLittleEndian:YES];
	
	//latitude
	[data setSInt32:[self degreesToSemicircles:[wpt doubleLatitude]]
			AtIndex:6 dataIsLittleEndian:YES];
	
	//longitude
	[data setSInt32:[self degreesToSemicircles:[wpt doubleLongitude]]
			AtIndex:10 dataIsLittleEndian:YES];
	
	NSRange range;
	range.length = 6;
	range.location = 0;
	
	[data setNonTerminatedString:[self makeStringGPSSafe:[wpt name] maxLength:6 allowSpaces:NO]
						   range:range];
	
	range.length = 40;
	range.location = 18;
	[data setNonTerminatedString:[self makeStringGPSSafe:[wpt comment] maxLength:40 allowSpaces:NO]
						   range:range];
	
	// actually form the packet to send
	GarminPacket * packet = [GarminPacket garminPacketWithPacketId:Pid_Wpt_Data
														packetData:(NSData*)data];
	
	//now, send this packet to the GPS
	[self sendPacket:packet];					
	
}


- (void)sendWaypoint_D102:(Waypoint*)wpt {
	// note, this only works for the D102_Wpt_Type
	// GPSMAP 175, GPSMAP 210, GPSMAP 220
	
	int i;
	int dataSize = 64;
	
	NSMutableData * data = [NSMutableData dataWithLength:dataSize];
	UInt8 * bytes = (UInt8*)[data mutableBytes];
	
	//symbol num for the waypoint icon
	[data setSInt16:(SInt16)[self iconNumFromName:[wpt symbolName]] 
			AtIndex:62 dataIsLittleEndian:YES];
	
	//latitude
	[data setSInt32:[self degreesToSemicircles:[wpt doubleLatitude]]
			AtIndex:6 dataIsLittleEndian:YES];
	
	//longitude
	[data setSInt32:[self degreesToSemicircles:[wpt doubleLongitude]]
			AtIndex:10 dataIsLittleEndian:YES];
	
	NSRange range;
	range.length = 6;
	range.location = 0;
	
	[data setNonTerminatedString:[self makeStringGPSSafe:[wpt name] maxLength:6 allowSpaces:NO]
						   range:range];
	
	range.length = 40;
	range.location = 18;
	[data setNonTerminatedString:[self makeStringGPSSafe:[wpt comment] maxLength:40 allowSpaces:NO]
						   range:range];
	
	// actually form the packet to send
	GarminPacket * packet = [GarminPacket garminPacketWithPacketId:Pid_Wpt_Data
														packetData:(NSData*)data];
	
	//now, send this packet to the GPS
	[self sendPacket:packet];					
	
}


- (void)sendWaypoint_D101:(Waypoint*)wpt {
	// note, this only works for the D101_Wpt_Type
	// GPSMAP 210, GPSMAP 220 (both prior to version 4.0)
	
	int i;
	int dataSize = 63;
	
	NSMutableData * data = [NSMutableData dataWithLength:dataSize];
	UInt8 * bytes = (UInt8*)[data mutableBytes];
	
	// symbol num for the waypoint icon
	// note, it's only a single byte in this format.
	bytes[62] = (UInt8)[self iconNumFromName:[wpt symbolName]];
	
	//latitude
	[data setSInt32:[self degreesToSemicircles:[wpt doubleLatitude]]
			AtIndex:6 dataIsLittleEndian:YES];
	
	//longitude
	[data setSInt32:[self degreesToSemicircles:[wpt doubleLongitude]]
			AtIndex:10 dataIsLittleEndian:YES];
	
	NSRange range;
	range.length = 6;
	range.location = 0;
	
	[data setNonTerminatedString:[self makeStringGPSSafe:[wpt name] maxLength:6 allowSpaces:NO]
						   range:range];
	
	range.length = 40;
	range.location = 18;
	[data setNonTerminatedString:[self makeStringGPSSafe:[wpt comment] maxLength:40 allowSpaces:NO]
						   range:range];
	
	// actually form the packet to send
	GarminPacket * packet = [GarminPacket garminPacketWithPacketId:Pid_Wpt_Data
														packetData:(NSData*)data];
	
	//now, send this packet to the GPS
	[self sendPacket:packet];					
	
}


- (void)sendWaypoint_D100:(Waypoint*)wpt {
	// note, this only works for the D100_Wpt_Type
	// GPS 38, GPS 40, GPS 45, GPS 75, GPS II
	
	int i;
	int dataSize = 58;
	
	NSMutableData * data = [NSMutableData dataWithLength:dataSize];
	UInt8 * bytes = (UInt8*)[data mutableBytes];
	
	//latitude
	[data setSInt32:[self degreesToSemicircles:[wpt doubleLatitude]]
			AtIndex:6 dataIsLittleEndian:YES];
	
	//longitude
	[data setSInt32:[self degreesToSemicircles:[wpt doubleLongitude]]
			AtIndex:10 dataIsLittleEndian:YES];
	
	NSRange range;
	range.length = 6;
	range.location = 0;
	
	[data setNonTerminatedString:[self makeStringGPSSafe:[wpt name] maxLength:6 allowSpaces:NO]
						   range:range];
		
	// actually form the packet to send
	GarminPacket * packet = [GarminPacket garminPacketWithPacketId:Pid_Wpt_Data
														packetData:(NSData*)data];
	
	//now, send this packet to the GPS
	[self sendPacket:packet];					
	
}





#pragma mark -
#pragma mark Helper methods


// Pass this some data and it will return a string
// with every byte represented in hex (ie, two hex digits per byte).
// It also prints it to the console.
- (NSString*)printDataAsHex:(NSData*)data {
	int size = [data length];
	int i;
	
	UInt8 * bytes = [data bytes];
	
	NSMutableString * s = [NSMutableString stringWithCapacity:20];
	
	for (i = 0; i < size; i++) {
		[s appendString:[NSString stringWithFormat:@"%X ", bytes[i]]];
	}
	
	NSString * result = [NSString stringWithFormat:@"hex data (length = %d) = %@", size, s];

	NSLog(result);
	return result;
}


//figures out which protocols to use for things like waypoints, etc.
//these will be stored in parameters so we don't have to figure them out
//*every* single time a waypoint, etc. comes in..

- (void) determineProtocolsToUse {
	
	//note, this will be called TWICE.  Once when we first connect and figure out the GPS ID,
	//and *if* the GPS has the ability to send a protocolArray, it will be called again
	//when the protocolArray is received.

	//*************
	//parameters
	//wptProtocol - a string representing which waypoint protocol we should use.  
	//              should be set to "" if none of the protocols the GPS uses are supported
	//*************
	
	int i, num;

	NSEnumerator * enumerator;
	id obj;

	if (protocolArrayExists) {
		//the GPS *did* provide us with a protocolArray, so use it!
		
		enumerator = [protocolArray objectEnumerator];
		
		//look for a waypoint protocol to use
		//these all are in the "100" series, ie, 100, 101, 102, ... , 109
		while (obj = [enumerator nextObject]) {
#if DEBUG
			NSLog(@"%@", (NSString*)obj);
#endif			
			if ([(NSString*)obj hasPrefix:@"D"]) {  
				// the number starts at index 1, so remove the prefix
				num = [[(NSString*)obj substringFromIndex:1] intValue];
				
				if ((num - 100) < 10) {
					//it's a waypoint protocol number since they're from 100 to 109
					wptProtocol = num;
				}
				
				
				if ( ((num - 300) < 10) && ((num - 300) >= 0) )  {
					//it's a tracklog protocol number
					trkProtocol = num;
				}
				
				if ( (num == 700) || (num == 800) ) {
					// it's a pvt protocol number
					pvtProtocol = num;
				}
			}
		}
					
	} else  {
		//the GPS is too old to send us a protocolArray, so we have to look up which protocols
		//it uses in a table..  What a pain!
						
		//****************
		//finish this later
		//****************
						
		wptProtocol = 0;
							
		//go through a HUGE lookup table to see which protocol the GPS supports
		//see pg. 51 of the Garmin manual for this...
															
		//note, a lot of these are the same in the waypoint protocol.
		//I put them all in anyway, because they differ in some of the other protocols which
		//I might want to look at in the future
							
		switch (GPSIDNum) {
			case 7:
				wptProtocol = 100;
				break;
			case 13:
				wptProtocol = 100;
				break;
			case 14:
				wptProtocol = 100;
				break;
			case 15:
				wptProtocol = 151;
				break;
			case 18:
				wptProtocol = 100;
				break;
			case 20:
				wptProtocol = 150;
				break;
			case 22:
				wptProtocol = 152;
				break;
			case 23:
				wptProtocol = 100;
				break;
			case 24:
				wptProtocol = 100;
				break;
			case 25:
				wptProtocol = 100;
				break;
			case 29:
				if (GPSVersion < 4) {
					wptProtocol = 101;
				} else {
					wptProtocol = 102;
				}
				break;
			case 31:
				wptProtocol = 100;
				break;
			case 33:
				wptProtocol = 150;
				break;
			case 34:
				wptProtocol = 150;
				break;
			case 35:
				wptProtocol = 100;
				break;
			case 36:
				if (GPSVersion < 3) {
					wptProtocol = 152;  //differs in PRX column
				} else {
					wptProtocol = 152;  //differs in PRX column
				}
				break;
			case 39:
				wptProtocol = 151;
				break;
			case 41:
				wptProtocol = 100;
				break;
			case 42:
				wptProtocol = 100;
				break;
			case 44:
				wptProtocol = 101;
				break;
			case 45:
				wptProtocol = 152;
				break;
			case 47:
				wptProtocol = 100;
				break;
			case 48:
				wptProtocol = 154;
				break;
			case 49:
				wptProtocol = 102;
				break;
			case 50:
				wptProtocol = 152;
				break;
			case 52:
				wptProtocol = 150;
				break;
			case 53:
				wptProtocol = 152;
				break;
			case 55:
				wptProtocol = 100;
				break;
			case 56:
				wptProtocol = 100;
				break;
			case 59:
				wptProtocol = 100;
				break;
			case 61:
				wptProtocol = 100;
				break;
			case 62:
				wptProtocol = 100;
				break;
			case 64:
				wptProtocol = 150;
				break;
			case 71:
				wptProtocol = 155;
				break;
			case 72:
				wptProtocol = 104;
				break;
			case 73:
				wptProtocol = 103;
				break;
			case 74:
				wptProtocol = 100;
				break;
			case 76:
				wptProtocol = 102;
				break;
			case 77:
				if (GPSVersion < 3.01) {
					wptProtocol = 100;
				} else if ((GPSVersion >= 3.01) && (GPSVersion < 3.5)) {
					wptProtocol = 103;
				} else if ((GPSVersion >= 3.5) && (GPSVersion < 3.61)) {
					wptProtocol = 103;
				} else if (GPSVersion >= 3.61) {
					wptProtocol = 103;
				}
				break;
			case 87:
				wptProtocol = 103;
				break;
			case 88:
				wptProtocol = 102;
				break;
			case 95:
				wptProtocol = 103;
				break;
			case 96:
				wptProtocol = 103;
				break;
			case 97:
				wptProtocol = 103;
				break;
			case 98:
				wptProtocol = 150;
				break;
			case 100:
				wptProtocol = 103;
				break;
			case 105:
				wptProtocol = 103;
				break;
			case 106:
				wptProtocol = 103;
				break;
			case 111:
				//garmin eMap with an old version (2.52)
				wptProtocol = 108;
				break;
			case 112:
				wptProtocol = 152;
		}
	}
	
								
	if ((wptProtocol >= 100) && (wptProtocol <= 109) && (wptProtocol != 106)) {
		wptProtocolSupported = YES;
		[self logMessage:@"Waypoint upload and download is supported.\n"];
	} else {
		wptProtocolSupported = NO;
	}
	
	if (trkProtocol >= 300) {
		trkProtocolSupported = YES;
		[self logMessage:@"Tracklog upload and download is supported.\n"];
	} else {
		trkProtocolSupported = NO;
	}
}



//when passed a data block, it returns a string with its hex representation
- (NSString*)getHexString:(NSData*)data {
	int i, numBytes, anInt;
	NSMutableString * s = [[NSMutableString alloc] init];
	
	SInt8 * bytes = [data bytes];
	
	numBytes = [data length];
	
	for (i = 0; i < numBytes; i++) {
		anInt = bytes[i];
		[s appendString: [NSString stringWithFormat:@" %X", anInt]];
	}
			
	return (NSString*)s;
}

// Latitude and longitude are stored in "semicircles" in the GPS.  These
// two methods convert to and from that type.

- (double)semicirclesToDegrees:(SInt32)semi {
	return (double)(semi * (180.0 / (double)pow(2,31)));
}

- (SInt32)degreesToSemicircles:(double)deg {
	return (SInt32) round(deg * ((double)pow(2, 31) / 180.0));
}

- (double)radiansToDegrees:(double)rad {
	return (double)(rad * (180.0 / (double)PI));
}

// Removes characters which are universally not accepted in GPS receivers.
// Pass it a string and a maximum allowable length.
// 
// Characters which are not accepted on a specific GPS receiver should be removed
// within the proper sending method instead.  (?)
- (NSString*)makeStringGPSSafe:(NSString*)s 
					 maxLength:(int)maxLen 
				   allowSpaces:(BOOL)allowSpaces {

	if ([s length] <= 0) return s;

	// most GPS waypoint names only allow uppercase letters and numbers. Dashes are okay (?)
	// most GPS comments allow uppercase letters, numbers, spaces, and hypen.
	
	NSRange range;
	if (maxLen > [s length]) {
		range.length = [s length];
	} else {
		range.length = maxLen;
	}
	range.location = 0;
	
	NSMutableString * result = [[s uppercaseString] substringWithRange:range];
	
	range.length = [result length];
	
	// some waypoint protocols don't allow the GPS to receive spaces inbetween words.
	if (! allowSpaces) {  //replace the spaces with dashes
		[result replaceOccurrencesOfString:@" " withString:@"-" 
								   options:NSLiteralSearch 
									 range:range];  
	}
					
	// now make sure that it has only legal ASCII characters in it
	// (ones that the GPS accepts)
					
	// space is ascii 32		0x20
	// hypen is ascii 45		0x2D
	// period is ascii 46		0x2E
	// numbers are ascii 48 through 57					0x30 through 0x39
	// uppercase letters are ascii 65 through 90		0x41 through 0x5A
					
  						
    // note, character arrays must be padded with spaces, not zeros like REALbasic does.
    // so, replace all null characters with spaces
    // it's important that we do this *before* we do the below checks..
	
	NSMutableData * stringData = [NSMutableData dataWithData:[result dataUsingEncoding:NSASCIIStringEncoding]];
	int length = [result length];
	UInt8 * bytes = [stringData bytes];
	int i;
	
	for (i = 0; i < length; i++) {
		if (bytes[i] == 0x00)   bytes[i] = 0x20;  // space character
		if (bytes[i] < 0x20)	bytes[i] = 0x2D;
		if ((bytes[i] > 0x20) && (bytes[i] < 0x2D))	bytes[i] = 0x2D;
		if (bytes[i] == 0x2F)	bytes[i] = 0x2D;
		if ((bytes[i] > 0x39) && (bytes[i] < 0x41)) bytes[i] = 0x2D;
		if (bytes[i] > 0x5A)	bytes[i] = 0x2D;
	}														
	
	result = [[[NSString alloc] initWithData:stringData encoding:NSASCIIStringEncoding] autorelease];

	return (NSString*)result;
}


// used to convert Garmin icon numbers (waypoint icons) 
// to and from the GPX standard strings
- (void)createIconConversionDict {
	// create the icon conversion dictionary
	if (! iconConversionDict) {
		iconConversionDict = [[NSDictionary dictionaryWithObjectsAndKeys: @"Marina", [NSNumber numberWithInt:0], @"Bell", [NSNumber numberWithInt:1], @"Bank", [NSNumber numberWithInt:6], @"Fishing Area", [NSNumber numberWithInt:7], @"Gas Station", [NSNumber numberWithInt:8], @"Residence", [NSNumber numberWithInt:10], @"Restaurant", [NSNumber numberWithInt:11], @"Bar", [NSNumber numberWithInt:13], @"Danger Area", [NSNumber numberWithInt:14], @"Waypoint", [NSNumber numberWithInt:18], @"Shipwreck", [NSNumber numberWithInt:19], @"Man Overboard", [NSNumber numberWithInt:21], @"Boat Ramp", [NSNumber numberWithInt:150], @"Campground", [NSNumber numberWithInt:151], @"Restroom", [NSNumber numberWithInt:152], @"Shower", [NSNumber numberWithInt:153], @"Drinking Water", [NSNumber numberWithInt:154], @"Telephone", [NSNumber numberWithInt:155], @"Medical Facility", [NSNumber numberWithInt:156], @"Information", [NSNumber numberWithInt:157], @"Parking Area", [NSNumber numberWithInt:158], @"Park", [NSNumber numberWithInt:159], @"Picnic Area", [NSNumber numberWithInt:160], @"Scenic Area", [NSNumber numberWithInt:161], @"Skiing Area", [NSNumber numberWithInt:162], @"Swimming Area", [NSNumber numberWithInt:163], @"Dam", [NSNumber numberWithInt:164], @"Ball Park", [NSNumber numberWithInt:169], @"Car", [NSNumber numberWithInt:170], @"Hunting Area", [NSNumber numberWithInt:171], @"Shopping Center", [NSNumber numberWithInt:172], @"Lodging", [NSNumber numberWithInt:173], @"Mine", [NSNumber numberWithInt:174], @"Trail Head", [NSNumber numberWithInt:175], @"Truck Stop", [NSNumber numberWithInt:176], @"TracBack Point", [NSNumber numberWithInt:8196], @"Golf Course", [NSNumber numberWithInt:8197], @"City (Small)", [NSNumber numberWithInt:8198], @"City (Medium)", [NSNumber numberWithInt:8199], @"City (Large)", [NSNumber numberWithInt:8200], @"Car Repair", [NSNumber numberWithInt:8207], @"Fast Food", [NSNumber numberWithInt:8208], @"Fitness Center", [NSNumber numberWithInt:8209], @"Movie Theater", [NSNumber numberWithInt:8210], @"Post Office", [NSNumber numberWithInt:8214], @"RV Park", [NSNumber numberWithInt:8215], @"Convenience Store", [NSNumber numberWithInt:8220], @"Live Theater", [NSNumber numberWithInt:8221], @"Scales", [NSNumber numberWithInt:8226], @"Toll Booth", [NSNumber numberWithInt:8227], @"Bridge", [NSNumber numberWithInt:8233], @"Building", [NSNumber numberWithInt:8234], @"Cemetery", [NSNumber numberWithInt:8235], @"Church", [NSNumber numberWithInt:8236], @"Civil", [NSNumber numberWithInt:8237], @"Crossing", [NSNumber numberWithInt:8238], @"Ghost Town", [NSNumber numberWithInt:8239], @"Levee", [NSNumber numberWithInt:8240], @"Military", [NSNumber numberWithInt:8241], @"Oil Field", [NSNumber numberWithInt:8242], @"Tunnel", [NSNumber numberWithInt:8243], @"Beach", [NSNumber numberWithInt:8244], @"Forest", [NSNumber numberWithInt:8245], @"Summit", [NSNumber numberWithInt:8246], @"Airport", [NSNumber numberWithInt:16384], @"Heliport", [NSNumber numberWithInt:16388], @"Private Field", [NSNumber numberWithInt:16389], @"Soft Field", [NSNumber numberWithInt:16390], @"Tall Tower", [NSNumber numberWithInt:16391], @"Short Tower", [NSNumber numberWithInt:16392], @"Glider Area", [NSNumber numberWithInt:16393], @"Ultralight Area", [NSNumber numberWithInt:16394], @"Parachute Area", [NSNumber numberWithInt:16395], @"Seaplane Base", [NSNumber numberWithInt:16402], NULL] retain];
	}	
}

// same as iconNameForNum, but the reverse.
- (int)iconNumFromName:(NSString*)s {
	NSArray * keysForObj = [iconConversionDict allKeysForObject:s];
	
	if ([keysForObj count] > 0) {
		return [[keysForObj objectAtIndex:0] intValue];
	}
	
	return 18;  // the default value
	
}

// pass this an icon number in the Garmin format, and it will return the icon
// name in the GPX standard.
- (NSString*)iconNameFromNum:(int)n {
	id obj = [iconConversionDict objectForKey:[NSNumber numberWithInt:n]];
	
	if (obj != nil) {
		return (NSString*)obj;
	}
	
	return @"Waypoint";
}


#pragma mark -
#pragma mark Other methods

- (void)displayNotSupportedMessage {
	NSRunAlertPanel(@"Model Not Supported", @"This feature is not supported on your GPS model at this time.", @"Okay", nil, nil);
}



- (float)GPSVersion { return GPSVersion; }
- (NSString*)GPSName { return GPSName; }

- (XMLElement*)waypointList { return waypointList; }
- (XMLElement*)trackList { return trackList; }
- (XMLElement*)routeList { return nil; }



- (void)dealloc {
	[buffer release];
	[protocolArray release];
	[wptsToUpload release];
	[iconConversionDict release];
	
	[waypointList release]; 
	[trackList release];
	
	[super dealloc];
}






#pragma mark -
#pragma mark Delegate methods

// these methods will send messages to the delegate of this class
// when certain interesting events occur.

- (id)delegate { return delegate; }

// Set the receiver's delegate to be aDelegate.
- (void)setDelegate:(id)aDelegate {
	// note, we don't want to retain this.  See 
	// http://cocoadevcentral.com/articles/000075.php for more info on this
	
	delegate = aDelegate;
}


- (void)GPSLocationUpdated:(Location*)loc {
	// this attempts to call a method by the same name in the delegate
	// class, if it responds to it.
	
	if ([delegate respondsToSelector:@selector(GPSLocationUpdated:)])
        [delegate GPSLocationUpdated:loc];
    else { 
        [NSException raise:NSInternalInconsistencyException
					format:@"Delegate doesn't respond to GPSLocationUpdated:(Location*)loc"];
    }	
}


- (void)GPSDownloadProgress:(int)currentItem
					  outOf:(int)numItems 
				currentName:(int)itemName {

	if ([delegate respondsToSelector:@selector(GPSDownloadProgress:outOf:currentName:)])
        [delegate GPSDownloadProgress:currentItem
								outOf:numItems 
						  currentName:itemName];
    else { 
        [NSException raise:NSInternalInconsistencyException
					format:@"Delegate doesn't respond to GPSDownloadProgress:outOf:currentName:"];
    }	
}


- (void)GPSFinishedWaypointDownload:(XMLElement*)list {
	// this attempts to call a method by the same name in the delegate
	// class, if it responds to it.
	
	if ([delegate respondsToSelector:@selector(GPSFinishedWaypointDownload:)])
        [delegate GPSFinishedWaypointDownload:list];
    else { 
        [NSException raise:NSInternalInconsistencyException
					format:@"Delegate doesn't respond to GPSFinishedWaypointDownload:(XMLElement*)waypointList"];
    }	
}


- (void)GPSFinishedTracklogDownload:(XMLElement*)list {
	// this attempts to call a method by the same name in the delegate
	// class, if it responds to it.
	
	if ([delegate respondsToSelector:@selector(GPSFinishedTracklogDownload:)])
        [delegate GPSFinishedTracklogDownload:list];
    else { 
        [NSException raise:NSInternalInconsistencyException
					format:@"Delegate doesn't respond to GPSFinishedTracklogDownload:(XMLElement*)trackList"];
    }	
}


- (void)GPSFinishedRouteDownload:(XMLElement*)routeList {
	
}

// called when finished connecting to GPS
- (void)GPSConnected {
	if ([delegate respondsToSelector:@selector(GPSConnected)])
        [delegate GPSConnected];
    else { 
        [NSException raise:NSInternalInconsistencyException
					format:@"Delegate doesn't respond to GPSConnected"];
    }		
}

- (void)logMessage:(NSString*)msg {
	if ([delegate respondsToSelector:@selector(logMessage:)])
        [delegate logMessage:msg];
    else { 
        [NSException raise:NSInternalInconsistencyException
					format:@"Delegate doesn't respond to logMessage:(NSString*)msg"];
    }	
}



@end
