//
//  Speech.h
//  SpeechToggle
//
//  Created by Ryan Poling on 5/5/2008.
//  Copyright 2008 Chimoosoft. All rights reserved.
//
//  Handles enabling, disabling, and testing of speech recognition.

#import <Cocoa/Cocoa.h>


@interface Speech : NSObject {

}

- (BOOL)enableSpeechRegonition;
- (BOOL)disableSpeechRegonition;
- (BOOL)isSpeechRecognitionOn;

@end
