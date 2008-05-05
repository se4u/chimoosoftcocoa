//
//  Controller.m
//  SpeechToggle
//
//  Created by Ryan on 12/12/06.
//  Copyright 2007 Chimoosoft. All rights reserved.
//

#import "Controller.h"
#import "CMSCommon.h"
#import "CMSDefaults.h"
#import "Speech.h"

#define PRODUCT_NAME @"Speech Toggle"
#define PRODUCT_URL @"http://www.chimoosoft.com/products/speechtoggle/"

@interface Controller ()

- (void)destroyTimer;
- (void)doUpdate:(NSTimer*)theTimer;
- (void)setImageStatus:(BOOL)b;

@end


@implementation Controller

- (id) init {
	self = [super init];
	if (self != nil) {
		#if DEBUG
		NSLog(@"Debug Mode Enabled");
		#endif
		
		[CMSCommon quitIfNotTiger];
		
		_defaults = [[NSUserDefaults standardUserDefaults] retain];
		_speech = [[Speech alloc] init];
	}
	return self;
}

- (void)dealloc {
	[self destroyTimer];
	[_defaults release];
	[_speech release];
	
	[super dealloc];
}



- (void)awakeFromNib {
	// Set up the menu item.
	
	statusBar = [[NSStatusBar systemStatusBar] retain];	
	statusItem = [[statusBar statusItemWithLength:20.0] retain];
	[statusItem setImage:[NSImage imageNamed:@"menuiconoff"]];
	[statusItem setAlternateImage:[NSImage imageNamed:@"menuiconinvert"]];
	[statusItem setHighlightMode:YES];
	[statusItem setMenu:menu];
	
	// Every ten seconds, check if speech recognition is enabled.  There's probably a better way
	// to do this, but at least this update frequency shouldn't bog the system down.
	_updateTimer = [[NSTimer scheduledTimerWithTimeInterval:10.0
													 target:self
												   selector:@selector(doUpdate:)
												   userInfo:nil
													repeats:YES] retain];
	
	[self doUpdate:nil];
	
}


- (void)doUpdate:(NSTimer*)theTimer {
	[self setImageStatus:[_speech isSpeechRecognitionOn]];
}

- (void)setImageStatus:(BOOL)b {
	if (b) [statusItem setImage:[NSImage imageNamed:@"menuiconon"]];
	else [statusItem setImage:[NSImage imageNamed:@"menuiconoff"]];	
}

- (IBAction)enableSpeechRecognition:(id)sender {
	[_speech enableSpeechRecognition];
	
	[_updateTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:5.0]];
}

- (IBAction)disableSpeechRecognition:(id)sender {
	[_speech disableSpeechRecognition];
	[_updateTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:2.0]];
}


- (IBAction)toggleSpeechRecognition:(id)sender {
	if ([_speech isSpeechRecognitionOn]) [self disableSpeechRecognition:sender];
	else [self enableSpeechRecognition:sender];
}

// from http://developer.apple.com/technotes/tn2006/tn2084.html
- (IBAction)addLoginItem:(id)sender {
	// Probably a better way to do this too.
	
	NSDictionary* errorDict;
	NSAppleEventDescriptor* returnDescriptor = NULL;

	NSAppleScript* scriptObject = [[NSAppleScript alloc] initWithSource:
		@"\
		set app_path to path to me\n\
		tell application \"System Events\"\n\
		if \"AddLoginItem\" is not in (name of every login item) then\n\
		make login item at end with properties {hidden:false, path:app_path}\n\
		end if\n\
		end tell"];

	returnDescriptor = [scriptObject executeAndReturnError: &errorDict];
	[scriptObject release];

	if (returnDescriptor != NULL) {
		// successful execution
		if (kAENullEvent != [returnDescriptor descriptorType]) {
			// script returned an AppleScript result
			if (cAEList == [returnDescriptor descriptorType]) {
				 // result is a list of other descriptors
			} else {
				// coerce the result to the appropriate ObjC type
			}
		}
	}
	else {
		// no script result, handle error here
	}
}

- (BOOL)validateMenuItem:(NSMenuItem*)anItem {
	int tag = [anItem tag];
	
	BOOL isOn = [_speech isSpeechRecognitionOn];
	[self setImageStatus:isOn];
	
	switch (tag) {
		case 1000:	
			if (isOn) [anItem setTitle:@"Speech Recognition: On"];
			else [anItem setTitle:@"Speech Recognition: Off"];
			return NO;
			break;
		case 1001:
			if (isOn) [anItem setTitle:@"Turn Speech Recognition Off"];
			else [anItem setTitle:@"Turn Speech Recognition On"];
			break;
	}
	
	return YES;
}

- (IBAction)sendFeedback:(id)sender {
	[CMSCommon sendFeedbackForProduct:PRODUCT_NAME];
}

- (IBAction)openURLForTitle:(id)sender {
	if (sender == mailToButton) {
		[self sendFeedback:self];
	} else {
		[CMSCommon openURLFromString:[sender alternateTitle]];
	}
}

- (IBAction)openAboutBox:(id)sender {
	[aboutBox orderFrontRegardless];
}

- (IBAction)openSpeechPreferences:(id)sender {
	NSAppleEventDescriptor * d = [CMSCommon runCompiledAppleScriptInBundle:@"openspeech"
																  matching:@"3238130d6ca04382353e630767f4c3fd"];
}

- (void)destroyTimer {
	[_updateTimer invalidate];
	[_updateTimer release];
	_updateTimer = nil;
}


- (IBAction)donateWebPage:(id)sender {
	[CMSCommon openDonationPage];
}


// Delegate methods for CMSVersioning
- (NSURL*)productURL {
	return [NSURL URLWithString:PRODUCT_URL];
}


@end
