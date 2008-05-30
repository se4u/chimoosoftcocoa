//
//  NMEASerial.m
//
//  Created by Ryan on Sat May 29 2004.
//  Copyright (c) 2004 Chimoosoft. All rights reserved.
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


#import "NMEASerial.h"
#import "NMEAPacket.h"
#import "AMSerialPortList.h"
#import "AMSerialPortAdditions.h"

#import "Location.h"
#import "LatLon.h"

@implementation NMEASerial

- (id)init {	
	if (self = [super init]) {
		NMEA = [[NMEAPacket alloc] init];
	}

	return self;
}

- (id)delegate { return delegate; }

// Set the receiver's delegate to be aDelegate.
- (void)setDelegate:(id)aDelegate {
	// note, we don't want to retain this.  See 
	// http://cocoadevcentral.com/articles/000075.php for more info on this
	
	delegate = aDelegate;
	[NMEA setDelegate:delegate];
}



- (void)connect {
	[buffer release];
	buffer = nil;
	[self initPort];
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
		
		// register self as delegate for port
		[port setDelegate:self];
		
/*
		[outputTextView insertText:@"attempting to open port\r"];
		[outputTextView setNeedsDisplay:YES];
		[outputTextView displayIfNeeded];
 */
				
		// open port - may take a few seconds ...
		if ([port open]) {
			
	/*
			[outputTextView insertText:@"port opened\r"];
			[outputTextView setNeedsDisplay:YES];
			[outputTextView displayIfNeeded];
	 */
			
			[port setSpeed:4800];
			[port setDataBits:8];
			[port setParityNone];
			[port setStopBits2:NO];
			BOOL b = [port commitChanges];
			
			// listen for data in a separate thread
			[port readDataInBackground];
			
		} else { // an error occured while creating port
			/*
			[outputTextView insertText:@"couldn't open port for device "];
			[outputTextView insertText:deviceName];
			[outputTextView insertText:@"\r"];
			[outputTextView setNeedsDisplay:YES];
			[outputTextView displayIfNeeded];
			 */
			[self setPort:nil];
		}
	}
}




// meant to be overridden by subclasses
- (void)serialPortReadData:(NSDictionary *)dataDictionary {
	// this method is called if data arrives 
	// @"data" is the actual data, @"serialPort" is the sending port
	
	AMSerialPort *sendPort = [dataDictionary objectForKey:@"serialPort"];
	NSData *data = [dataDictionary objectForKey:@"data"];
	
	NSString * str;
	
	if (! buffer) { buffer = [[NSMutableString alloc] init]; }
	
	if ([data length] > 0) {
		// convert the serial data into a string
		str = [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
		
		NSRange searchRange;
		
		searchRange.location = 0;
		searchRange.length = [str length];
		
		int dollarPos = 0;
		int lastDollarPos = 0;
		NSRange subRange;		
		BOOL foundDollar = YES;
		
		while (foundDollar) {
			// look for a $ and record the position if one is found.
			NSRange range = [str rangeOfString:@"$" options:NSLiteralSearch range:searchRange];
			
			if (range.location != NSNotFound) {
				// we found a $
				foundDollar = YES;
				
				dollarPos = range.location;
				
				// set up the search range for the next search
				searchRange.location = dollarPos + 1;
				searchRange.length = [str length] - searchRange.location;
				
				// figure out the range of the substring to the left of this $ sign
				subRange.location = lastDollarPos;
				subRange.length = dollarPos - lastDollarPos;
				
				// append the substring up to the $ to the buffer
				[buffer appendString:[str substringWithRange:subRange]];
				
				// process the buffer
				[self processString:[buffer stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
				
				[buffer setString:@""];
				
				lastDollarPos = dollarPos;
			} else {
				// we didn't find a $ in str
				foundDollar = NO;
				
				subRange.location = lastDollarPos;
				subRange.length = [str length] - lastDollarPos;
				
				[buffer appendString: [str substringWithRange:subRange]];
			}
		}		
		
		
	//	[outputTextView insertText:[NSString stringWithFormat:@"str: %@", str]];
		

		// continue listening
		[sendPort readDataInBackground];
	} else { // port closed
		//[outputTextView insertText:@"port closed\r"];
	}
	/*
	[outputTextView setNeedsDisplay:YES];
	[outputTextView displayIfNeeded];
	 */
}


// my method to process some data from the serial port.
- (void)processString:(NSString*)str {
	[NMEA processString:str];
}


- (void)dealloc {
	[NMEA release];
	[buffer release];
	[super dealloc];
}


@end
