//
//  AMSerialPortAdditions.m
//  CommX
//
//  Created by Andreas on Thu May 02 2002.
//  Copyright (c) 2001 Andreas Mayer. All rights reserved.
//
//  2002-07-02 Andreas Mayer
//	- initialize buffer in readString
//  2002-10-04 Andreas Mayer
//  - readDataInBackgroundWithTarget:selector: and writeDataInBackground: added
//  2002-10-10 Andreas Mayer
//	- stopWriteInBackground added
//	- send notifications about sent data through distributed notification center
//  2002-10-17 Andreas Mayer
//	- numberOfWriteInBackgroundThreads added
//	- if total write time will exceed 3 seconds, send
//		CommXWriteInBackgroundProgressNotification without delay
//  2002-10-25 Andreas Mayer
//	- readDataInBackground and stopReadInBackground added

#define AMSerialDebug FALSE


#import "AMSerialPortAdditions.h"


@implementation AMSerialPort (AMSerialPortAdditions)


// ============================================================
#pragma mark -
#pragma mark ━ blocking IO ━
// ============================================================

- (void)doRead:(NSTimer *)timer;
{
#if AMSerialDebug
	NSLog(@"doRead");
#endif
	int res;
	FD_ZERO(readfds);
	FD_SET(fileDescriptor, readfds);
	timeout->tv_sec = 0;
	timeout->tv_usec = 1;
	res = select(fileDescriptor+1, readfds, nil, nil, timeout);
	if (res >= 1)
	{
		[readTarget performSelector:readSelector withObject:[self readString]];
	}
	else
	{
		readTimer = [[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(doRead:) userInfo:self  repeats:NO] retain];
	}
}

-(NSString *)readString
{
#if AMSerialDebug
	NSLog(@"readString");
#endif
	int	len;

	if (buffer == nil)
		buffer = malloc(AMSER_MAXBUFSIZE);

	len = read(fileDescriptor, buffer, AMSER_MAXBUFSIZE);
	return [NSString stringWithCString:buffer length:len];
}

-(int)writeString:(NSString *)string
{
#if AMSerialDebug
	NSLog(@"writeString");
#endif
	return write(fileDescriptor, [string cString], [string cStringLength]);
}

- (int)checkRead
{
#if AMSerialDebug
	NSLog(@"checkRead");
#endif
	FD_ZERO(readfds);
	FD_SET(fileDescriptor, readfds);
	timeout->tv_sec = 0;
	timeout->tv_usec = 1;
	return select(fileDescriptor+1, readfds, nil, nil, timeout);
}

- (void)waitForInput:(id)target selector:(SEL)selector
{
#if AMSerialDebug
	NSLog(@"waitForInput");
#endif
	readTarget = [target retain];
	readSelector = selector;
	if (readTimer != NULL)
		[readTimer release];
	readTimer = [[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(doRead:) userInfo:self repeats:NO] retain];

}

// ============================================================
#pragma mark -
#pragma mark ━ threaded IO ━
// ============================================================

- (void)readDataInBackground
{
#if AMSerialDebug
	NSLog(@"readDataInBackground");
#endif
	if (delegateHandlesReadInBackground) {
		[countReadInBackgroundThreadsLock lock];
		countReadInBackgroundThreads++;
		[countReadInBackgroundThreadsLock unlock];
		[NSThread detachNewThreadSelector:@selector(readDataInBackgroundThread) toTarget:self withObject:nil];
	} else {
		// ... throw exception?
	}
}

- (void)stopReadInBackground
{
#if AMSerialDebug
	NSLog(@"stopReadInBackground");
#endif
	[stopReadInBackgroundLock lock];
	stopReadInBackground = YES;
	//NSLog(@"stopReadInBackground set to YES");
	[stopReadInBackgroundLock unlock];
}

- (void)writeDataInBackground:(NSData *)data
{
#if AMSerialDebug
	NSLog(@"writeDataInBackground");
#endif
	if (delegateHandlesWriteInBackground) {
		[countWriteInBackgroundThreadsLock lock];
		countWriteInBackgroundThreads++;
		[countWriteInBackgroundThreadsLock unlock];
		[NSThread detachNewThreadSelector:@selector(writeDataInBackgroundThread:) toTarget:self withObject:data];
	} else {
		// ... throw exception?
	}
}

- (void)stopWriteInBackground
{
#if AMSerialDebug
	NSLog(@"stopWriteInBackground");
#endif
	[stopWriteInBackgroundLock lock];
	stopWriteInBackground = YES;
	[stopWriteInBackgroundLock unlock];
}

- (int)numberOfWriteInBackgroundThreads
{
	return countWriteInBackgroundThreads;
}


// ============================================================
#pragma mark -
#pragma mark ━ threaded methods ━
// ============================================================

