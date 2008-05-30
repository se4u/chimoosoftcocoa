//
//  Location.h
//  Terrabrowser
//
//  Created by Ryan on Mon Nov 24 2003.
//  Copyright (c) 2003 Chimoosoft. All rights reserved.
//
//  Represents a location on the Earth's surface.  Methods to set/access it
//  with either Lat/Lon or UTM coordinate systems.
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

@class Ellipsoid;
@class LatLon;

@interface Location : NSObject <NSCoding> {
	LatLon * latitude;			// <lat>
	LatLon * longitude;			// <lon>
	
	double northing, easting;
	char  zoneLetter;
	int zoneNumber;
	
	Ellipsoid * ellipsoid;  //the ellipsoid used to convert between coordinates

	BOOL valid;
}


- (NSString *)description;


///////////////
// initializers
///////////////

// uses default ellipsoid
+ (id)locationWithDoubleLatitude:(double)newLat doubleLongitude:(double)newLon;


// uses default ellipsoid
- (id)initWithLatitude:(LatLon*)newLat longitude:(LatLon*)newLon;

- (id)initWithLatitude:(LatLon*)newlat 
			 longitude:(LatLon*)newlon ellipsoid:(Ellipsoid*)newEllip;

- (id)initWithNorthing:(double)northing easting:(double)easting
			zoneLetter:(char)zLetter zoneNumber:(int)zNumber
			 ellipsoid:(Ellipsoid*)newEllip;

//copying
- (id)copyWithZone:(NSZone *)zone;

- (void)fixZoneNumber;

- (float)metricDistanceBetween:(Location*)otherLoc;
	
//accessors
- (void)setLatitude:(LatLon*)newLat;
- (LatLon*)latitude;
- (void)setLongitude:(LatLon*)newLon;
- (LatLon*)longitude;

- (double)doubleLatitude;
- (double)doubleLongitude;

- (double)northing;
- (double)easting;
- (Ellipsoid*)ellipsoid;
- (char)zoneLetter;
- (int)zoneNumber;

- (BOOL)isValid;

- (void)offsetLongitudeBy:(double)offset;

- (void)encodeWithCoder:(NSCoder *)encoder;
- (id)initWithCoder:(NSCoder *)decoder;


@end
