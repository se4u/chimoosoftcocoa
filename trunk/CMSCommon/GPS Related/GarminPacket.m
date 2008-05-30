//
//  GarminPacket.m
//  GPSTest
//
//  Created by Ryan on Mon May 31 2004.
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

#import "GarminPacket.h"
#import "GarminConstants.h"

@implementation GarminPacket

- (id)init {
	if (self = [super init]) {	

	}	
	return self;
}

+ (id)garminPacketWithRawPacketData:(NSData*)d {
	if ([d length] < 6) return nil;
	
	GarminPacket * p = [[GarminPacket alloc] init];
	[p setRawPacketData:d];
	return [p autorelease];
}

+ (id)garminPacketWithPacketId:(GarminPid)pid packetData:(NSData*)d {
	GarminPacket * p = [[GarminPacket alloc] init];
	[p setPacketID:pid packetData:d];
	return [p autorelease];
}


- (BOOL)checksumIsValid {
	if ((data == nil) || ([data length] < 6)) {
		return NO;
	}
	
	UInt8 checksum = [self calculateChecksum:data];
	UInt8 * bytes = [data bytes];
	int size = [data length];
	
	if (checksum == bytes[size - 3]) {
		return YES;
	}
	
	// if we make it here, then the packet is invalid
	checksum = [self calculateChecksum:data];
	// testing - calc it again for debugging
	
	return NO;
}

- (const void*)packetDataBytes {
	return [[self packetData] bytes];
}

- (NSData*)packetData {
	NSRange range;
	range.length = [self packetDataLength];
	range.location = 3;
	
	return [data subdataWithRange:range];
}

- (void)setRawPacketData:(NSData*)d {
	// remove any double 0x10's which may be in the raw packet
	data = [[self unescapePacket:d] retain];
}


- (NSData*)packetForSending {
	// add 0x10's if needed
	return [self escapePacket:data];
}


- (int)packetDataLength {
	return [data length] - 6;
}

// it's okay to send nil data.
- (void)setPacketID:(GarminPid)pid packetData:(NSData*)d {

	int pdsize = 0;
	if (d != nil) {
		pdsize = [d length];
	}
	
	int packetLength = pdsize + 6;
	
	UInt8 bytes[packetLength];		// size of new packet
	
	UInt8 * test = bytes;
	
	// Header //
	////////////
	bytes[0] = 0x10;				// start of message indicator 
	bytes[1] = (UInt8)pid;			// packet id

	// Packet Data Size //
	//////////////////////
	bytes[2] = (UInt8)pdsize;		// data size
		
	// Packet Data //
	/////////////////
	
	if (d != nil) {
		int i, dataSize;
		UInt8 * dbytes = (UInt8*)[d bytes];
	
		// loop through each byte in the passed data
		for (i = 0; i < pdsize; i++) {
			bytes[i+3] = dbytes[i];
		}
	}

	// Checksum //
	//////////////
		
	bytes[3 + pdsize] = 0x00;		// blank checksum
	
	// Footer //
	////////////
	
	bytes[4 + pdsize] = 0x10;
	bytes[5 + pdsize] = 0x03;


	// now we have to actually calculate the checksum

	NSData * dataForChecksum = [NSData dataWithBytes:(void*)bytes length:packetLength];
	UInt8 checksum = [self calculateChecksum:dataForChecksum];
	
	bytes[3 + pdsize] = checksum;
	
	[data release];
	data = [[self escapePacket: [NSData dataWithBytes:(void*)bytes length:packetLength]] retain];
}



- (GarminPid)packetID {
	if ([data length] > 2) {
		UInt8 * bytes = [data bytes];
		return bytes[1];
	}
	
	return 0;
}



- (NSString*)hexString {
	int i, numBytes, anInt;
	NSMutableString * s = [[NSMutableString alloc] init];
	
	SInt8 * bytes = [data bytes];
	
	numBytes = [data length];
	
	for (i = 0; i < numBytes; i++) {
		[s appendString: [NSString stringWithFormat:@" %X ", bytes[i]]];
	}
	
	return (NSString*)s;
}


#pragma mark -
#pragma mark Private methods

