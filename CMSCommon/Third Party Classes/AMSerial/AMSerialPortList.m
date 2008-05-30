//
//  AMSerialPortList.m
//  CommX
//
//  Created by Andreas on 2002-04-24.
//  Copyright (c) 2001 Andreas Mayer. All rights reserved.
//
//  2002-09-09 Andreas Mayer
//  - reuse AMSerialPort objects when calling init on an existing AMSerialPortList
//  2002-09-30 Andreas Mayer
//  - added +sharedPortList


#import "AMSerialPortList.h"
#import "AMSerialPort.h"
#import "AMStandardEnumerator.h"

#include <termios.h>

#include <CoreFoundation/CoreFoundation.h>

#include <IOKit/IOKitLib.h>
#include <IOKit/serial/IOSerialKeys.h>
#include <IOKit/IOBSD.h>

static AMSerialPortList *AMSerialPortListSoliton = nil;

@interface AMSerialPortList (Private)
- (NSArray *)oldPortList;
- (void)setOldPortList:(NSArray *)newOldPortList;
@end


@implementation AMSerialPortList


// we do not want more than one instance of this class
+(id)allocWithZone:(NSZone *)zone
{
	if (AMSerialPortListSoliton != nil)
		return AMSerialPortListSoliton;
	else {
		AMSerialPortListSoliton = [super allocWithZone:zone];
		return AMSerialPortListSoliton;
	}
}

+(AMSerialPortList *)sharedPortList
{
	if (AMSerialPortListSoliton != nil)
		return AMSerialPortListSoliton;
	else {
		AMSerialPortListSoliton = [[super alloc] init];
		return AMSerialPortListSoliton;
	}
}

+ (NSEnumerator *)portEnumerator
{
	return [[[AMStandardEnumerator alloc] initWithCollection:[AMSerialPortList sharedPortList] countSelector:@selector(count) objectAtIndexSelector:@selector(objectAtIndex:)] autorelease];
}

// we do not want to deallocate this object 'til the app ends
-(void)dealloc
{
	/*
	[oldPortList release];
	[portList release];
	[super dealloc];
	 */
}


// no copies allowed
+ (id)copyWithZone:(NSZone *)zone;
{
	return self;
}

// nothing to retain ...
- (id)retain
{
    return self;
}

// ... or release
- (oneway void)release
{}

- (id)autorelease
{
    return self;
}

// ---------------------------------------------------------
// - oldPortList:
// ---------------------------------------------------------
- (NSArray *)oldPortList
{
    return oldPortList;
}

// ---------------------------------------------------------
// - setOldPortList:
// ---------------------------------------------------------
- (void)setOldPortList:(NSArray *)newOldPortList
{
    id old = nil;

    if (newOldPortList != oldPortList) {
        old = oldPortList;
        oldPortList = [newOldPortList retain];
        [old release];
    }
}

- (AMSerialPort *)oldPortByPath:(NSString *)bsdPath
{
	AMSerialPort *result = nil;
	AMSerialPort *object;
	NSEnumerator *enumerator;

	enumerator = [oldPortList objectEnumerator];
	while (object = [enumerator nextObject]) {
		if ([[object bsdPath] isEqualToString:bsdPath]) {
			result = object;
			break;
		}
	}
	return result;
}

-(kern_return_t)findSerialPorts:(io_iterator_t *)matchingServices
{
    kern_return_t		kernResult; 
    mach_port_t			masterPort;
    CFMutableDictionaryRef	classesToMatch;

    kernResult = IOMasterPort(MACH_PORT_NULL, &masterPort);
    if (KERN_SUCCESS != kernResult)
    {
        //printf("IOMasterPort returned %d\n", kernResult);
    }
        
    // Serial devices are instances of class IOSerialBSDClient
    classesToMatch = IOServiceMatching(kIOSerialBSDServiceValue);
    if (classesToMatch == NULL)
    {
        //printf("IOServiceMatching returned a NULL dictionary.\n");
    }
    else
        CFDictionarySetValue(classesToMatch,
                            CFSTR(kIOSerialBSDTypeKey),
                            CFSTR(kIOSerialBSDAllTypes));
    
    kernResult = IOServiceGetMatchingServices(masterPort, classesToMatch, matchingServices);    
    if (KERN_SUCCESS != kernResult)
    {
        //printf("IOServiceGetMatchingServices returned %d\n", kernResult);
    }
        
    return kernResult;
}


-(AMSerialPort *)getNextSerialPort:(io_iterator_t)serialPortIterator
//static kern_return_t GetModemPath(io_iterator_t serialPortIterator, char *bsdPath, CFIndex maxPathSize)
{
    io_object_t		serialService;
    AMSerialPort	*result = nil;
    
    if ((serialService = IOIteratorNext(serialPortIterator)))
    {
        CFTypeRef	modemNameAsCFString;
        CFTypeRef	bsdPathAsCFString;

        modemNameAsCFString = IORegistryEntryCreateCFProperty(serialService,
                                                              CFSTR(kIOTTYDeviceKey),
                                                              kCFAllocatorDefault,
                                                              0);
        bsdPathAsCFString = IORegistryEntryCreateCFProperty(serialService,
                                                            CFSTR(kIOCalloutDeviceKey),
                                                            kCFAllocatorDefault,
                                                            0);
        if (modemNameAsCFString && bsdPathAsCFString) {
			result = [self oldPortByPath:(NSString *)bsdPathAsCFString];
			if (result == nil)
				result = [[AMSerialPort alloc] init:(NSString *)bsdPathAsCFString withName:(NSString *)modemNameAsCFString];
		}

        if (modemNameAsCFString)
            CFRelease(modemNameAsCFString);
            
        if (bsdPathAsCFString)
            CFRelease(bsdPathAsCFString);
    
        (void) IOObjectRelease(serialService);
        // We have sucked this service dry of information so release it now.
        return result;
    }
    else
        return NULL;
}


-(id)init
{
    kern_return_t	kernResult; // on PowerPC this is an int (4 bytes)
    /*
     *	error number layout as follows (see mach/error.h):
     *
     *	hi		 		       lo
     *	| system(6) | subsystem(12) | code(14) |
     */
    io_iterator_t	serialPortIterator;
    AMSerialPort	*serialPort;

	if (portList != nil) {
		[self setOldPortList:[NSArray arrayWithArray:portList]];
		[portList removeAllObjects];
	} else {
		[super init];
		portList = [[NSMutableArray array] retain];
	}
		kernResult = [self findSerialPorts:&serialPortIterator];
		do
		{ 
			serialPort = [self getNextSerialPort:serialPortIterator];
			if (serialPort != NULL)
			{
				[portList addObject:serialPort];
			}
		}
		while (serialPort != NULL);
		IOObjectRelease(serialPortIterator);	// Release the iterator.

    return self;
}

-(NSArray *)getPortList;
{
    return [[portList copy] autorelease];
}

-(unsigned)count
{
    return [portList count];
}

-(AMSerialPort *)objectAtIndex:(unsigned)index
{
    return [portList objectAtIndex:index];
}

-(AMSerialPort *)objectWithName:(NSString *)name
{
	AMSerialPort *result = NULL;
	int i;

	for (i=0; i<[portList count]; i++)
    {
        if ([[(AMSerialPort *)[portList objectAtIndex:i] name] isEqualToString:name])
		{
			result = (AMSerialPort *)[portList objectAtIndex:i];
			break;
		}
    }
	return result;
}


@end
