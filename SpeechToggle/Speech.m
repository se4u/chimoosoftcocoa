//
//  Speech.m
//  SpeechToggle
//
//  Created by Ryan Poling on 5/5/2008.
//  Copyright 2008 Chimoosoft. All rights reserved.
//

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
