//
//  AMSerialPort.m
//  CommX
//
//  Created by Andreas on 2002-04-24.
//  Copyright (c) 2001 Andreas Mayer. All rights reserved.
//
//  2002-09-18 Andreas Mayer
//  - added available & owner
//  2002-10-10 Andreas Mayer
//	- some log messages changed
//  2002-10-25 Andreas Mayer
//	- additional locks and other changes for reading and writing in background
//  2003-11-26 James Watson
//	- in dealloc [self close] reordered to execute before releasing closeLock


#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <paths.h>
#include <termios.h>
#include <sys/time.h>
#include <sysexits.h>
#include <sys/param.h>

#import "AMSerialPort.h"

@implementation AMSerialPort

- (id)init:(NSString *)path withName:(NSString *)name
	// path is a bsdPath
	// name is an IOKit service name
{
	[super init];
	bsdPath = malloc([path cStringLength]);
	strcpy(bsdPath, [path cString]);
	serviceName = [name retain];
	optionsDictionary = [[NSMutableDictionary dictionaryWithCapacity:8] retain];
	options = malloc(sizeof(*options));
	originalOptions = malloc(sizeof(*originalOptions));
	//buffer = malloc(AMSER_MAXBUFSIZE);
	timeout = malloc(sizeof(*timeout));
	readfds = malloc(sizeof(*readfds));
	fileDescriptor = -1;
	
	writeLock = [[NSLock alloc] init];
	stopWriteInBackgroundLock = [[NSLock alloc] init];
	countWriteInBackgroundThreadsLock = [[NSLock alloc] init];
	readLock = [[NSLock alloc] init];
	stopReadInBackgroundLock = [[NSLock alloc] init];
	countReadInBackgroundThreadsLock = [[NSLock alloc] init];
	closeLock = [[NSLock alloc] init];
	
	return self;
}

- (void)dealloc;
{
	if (fileDescriptor != -1)
		[self close];
	
	[countReadInBackgroundThreadsLock release];
	[stopReadInBackgroundLock release];
	[readLock release];
	[countWriteInBackgroundThreadsLock release];
	[stopWriteInBackgroundLock release];
	[writeLock release];
	[closeLock release];
	
	free(readfds);
	free(timeout);
	//free(buffer);
	free(originalOptions);
	free(options);
	[optionsDictionary release];
	[serviceName release];
	free(bsdPath);
	[super dealloc];
}


- (id)delegate
{
	return delegate;
}

- (void)setDelegate:(id)newDelegate
{
	id old = nil;
	
	// *********
	// 12/2007 - Yikes - are these supposed to be retained??
	if (newDelegate != delegate) {
		old = delegate;
		delegate = [newDelegate retain];
		[old release];
		delegateHandlesReadInBackground = [delegate respondsToSelector:@selector(serialPortReadData:)];
		delegateHandlesWriteInBackground = [delegate respondsToSelector:@selector(serialPortWriteProgress:)];
	}
}


- (NSString *)bsdPath
{
	return [NSString stringWithCString:bsdPath];
}

- (NSString *)name
{
	return serviceName;
}

- (BOOL)isOpen
{
	// YES if port is open
	return (fileDescriptor >= 0);
}

- (AMSerialPort *)obtainBy:(id)sender
{
	// get this port exclusively; NULL if it's not free
	if (owner == nil) {
		owner = sender;
		return self;
	} else
		return nil;
}

- (void)free
{
	// give it back
	owner = nil;
	[self close];	// you never know ...
}

- (BOOL)available
{
	// check if port is free and can be obtained
	return (owner == nil);
}

- (id)owner
{
	// who obtained the port?
	return owner;
}


