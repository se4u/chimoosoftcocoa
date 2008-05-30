//
//  NMEAPacket.m
//  GPSTest
//
//  Created by Ryan on Fri May 28 2004.
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


#import "NMEAPacket.h"
#import "LatLon.h"
#import "Location.h"

@implementation NMEAPacket

- (id)init {
	if (self = [super init]) {
		dict = [[NSMutableDictionary alloc] init];
		
		upToDate = NO;
	}
	
    return self;	
}


#pragma mark -
#pragma mark Delegate methods

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

- (void)NMEAStartOfNewPacket:(NMEAPacket*)packet {
	// this attempts to call a method by the same name in the delegate
	// class, if it responds to it.
	
	if ([delegate respondsToSelector:@selector(NMEAStartOfNewPacket:)])
        [delegate NMEAStartOfNewPacket:packet];
    else { 
        [NSException raise:NSInternalInconsistencyException
					format:@"Delegate doesn't respond to NMEAStartOfNewPacket:(NMEAPacket*)packet"];
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

#pragma mark -
#pragma mark Accessor methods


- (float)speed {
	NSArray * comp = [dict objectForKey:@"$GPRMC"];
	if (comp == nil) { return nil; }
	
	return [[comp objectAtIndex:7] floatValue];
}


// returns the location for this NMEA packet
// which is stored under the $GPRMC key
- (Location*)location {
	// the data line will look like this:  ,001310,V,3407.9493,N,11828.3633,W,
	//												 ddmm.mmmm   dddmm.mmmm 
	//												 latitude    longitude
		
	
	if (upToDate) {  // so we don't calculate stuff too often
		return location;
	}
	
	
	NSArray * comp = [dict objectForKey:@"$GPRMC"];
	if (comp == nil) { return nil; }

	NSString * t;
	NSRange range;
		
	// split the lat into two elements around the decimal point.
	NSArray * split = [[comp objectAtIndex:3] componentsSeparatedByString:@"."];
	
	// so index 0 should be 3407 and index 1 should be 9493 (for the example above)
	t = [split objectAtIndex:0];

	float min = [[t substringFromIndex:[t length] - 2] floatValue];
	min = min + [[NSString stringWithFormat:@"0.%@", [split objectAtIndex:1]] floatValue];
	int deg = [[t substringToIndex:[t length] - 2] intValue];

	NSString * direction = [comp objectAtIndex:4];	// N or S
	if ([direction isEqualToString:@"S"]) {
		deg *= -1;  // multiply by negative one if southern hemisphere
	}
	
	LatLon * lat = [LatLon latLonWithDegrees:deg minutes:min];
	
	// now we'll do the longitude in the same way
	// Note, this is repetitive code, but it seems silly to make a separate
	// method for something which will only be done twice..
	
	// split the lon into two elements around the decimal point.
	split = [[comp objectAtIndex:5] componentsSeparatedByString:@"."];
	
	t = [split objectAtIndex:0];
	
	min = [[t substringFromIndex:[t length] - 2] floatValue];
	min = min + [[NSString stringWithFormat:@"0.%@", [split objectAtIndex:1]] floatValue];
	deg = [[t substringToIndex:[t length] - 2] intValue];
	
	direction = [comp objectAtIndex:6];	// E or W
	if ([direction isEqualToString:@"W"]) {
		deg *= -1;  // multiply by negative one if western hemisphere
	}
	
	LatLon * lon = [LatLon latLonWithDegrees:deg minutes:min];
	
	// now form a location
	
	Location * loc = [[[Location alloc] initWithLatitude:lat longitude:lon] autorelease];

	[location release];
	location = [loc retain];		// save for later 
	upToDate = YES;

	if ((lastLat != [lat doubleDegrees]) || (lastLon != [lon doubleDegrees])) {
		// if the location has changed since last time we recorded it, then 
		// notify the delegate.
		[self GPSLocationUpdated:loc];
	}
		
	
	lastLat = [lat doubleDegrees];
	lastLon = [lon doubleDegrees];
	
	return loc;
}


// returns 2 for 2d fix and 3 for 3d fix.
- (int)gpsFix {
	
	NSArray * comp = [dict objectForKey:@"$GPGSA"];
	if (comp == nil) { return nil; }
	
	return [[comp objectAtIndex:2] intValue];
}

// returns the number of satellites
- (int)numSatellites {

	NSArray * comp = [dict objectForKey:@"$GPGGA"];
	if (comp == nil) { return nil; }
	
	return [[comp objectAtIndex:7] intValue];
}


- (float)elevation {

	NSArray * comp = [dict objectForKey:@"$GPGGA"];
	if (comp == nil) { return nil; }
	
	NSString * units = [comp objectAtIndex:10];  // should be meters (m) ?
	
	if (!([units isEqualToString:@"M"] || [units isEqualToString:@"m"])) {
		return 0.0;  // who knows what it means if it's not in meters
	}
	
	return [[comp objectAtIndex:9] floatValue];
}


- (float)magneticBearing {
	//bearing 045 True from "START" to "DEST"

	NSArray * comp = [dict objectForKey:@"$GPBOD"];
	if (comp == nil) { return nil; }
	
	return [[comp objectAtIndex:3] floatValue];
}


- (float)trueBearing {
	//bearing 045 True from "START" to "DEST"
	
	NSArray * comp = [dict objectForKey:@"$GPBOD"];
	if (comp == nil) { return nil; }
	
	return [[comp objectAtIndex:1] floatValue];
}

- (float)horizontalError {
	//Estimated horizontal position error in metres (HPE)

	//*************************
	//NOTE, I should be looking at the next field to see what the 
	//units are.. If they're not set to meters, then this won't work right
	
	NSArray * comp = [dict objectForKey:@"$PGRME"];
	if (comp == nil) { return nil; }
	
	return [[comp objectAtIndex:1] floatValue];
}

- (float)verticalError {
	//Estimated vertical error (VPE) in metres
	
	//*************************
	//NOTE, I should be looking at the next field to see what the 
	//units are.. If they're not set to meters, then this won't work right
	
	NSArray * comp = [dict objectForKey:@"$PGRME"];
	if (comp == nil) { return nil; }
	
	return [[comp objectAtIndex:2] floatValue];
}

- (float)courseMadeGood {   
	//Course Made Good, True (ie, which direction you're going) in degrees
		
	NSArray * comp = [dict objectForKey:@"$GPRMC"];
	if (comp == nil) { return nil; }
	
	return [[comp objectAtIndex:8] floatValue];
}


- (NSDate*)fixTime {   
	//Time of fix 22:54:46 UTC
	
	NSArray * comp = [dict objectForKey:@"$GPRMC"];
	if (comp == nil) { return nil; }
	
	NSString * theTime = [comp objectAtIndex:1];

	NSRange range;
	range.length = 2;
	range.location = 0;
	
	int hours = [[theTime substringWithRange:range] intValue];
	
	range.location = 2;
	int minutes = [[theTime substringWithRange:range] intValue];
	
	range.location = 4;
	int seconds = [[theTime substringWithRange:range] intValue];

	// now, convert this into an NSDate
	
	// not done yet
	return nil;
}



#pragma mark -
#pragma mark Other methods


// this should be called with one line from the NMEA output
- (void)processString:(NSString*)str {
	
	upToDate = NO;
	
	// first figure out what kind of string it is
	NSRange range = [str rangeOfString:@"$"];
	if (range.location == NSNotFound) {
		return;
	}
	
	range.length = 6;   // all codes are of the form $xxxxx where x is a character.
	NSString * type = [str substringWithRange:range];
	
	range.location += 6;
	range.length = [str length] - range.length;
	
	// break the data string apart by commas and then add
	// the NSArray to the dictionary, keyed by its code (ie, $GPRMC)
	NSString *s = [str substringWithRange: range];
	NSArray * comp = [str componentsSeparatedByString:@","];

	[dict setObject:comp forKey:type];
	
	if ([type isEqualToString:@"$GPRMC"]) {
		// then we're at the start of a new packet 
		// since this is usually the first sent.
		[self NMEAStartOfNewPacket:self];
	}
	
	// for now, we'll force the location to be parsed everytime
	Location * loc = [self location];
	
	//NSLog(@"%f, %f", [[loc latitude] doubleDegrees], [[loc longitude] doubleDegrees]);
}


- (void)dealloc {
	[dict release];
	[super dealloc];
}

@end
