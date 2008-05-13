//
//  CMSProgressIndicator.m
//
//  Created by Ryan Poling on 12/20/07.
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

#import "CMSProgressIndicator.h"


@interface CMSProgressIndicator (Private)

- (BOOL)shouldPerformMagic;

@end


@implementation CMSProgressIndicator (Private)

- (BOOL)shouldPerformMagic {
	return ([self isIndeterminate] && [self isDisplayedWhenStopped]);
}

@end


@implementation CMSProgressIndicator


- (void) dealloc {
	[_imageView release];
	[super dealloc];
}


- (void)startAnimation:(id)sender {
	if ([self shouldPerformMagic]) [self setHidden:NO];
	[super startAnimation:sender];
	
	if ([self shouldPerformMagic]) [_imageView removeFromSuperview];
}

- (void)stopAnimation:(id)sender {	
	[super stopAnimation:sender];

	if ([self shouldPerformMagic]) {
		
		[self setHidden:YES];
				
		if (nil == _imageView) {	
			NSImage * image = [NSImage imageNamed:@"disabledprogress.png"];
			_imageView = [[NSImageView alloc] init];
			[_imageView setFrame:NSMakeRect(0.0, 0.0, [image size].width, [image size].height)];
			[_imageView setImage:image];
		}
		 
		[[self superview] addSubview:_imageView];
		[[self superview] setNeedsDisplay:YES];
			
	}
}

@end