- (NSFileHandle *)open		// use returned file handle to read and write
{
	fileDescriptor = open(bsdPath, O_RDWR | O_NOCTTY); // | O_NONBLOCK);
	NSLog(@"open %s (%d)\n", bsdPath, fileDescriptor);
	
	if (fileDescriptor < 0)
	{
		NSLog(@"Error opening serial port %s - %s(%d).\n", bsdPath, strerror(errno), errno);
		goto error;
	}
	
	/*
	 if (fcntl(fileDescriptor, F_SETFL, fcntl(fileDescriptor, F_GETFL, 0) & !O_NONBLOCK) == -1)
	 {
		 NSLog(@"Error clearing O_NDELAY %s - %s(%d).\n", bsdPath, strerror(errno), errno);
		 goto error;
	 }
	 */
	
	// Get the current options and save them for later reset
	if (tcgetattr(fileDescriptor, originalOptions) == -1)
	{
		NSLog(@"Error getting tty attributes %s - %s(%d).\n", bsdPath, strerror(errno), errno);
		goto error;
	}
	// Get a copy for local options
	tcgetattr(fileDescriptor, options);
	
	// Success
	fileHandle = [[NSFileHandle alloc] initWithFileDescriptor:fileDescriptor closeOnDealloc:YES];
	//NSLog(@"fileHandle retain count: %d\n", [fileHandle retainCount]);
	return fileHandle;
	
	// Failure path
error:
    if (fileDescriptor >= 0)
			close(fileDescriptor);
	fileDescriptor = -1;
	
	return NULL;
}


- (void)close
{
	//int err;
	// Traditionally it is good to reset a serial port back to
	// the state in which you found it.  Let's continue that tradition.
	if (fileDescriptor >= 0) {
		//NSLog(@"close - attempt closeLock");
		[closeLock lock];
		//NSLog(@"close - closeLock locked");
		// kill pending read by setting O_NONBLOCK
		if (fcntl(fileDescriptor, F_SETFL, fcntl(fileDescriptor, F_GETFL, 0) | O_NONBLOCK) == -1)
		{
			NSLog(@"Error clearing O_NONBLOCK %s - %s(%d).\n", bsdPath, strerror(errno), errno);
			//goto error;
		}
		
		if (tcsetattr(fileDescriptor, TCSANOW, originalOptions) == -1)
		{
			NSLog(@"Error resetting tty attributes - %s(%d).\n", 				strerror(errno), errno);
		}
		
		if (readTimer != NULL)	// ob das so richtig ist? :-/
		{
			[readTarget release];
			[readTimer release];
		}
		//NSLog([NSString stringWithFormat:@"AMSerialPort - close(1): fileHandle retain count: %d", [fileHandle retainCount]]);
		[fileHandle closeFile];
		//NSLog([NSString stringWithFormat:@"AMSerialPort - close(2): fileHandle retain count: %d", [fileHandle retainCount]]);
		if ([fileHandle retainCount] > 1)
			NSLog(@"possibly leaking fileHandle (%d)\n", fileDescriptor);
		[fileHandle release];
		//NSLog([NSString stringWithFormat:@"AMSerialPort - close(2): fileHandle released"]);
		NSLog(@"close (%d)\n", fileDescriptor);
		close(fileDescriptor);
		//err = close(fileDescriptor); // OS X 10.2 does not release DTR anymore. Bug?
		//NSLog([NSString stringWithFormat:@"close(%i) result: %i\n", fileDescriptor, err]);
		
		fileDescriptor = -1;
		[closeLock unlock];
		//NSLog(@"close - closeLock unlocked");
	}
}

-(void)drainInput
{
	tcdrain(fileDescriptor);
}

-(void)flushInput:(bool)fIn Output:(bool)fOut	// (fIn or fOut) must be YES
{
	int mode = 0;
	if (fIn == YES)
		mode = TCIFLUSH;
	if (fOut == YES)
		mode = TCOFLUSH;
	if (fIn && fOut)
		mode = TCIOFLUSH;
	
	tcflush(fileDescriptor, mode);
}

-(void)sendBreak
{
	tcsendbreak(fileDescriptor, 0);
}


// read and write serial port settings through a dictionary

