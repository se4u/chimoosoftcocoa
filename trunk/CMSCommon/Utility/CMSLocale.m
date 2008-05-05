//
//  CMSLocale.m
//  
//
//  Created by Ryan on 1/25/08.
//  Copyright 2008 Chimoosoft. All rights reserved.
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


#import "CMSLocale.h"


@implementation CMSLocale

+ (NSString*)preferredLocale {	
	NSString * locale = [[NSLocale currentLocale] objectForKey: NSLocaleLanguageCode];
	if (locale) return locale;
	return @"en";
}
/*
+ (NSString*)pluralizeWithBase:(NSString*)base andCount:(int)count {
	if (count == 1) return base;
		
	NSString * format = @"%@";

	// Grab the last letter.
	NSRange lastRange = NSMakeRange([base length] - 1, 1);
	NSString * lastLetter = [base substringWithRange:lastRange];
	
	NSCharacterSet * vowels = [NSCharacterSet characterSetWithCharactersInString:@"aeiou"];
	NSCharacterSet * consonants = [NSCharacterSet characterSetWithCharactersInString:@"bcdfghjklmnpqrstvwxyz"];
	
	// Let the fun begin.
	NSString * locale = [CMSLocale preferredLocale];
	
	if ([locale isEqualToString:@"en"]) {
		// English.
		format = @"%@s";
		
	} else if ([locale isEqualToString:@"es"]) {
		// Spanish.
		if ([lastLetter rangeOfCharacterFromSet:vowels].location != NSNotFound) format = @"%@s";
		
	}
	
	
	return [NSString stringWithFormat:format, base];
}

*/

@end