- (void)readDataInBackgroundThread
{
	NSData *data = nil;
	void *localBuffer;
	int bytesRead = 0;
	fd_set *localReadFDs;

#if AMSerialDebug
	NSLog(@"readDataInBackgroundThread: %@", [NSThread currentThread]);
#endif
	localBuffer = malloc(AMSER_MAXBUFSIZE);
	[stopReadInBackgroundLock lock];
	stopReadInBackground = NO;
	//NSLog(@"stopReadInBackground set to NO: %@", [NSThread currentThread]);
	[stopReadInBackgroundLock unlock];
	//NSLog(@"attempt readLock: %@", [NSThread currentThread]);
	[readLock lock];	// write in sequence
	//NSLog(@"readLock locked: %@", [NSThread currentThread]);
	NSAutoreleasePool *localAutoreleasePool = [[NSAutoreleasePool alloc] init];
	localReadFDs = malloc(sizeof(*localReadFDs));
	FD_ZERO(localReadFDs);
	FD_SET(fileDescriptor, localReadFDs);
	int res = select(fileDescriptor+1, localReadFDs, nil, nil, nil); // timeout);
	if (!stopReadInBackground) {
		//NSLog(@"attempt closeLock: %@", [NSThread currentThread]);
		[closeLock lock];
		//NSLog(@"closeLock locked: %@", [NSThread currentThread]);
		if ((res >= 1) && (fileDescriptor >= 0)) {
#if AMSerialDebug
			NSLog(@"attempt read: %@", [NSThread currentThread]);
#endif
			bytesRead = read(fileDescriptor, localBuffer, AMSER_MAXBUFSIZE);
		}
#if AMSerialDebug
		NSLog(@"data read: %@", [NSThread currentThread]);
#endif
		data = [NSData dataWithBytes:localBuffer length:bytesRead];
#if AMSerialDebug
		NSLog(@"send AMSerialReadInBackgroundDataMessage");
#endif
		[delegate performSelectorOnMainThread:@selector(serialPortReadData:) withObject:[NSDictionary dictionaryWithObjectsAndKeys: self, @"serialPort", data, @"data", nil] waitUntilDone:NO];
		[closeLock unlock];
		//NSLog(@"closeLock unlocked: %@", [NSThread currentThread]);
	} else {
#if AMSerialDebug
		NSLog(@"read stopped: %@", [NSThread currentThread]);
#endif
	}

	[readLock unlock];
	//NSLog(@"readLock unlocked: %@", [NSThread currentThread]);
	[countReadInBackgroundThreadsLock lock];
	countReadInBackgroundThreads--;
	[countReadInBackgroundThreadsLock unlock];
	
	free(localReadFDs);
	[localAutoreleasePool release];
	free(localBuffer);
}


- (void)reportProgress:(int)progress withDataLength:length {
#if AMSerialDebug
	NSLog(@"send AMSerialWriteInBackgroundProgressMessage");
#endif
	[delegate performSelectorOnMainThread:@selector(serialPortWriteProgress:) withObject:[NSDictionary dictionaryWithObjectsAndKeys:self, @"serialPort", [NSNumber numberWithInt:progress], @"value", [NSNumber numberWithInt:length], @"total", nil] waitUntilDone:NO];
}



- (void)writeDataInBackgroundThread:(NSData *)data
{
	
#if AMSerialDebug
	NSLog(@"writeDataInBackgroundThread");
#endif
	void *localBuffer;
	unsigned int pos;
	unsigned int bufferLen;
	unsigned int dataLen;
	unsigned int written;
	NSDate *nextNotificationDate;
	BOOL notificationSent = NO;
	long speed;
	long estimatedTime;
	BOOL error = NO;

	
	NSAutoreleasePool *localAutoreleasePool = [[NSAutoreleasePool alloc] init];

	[data retain];
	localBuffer = malloc(AMSER_MAXBUFSIZE);
	[stopWriteInBackgroundLock lock];
	stopWriteInBackground = NO;
	[stopWriteInBackgroundLock unlock];
	[writeLock lock];	// write in sequence
	pos = 0;
	dataLen = [data length];
	speed = [self getSpeed];
	estimatedTime = (dataLen*8)/speed;
	if (estimatedTime > 3) { // will take more than 3 seconds
		notificationSent = YES;
		[self reportProgress:pos withDataLength:dataLen];
		nextNotificationDate = [NSDate dateWithTimeIntervalSinceNow:1.0];
	} else {
		nextNotificationDate = [NSDate dateWithTimeIntervalSinceNow:2.0];
	}
	while (!stopWriteInBackground && (pos < dataLen) && !error) {
		bufferLen = MIN(AMSER_MAXBUFSIZE, dataLen-pos);

		[data getBytes:localBuffer range:NSMakeRange(pos, bufferLen)];
		written = write(fileDescriptor, localBuffer, bufferLen);
		if (error = (written == 0)) // error condition
			break;
		pos += written;

		if ([(NSDate *)[NSDate date] compare:nextNotificationDate] == NSOrderedDescending) {
			if (notificationSent || (pos < dataLen)) { // not for last block only
				notificationSent = YES;
				[self reportProgress:pos withDataLength:dataLen];
				nextNotificationDate = [NSDate dateWithTimeIntervalSinceNow:1.0];
			}
		}
	}
	if (notificationSent) {
		[self reportProgress:pos withDataLength:dataLen];
	}
	[stopWriteInBackgroundLock lock];
	stopWriteInBackground = NO;
	[stopWriteInBackgroundLock unlock];
	[writeLock unlock];
	[countWriteInBackgroundThreadsLock lock];
	countWriteInBackgroundThreads--;
	[countWriteInBackgroundThreadsLock unlock];
	
	free(localBuffer);
	[data release];
	[localAutoreleasePool release];
}


@end