- (void)buildOptionsDictionary
{
	[optionsDictionary removeAllObjects];
	[optionsDictionary setObject:[self name]
												forKey:AMSerialOptionServiceName];
	[optionsDictionary setObject:[NSString stringWithFormat:@"%d", [self getSpeed]]
												forKey:AMSerialOptionSpeed];
	[optionsDictionary setObject:[NSString stringWithFormat:@"%d", [self getDataBits]]
												forKey:AMSerialOptionDataBits];
	if ([self testParity]) {
		if ([self testParityOdd]) {
			[optionsDictionary setObject:@"Odd" forKey:AMSerialOptionParity];
		} else {
			[optionsDictionary setObject:@"Even" forKey:AMSerialOptionParity];
		}
	}
	
	[optionsDictionary setObject:[NSString stringWithFormat:@"%d", [self getStopBits]]
												forKey:AMSerialOptionStopBits];
	if ([self testRTSInputFlowControl])
		[optionsDictionary setObject:@"RTS" forKey:AMSerialOptionInputFlowControl];
	if ([self testDTRInputFlowControl])
		[optionsDictionary setObject:@"DTR" forKey:AMSerialOptionInputFlowControl];
	
	if ([self testCTSOutputFlowControl])
		[optionsDictionary setObject:@"CTS" forKey:AMSerialOptionOutputFlowControl];
	if ([self testDSROutputFlowControl])
		[optionsDictionary setObject:@"DSR" forKey:AMSerialOptionOutputFlowControl];
	if ([self testCAROutputFlowControl])
		[optionsDictionary setObject:@"CAR" forKey:AMSerialOptionOutputFlowControl];
	
	if ([self testEchoEnabled])
		[optionsDictionary setObject:@"YES" forKey:AMSerialOptionEcho];
	
}


- (NSDictionary *)getOptions
{
	// will open the port to get options if neccessary
	if ([optionsDictionary objectForKey:AMSerialOptionServiceName] == nil)
	{
		if (fileHandle < 0) {
			[self open];
			[self close];
		}
		[self buildOptionsDictionary];
	}
	return [NSMutableDictionary dictionaryWithDictionary:optionsDictionary];
}

- (void)setOptions:(NSDictionary *)newOptions
{
	// AMSerialOptionServiceName HAS to match! You may NOT switch ports using this
	// method.
	NSString *temp;
	
	if ([(NSString *)[newOptions objectForKey:AMSerialOptionServiceName] 							isEqualToString:[self name]])
	{
		[optionsDictionary addEntriesFromDictionary:newOptions];
		// parse dictionary
		temp = (NSString *)[optionsDictionary objectForKey:AMSerialOptionSpeed];
		[self setSpeed:[temp intValue]];
		
		temp = (NSString *)[optionsDictionary objectForKey:AMSerialOptionDataBits];
		[self setDataBits:[temp intValue]];
		
		temp = (NSString *)[optionsDictionary objectForKey:AMSerialOptionParity];
		if (temp == nil)
			[self setParityNone];
		else
			if ([temp isEqualToString:@"Odd"])
				[self setParityOdd];
		else
			[self setParityEven];
		
		temp = (NSString *)[optionsDictionary objectForKey:AMSerialOptionStopBits];
		[self setStopBits2:([temp intValue] == 2)];
		
		temp = (NSString *)[optionsDictionary objectForKey:AMSerialOptionInputFlowControl];
		[self setRTSInputFlowControl:[temp isEqualToString:@"RTS"]];
		[self setDTRInputFlowControl:[temp isEqualToString:@"DTR"]];
		
		temp = (NSString *)[optionsDictionary objectForKey:AMSerialOptionOutputFlowControl];
		[self setCTSOutputFlowControl:[temp isEqualToString:@"CTS"]];
		[self setDSROutputFlowControl:[temp isEqualToString:@"DSR"]];
		[self setCAROutputFlowControl:[temp isEqualToString:@"CAR"]];
		
		temp = (NSString *)[optionsDictionary objectForKey:AMSerialOptionEcho];
		[self setEchoEnabled:(temp != nil)];
		
		[self commitChanges];
	} else
		NSLog(@"Error setting options for port %s (wrong port name: %s).\n", [self name], [newOptions objectForKey:AMSerialOptionServiceName]);
}


-(long)getSpeed
{
	return cfgetospeed(options);	// we should support cfgetispeed too
}

-(void)setSpeed:(long)speed
{
	cfsetospeed(options, speed);
	cfsetispeed(options, 0);		// same as output speed
	// we should support setting input and output speed separately
}


-(int)getDataBits
{
	return 5 + ((options->c_cflag & CSIZE) >> 8);
	// man ... I *hate* C syntax ...
}

