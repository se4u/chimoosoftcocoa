//
//  DataAdditions.m
//  GPSTest
//
//  Created by Ryan on Mon May 31 2004.
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


#import "DataAdditions.h"

@implementation NSData ( DataAdditions )

- (SInt16)sInt16AtIndex:(int)index dataIsLittleEndian:(BOOL)le {
	SInt16 num, retVal;
	NSRange range;
	range.location = index;
	range.length = 2;  // two bytes = 16 bits
	
	[self getBytes:&num range:range];
	retVal = num;
	
	if (le) {
		retVal = CFSwapInt16LittleToHost(num);
	}
	
	return retVal;
}

- (SInt32)sInt32AtIndex:(int)index dataIsLittleEndian:(BOOL)le {
	SInt32 num, retVal;
	NSRange range;
	range.location = index;
	range.length = 4;  // four bytes = 32 bits
	
	[self getBytes:(void*)&num range:range];
	retVal = num;
	
	if (le) {
		retVal = CFSwapInt32LittleToHost(num);
	}
	
	return retVal;
}


- (UInt32)uInt32AtIndex:(int)index dataIsLittleEndian:(BOOL)le {
	UInt32 num, retVal;
	NSRange range;
	range.location = index;
	range.length = 4;  // four bytes = 32 bits
	
	[self getBytes:(void*)&num range:range];
	retVal = num;
	
	if (le) {
		retVal = CFSwapInt32LittleToHost(num);
	}
	
	return retVal;
}



- (Float32)float32AtIndex:(int)index dataIsLittleEndian:(BOOL)le {
	Float32 num, retVal;
	NSRange range;
	range.location = index;
	range.length = 4;  // four bytes = 32 bits
	
	// do we need to swap the endianess of the data?
	if ( ((CFByteOrderGetCurrent() == CFByteOrderBigEndian) && le) ||
		 ((CFByteOrderGetCurrent() == CFByteOrderLittleEndian) && (! le)) )
	{
		[self getSwappedBytes:&num range:range];
	} else {
		[self getBytes:&num range:range];
	}
	
	retVal = (Float32)num;
	
	return retVal;
}


- (Float64)float64AtIndex:(int)index dataIsLittleEndian:(BOOL)le {
	Float64 num, retVal;
	NSRange range;
	range.location = index;
	range.length = 8;  // eight bytes = 64 bits
	
	// do we need to swap the endianess of the data?
	if ( ((CFByteOrderGetCurrent() == CFByteOrderBigEndian) && le) ||
		 ((CFByteOrderGetCurrent() == CFByteOrderLittleEndian) && (! le)) )
	{
		[self getSwappedBytes:&num range:range];
	} else {
		[self getBytes:&num range:range];
	}
	
	retVal = (Float64)num;
	
	return retVal;	
}


// pass this a starting position.  It will attempt to parse a
// c string (null terminated) from the data, return the string, and set the byref 
// argument "end" to the end position (ie, where the null terminator is).
- (NSString*) cStringAtIndex:(int)start endPos:(int*)end {
	UInt8 * bytes = [self bytes];
	int size = [self length];
	
	int i = start;
	
	while ((i < size) && (bytes[i] != 0x00)) {
		i++;
	}
	
	*end = i;
	
	// now, we should have the position of the terminating character
	if (bytes[i] != 0x00) {
		// then something is wrong, so return
		NSLog(@"cStringAtIndex, something weird happened...");
		return nil;
	}
	
	// if we make it to here, then it's a valid string
	NSRange range;
	range.length = i - start + 1;
	range.location = start;
	
	return [[[NSString alloc] initWithData:[self subdataWithRange:range] 
								  encoding:NSASCIIStringEncoding] autorelease];
}


// returns the swapped bytes in a the passed range.
- (void)getSwappedBytes:(void *)buffer range:(NSRange)range {
	
	NSMutableData * data = [NSMutableData dataWithData:[self subdataWithRange:range]];
	
	NSRange swapRange;
	swapRange.length = range.length;
	swapRange.location = 0;
	[data swapBytesInRange:swapRange];
		
	[data getBytes:buffer];
}


@end

