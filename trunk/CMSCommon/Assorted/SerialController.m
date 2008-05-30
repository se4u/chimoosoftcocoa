//
//  SerialController.m
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

#import "SerialController.h"
#import "AMSerialPort.h"
#import "AMSerialPortList.h"
#import "AMSerialPortAdditions.h"


@implementation SerialController

- (AMSerialPort *)port {
    return port;
}

- (void)setPort:(AMSerialPort *)newPort {
    id old = nil;
	
    if (newPort != port) {
        old = port;
        port = [newPort retain];
        [old release];
		old = nil;
    }
}

- (void)initPort {
	// Subclass
}

- (void)setPortName:(NSString*)newPortName {
	if (portName != newPortName) {
		[portName release];
		portName = [newPortName retain];
	}
}


// meant to be overridden by subclasses
- (void)serialPortReadData:(NSDictionary *)dataDictionary {
	// this method is called if data arrives 
	// @"data" is the actual data, @"serialPort" is the sending port

	
	AMSerialPort *sendPort = [dataDictionary objectForKey:@"serialPort"];
	NSData *data = [dataDictionary objectForKey:@"data"];
	
	NSString * str;
	
//	if (! buffer) { buffer = [[NSMutableString alloc] init]; }
	
	if ([data length] > 0) {
		str = [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];

		// continue listening
		[sendPort readDataInBackground];

	} else { // port closed
		
	}

}


- (void)sendString:(NSString*)str {
	if (!port) {
		// open a new port if we don't already have one
		[self initPort];
	}
	
	if ([port isOpen]) { // in case an error occured while opening the port
		[port writeString:str];
	}
}




- (void)dealloc {

	[port release];
	[portName release];
	
	[super dealloc];
}

@end
