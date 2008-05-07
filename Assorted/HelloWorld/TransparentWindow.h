//
//  TransparentWindow.h
//  HelloWorld
//
//  Created by Ryan on 12/17/07.
//  Copyright 2007 Chimoosoft. All rights reserved.
//
//  Creates a transparent window which can be used to draw things so they appear as if they're 
//  directly on the screen.
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

@interface TransparentWindow : NSWindow {

}

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)windowStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)deferCreation;

@end
