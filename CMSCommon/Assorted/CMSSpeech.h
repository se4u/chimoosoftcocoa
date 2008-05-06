//
//  CMSSpeech.h
//  ChimooTimer
//
//  Created by Ryan on 1/25/07.
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

#import <Cocoa/Cocoa.h>

@interface CMSSpeech : NSObject {
	NSSpeechSynthesizer * speech;
	NSMutableArray * thingsToSay;
	
	NSString * voiceIdentifier;
	float speechRate;
}

+ (id)sharedInstance;

- (void)setVoiceWithIdentifier:(NSString*)voiceId;
- (void)setRate:(float)rate;

// If speech is not available, this string will never be spoken.
- (void)speakStringIfFree:(NSString*)toSay;

// Speaks the string as soon as it can.
- (void)speakStringWhenFree:(NSString*)toSay;

- (void)stopSpeakingAndSpeakString:(NSString*)toSay;
- (void)stopSpeaking;

- (void)clearSpeechBuffer;
- (void)startCooking;

- (BOOL)isSpeaking;

@end
