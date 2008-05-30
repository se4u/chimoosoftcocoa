//
//  Waypoint.m
//  Terrabrowser
//
//  Created by Ryan on Fri Dec 05 2003.
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

#import "Waypoint.h"
#import "Location.h"
#import "LatLon.h"

// psedo-constants to use as the names for elements in the dictionary.
//
// Not all elements need to be explicitly defined here - only the ones we actually
// want to use in the GUI (so we can talk to them with the Cocoa bindings).  
// The rest of them can just be set in the dictionary based on their names
// and written back to the file the same way.

// Optional Position Information
NSString *WPTElevation = @"ele";
NSString *WPTTime = @"time";

// Optional Description Information
NSString *WPTName = @"name";
NSString *WPTComment = @"cmt";
NSString *WPTSymbol = @"sym";
NSString *WPTDescription = @"desc";
NSString *WPTType = @"type";
NSString *WPTUrl = @"url";
NSString *WPTUrlName = @"urlname";

// Optional Accuracy Information
NSString *WPTGpsFix = @"fix";
NSString *WPTNumberOfSatellites = @"sat";

NSDictionary* waypointIconDict;

@implementation Waypoint


#pragma mark -
#pragma mark Initializers


+ (id)waypointWithLocation:(Location*)loc {
	Waypoint * wpt = [[[Waypoint alloc] initWithLocation:loc] autorelease];
	return wpt;
}

+ (id)waypointWithDoubleLatitude:(double)lat doubleLongitude:(double)lon {
	Waypoint * wpt = [[Waypoint alloc] init];
	[wpt setDoubleLatitude:lat];
	[wpt setDoubleLongitude:lon];
	return [wpt autorelease];
}

+ (id)waypointWithLatitude:(LatLon*)lat longitude:(LatLon*)lon {
	Waypoint * wpt = [[Waypoint alloc] init];

	Location * loc = [[Location alloc] init];
	
	[loc setLatitude:lat];
	[loc setLongitude:lon];
	
	[wpt setLocation:loc];
	
	[loc release];
	loc = nil;

	return [wpt autorelease];
}


// returns an array of waypoint icon names
+ (NSArray*)iconNames {
	if (nil == waypointIconDict) return nil;
	return [waypointIconDict allKeys];
}

