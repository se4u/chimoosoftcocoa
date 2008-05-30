//
//  MutableDataAdditions.m
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


#import "MutableDataAdditions.h"

@implementation NSMutableData ( MutableDataAdditions )

- (void)setSInt16:(SInt16)num AtIndex:(int)index dataIsLittleEndian:(BOOL)le {
	SInt16 toSet;
	NSRange range;
	range.location = index;
	range.length = 2;  // two bytes = 16 bits
	
	toSet = num;
	
	if (le) {
		toSet = CFSwapInt16HostToLittle(num);
	}

	[self replaceBytesInRange:range withBytes:(void*)&toSet];
}

- (void)setSInt32:(SInt32)num AtIndex:(int)index dataIsLittleEndian:(BOOL)le {
	SInt32 toSet;
	NSRange range;
	range.location = index;
	range.length = 4;  // four bytes = 32 bits
	
	toSet = num;
	
	if (le) {
		toSet = CFSwapInt32HostToLittle(num);
	}
	
	[self replaceBytesInRange:range withBytes:(void*)&toSet];
}


- (void)setFloat32:(Float32)num AtIndex:(int)index dataIsLittleEndian:(BOOL)le {

	NSRange subRange;
	subRange.length = 4;
	subRange.location = index;
	
	// if the computer is big endian and the data is supposed to be big endian,
	// or if the computer is little endian and the data is supposed to be big endian
	// then we need to swap the byte order.
	if ( ((CFByteOrderGetCurrent() == CFByteOrderBigEndian) && le) ||
		 ((CFByteOrderGetCurrent() == CFByteOrderLittleEndian) && (! le)) )
	{
		// swap byte order of float
		
		[self replaceBytesInRange:subRange withBytes:(void*)&num];
		[self swapBytesInRange:subRange];
		
	} else {  // no need to swap
		[self replaceBytesInRange:subRange withBytes:(void*)&num];
	}
}




// pass this a starting position.  It will attempt to parse a
// c string (null terminated) from the data, return the string, and set the byref 
// argument "end" to the end position (ie, where the null terminator is).
- (void)setCString:(NSString*)s atIndex:(int)start {
	
	char * cString = [s cString];
	
	NSRange range;
	range.length = [s length];
	
	if (range.length == 0) { return; } else range.length += 1;
	// plus 1 for the string terminator
	
	range.location = start;
	
	[self replaceBytesInRange:range withBytes:(void*)cString];
}

// same as setCString, but sets a non terminated string (ie, just a character array)
// at a certain position and of a certain length
- (void)setNonTerminatedString:(NSString*)s range:(NSRange)range {
	char * cString = [s cString];
	
	[self replaceBytesInRange:range withBytes:(void*)cString];
}


// swaps the bytes in the passed range for endian conversions
- (void)swapBytesInRange:(NSRange)subRange {
	
	NSMutableData * data = [NSMutableData dataWithData:[self subdataWithRange:subRange]];
	
	NSRange range;
	range.length = subRange.length;
	range.location = 0;
	
	UInt8 * oldBytes = (UInt8*)malloc(range.length);
	[data getBytes:(void*)oldBytes];
	
	UInt8 * newBytes = [data mutableBytes];
	
	int i;
	for (i = range.location; i < range.length; i++) {
		newBytes[i] = oldBytes[range.length - 1 - i];
	}
				
	free(oldBytes);
	
	[self replaceBytesInRange:subRange withBytes:(void*)newBytes];	
}




@end

