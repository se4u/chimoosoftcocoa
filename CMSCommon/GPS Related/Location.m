//
//  Location.m
//  Terrabrowser
//
//  Created by Ryan on Mon Nov 24 2003.
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


#import "Location.h"
#import "LatLon.h"
#import "Ellipsoid.h"
#import <stdlib.h>
#import "Constants.h"


@interface Location ()

- (void)convertLatLonToUTM;
- (void)convertUTMToLatLon;
- (char)UTMLetterDesignatorForLatitude:(double)lat;

@end


@implementation Location

#pragma mark -
#pragma mark Init methods

// class method
+ (id)locationWithDoubleLatitude:(double)newLat doubleLongitude:(double)newLon {
	LatLon * lat = [LatLon latLonWithDegrees:newLat];
	LatLon * lon = [LatLon latLonWithDegrees:newLon];
	
	Location * loc = [[Location alloc] initWithLatitude:lat
											  longitude:lon];

	valid = YES;
	
	return [loc autorelease];
}


// defaults to WGS84 ellipsoid
- (id)init {
    if (self = [super init]) {
		latitude = [[LatLon alloc] init];
		longitude = [[LatLon alloc] init];
		ellipsoid = [[Ellipsoid alloc] init];

		valid = NO;
	}
	
    return self;
}

// same as below, but uses the default ellipsoid
- (id)initWithLatitude:(LatLon*)newLat longitude:(LatLon*)newLon {
	if (self = [super init]) {
		
		if (latitude != newLat) {
			[latitude release];
			latitude = [newLat retain];
		}
		
		if (longitude != newLon) {
			[longitude release];
			longitude = [newLon retain];
		}
		
		ellipsoid = [[Ellipsoid alloc] init];
		
		//now convert it to UTM coordinates
		[self convertLatLonToUTM];
	}
	
	valid = YES;
	
	return self;	
}

//designated initializer
- (id)initWithLatitude:(LatLon*)newlat 
	longitude:(LatLon*)newlon ellipsoid:(Ellipsoid*)newEllip {
	
	if (self = [super init]) {
		
		if (latitude != newlat) {
			[latitude release];
			latitude = [newlat retain];
		}
		
		if (longitude != newlon) {
			[longitude release];
			longitude = [newlon retain];
		}
		
		if (ellipsoid != newEllip) {
			[ellipsoid release];
			ellipsoid = [newEllip retain];
		}

		//now convert it to UTM coordinates
		[self convertLatLonToUTM];
		
		valid = YES;
	}
	
	return self;
}


- (id)initWithNorthing:(double)newNorthing easting:(double)newEasting
		zoneLetter:(char)zLetter zoneNumber:(int)zNumber
		ellipsoid:(Ellipsoid*)newEllip {
	
	if (self = [super init]) {
		northing = newNorthing;
		easting = newEasting;
		zoneLetter = zLetter;
		zoneNumber = zNumber;
		
		if (ellipsoid != newEllip) {
			[ellipsoid release];
			ellipsoid = [newEllip retain]; 
		}

		latitude = [[LatLon alloc] init];
		longitude = [[LatLon alloc] init];		
		
		//convert it to latitude and longitude.
		[self convertUTMToLatLon];
		
		valid = YES;
	}
	
	return self;
}


- (id)copyWithZone:(NSZone *)zone {
	id newLoc = [[Location alloc] initWithLatitude:latitude
							longitude:longitude 
							ellipsoid:ellipsoid];
	
	return newLoc;
}


#pragma mark -
#pragma mark Other methods

// returns a true value if this location has been set (ie, is not empty).
- (BOOL)isValid {
	return valid;
}

// Pass this another location object and it will calculate the great circle
// distance between them in meters.  Called the 'Haversine formula'.
//
// Haversine formula - R. W. Sinnott, "Virtues of the Haversine",
// Sky and Telescope, vol 68, no 2, 1984
// http://www.census.gov/cgi-bin/geo/gisfaq?Q5.1 
//
// Formula obtained from http://www.movable-type.co.uk/scripts/LatLong.html 
//
- (float)metricDistanceBetween:(Location*)otherLoc {
	double R = 6371.0;	// mean radius of earth = 6371 km
	
	double lat1 = [[self latitude] doubleDegrees];
	double lat2 = [[otherLoc latitude] doubleDegrees];
	
	double deltaLat = lat2 - lat1;
	double deltaLon =  [[otherLoc longitude] doubleDegrees] - [[self longitude] doubleDegrees];
	
	double a = pow((sin([Constants degToRad:deltaLat/2.0])), 2.0) + 
		(cos([Constants degToRad:lat1]))*
		(cos([Constants degToRad:lat2]))*
		pow((sin([Constants degToRad:deltaLon/2.0])), 2.0);
	double c = 2.0*atan2(sqrt(a), sqrt(1-a));
	double d = R * c;
																		
	return (float)d * 1000;																	
}



