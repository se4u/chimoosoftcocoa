//
//  Controller.h
//  SpeechToggle
//
//  Created by Ryan on 12/12/06.
//  Copyright 2006 Chimoosoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Speech;

@interface Controller : NSObject {
	id statusBar;
	id statusItem;
	id menu;
	IBOutlet id mailToButton;
	IBOutlet id aboutBox;
	
	Speech * _speech;
	NSTimer * _updateTimer;
	NSUserDefaults * _defaults;
}

- (IBAction)enableSpeechRecognition:(id)sender;
- (IBAction)disableSpeechRecognition:(id)sender;
- (IBAction)toggleSpeechRecognition:(id)sender;
- (IBAction)sendFeedback:(id)sender;
- (IBAction)openURLForTitle:(id)sender;
- (IBAction)openSpeechPreferences:(id)sender;
- (IBAction)addLoginItem:(id)sender;
- (IBAction)donateWebPage:(id)sender;

- (IBAction)openAboutBox:(id)sender;


// Delegates for CMSVersioning.
- (NSURL*)productURL;

@end
