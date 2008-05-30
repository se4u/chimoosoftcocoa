
//
//  NMEAPacket.h
//  GPSTest
//
//  Created by Ryan on Fri May 28 2004.
//  Copyright (c) 2004 Chimoosoft. All rights reserved.
//
//  Decodes (parses) a packet in the NMEA format and provides
//  accessors for various fields as well as delegate methods which
//  other classes can use to be notifed of changes in location, etc.
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
@class Location;

@interface NMEAPacket : NSObject {
	NSMutableDictionary * dict;
	
	id delegate;
	
	BOOL upToDate;
	Location * location;
	
	double lastLat, lastLon;
}

- (id)init;

- (id)delegate;
- (void)setDelegate:(id)aDelegate;

- (void)processString:(NSString*)str;


// Accessors for data contained in the NMEA packet
- (float)speed;
- (Location*)location;

- (int)gpsFix;
- (int)numSatellites;
- (float)elevation;
- (float)magneticBearing;
- (float)trueBearing;
- (float)horizontalError;
- (float)verticalError;
- (float)courseMadeGood;
- (NSDate*)fixTime;

- (void)dealloc;

@end




// This informal protocol is declared for the delegate
// methods.  Delegates should implement at least some of this
// protocol.

@interface NSObject (CMSNMEAPacketDelegate)
	
// delegate method which is called when the location (lat/lon) changes to a different value
- (void)GPSLocationUpdated:(Location*)loc;
- (void)NMEAStartOfNewPacket:(NMEAPacket*)packet;

- (void)logMessage:(NSString*)msg;

@end