#pragma mark -
#pragma mark Conversion methods


// Converts lat/long to UTM coords.  Equations from USGS Bulletin 1532 
// East Longitudes are positive, West longitudes are negative. 
// North latitudes are positive, South latitudes are negative
// Lat and Long are in decimal degrees
// Originally written by Chuck Gantz - chuck.gantz@globalstar.com 
// Converted to Objective-C and modified by Ryan at Chimoosoft,  11/2003
- (void)convertLatLonToUTM {
	const double deg2rad = PI / 180;
	
	double a = [ellipsoid equatorialRadius];
	double eccSquared = [ellipsoid eccentricitySquared];
	double eccSquared2 = eccSquared * eccSquared;
	double eccSquared3 = eccSquared2 * eccSquared;
	
	double k0 = 0.9996;
	
	double lonOrigin;
	double eccPrimeSquared;
	double N, T, C, A, M;
	
	double lat = [latitude doubleDegrees];
	double lon = [longitude doubleDegrees];
	
	//Make sure the longitude is between -180.00 .. 179.9
	double lonTemp = (lon + 180) - ((int)((lon + 180) / 360)) * 360 - 180; // -180.00 .. 179.9;
	
	double latRad = lat * deg2rad;
	double lonRad = lon * deg2rad;
	double lonOriginRad;
	
	zoneNumber = ((int)((lonTemp + 180)/6)) + 1;
	
	if ((lat >= 56.0) && 
		(lat < 64.0) && 
		(lonTemp >= 3.0) &&
		(lonTemp < 12.0) ) {
			zoneNumber = 32;
	}
		
	// Special zones for Svalbard
	if ((lat >= 72.0) && (lat < 84.0) ) {
		if (	 lonTemp >= 0.0  && lonTemp <  9.0 ) { (zoneNumber) = 31; }
		else if( lonTemp >= 9.0  && lonTemp < 21.0 ) { (zoneNumber) = 33; }
		else if( lonTemp >= 21.0 && lonTemp < 33.0 ) { (zoneNumber) = 35; }
		else if( lonTemp >= 33.0 && lonTemp < 42.0 ) { (zoneNumber) = 37; }
	}
	
	lonOrigin = (((zoneNumber) - 1)*6) - 180 + 3;  //+3 puts origin in middle of zone
	lonOriginRad = lonOrigin * deg2rad;
	
	zoneLetter = [self UTMLetterDesignatorForLatitude:lat];
	
	eccPrimeSquared = (eccSquared) / (1 - eccSquared);
	
	N = a / sqrt(1 - eccSquared * sin(latRad) * sin(latRad));
	T = tan(latRad) * tan(latRad);
	C = eccPrimeSquared * cos(latRad) * cos(latRad);
	A = cos(latRad) * (lonRad - lonOriginRad);
	
	M = a*((1	- eccSquared/4		- 3*eccSquared2/64	- 5*eccSquared3/256)*latRad 
		- (3*eccSquared/8	+ 3*eccSquared2/32	+ 45*eccSquared3/1024)*sin(2*latRad)
		+ (15*eccSquared2/256 + 45*eccSquared3/1024)*sin(4*latRad) 
		- (35*eccSquared3/3072)*sin(6*latRad));
	
	easting = (double)(k0*N*(A+(1-T+C)*A*A*A/6
			+ (5-18*T+T*T+72*C-58*eccPrimeSquared)*A*A*A*A*A/120)
			+ 500000.0);
	
	northing = (double)(k0*(M+N*tan(latRad)*(A*A/2+(5-T+9*C+4*C*C)*A*A*A*A/24
			+ (61-58*T+T*T+600*C-330*eccPrimeSquared)*A*A*A*A*A*A/720)));

	if(lat < 0) {
		northing += 10000000.0; //10000000 meter offset for southern hemisphere								  
	}	
	 
}