// This is used so we can export/import to GPX format which
// doesn't want the garmin waypoint number, but
// instead wants the *name* of the waypoint icon..
+ (int)iconNumberForSymbolName:(NSString*)symbolName {
	int num;
	
	if (nil == waypointIconDict) {	
		waypointIconDict = [[NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithInt:0], @"Marina",
			[NSNumber numberWithInt:1], @"Bell",
			[NSNumber numberWithInt:6], @"Bank",
			[NSNumber numberWithInt:7], @"Fishing Area",
			[NSNumber numberWithInt:8], @"Gas Station",
			[NSNumber numberWithInt:10], @"Residence",
			[NSNumber numberWithInt:11], @"Restaurant",
			[NSNumber numberWithInt:14], @"Danger Area",
			[NSNumber numberWithInt:18], @"Waypoint",			
			[NSNumber numberWithInt:19], @"Shipwreck",
			[NSNumber numberWithInt:21], @"Man Overboard",
			[NSNumber numberWithInt:150], @"Boat Ramp",
			[NSNumber numberWithInt:151], @"Campground",
			[NSNumber numberWithInt:152], @"Restroom",
			[NSNumber numberWithInt:153], @"Shower",
			[NSNumber numberWithInt:154], @"Drinking Water",
			[NSNumber numberWithInt:155], @"Telephone",
			[NSNumber numberWithInt:156], @"Medical Facility",			
			[NSNumber numberWithInt:157], @"Information",
			[NSNumber numberWithInt:158], @"Parking Area",
			[NSNumber numberWithInt:159], @"Park",
			[NSNumber numberWithInt:160], @"Picnic Area",
			[NSNumber numberWithInt:161], @"Scenic Area",
			[NSNumber numberWithInt:162], @"Skiing Area",
			[NSNumber numberWithInt:163], @"Swimming Area",
			[NSNumber numberWithInt:164], @"Dam",
			[NSNumber numberWithInt:169], @"Ball Park",
			[NSNumber numberWithInt:170], @"Car",
			[NSNumber numberWithInt:171], @"Hunting Area",
			[NSNumber numberWithInt:172], @"Shopping Center",
			[NSNumber numberWithInt:173], @"Lodging",
			[NSNumber numberWithInt:174], @"Mine",
			[NSNumber numberWithInt:175], @"Trail Head",
			[NSNumber numberWithInt:176], @"Truck Stop",
			[NSNumber numberWithInt:8196], @"TracBack Point",
			[NSNumber numberWithInt:8197], @"Golf Course",
			[NSNumber numberWithInt:8198], @"City ([Small])",
			[NSNumber numberWithInt:8199], @"City ([Medium])",
			[NSNumber numberWithInt:8200], @"City ([Large])",
			[NSNumber numberWithInt:8207], @"Car Repair",
			[NSNumber numberWithInt:8208], @"Fast Food",
			[NSNumber numberWithInt:8209], @"Fitness Center",
			[NSNumber numberWithInt:8210], @"Movie Theater",
			[NSNumber numberWithInt:8214], @"Post Office",
			[NSNumber numberWithInt:8215], @"RV Park",
			[NSNumber numberWithInt:8220], @"Convenience Store",
			[NSNumber numberWithInt:8221], @"Live Theater",
			[NSNumber numberWithInt:8226], @"Scales",
			[NSNumber numberWithInt:8227], @"Toll Booth",
			[NSNumber numberWithInt:8233], @"Bridge",
			[NSNumber numberWithInt:8234], @"Building",
			[NSNumber numberWithInt:8235], @"Cemetery",
			[NSNumber numberWithInt:8236], @"Church",
			[NSNumber numberWithInt:8237], @"Civil",
			[NSNumber numberWithInt:8238], @"Crossing",
			[NSNumber numberWithInt:8239], @"Ghost Town",
			[NSNumber numberWithInt:8240], @"Levee",
			[NSNumber numberWithInt:8241], @"Military",
			[NSNumber numberWithInt:8242], @"Oil Field",
			[NSNumber numberWithInt:8243], @"Tunnel",
			[NSNumber numberWithInt:8244], @"Beach",
			[NSNumber numberWithInt:8245], @"Forest",
			[NSNumber numberWithInt:8246], @"Summit",
			[NSNumber numberWithInt:16384], @"Airport",
			[NSNumber numberWithInt:16388], @"Heliport",
			[NSNumber numberWithInt:16389], @"Private Field",
			[NSNumber numberWithInt:16390], @"Soft Field",
			[NSNumber numberWithInt:16391], @"Tall Tower",
			[NSNumber numberWithInt:16392], @"Short Tower",
			[NSNumber numberWithInt:16393], @"Glider Area",
			[NSNumber numberWithInt:16394], @"Ultralight Area",
			[NSNumber numberWithInt:16395], @"Parachute Area",
			[NSNumber numberWithInt:16402], @"Seaplane Base",			
			nil] retain];
	}

	id obj = [waypointIconDict objectForKey:symbolName];
	if (nil == obj) return 0;
	return [obj intValue];	
}

+ (NSImage*)iconForSymbolName:(NSString*)symbolName {
	int iconNum = [Waypoint iconNumberForSymbolName:symbolName];
	NSString * icnName = [NSString stringWithFormat:@"icon%05d.pict", iconNum];
	return [NSImage imageNamed:icnName];
}


// designated initializer
- (id)init {
    if (self = [super init]) {
		iconNumber = 18;

		location = [[Location alloc] init];
		[self setSymbolName:@"waypoint"];
		
		[self setElementName:@"wpt"];		//xml element name
	}	
    return self;
}


- (id)initWithLocation:(Location*)loc {
	id wpt = [self init];
	[location release];
	location = [loc retain];
	
	return wpt;
}


#pragma mark -
#pragma mark Simple Accessors

- (NSString*)description {
	return [NSString stringWithFormat:@"%f, %f", [[self latitude] doubleDegrees], [[self longitude] doubleDegrees] ];
}

- (Location*)location {
	return location;
}

- (void)setLocation:(Location*)loc {
	if (location != loc) {
		[location release];
		location = [loc retain];
	}
}

- (LatLon*)latitude { return [location latitude]; }
- (void)setLatitude:(LatLon*)l { [location setLatitude:l]; }
- (LatLon*)longitude { return [location longitude]; }
- (void)setLongitude:(LatLon*)l { [location setLongitude:l]; }

- (double)easting { return [location easting]; }
- (double)northing { return [location northing]; }


- (void)setDoubleLatitude:(double)newLat {
	LatLon * lat = [LatLon latLonWithDegrees:newLat];
	[location setLatitude:lat];
}

