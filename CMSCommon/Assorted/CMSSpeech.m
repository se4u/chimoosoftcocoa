//
//  CMSSpeech.m
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

#import "CMSSpeech.h"


@implementation CMSSpeech

static CMSSpeech *sharedInstance = nil;

+ (id)sharedInstance {
	if (sharedInstance == nil) {
		[[self alloc] init]; // assignment not done here
	}
	
	return sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone {
	if (sharedInstance == nil) {
		sharedInstance = [super allocWithZone:zone];
		return sharedInstance;  // assignment and return on first allocation
	}
	
    return nil; //on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id)retain {
    return self;
}

- (unsigned)retainCount {
    return UINT_MAX;  //denotes an object that cannot be released
}

- (void)release {
    //do nothing
}

- (id)autorelease {
    return self;
}

- (id)init {

	[self setupSpeech];
	
	return [super init];
}



- (void)setupSpeech {
	// set up text to speech
	if (nil == thingsToSay) thingsToSay = [[NSMutableArray arrayWithCapacity:5] retain];
	if (nil == speech) {
		speech = [[NSSpeechSynthesizer alloc] initWithVoice:nil];
		[speech setDelegate:self];
	}
}


- (void)setVoiceWithIdentifier:(NSString*)voiceId {
	if ([voiceId isEqualToString:voiceIdentifier]) return;
	
	if (voiceIdentifier != voiceId) {
		[voiceIdentifier release];
		voiceIdentifier = [voiceId retain];
	}
	
	if ([speech isSpeaking]) [speech stopSpeaking];
	if ([voiceId length] > 0) [speech setVoice:voiceId];
	else [speech setVoice:nil];	
}

- (void)setRate:(float)rate {
	if (rate < 50.0) speechRate = 50.0;
	else if (rate > 500.0) speechRate = 500.0;
	else speechRate = rate;
	
	//NSLog(@"rate = %f", rate);
}

// Text-to-speech methods
- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender didFinishSpeaking:(BOOL)success {
	[self tryToSpeak];
}

- (void)tryToSpeak {
	if (([NSSpeechSynthesizer isAnyApplicationSpeaking]) || ([speech isSpeaking])) {
		// try again after a delay.
		[self performSelector:@selector(tryToSpeak) withObject:nil afterDelay:1.5];
	}
	[self speakNext];
}

- (void)speakNext {
	if ([NSSpeechSynthesizer isAnyApplicationSpeaking]) return;
	if ([speech isSpeaking]) return;
	if ([thingsToSay count] < 1) return;
	
	id obj = [thingsToSay objectAtIndex:0];
	[self startSpeakingWrapper:obj];
	[thingsToSay removeObject:obj];
}

- (void)speakStringWhenFree:(NSString*)toSay {
	[thingsToSay addObject:toSay];
	[self tryToSpeak];
}

- (void)startSpeakingWrapper:(NSString*)string {
	NSString * say = [NSString stringWithFormat:@"[[rate %f]]%@", speechRate, string];
	//NSLog(@"about to say %@", say);
	[speech startSpeakingString:say];
}

- (void)speakStringIfFree:(NSString*)toSay {
	if ([speech isSpeaking]) return;
	if ([NSSpeechSynthesizer isAnyApplicationSpeaking]) return;
	
	[self startSpeakingWrapper:toSay];
}

- (void)stopSpeaking {
	[speech stopSpeaking];
}

- (void)stopSpeakingAndSpeakString:(NSString*)toSay {
	[speech stopSpeaking];
	[self startSpeakingWrapper:toSay];
}

- (void)clearSpeechBuffer {
	[speech stopSpeaking];
	[thingsToSay removeAllObjects];
}

- (void)startCooking {
	[speech startSpeakingString:@" "];  // just to get things cooking
}

- (BOOL)isSpeaking {
	return [speech isSpeaking];
}

- (void)dealloc {
	[thingsToSay release];
	[speech release];
	[super dealloc];
}


@end
