//
//  SmartTextField.m
//
//  Created by Ryan on Sat Sep 27 2003.
//
//  ****************
//  Short Disclaimer (please read!):
//
//  Why open source?  This project was briefly popular several years ago and has since lost interest (on both
//  my part and the public's part).  Rather than letting it moulder for eternity, I decided to open source it 
//  in case anyone else is interested in renovating it and bringing it up to date.
//
//  My main concern with open sourcing it is that this program is one of the first Cocoa programs I wrote and
//  as such, it is in no way representative of my current coding style!  Many things are done incorrectly in 
//  this code base but I have not taken the time to revise them for the open source release. Hence, if you work
//  for a company looking to hire me, don't look too critically at this old code!
//
//  This code was originally written in 2002 to 2003 and hence was created before technologies such as 
//  Cocoa Bindings and properties (Obj-C 2.0) existed.  Much of the code could be ripped out and replaced 
//  with the newer way of doing things.
//
//  The GUI is also fairly out of date and in need of some serious updating.
//  
//  Have fun!
//  April, 2008.
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


#import "SmartTextField.h"

@implementation SmartTextField


/* 3/2007 this init never gets called! */

- (id)initWithFrame:(NSRect)frameRect {
	
	self = [super initWithFrame:frameRect];
	if (self != nil) {
		NSLog(@"smart initing");
		showURL = YES;
		useOwnURL = YES;
		userSetURL = nil;
		
		[[self window] setAcceptsMouseMovedEvents: YES];
		
		[self addTrackingRect:[self frame] 
						owner:self
					 userData:nil
				 assumeInside:NO];
	}
	return self;
}




- (void)dealloc {
	[userSetURL release];
	[super dealloc];
}


- (IBAction)gotoOwnURL:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[self stringValue]]];
}

- (void)setShowURL:(BOOL)b { showURL = b; }
- (void)setUsesOwnURL:(BOOL)b { useOwnURL = b; }

- (void)setURLWithString:(NSString *)s { 
	[self setURLToShow:[NSURL URLWithString:s]];
}

- (void)setURLToShow:(NSURL *)url {
	if (userSetURL != url) {
		[userSetURL release];
		userSetURL = [url retain];
	}
	
	useOwnURL = NO;
	
	[self setShowURL: YES]; //set it to show by default.
}


- (NSURL*)url {
	if (useOwnURL) {
		return [NSURL URLWithString:[self stringValue]];
	} else {
		return userSetURL;
	}
}

- (void)mouseDown:(NSEvent *)event {
	//NSLog(@"mousedown: %d", [event clickCount]);
	if (showURL) {
		[[NSWorkspace sharedWorkspace] openURL:[self url]];
	}
}


- (void)mouseEntered:(NSEvent *)event {
	NSLog(@"mouseEntered");
	if (showURL) {
		//underline the text
		//[self underline];
		//[[self textStorage] addAttributes: NSUnderlineStyleAttributeName range: all];
	}
}

- (void)mouseExited:(NSEvent *)event {
	//NSLog(@"mouseExited");
	if (showURL) {
		//remove underlining.
		//[[self textStorage] removeAttributes: NSUnderlineStyleAttributeName range: all];		
	}
}


@end
