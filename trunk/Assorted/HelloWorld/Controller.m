//
//  Controller.m
//  HelloWorld
//
//  Created by Ryan on 12/17/07.
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


#import "Controller.h"


@implementation Controller

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	NSWindow * window = [textField window];
	
	[window setFrame:NSMakeRect(400.0, 400.0, 600.0, 200.0) display:YES animate:YES];

	[[textField animator] setFrame:[[window contentView] frame]];
	[[textField animator] setFont:[NSFont fontWithName:@"Zapfino" size:60.0]];
	[textField setStringValue:@"Hello World"];
	
	[textField setNeedsDisplay:YES];

}




@end
