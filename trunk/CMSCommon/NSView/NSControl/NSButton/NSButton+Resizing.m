//
//  NSButton+Resizing.m
//
//  Created by Ryan Poling on 12/2/07.
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

#import "NSButton+Resizing.h"


@implementation NSButton (CMSButtonResizing) 


- (void)setTitle:(NSString*)title sizeToFit:(BOOL)resize alignLeft:(BOOL)left animate:(BOOL)shouldAnimate {

	if (nil == title) {
		[self setTitle:@""];
		return;
	}
	
	if ((!resize) || ([title length] <= 0)) {
		[self setTitle:title];
		return;
	}
	
	
	// Check for Leopard.  The animator is only supported on 
	// Leopard and later, so don't call it if earlier.
	SInt32 MacVersion;	
	if (Gestalt(gestaltSystemVersion, &MacVersion) == noErr) {
		if ((MacVersion < 0x1050)) {
			shouldAnimate = NO;
		}
	}	
	
	
	NSRect frame = [self frame];
	
	// Record left and right bottom origins for future use.
	NSPoint leftOrigin = frame.origin;
	NSPoint rightOrigin = frame.origin;
	rightOrigin.x = leftOrigin.x + frame.size.width;	
		
	// Divide by zero check done at top.
	// Estimate the width of the button after setting the new title.
	float factor = (float)[title length] / (float)[[self title] length];
	frame.size.width = (frame.size.width * factor);	
	
	// Expand button to new estimated width.
	if (shouldAnimate) {
		[[self animator] setFrame:frame];
	} else {
		[self setFrame:frame];
	}
	
	// Now that button is expanded, set title.
	[self setTitle:title];
	
	// Calculate actual width (better than estimate above).
	[self sizeToFit];
	frame = [self frame];
	frame.size.width += 10.0;
				
	// Reposition the origin for proper left or right alignment.
	if (left) {
		frame.origin.x = leftOrigin.x;
	} else {
		frame.origin.x = rightOrigin.x;
		frame.origin.x = rightOrigin.x - frame.size.width;
	}
	
	// Set the new frame for the button.
	if (shouldAnimate) {
		[[self animator] setFrame:frame];
	} else {
		[self setFrame:frame];
	}
	
}



@end
