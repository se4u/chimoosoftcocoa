//
//  MagellanController.m
//  GPSTest
//
//  Created by Ryan on Sat May 29 2004.
//  Copyright (c) 2004 Chimoosoft. All rights reserved.
//


#import "MagellanController.h"
#import "SerialController.h"
#import "AMSerialPortList.h"
#import "AMSerialPortAdditions.h"

#import "DataAdditions.h"
#import "MutableDataAdditions.h"

#import "Waypoint.h"
#import "Location.h"
#import "LatLon.h"

#import "Constants.h"

@implementation MagellanController


- (void)awakeFromNib {		
		
}


#pragma mark -
#pragma mark Action methods

- (IBAction)connect:(id)sender {
	[buffer release];
	buffer = nil;
	[super connect:sender];
}

- (IBAction)disconnect:(id)sender {
	if (port) {
		[port free];
		[port release];
		port = nil;
	}
}

- (IBAction)download:(id)sender {
		
}

- (IBAction)abortTransfer:(id)sender {
}


#pragma mark -
#pragma mark Serial methods



- (void)initPort {
	NSString *deviceName = [portMenu titleOfSelectedItem];
	
	if (![deviceName isEqualToString:[port bsdPath]]) {
		[port close];
		
		[self setPort:[[[AMSerialPort alloc] init:deviceName withName:deviceName] autorelease]];
		
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
		
		
		// now we have to delete this from the buffer.
		// so copy all of the data we haven't read yet
		range.location = range.location + range.length;
		range.length = [buffer length] - range.location;
		
		// this is the remaining data in the buffer that we haven't read yet
		[buffer setData:[buffer subdataWithRange:range]];

	}
}

@end