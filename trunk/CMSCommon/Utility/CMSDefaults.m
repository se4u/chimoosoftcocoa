//
//  CMSDefaults.m
//
//  Created by Ryan on 3/1/07.
//  Copyright 2007 Chimoosoft. All rights reserved.
//
//  Common operations related to files.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.


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
