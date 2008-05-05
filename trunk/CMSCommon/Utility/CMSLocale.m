//
//  CMSLocale.m
//  
//
//  Created by Ryan on 1/25/08.
//  Copyright 2008 Chimoosoft. All rights reserved.
//

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
