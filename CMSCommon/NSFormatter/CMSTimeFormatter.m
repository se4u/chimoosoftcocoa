//
//  CMSTimeFormatter.m
//
//  Created by Ryan Poling on 1/16/07.
//  Copyright 2007 Chimoosoft. All rights reserved.
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



#import "CMSTimeFormatter.h"

@interface CMSTimeFormatter (Private) 

- (NSString*)fullSecondsForm;
- (NSString*)speakableForm;
- (NSString *)naturalForm;

@end

@implementation CMSTimeFormatter

- (id)init {
	if (self = [super init]) {
		format = HMS;
		showSecondFractions = YES;
		
		useCeil = NO;
		
		totalTime = 0.0;
		hours = 0;
		minutes = 0;
		seconds = 0;
		doubleSeconds = 0.0;
	}	
    return self;	
}

- (void)setUseCeil:(BOOL)b { useCeil = b; }
- (void)setUseHMSFormat:(BOOL)b { format = HMS; }
- (void)setUseFullSeconds:(BOOL)b { format = FULL_SEC; }
- (void)setUseSpeakableFormat:(BOOL)b { format = SPEAKABLE; }
- (void)setUseNaturalFormat:(BOOL)b { format = NATURAL; }
- (void)setUseSecondsOnly:(BOOL)b { format = SEC_ONLY; }

- (void)setShowSecondFractions:(BOOL)b { showSecondFractions = b; }


// Should be passed a number of seconds as a number.
- (NSString *)stringForObjectValue:(id)anObject {	
	totalTime = [anObject doubleValue];		// Seconds; not factored into HMS.
	
	doubleSeconds = fmod(totalTime, 60.0);
	
	if (useCeil && (!showSecondFractions)) totalTime = ceil(totalTime);
	
	seconds = (int)floor(totalTime);

	minutes = (int)floor(seconds / 60.0);
	seconds = fmod(seconds, 60.0);	
	hours =	(int)floor(minutes / 60.0);
	minutes = fmod(minutes, 60.0);
	hours = fmod(hours, 60.0);		
		
	switch (format) {
	case HMS:
		if (showSecondFractions) return [NSString stringWithFormat:@"%02i:%02i:%04.1f", hours, minutes, doubleSeconds];
		else return [NSString stringWithFormat:@"%02i:%02i:%02i", hours, minutes, seconds];
		break;
	case FULL_SEC:
		return [self fullSecondsForm];
		break;
	case SPEAKABLE:
		return [self speakableForm];
		break;
	case NATURAL:
		return [self naturalForm];
		break;
	case SEC_ONLY:
		return [self secondsOnlyForm];
		break;
	}
	
	return [self fullSecondsForm];

}


// A form which can be spoken out loud.
- (NSString*)speakableForm {
	NSString *hString;
	NSString *mString;
	NSString *sString;
		
	if (hours == 1) hString = NSLocalizedStringFromTable(@"hour", @"CMSDateTimeStrings", @""); else hString = NSLocalizedStringFromTable(@"hours", @"CMSDateTimeStrings", @"");
	if (minutes == 1) mString = NSLocalizedStringFromTable(@"minute", @"CMSDateTimeStrings", @""); else mString = NSLocalizedStringFromTable(@"minutes", @"CMSDateTimeStrings", @"");
	if (showSecondFractions && (doubleSeconds > 1.0)) sString = NSLocalizedStringFromTable(@"seconds", @"CMSDateTimeStrings", @"");
	else if (seconds == 1) sString = NSLocalizedStringFromTable(@"second", @"CMSDateTimeStrings", @""); else sString = NSLocalizedStringFromTable(@"seconds", @"CMSDateTimeStrings", @"");
	
	NSMutableString * string = [NSMutableString stringWithCapacity:20];
	if (hours > 0) [string appendFormat:@"%d %@, ", hours, hString];
	if (minutes > 0) [string appendFormat:@"%d %@, ", minutes, mString];
	if (doubleSeconds > 0.0) {
		if (showSecondFractions) [string appendFormat:@"%4.1f %@", doubleSeconds, sString];
		else [string appendFormat:@"%i %@", seconds, sString];		
	}
	
	if ((hours == 0) && (minutes == 0) && (doubleSeconds <= 0.0)) {
		string = [NSMutableString stringWithString:NSLocalizedStringFromTable(@"NoTimeElapsed", @"CMSDateTimeStrings", @"")];
	}
	
	return string;
}

- (NSString *)naturalForm {
	NSString *hString;
	NSString *mString;
	NSString *sString;
	
	if (hours == 1) hString = NSLocalizedStringFromTable(@"hour", @"CMSDateTimeStrings", @""); else hString = NSLocalizedStringFromTable(@"hours", @"CMSDateTimeStrings", @"");
	if (minutes == 1) mString = NSLocalizedStringFromTable(@"minute", @"CMSDateTimeStrings", @""); else mString = NSLocalizedStringFromTable(@"minutes", @"CMSDateTimeStrings", @"");
	if (showSecondFractions && (doubleSeconds > 1.0)) sString = NSLocalizedStringFromTable(@"seconds", @"CMSDateTimeStrings", @"");
	else if (seconds == 1) sString = NSLocalizedStringFromTable(@"second", @"CMSDateTimeStrings", @""); else sString = NSLocalizedStringFromTable(@"seconds", @"CMSDateTimeStrings", @"");
	
	NSMutableString * string = [NSMutableString stringWithCapacity:20];
	if (hours > 0) [string appendFormat:@"%d %@, ", hours, hString];
	if (minutes > 0) [string appendFormat:@"%d %@, ", minutes, mString];
	if (doubleSeconds > 0.0) {
		if (showSecondFractions) [string appendFormat:@"%4.1f %@", doubleSeconds, sString];
		else [string appendFormat:@"%i %@", seconds, sString];		
	}
	
	if ((hours == 0) && (minutes == 0) && (seconds <= 0.0)) {
		string = [NSMutableString stringWithString:NSLocalizedStringFromTable(@"NoTimeElapsed", @"CMSDateTimeStrings", @"")];
	}
	
	return string;	
}

- (NSString*)fullSecondsForm {
	if (showSecondFractions) return [NSString stringWithFormat:@"%.1f", totalTime];
	else return [NSString stringWithFormat:@"%i", (int)totalTime];
}

- (NSString*)secondsOnlyForm {
	return [NSString stringWithFormat:@"%i", seconds];
}

- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error {
	
	return YES;
}



@end
