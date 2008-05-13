//
//  CMSClickableImageView.h
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


#import <Cocoa/Cocoa.h>

@interface CMSClickableImageView : NSImageView {
	id delegate;
	BOOL shouldAcceptFirstMouse;
}

- (id)delegate;
- (void)setDelegate:(id)aDelegate;
- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent;
- (void)setShouldAcceptFirstMouse:(BOOL)fm;

- (void)drawRect:(NSRect)aRect;

@end


// Delegate may implement these methods.

@interface NSObject (CMSClickableImageViewDelegate)

- (void)imageViewClicked:(NSImageView *)sender;

@end
