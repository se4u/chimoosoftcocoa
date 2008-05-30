//
//  Ellipsoid.m
//  Terrabrowser
//
//  Created by Ryan on Mon Nov 24 2003.
//  Copyright (c) 2003 Chimoosoft. All rights reserved.
//
//  The GPX file format stores everything internally in WGS84.
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


#import "Ellipsoid.h"

//********************************
//Note, defaults to WGS84 for now
//*********************************

@implementation Ellipsoid

- (id)init {
	if (self = [super init]) {
		[[NSUserDefaults standardUserDefaults] stringForKey:@"BrowserShowTracklogs"];
		datum = 0;	// WGS84
	}
	
	return self;
}

- (double)equatorialRadius {
	switch (datum) {
		case 0:
			return 6378137;  //WGS84
			break;
		case 1:
			return 6378206;  //NAD27
			break;		
	}
	
	return 6378137;
}

- (double)eccentricitySquared {
	switch (datum) {
		case 0:
			return 0.00669438;  //WGS84
			break;
		case 1:
			return 0.006768658;  //NAD27
			break;
	}

	return 0.00669438;
}


- (void)encodeWithCoder:(NSCoder *)encoder {
	//[super encodeWithCoder:encoder];
/*
	[encoder encodeValueOfObjCType:@encode(double) at:&northing];
	[encoder encodeValueOfObjCType:@encode(double) at:&easting];
	[encoder encodeValueOfObjCType:@encode(char) at:&zoneLetter];
	[encoder encodeValueOfObjCType:@encode(int) at:&zoneNumber];
	[encoder encodeObject:latitude];
	[encoder encodeObject:longitude];
	[encoder encodeObject:ellipsoid];
 */
}

- (id)initWithCoder:(NSCoder *)decoder {
	//self = [super initWithCoder:decoder];
	self = [super init];
/*
	[decoder decodeValueOfObjCType:@encode(double) at:&northing];
	[decoder decodeValueOfObjCType:@encode(double) at:&easting];
	[decoder decodeValueOfObjCType:@encode(char) at:&zoneLetter];
	[decoder decodeValueOfObjCType:@encode(int) at:&zoneNumber];
	latitude = [[decoder decodeObject] retain];
	longitude = [[decoder decodeObject] retain];
	ellipsoid = [[decoder decodeObject] retain];
 */
	return self;
}


@end
