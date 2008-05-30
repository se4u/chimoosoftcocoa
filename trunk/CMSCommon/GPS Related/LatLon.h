//
//  LatLon.h
//  Terrabrowser
//
//  Created by Ryan on Thu Dec 25 2003.
//  Copyright (c) 2003 Chimoosoft. All rights reserved.
//
//  Represents a latitude or longitude value and offers methods to set and access the
//  value in several formats (DMS, decimal, DM, etc.
//
//  Note, this class is now shared amongst several Cocoa programs.
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

@interface LatLon : NSObject <NSCoding, NSCopying> {
	double doubleValue;
}


//autoreleased "convenience" initializers
+ (id)latLonWithDegrees:(double)deg;
+ (id)latLonWithDegrees:(int)deg minutes:(float)min;
+ (id)latLonWithDegrees:(int)deg minutes:(int)min seconds:(float)sec;

//standard initializers
- (id)initWithDegrees:(double)deg;
- (id)initWithDegrees:(int)deg minutes:(float)min;
- (id)initWithDegrees:(int)deg minutes:(int)min seconds:(float)sec;

//copying
- (id)copyWithZone:(NSZone *)zone;

//accesors
- (void)setWithDegrees:(double)deg;
- (void)setWithDegrees:(int)deg minutes:(float)min;
- (void)setWithDegrees:(int)deg minutes:(int)min seconds:(float)sec;

- (double)doubleDegrees;
- (int)intDegrees;

- (float)floatMinutes;
- (int)intMinutes;

- (float)floatSeconds;

- (void)offsetWithDouble:(double)offset;


- (void)encodeWithCoder:(NSCoder *)encoder;
- (id)initWithCoder:(NSCoder *)decoder;


// sorting
- (NSComparisonResult)compare:(LatLon *)aLatLon;

@end
