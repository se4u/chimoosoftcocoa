//
//  CMSDefaults.m
//
//  Created by Ryan on 3/1/07.
//  Copyright 2007 Chimoosoft. All rights reserved.
//

#import "CMSDefaults.h"


@implementation CMSDefaults


// sets only if not already set
+ (void)setDefaultBool:(BOOL)b forKey:(NSString*)key {
	id defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults objectForKey:key]) return;
	[defaults setBool:b forKey:key];
}

// sets only if not already set
+ (void)setDefaultFloat:(float)f forKey:(NSString*)key {
	id defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults objectForKey:key]) return;
	[defaults setFloat:f forKey:key];
}

// sets only if not already set
+ (void)setDefaultInteger:(int)i forKey:(NSString*)key {
	id defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults objectForKey:key]) return;
	[defaults setInteger:i forKey:key];
}

// sets only if not already set
+ (void)setDefaultObject:(id)o forKey:(NSString*)key {
	id defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults objectForKey:key]) return;	
	if (nil == o) return;
	[defaults setObject:o forKey:key];
}


@end
