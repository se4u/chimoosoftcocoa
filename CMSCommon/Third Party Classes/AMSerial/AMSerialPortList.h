//
//  AMSerialPortList.h
//  CommX
//
//  Created by Andreas on 2002-04-24.
//  Copyright (c) 2001 Andreas Mayer. All rights reserved.
//
//  2002-09-09 Andreas Mayer
//  - reuse AMSerialPort objects when calling init on an existing AMSerialPortList
//  2002-09-30 Andreas Mayer
//  - added +sharedPortList
//  2004-02-10 Andreas Mayer
//  - added +portEnumerator


#import <Cocoa/Cocoa.h>
#import "AMSerialPort.h"

@interface AMSerialPortList : NSObject
{
	@private
	NSMutableArray *portList;
	NSArray *oldPortList;
}

+ (AMSerialPortList *)sharedPortList;

+ (NSEnumerator *)portEnumerator;

- (unsigned)count;
- (AMSerialPort *)objectAtIndex:(unsigned)index;
- (AMSerialPort *)objectWithName:(NSString *)name;
- (NSArray *)getPortList;


@end
