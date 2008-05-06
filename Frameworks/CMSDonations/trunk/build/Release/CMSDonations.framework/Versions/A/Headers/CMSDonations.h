//
//  CMSDonations.h
//  CMSDonations
//
//  Created by Ryan Poling on 12/14/07.
//  Copyright 2007 Chimoosoft. All rights reserved.
//
//  Public Header File
// 
//  Simply call the setupWithDollarCost: class method from within your applicationDidFinishLaunching
//  method, and the CMSDonations framework will take care of *everything* else!

#import <Cocoa/Cocoa.h>

@interface CMSDonations : NSObject {
}

+ (void) setupWithDollarCost:(NSString*)cost;


+ (void) finished;

@end
