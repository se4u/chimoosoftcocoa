//
//  MagellanController.h
//  GPSTest
//
//  Created by Ryan on Sat May 29 2004.
//  Copyright (c) 2004 Chimoosoft. All rights reserved.
//
//  Doesn't do anything yet...  Here to inspire me for the future.

#import <Foundation/Foundation.h>
#import "SerialController.h"

@class xmlElement;

@interface MagellanController : SerialController {
	
	IBOutlet id portMenu;
	IBOutlet id baudMenu;
	
	IBOutlet id connectButton;
	
	IBOutlet NSTextView *outputTextView;
	
	IBOutlet id transferTypeRadios;
	
	NSMutableData * buffer;

}


- (IBAction)connect:(id)sender;
- (IBAction)disconnect:(id)sender;
- (IBAction)download:(id)sender;
- (IBAction)abortTransfer:(id)sender;

- (void)initPort;
- (void)serialPortReadData:(NSDictionary *)dataDictionary;

- (void)dealloc;	

- (void)parseSerialData:(NSData*)d;

@end
