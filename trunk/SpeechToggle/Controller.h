//
//  Controller.h
//  SpeechToggle
//
//  Created by Ryan on 12/12/06.
//  Copyright 2006 Chimoosoft. All rights reserved.
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
