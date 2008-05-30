//
//  LatLon.m
//  Terrabrowser
//
//  Created by Ryan on Thu Dec 25 2003.
//  Copyright (c) 2003 Chimoosoft. All rights reserved.
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

#import "LatLon.h"
#import <math.h>

@implementation LatLon

/////////////////////
//initializers

//(the class methods (+) return autoreleased objects)

+ (id)latLonWithDegrees:(double)deg {
	LatLon* obj = [[[LatLon alloc] initWithDegrees:deg] autorelease];
	return obj;
}

+ (id)latLonWithDegrees:(int)deg minutes:(float)min {
	id obj = [[LatLon alloc] initWithDegrees:deg minutes:min];
	return [obj autorelease];
}

+ (id)latLonWithDegrees:(int)deg minutes:(int)min seconds:(float)sec {
	id obj = [[LatLon alloc] initWithDegrees:deg minutes:min seconds:sec];
	return [obj autorelease];
}


- (id)init {
	if (self = [super init]) {	
		doubleValue = 0.0;
	}	
	return self;
}


- (id)initWithDegrees:(double)deg {
	if (self = [super init]) {	
		doubleValue = deg;
	}	
	return self;
}
	
- (id)initWithDegrees:(int)deg minutes:(float)min {
	id newself = [self initWithDegrees: 0.0];
	[newself setWithDegrees:deg minutes:min];
	return newself;
}

- (id)initWithDegrees:(int)deg minutes:(int)min seconds:(float)sec {
	id newself = [self initWithDegrees: 0.0];
	[newself setWithDegrees:deg minutes:min seconds:sec];
	return newself;
}

////////////
//copying

- (id)copyWithZone:(NSZone *)zone {
	return [[LatLon alloc] initWithDegrees:doubleValue];
}


//////////////
//accessors

- (void)setWithDegrees:(double)deg { 
	doubleValue = deg;
}

- (void)setWithDegrees:(int)deg minutes:(float)min {
	if (deg < 0) {
		doubleValue = (double)deg - ((double)min / 60.0);
	} else {
		doubleValue = (double)deg + ((double)min / 60.0);
	}
	
}

- (void)setWithDegrees:(int)deg minutes:(int)min seconds:(float)sec {
	if (deg < 0) {
		doubleValue = (double)deg - ((double)min / 60.0) - ((double)sec / 3600.0);	
	} else {
		doubleValue = (double)deg + ((double)min / 60.0) + ((double)sec / 3600.0);	
	}
	
}

- (double)doubleDegrees { return doubleValue; }

- (int)intDegrees {
	double ip;  //note, modf returns the floating part and integer part of a double.
	double fp = modf(doubleValue, &ip);
	return (int)ip;  //can be positive or negative.
}

- (float)floatMinutes {
	double ip;
	double fp = modf(doubleValue, &ip);
	
	//important to take absolute value here..
	return fabs((float)(60.0 * fp));
}

- (int)intMinutes {
	return (int)floor([self floatMinutes]);
}

- (float)floatSeconds {
	double ip;
	double fp = modf([self floatMinutes], &ip);
	
	return (float)(60.0 * fp);
}


- (void)offsetWithDouble:(double)offset { 
	doubleValue += offset; 
}



- (void)encodeWithCoder:(NSCoder *)encoder {
	//[super encodeWithCoder:encoder];
	[encoder encodeValueOfObjCType:@encode(double) at:&doubleValue];
}

- (id)initWithCoder:(NSCoder *)decoder {
	//self = [super initWithCoder:decoder];
	self = [super init];
	[decoder decodeValueOfObjCType:@encode(double) at:&doubleValue];
	return self;
}


// sorting
- (NSComparisonResult)compare:(LatLon *)aLatLon {
	float a = [self doubleDegrees];
	float b = [aLatLon doubleDegrees];
	if (a < b) return NSOrderedAscending;
	else return NSOrderedDescending;
}



@end
