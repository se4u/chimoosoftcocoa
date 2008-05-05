//
//  CMSDefaults.h
//
//  Created by Ryan on 3/1/07.
//  Copyright 2007 Chimoosoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CMSDefaults : NSObject {

}

+ (void)setDefaultBool:(BOOL)b forKey:(NSString*)key;
+ (void)setDefaultFloat:(float)f forKey:(NSString*)key;
+ (void)setDefaultInteger:(int)i forKey:(NSString*)key;
+ (void)setDefaultObject:(id)o forKey:(NSString*)key;

@end
