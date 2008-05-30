//
//  AMSerialPortAdditions.h
//  CommX
//
//  Created by Andreas on Thu May 02 2002.
//  Copyright (c) 2001 Andreas Mayer. All rights reserved.
//
//  2002-10-04 Andreas Mayer
//  - readDataInBackgroundWithTarget:selector: and writeDataInBackground: added
//  2002-10-10 Andreas Mayer
//	- stopWriteInBackground added
//  2002-10-17 Andreas Mayer
//	- numberOfWriteInBackgroundThreads added
//  2002-10-25 Andreas Mayer
//	- readDataInBackground and stopReadInBackground added
//  2004-02-10 Andreas Mayer
//    - replaced notifications for background reading/writing with direct messages to delegate
//      see informal protocol

#import <Foundation/Foundation.h>
#import "AMSerialPort.h"

#define	AMSER_MAXBUFSIZE	4096
#define AMSerialWriteInBackgroundProgressNotification @"AMSerialWriteInBackgroundProgressNotification"
#define AMSerialReadInBackgroundDataNotification @"AMSerialReadInBackgroundDataNotification"


@interface NSObject (AMSerialDelegate)
- (void)serialPortReadData:(NSDictionary *)dataDictionary;
- (void)serialPortWriteProgress:(NSDictionary *)dataDictionary;
@end


@interface AMSerialPort (AMSerialPortAdditions)

// returns the number of bytes available in the input buffer
- (int)checkRead;

- (void)waitForInput:(id)target selector:(SEL)selector;

// reads up to AMSER_MAXBUFSIZE bytes from the input buffer
- (NSString *)readString;

// write string to the serial port
- (int)writeString:(NSString *)string;


- (void)readDataInBackground;
//
// Will send serialPortReadData: to delegate
// the dataDictionary object will contain these entries:
// 1. "serialPort": the AMSerialPort object that sent the message
// 2. "data": (NSData *)data - received data

- (void)stopReadInBackground;

- (void)writeDataInBackground:(NSData *)data;
//
// Will send serialPortWriteProgress: to delegate if task lasts more than
// approximately three seconds.
// the dataDictionary object will contain these entries:
// 1. "serialPort": the AMSerialPort object that sent the message
// 2. "value": (NSNumber *)value - bytes sent
// 3. "total": (NSNumber *)total - bytes total

- (void)stopWriteInBackground;

- (int)numberOfWriteInBackgroundThreads;


@end
