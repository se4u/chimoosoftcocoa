//
//  CMSSlider.m
//
//  Created by Ryan on 9/3/06.
//  Copyright 2006 Chimoosoft. All rights reserved.
//
//  Same as NSSliderCell, but sends a sliderIsDoneMoving message when the user lets go.
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

#import "CMSSliderCell.h"



@implementation CMSSliderCell

// by John Pannell.  modified by Ryan Poling
// http://www.cocoabuilder.com/archive/message/cocoa/2004/1/11/98720
//
- (void)stopTracking:(NSPoint)lastPoint at:(NSPoint)stopPoint
              inView:(NSView *)controlView mouseIsUp:(BOOL)flag {
    if (flag == YES) {
        // mouse just came up

		if ([[self target] respondsToSelector:@selector(sliderIsDoneMoving)]) {
			[[self target] sliderIsDoneMoving];	
		}
    }
    [super stopTracking:lastPoint at:stopPoint inView:controlView mouseIsUp:flag];
}

@end