//
//  Speech.m
//  SpeechToggle
//
//  Created by Ryan on 5/5/2008.
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



#import "Speech.h"


@implementation Speech

- (BOOL)enableSpeechRegonition {
	// Not an ideal way to do this.
	
	NSTask * task = [[NSTask alloc] init];
	[task setLaunchPath:@"/usr/bin/open"];
	[task setArguments:[NSArray arrayWithObjects:@"/System/Library/Speech/Recognizers/AppleSpeakableItems.SpeechRecognizer/Contents/Resources/SpeakableItems.app/", nil]];
	[task launch];
	[task release];	
	
	return YES;		// Just assume it worked for now - fix this later.
}

- (BOOL)disableSpeechRegonition {
	// Not an ideal way to do this.
	
	NSTask * task = [[NSTask alloc] init];
	[task setLaunchPath:@"/usr/bin/perl"];
	[task setArguments:[NSArray arrayWithObjects:[NSString stringWithFormat:@"%@/Contents/Resources/kill.pl", [[NSBundle mainBundle] bundlePath]], nil]];
	[task launch];
	[task release];
	
	return YES;		// Just assume it worked for now - fix this later.
	
}

- (BOOL)isSpeechRecognitionOn {
	NSTask * task = [[NSTask alloc] init];
	[task setLaunchPath:@"/usr/bin/perl"];
	[task setArguments:[NSArray arrayWithObjects:[NSString stringWithFormat:@"%@/Contents/Resources/isrunning.pl", [[NSBundle mainBundle] bundlePath]], nil]];
	[task launch];
	[task waitUntilExit];
	
	BOOL isRunning = ([task terminationStatus] == 1);
	
	[task release];
	
	return isRunning;		
}


@end