// converts UTM coords to lat/long.  Equations from USGS Bulletin 1532 
// East Longitudes are positive, West longitudes are negative. 
// North latitudes are positive, South latitudes are negative
// Originally written by Chuck Gantz - chuck.gantz@globalstar.com 
// Converted to Cocoa and modified by Ryan at Chimoosoft, 11/2003
- (void)convertUTMToLatLon {
	
	//**********
	//Note, this is where the problems seem to be.
	//Or perhaps it's in the one which converts to UTM.  But something is wrong here..
	
	const double rad2deg = 180.0 / PI;
	
	double k0 = 0.9996;
	double a = [ellipsoid equatorialRadius];
	double eccSquared = [ellipsoid eccentricitySquared];
	double eccSquared2 = eccSquared * eccSquared;
	double eccSquared3 = eccSquared2 * eccSquared;
	
	double eccPrimeSquared;
	double e1 = (1-sqrt(1-eccSquared))/(1+sqrt(1-eccSquared));
	double N1, T1, C1, R1, D, M;
	double lonOrigin;
	double mu, phi1, phi1Rad;
	double x, y;
	BOOL northernHemisphere;
	
	x = easting - 500000.0; //remove 500,000 meter offset for lonitude
	y = northing;

	//*************
	//**note, I changed this from the previous way of doing it, so it may not work
	//correctly..  it used to say 	if((*ZoneLetter - 'N') >= 0)
	if(zoneLetter > 'N')
		northernHemisphere = YES;  //point is in northern hemisphere
	else
	{
		northernHemisphere = NO;//point is in southern hemisphere
		y -= 10000000.0;//remove 10,000,000 meter offset used for southern hemisphere
	}
	
	lonOrigin = (zoneNumber - 1)*6 - 180 + 3;  //+3 puts origin in middle of zone
	
	eccPrimeSquared = (eccSquared)/(1-eccSquared);
	
	M = y / k0;
	mu = M/(a*(1-eccSquared/4-3*eccSquared2/64-5*eccSquared3/256));
	
	phi1Rad = mu + (3*e1/2-27*e1*e1*e1/32)*sin(2*mu) 
		+ (21*e1*e1/16-55*e1*e1*e1*e1/32)*sin(4*mu)
		+(151*e1*e1*e1/96)*sin(6*mu);
	phi1 = phi1Rad*rad2deg;
	
	N1 = a/sqrt(1-eccSquared*sin(phi1Rad)*sin(phi1Rad));
	T1 = tan(phi1Rad)*tan(phi1Rad);
	C1 = eccPrimeSquared*cos(phi1Rad)*cos(phi1Rad);
	R1 = a*(1-eccSquared)/pow(1-eccSquared*sin(phi1Rad)*sin(phi1Rad), 1.5);
	D = x/(N1*k0);
	
	double newlat, newlon;
	
	newlat = phi1Rad - (N1*tan(phi1Rad)/R1)*(D*D/2-(5+3*T1+10*C1-4*C1*C1-9*eccPrimeSquared)*D*D*D*D/24
			+ (61+90*T1+298*C1+45*T1*T1-252*eccPrimeSquared-3*C1*C1)*D*D*D*D*D*D/720);
	newlat *= rad2deg;
	
	newlon = (D-(1+2*T1+C1)*D*D*D/6+(5-2*C1+28*T1-3*C1*C1+8*eccPrimeSquared+24*T1*T1)
		 *D*D*D*D*D/120)/cos(phi1Rad);
	newlon = lonOrigin + newlon * rad2deg;
	
	[latitude setWithDegrees:newlat];
	[longitude setWithDegrees:newlon];
}



//returns the UTM zone letter designator for the passed latitude.
//if latitude is outside of UTM limits (80S to 84N), it returns 'Z'
//note, these are for the **horizontal** UTM zones which are each 
//8 degrees tall.  They begin at 80S with letter 'C', and end at 84N 
//with letter 'X'
//***NOTE, letters 'I' and 'O' are skipped to avoid confusion!
- (char)UTMLetterDesignatorForLatitude:(double)lat {
	char c;
	
	if ((lat > 84) || (lat < 80)) return 'Z';  //out of bounds
	
	if      ((lat >= -80) && (lat < -72)) c = 'C';
	else if ((lat >= -72) && (lat < -64)) c = 'D';
	else if ((lat >= -64) && (lat < -56)) c = 'E';
	else if ((lat >= -56) && (lat < -48)) c = 'F';
	else if ((lat >= -48) && (lat < -40)) c = 'G';
	else if ((lat >= -40) && (lat < -32)) c = 'H';  //skip letter 'I'
	else if ((lat >= -32) && (lat < -24)) c = 'J';
	else if ((lat >= -24) && (lat < -16)) c = 'K';
	else if ((lat >= -16) && (lat <  -8)) c = 'L';
	else if ((lat >=  -8) && (lat <   0)) c = 'M';
	else if ((lat >=   0) && (lat <   8)) c = 'N';  //skip letter 'O'
	else if ((lat >=   8) && (lat <  16)) c = 'P';
	else if ((lat >=  16) && (lat <  24)) c = 'Q';
	else if ((lat >=  24) && (lat <  32)) c = 'R';
	else if ((lat >=  32) && (lat <  40)) c = 'S';
	else if ((lat >=  40) && (lat <  48)) c = 'T';
	else if ((lat >=  48) && (lat <  56)) c = 'U';
	else if ((lat >=  56) && (lat <  64)) c = 'V';
	else if ((lat >=  64) && (lat <  72)) c = 'W';
	else if ((lat >=  72) && (lat <= 84)) c = 'X';

	return c;
}


