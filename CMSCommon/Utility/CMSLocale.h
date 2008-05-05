//
//  CMSLocale.h
//  
//
//  Created by Ryan on 1/25/08.
//  Copyright 2008 Chimoosoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CMSLocale : NSObject {

}

// Returns preferred locale code; defaults to en.
+ (NSString*)preferredLocale;

/*

// Attempts to take locale into account.
+ (NSString*)pluralizeWithBase:(NSString*)base andCount:(int)count;
*/

@end
