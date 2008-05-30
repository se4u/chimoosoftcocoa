//
//  GarminPacket.h
//  GPSTest
//
//  Created by Ryan on Mon May 31 2004.
//  Copyright (c) 2004 Chimoosoft. All rights reserved.
//
//  Represents a packet of data in the Garmin protocol.
//  Allows you to create a packet from scratch by supplying the
//  data portion and the packetID, or can parse an existing packet
//  to verify the checksum or get the packetID and packetData.

//
//  Here is the Garmin packet layout - see page 8 of the Garmin manual for details.
//	byte		description
//  ------------------------------------
//	0			0x10
//	1			packetID
//	2			size of packet data (excluding double 0x10's)
//	3 to n-4	packet data
//	n-3			checksum (excludes double 0x10's)
//	n-2			0x10
//  n-1			0x03

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
//
// The internal data stored in this class will *NOT* have the extra 0x10's in it.  There
// are two methods provided, one for setting the entire packet *with* the extra 0x10's 
// (in which case they will be stripped off before being stored), and one for setting the
// packet id and packet data separately (assumed to not have extra 10's).  There are also two
// ways to access the data, one with the extra 10's, and one without.
//
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
#import "GarminConstants.h"

@interface GarminPacket : NSObject {
	NSData * data;		// data without duplicate 0x10's.
}


// Returns an autoreleased packet set with data from the GPS, so this would
// include the headers, checksum, and footers (as well as extra 0x10's)
+ (id)garminPacketWithRawPacketData:(NSData*)d;

// Returns an autoreleased packet with the passed packetID and data, calculates
// and inserts the checksum, size, and header/footer info automatically.
//
// Note, you shouldn't insert double 10's in the packetData.
// It's okay to send nil data.
+ (id)garminPacketWithPacketId:(GarminPid)pid packetData:(NSData*)d;

- (id)init;

// Is the checksum on this packet valid?
- (BOOL)checksumIsValid;
	
// returns the data portion of the packet sans any double 0x10's
- (NSData*)packetData;

// same as above, but gives direct read only access to bytes.
- (const void*)packetDataBytes;

// sets the packet from the GPS (including double 0x10's)
- (void)setRawPacketData:(NSData*)d;

// returns the entire raw packet including the headers and 0x10's
- (NSData*)packetForSending;

// returns the packet data length, excluding double 10's (see page 8 in Garmin manual).
- (int)packetDataLength;

// note, it's okay to send nil data
- (void)setPacketID:(GarminPid)pid packetData:(NSData*)d;

- (GarminPid)packetID;

// returns a string with the raw packet's hex representation
- (NSString*)hexString;


// private methods
- (UInt8)calculateChecksum:(NSData*)data;
- (UInt8)twosComplementOfByte:(UInt8)byte;


@end