- (NSString *)description {
	if (latitude && longitude) {
		NSString * d = [NSString stringWithFormat:@"lat = %f, lon = %f", 
				[latitude doubleDegrees], [longitude doubleDegrees]];
		return d;
	} else {
		return @"";
	}

}



//offsets the longitude value by adding the passed value to it
//and then re-calculating the other coordinates
- (void)offsetLongitudeBy:(double)offset {
	[longitude offsetWithDouble:offset];
	
	double newLon = [longitude doubleDegrees];
	
	while (newLon > 180.0)  { newLon -= 360.0; }
	while (newLon < -180.0) { newLon += 360.0; }

	[longitude setWithDegrees:newLon];
	
	[self convertLatLonToUTM];
}


//trys to fix a problem which occurs if you initialize a Location object
//with an invalid zone number and easting value.  For example, if you are at
//a zone boundary (ie, -120deg or -114deg, etc..) and try to move past it
//by simply incrementing the easting value, you will create an invalid UTM
//value.  This is a problem which is present in Microsoft's own implementation
//of the Terraserver.  Try it out on their web page:
//<http://terraserver-usa.com/image.aspx?t=1&s=16&x=18&y=328&z=11&w=1>
- (void)fixZoneNumber {

//if you set the position with an invalid easting and zone number,
//the latitude/longitude is still set correctly (amazingly!), so
//we can just take that and convert it to UTM again to correct the problem.
	
	
	//note, this seems completely worthless.. remove it later?
	[self convertLatLonToUTM];
		
	
/*  //this was the old way I came up with to do it, but it didn't work
	//because the easting value was still incorrect.
	
	//zone 1 is from -180 to -174
	//zone 2 is from -174 to -168, etc..
	int newZoneNum = ((longitude + 180) / 6) + 1;
	zoneNumber = newZoneNum;
*/
}

#pragma mark -
#pragma mark Simple accessors

- (void)setLatitude:(LatLon*)newLat {
	if (latitude != newLat) {
		[latitude release];
		latitude = [newLat retain];
	}
	
	[self convertLatLonToUTM];
}

- (LatLon*)latitude			{ return latitude; }

- (void)setLongitude:(LatLon*)newLon {
	if (longitude != newLon) {
		[longitude release];
		longitude = [newLon retain];
	}
	
	[self convertLatLonToUTM];
}


- (double)doubleLatitude { return [latitude doubleDegrees];	}
- (double)doubleLongitude { return [longitude doubleDegrees]; }


- (LatLon*)longitude		{ return longitude; }
- (double)northing			{ return northing; }
- (double)easting			{ return easting; }
- (char)zoneLetter			{ return zoneLetter; }
- (int)zoneNumber			{ return zoneNumber; }
- (Ellipsoid*)ellipsoid		{ return ellipsoid; }


- (void)dealloc {
	
	[ellipsoid release];
	[latitude release];
	[longitude release];
	
	[super dealloc];
}


#pragma mark -
#pragma mark Coding methods

- (void)encodeWithCoder:(NSCoder *)encoder {
	//[super encodeWithCoder:encoder];
	[encoder encodeValueOfObjCType:@encode(double) at:&northing];
	[encoder encodeValueOfObjCType:@encode(double) at:&easting];
	[encoder encodeValueOfObjCType:@encode(char) at:&zoneLetter];
	[encoder encodeValueOfObjCType:@encode(int) at:&zoneNumber];
	[encoder encodeObject:latitude];
	[encoder encodeObject:longitude];
	[encoder encodeObject:ellipsoid];
}

- (id)initWithCoder:(NSCoder *)decoder {
	//self = [super initWithCoder:decoder];
	self = [super init];
	[decoder decodeValueOfObjCType:@encode(double) at:&northing];
	[decoder decodeValueOfObjCType:@encode(double) at:&easting];
	[decoder decodeValueOfObjCType:@encode(char) at:&zoneLetter];
	[decoder decodeValueOfObjCType:@encode(int) at:&zoneNumber];
	latitude = [[decoder decodeObject] retain];
	longitude = [[decoder decodeObject] retain];
	ellipsoid = [[decoder decodeObject] retain];
	return self;
}



@end
