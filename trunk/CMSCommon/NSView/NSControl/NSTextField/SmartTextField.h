//
//  SmartTextField.h
//
//  Created by Ryan on Sat Sep 27 2003.
//
//  Subclass of NSTextField which has the ability to open a URL
//  in the user's web browser when the user clicks on it and also underlines
//  the url appropriately.

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


#import <Cocoa/Cocoa.h>

@class Controller;

@interface SmartTextField : NSTextField {
	BOOL showURL;
	BOOL useOwnURL;
	
	NSURL * userSetURL;
}

- (id)initWithFrame:(NSRect)frameRect;

// Goes to the URL contained in the textfield itself
- (IBAction)gotoOwnURL:(id)sender;

// Should we open a URL when the user clicks on the link
// and underline the link when the mouse passes over it?
- (void)setShowURL:(BOOL)b;

// If true, then use the text of the textfield itself as the URL.
- (void)setUsesOwnURL:(BOOL)b;

// URLtoShow when clicked on.  Automatically set to show it.
- (void)setURLToShow:(NSURL *)url;
- (void)setURLWithString:(NSString *)s;

- (void)mouseDown:(NSEvent *)event;

// The url it will show.
- (NSURL*)url;

@end