// adds appropriate double 0x10's where necessary and returns the new packet
- (NSData*)escapePacket:(NSData*)d {
	UInt8 * bytes = [d bytes];
	int size = [d length];
	int i;
	
	// scan for 0x10's in the size, packet data, and checksum fields
	// and count them
	int count = 0;
	for (i = 2; i < (size - 2); i++) {
		if (bytes[i] == 0x10) {
			count++;
		}
	}
	
	if (count == 0) {
		// no 0x10's to be escaped
		return d;
	}
	
	// if we make it to here, then we need to escape some bytes.
	
	// new bytes with enough room to include the duplicates
	int newSize = size + count;
	UInt8 newBytes[newSize];
	
	newBytes[0] = bytes[0];
	newBytes[1] = bytes[1];
	
	int newIndex = 2;
	for (i = 2; i < (size - 2); i++) {
		newBytes[newIndex] = bytes[i];
		
		if (bytes[i] == 0x10) {
			newIndex++;
			newBytes[newIndex] = 0x10;  // add the duplicate
		}
		
		newIndex++;
	}
	
	// end of packet
	newBytes[newSize - 2] = bytes[size - 2];
	newBytes[newSize - 1] = bytes[size - 1];
		
	UInt8 * test = newBytes;
	
	NSData * newData = [NSData dataWithBytes:(void*)newBytes length:newSize];
	return newData;
}

// removes appropriate double 0x10's where necessary and returns the new packet
- (NSData*)unescapePacket:(NSData*)d {
	UInt8 * bytes = [d bytes];
	int oldSize = [d length];
	int oldIndex, newIndex;
	
	
	// new bytes buffer is declared to the same size as the original to start
	// with because we don't know how many (if any) bytes we'll be discarding.
	UInt8 newBytes[oldSize];
	
	newBytes[0] = bytes[0];
	newBytes[1] = bytes[1];
	
	oldIndex = 2;
	int newCount = 2;
	for (newIndex = 2; newIndex < (oldSize - 2); newIndex++) {
		newBytes[newIndex] = bytes[oldIndex];
		newCount++;
		
		if (bytes[oldIndex] == 0x10) {
			// make sure the next one is 0x10 as well (it should always be true)
			if ((oldIndex + 1) < oldSize) {
				if (bytes[oldIndex + 1] == 0x10) {
					oldIndex++;  // skip over it.
					newCount--;  // the new count should be one less since we're skipping.
				}
			}
		}
		
		oldIndex++;
	}

	
	// end of packet
	newBytes[newCount] = bytes[oldSize - 2];
	newBytes[newCount + 1] = bytes[oldSize - 1];
	
	NSData * newData = [NSData dataWithBytes:(void*)newBytes 
									  length:(newCount + 2)];
	return newData;
	
}



// Pass this a data block in the Garmin protocol and it will calculate
// the checksum
- (UInt8)calculateChecksum:(NSData*)data {
	
	// Note, this *expects* to receive the *entire* data block
	// the checksum is the 2's complement of the modulo-256 sum of 
	// all message bytes after the start of message character (&h10) and
	// up to but not including the checksum itself.
	//
	// This was done so the same method could be used to check data we're 
	// getting ready to send as well as data we're receiving.
	
	int i, sum;
	int size = [data length];
	
	if (size < 5) {
		return (UInt8)0;  // error - the message can't be this small!
	}
	
	UInt8 * bytes = [data bytes];
	
	// sum the bytes
	sum = 0;
	for (i = 1; i <= size - 4; i++) {
		sum = sum + (int)bytes[i];
	}
				
	// now we have the sum, so we need to mod it by 256.
	sum = sum % 256;
	
	// take the 2's complement of it.
	UInt8 m2 = (UInt8)sum;
	
	m2 = [self twosComplementOfByte:m2];
	
	return (int)m2;
}


//this only works with ONE BYTE input..
- (UInt8)twosComplementOfByte:(UInt8)byte {
	
	UInt8 i;
	i = byte;
	i = ~i;		// one's complement
	
	return i + 1;
}


- (void)dealloc {
	[data release];
	
	[super dealloc];
}



@end
