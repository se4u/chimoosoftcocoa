//
//  CMSTimeFormatter.h
//  ChimooTimer
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


#import <Foundation/Foundation.h>

// FULL_SEC means the time represented in seconds.
// SEC_ONLY means only show the seconds, leaving off minutes, hours, etc.

typedef enum {
	NATURAL		= 1001,
	SPEAKABLE	= 1002,
	SEC_ONLY	= 1003,
	HMS			= 1004,
	FULL_SEC	= 1005
} FormatType;


@interface CMSTimeFormatter : NSFormatter {
	BOOL showSecondFractions;
	BOOL useCeil;

	FormatType format;

	double totalTime;
	
	int hours;
	int minutes;
	int seconds;
	double doubleSeconds;
}

- (id)init;

- (NSString *)stringForObjectValue:(id)anObject;
- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error;

- (void)setUseCeil:(BOOL)b;
- (void)setShowSecondFractions:(BOOL)b;

- (void)setUseHMSFormat:(BOOL)b;
- (void)setUseSpeakableFormat:(BOOL)b;
- (void)setUseSecondsOnly:(BOOL)b;
- (void)setUseNaturalFormat:(BOOL)b;

- (NSString*)secondsOnlyForm;

@end