-(void)setDataBits:(int)bits	// 5 to 8 (5 is marked as "(pseudo)")
{
	// ?? options->c_oflag &= ~OPOST;
	options->c_cflag &= ~CSIZE;
	switch (bits)
	{
		case 5:	options->c_cflag |= CS5;	// redundant since CS5 == 0
			break;
		case 6:	options->c_cflag |= CS6;
			break;
		case 7:	options->c_cflag |= CS7;
			break;
		case 8:	options->c_cflag |= CS8;
			break;
	}
}


-(bool)testParity
{
	// NO for "no parity"
	return (options->c_cflag & PARENB);
}

-(bool)testParityOdd
{
	// meaningful only if TestParity == YES
	return (options->c_cflag & PARODD);
}

-(void)setParityNone
{
	options->c_cflag &= ~PARENB;
}

-(void)setParityEven
{
	options->c_cflag |= PARENB;
	options->c_cflag &= ~PARODD;
}

-(void)setParityOdd
{
	options->c_cflag |= PARENB;
	options->c_cflag |= PARODD;
}


-(int)getStopBits
{
	if (options->c_cflag & CSTOPB)
		return 2;
	else
		return 1;
}

-(void)setStopBits2:(bool)two	// one else
{
	if (two)
		options->c_cflag |= CSTOPB;
	else
		options->c_cflag &= ~CSTOPB;
}


-(bool)testEchoEnabled
{
	return (options->c_lflag & ECHO);
}

-(void)setEchoEnabled:(bool)echo
{
	if (echo == YES)
		options->c_lflag |= ECHO;
	else
		options->c_lflag &= ~ECHO;
}

-(bool)testRTSInputFlowControl
{
	return (options->c_cflag & CRTS_IFLOW);
}

-(void)setRTSInputFlowControl:(bool)rts
{
	if (rts == YES)
		options->c_cflag |= CRTS_IFLOW;
	else
		options->c_cflag &= ~CRTS_IFLOW;
}


-(bool)testDTRInputFlowControl
{
	return (options->c_cflag & CDTR_IFLOW);
}

-(void)setDTRInputFlowControl:(bool)dtr
{
	if (dtr == YES)
		options->c_cflag |= CDTR_IFLOW;
	else
		options->c_cflag &= ~CDTR_IFLOW;
}


-(bool)testCTSOutputFlowControl
{
	return (options->c_cflag & CCTS_OFLOW);
}

-(void)setCTSOutputFlowControl:(bool)cts
{
	if (cts == YES)
		options->c_cflag |= CCTS_OFLOW;
	else
		options->c_cflag &= ~CCTS_OFLOW;
}


-(bool)testDSROutputFlowControl
{
	return (options->c_cflag & CDSR_OFLOW);
}

-(void)setDSROutputFlowControl:(bool)dsr
{
	if (dsr == YES)
		options->c_cflag |= CDSR_OFLOW;
	else
		options->c_cflag &= ~CDSR_OFLOW;
}


-(bool)testCAROutputFlowControl
{
	return (options->c_cflag & CCAR_OFLOW);
}

-(void)setCAROutputFlowControl:(bool)car
{
	if (car == YES)
		options->c_cflag |= CCAR_OFLOW;
	else
		options->c_cflag &= ~CCAR_OFLOW;
}


-(bool)testHangupOnClose
{
	return (options->c_cflag & HUPCL);
}

-(void)setHangupOnClose:(bool)hangup
{
	if (hangup == YES)
		options->c_cflag |= HUPCL;
	else
		options->c_cflag &= ~HUPCL;
}

- (bool)getLocal
{
	return (options->c_cflag & CLOCAL);
}

- (void)setLocal:(bool)local	// YES = ignore modem status lines
{
	if (local == YES)
		options->c_cflag |= CLOCAL;
	else
		options->c_cflag &= ~CLOCAL;
}


-(bool)commitChanges
{
	// call this after using any of the above Set functions
	if (tcsetattr(fileDescriptor, TCSANOW, options) == -1)
	{
		// something went wrong
		lastError = errno;
		return NO;
	}
	else
	{
		[self buildOptionsDictionary];
		return YES;
	}
}

-(int)errorCode
{
	// if CommitChanges returns NO, look here for further info
	return lastError;
}


@end