- (double)doubleLatitude { return [[location latitude] doubleDegrees]; }

- (void)setDoubleLongitude:(double)newLon {
	LatLon * lon = [LatLon latLonWithDegrees:newLon];
	[location setLongitude:lon];
}
- (double)doubleLongitude { return [[location longitude] doubleDegrees]; }


// Returns the image for this waypoint (ie, the waypoint icon)
- (NSImage*)image {
	return [Waypoint iconForSymbolName:[self symbolName]];
}

- (NSPopUpButtonCell*)imageMenuItem {
	NSPopUpButtonCell * item = [[NSPopUpButtonCell alloc] initTextCell:@"test" pullsDown:NO];
	[item setImage: [self image]];
	return item;
}


#pragma mark -
#pragma mark Dictionary Accessors

// The following elements are stored in the dictionary in the superclass

- (void)setElevation:(NSNumber*)n {
	[otherElements setObject:n forKey:WPTElevation];
}
- (NSNumber*)elevation {
	return [otherElements objectForKey:WPTElevation];
}

/*
 - (void)setElevation:(float)v {
	NSNumber * n = [NSNumber numberWithFloat:v];
	[otherElements setObject:n forKey:WPTElevation];
}
- (float)elevation { 
	return [[otherElements objectForKey:WPTElevation] floatValue];
}
*/

/*
- (void)setName:(NSString *)s { [otherElements setObject:s forKey:WPTName]; }
- (NSString *)name { return [otherElements objectForKey:WPTName]; }

- (void)setComment:(NSString *)s { [otherElements setObject:s forKey:WPTComment]; }
- (NSString *)comment { return [otherElements objectForKey:WPTComment]; }
*/

- (void)setSymbolName:(NSString *)s {
	[otherElements setObject:s forKey:WPTSymbol];
	id blah = [self image];
}
- (NSString *)symbolName { return [otherElements objectForKey:WPTSymbol]; }

/*
- (void)setWaypointDescription:(NSString *)s { [otherElements setObject:s forKey:WPTDescription]; }
- (NSString *)waypointDescription { return [otherElements objectForKey:WPTDescription]; }
*/

- (void)setType:(NSString *)s { [otherElements setObject:s forKey:WPTType]; }
- (NSString *)type { return [otherElements objectForKey:WPTType]; }

/*
- (void)setURL:(NSString *)s { [otherElements setObject:s forKey:WPTUrl]; }
- (NSString *)url { return [otherElements objectForKey:WPTUrl]; }

- (void)setURLName:(NSString *)s { [otherElements setObject:s forKey:WPTUrlName]; }
- (NSString *)urlName { return [otherElements objectForKey:WPTUrlName]; }
*/

- (void)setTime:(NSString *)s { [otherElements setObject:s forKey:WPTTime]; }
- (NSString *)time { return [otherElements objectForKey:WPTTime]; }

- (void)setGpsFix:(NSString *)s { [otherElements setObject:s forKey:WPTGpsFix]; }
- (NSString *)gpsFix { return [otherElements objectForKey:WPTGpsFix]; }

- (void)setNumberOfSatellites:(int)v {
	NSNumber * n = [NSNumber numberWithInt:v];
	[otherElements setObject:n forKey:WPTNumberOfSatellites];
}
- (int)numberOfSatellites { return [[otherElements objectForKey:WPTNumberOfSatellites] intValue]; }


#pragma mark -
#pragma mark Other methods



// overridden method from superclass
- (NSString*)attributeString {
	NSMutableString * attrString = [NSMutableString stringWithCapacity:50];
	[attrString appendFormat:@" lat=\"%f\" lon=\"%f\" %@", [self doubleLatitude], [self doubleLongitude], [super attributeString]];

	return attrString;
}



// overrides method in XMLElement
- (int)numberOfSubElements {
	return 1;
}



- (void)dealloc {
	[location release];
	[super dealloc];
}


#pragma mark -
#pragma mark Coding methods

- (void)encodeWithCoder:(NSCoder *)encoder {
	[super encodeWithCoder:encoder];
	[encoder encodeValueOfObjCType:@encode(int) at:&iconNumber];
	[encoder encodeObject:location];
}

- (id)initWithCoder:(NSCoder *)decoder {
	self = [super initWithCoder:decoder];
	[decoder decodeValueOfObjCType:@encode(int) at:&iconNumber];
	location = [[decoder decodeObject] retain];
	return self;
}




@end
