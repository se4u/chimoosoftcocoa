//
//  CMSClickableImageView.m
//
//  Created by Ryan on 9/8/06.
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


#import "CMSClickableImageView.h"

@implementation CMSClickableImageView

- (id)initWithFrame:(NSRect)frameRect {
	[super initWithFrame: frameRect];
	
	if ([self window] != nil) {
		[[self window] makeFirstResponder:self];
		[[self window] setAcceptsMouseMovedEvents: YES];
		[self addTrackingRect:[self frame]
								 owner:self
							  userData:nil
						  assumeInside:NO];
	}
	
	shouldAcceptFirstMouse = NO;
	
	return self;
}


- (void)drawRect:(NSRect)aRect {
	[super drawRect:aRect];

	/*
	NSRect rect;
	
	rect.origin.x = aRect.origin.x + aRect.size.width / 6;
	rect.origin.y = aRect.origin.y - aRect.size.height / 2;
	rect.size.width = aRect.size.width / 2;
	rect.size.height = aRect.size.height - 10;

	NSMutableDictionary * dict = [NSMutableDictionary dictionaryWithCapacity:2];
	[dict setObject:[NSColor colorWithDeviceRed:0.6 green:0.6 blue:0.6 alpha:1.0] forKey:NSBackgroundColorAttributeName];
	[dict setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];

	[@"Move and resize me, then click inside to capture what's behind me!" drawInRect:rect withAttributes:dict];
	 */
}

// for click-through
- (void)setShouldAcceptFirstMouse:(BOOL)fm {
	shouldAcceptFirstMouse = fm;
}

- (void)mouseDown:(NSEvent *)event {
	if (nil == delegate) return;
	
	if ([delegate respondsToSelector:@selector(imageViewClicked:)])
        [delegate imageViewClicked:self];
    else { 
        [NSException raise:NSInternalInconsistencyException
					format:@"Delegate doesn't respond to mouseDown:(NSEvent*)event"];
    }
}


- (void)mouseEntered:(NSEvent *)event {
	
}

- (void)mouseExited:(NSEvent *)event {
	
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
	return shouldAcceptFirstMouse;
}

// these methods will send messages to the delegate of this class
// when certain interesting events occur.

- (id)delegate { return delegate; }

// Set the receiver's delegate to be aDelegate.
- (void)setDelegate:(id)aDelegate {
	// note, we don't want to retain this.  See 
	// http://cocoadevcentral.com/articles/000075.php for more info on this
	
	delegate = aDelegate;
}

- (void) dealloc {
	
	[super dealloc];
}


@end

