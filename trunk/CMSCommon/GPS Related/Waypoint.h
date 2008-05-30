//
//  Waypoint.h
//  Terrabrowser
//
//  Created by Ryan on Fri Dec 05 2003.
//
//  This represents a waypoint with all of the GPX waypoint fields such as 
//  name, comment, location, description, symbol, etc.  Inherits from XMLElement.
//
//  Can also be used to represent GPX items such as route points and track points.
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
#import "XMLElement.h"
#import <AppKit/AppKit.h>

@class Location;
@class LatLon;

@interface Waypoint : XMLElement <NSCoding> {
	Location * location;
	int iconNumber;		// icon number used by garmin (not part of GPX file)
}

+ (id)waypointWithLocation:(Location*)loc;
+ (id)waypointWithDoubleLatitude:(double)lat doubleLongitude:(double)lon;
//+ (id)waypointWithWaypoint:(Waypoint*)wpt;

+ (NSArray*)iconNames;
+ (int)iconNumberForSymbolName:(NSString*)symbolName;
+ (NSImage*)iconForSymbolName:(NSString*)symbolName;

- (id)init;		//designated initializer
- (id)initWithLocation:(Location*)loc;

- (Location*)location;
- (void)setLocation:(Location*)loc;

- (LatLon*)latitude;
- (void)setLatitude:(LatLon*)l;
- (LatLon*)longitude;
- (void)setLongitude:(LatLon*)l;

- (double)easting;
- (double)northing;

- (void)setDoubleLatitude:(double)newLat;
- (double)doubleLatitude;

- (void)setDoubleLongitude:(double)newLon;
- (double)doubleLongitude;

- (NSImage*)image;
- (NSPopUpButtonCell*)imageMenuItem;

- (NSString*)attributeString;


// OPTIONAL Position Information
//=================================

// <ele>	Elevation of the waypoint
- (void)setElevation:(NSNumber*)n;
- (NSNumber*)elevation;

// OPTIONAL Description Information
//=================================

/*
// <name>		GPS waypoint name
- (void)setName:(NSString *)s;
- (NSString *)name;

// <cmt>		GPS comment
- (void)setComment:(NSString *)s;
- (NSString *)comment;
*/

// <sym>		Waypoint symbol
- (void)setSymbolName:(NSString *)s;
- (NSString *)symbolName;

/*
// <desc>		Descriptive description of the waypoint
- (void)setWaypointDescription:(NSString *)s;
- (NSString *)waypointDescription;
*/

// <type>		Type (category) of waypoint
- (void)setType:(NSString *)s;
- (NSString *)type;

/*
// <url>		URL associated with the waypoint
- (void)setURL:(NSString *)s;
- (NSString *)url;

// <urlname>	Text to display on the <url> hyperlink
- (void)setURLName:(NSString *)s;
- (NSString *)urlName;

*/

// <time>		Creation date/time of the waypoint
- (void)setTime:(NSString *)s;
- (NSString *)time;


// OPTIONAL Accuracy Information
//=================================

// <fix>		Type of GPS Fix (2d, 3d, etc.)
- (void)setGpsFix:(NSString *)s;
- (NSString *)gpsFix;

// <sat>		Number of satellites
- (void)setNumberOfSatellites:(int)v;
- (int)numberOfSatellites;

- (int)numberOfSubElements;


@end
