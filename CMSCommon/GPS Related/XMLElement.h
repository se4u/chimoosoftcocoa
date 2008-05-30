//
//  XMLElement.h
//  Terrabrowser
//
//  Created by Ryan on Mon May 10 2004.
//  Copyright (c) 2004 Chimoosoft. All rights reserved.
//
//  Used to represent an XML Element (tag).  For our purposes (reading GPX files),
//  this tag will most likely be <rte>, <trk>, or <trkseg>.
//
//  Each of these tags has a list of other tags (or waypoints), and some of its own tags.
//  For example, the <rte> tag has a list of <rtept> tags (represented with Waypoints), 
//  but it also has several singular tags such as <name>, <cmnt>, etc.  Waypoints could also
//  be represented with this class, but it is more efficient to use the much more specialized 
//  Waypoint class for this purpose.
//
//  Each element also has an attributeDict which stores attributes of an element that occur
//  within the element tag.  For example, in <gpx version="1.0">, the version is an attribute.
//
//  ********
//  Disclaimer: Terrabrowser was one of the first Cocoa programs I wrote and
//  as such, it is in no way representative of my current coding style! ;-) 
//  Many things are done incorrectly in this code base but I have not taken the
//  time to revise them for the open source release. There are also many compile
//  time warnings which should be corrected as some of them hint at serious problems.
//  If you work for a company looking to hire me, don't look too critically at this old code!
//  Similarly, if you're trying to learn Cocoa / Objective-C, keep this in mind.
//  ********

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

#import <Foundation/Foundation.h>

@interface XMLElement : NSObject <NSCoding> {
	
	NSString * elementName;						// name of the xml element this object represents
												// for example, "name" or "wpt"
	NSMutableArray * subList;					// list of tags under this tag
	NSMutableDictionary * otherElements;		// other elements under this tag, but not really list
	NSDictionary * attributes;					// attributes of *this* tag
	
	BOOL showCheck;								// should it be shown on the drawings?
}

+ (id)XMLElementWithName:(NSString*)s;

// designated initializer
- (id)init;

- (void)setElementName:(NSString*)s;
- (NSString*)elementName;

- (void)setAttributes:(NSDictionary*)attributeDict;

// add the passed element to the sublist
- (void)addElementToList:(id)element;

- (void)setElement:(id)element ForKey:(id)key;
- (id)elementForKey:(id)key;

- (NSArray*)list;

- (NSEnumerator *)objectEnumerator;
- (NSEnumerator *)elementKeyEnumerator;

- (NSString*)attributeString;
- (NSString*)gpxString;


// These are some simple accesor methods which are needed
// to work with the Cocoa bindings in the WaypointDocument window.
- (NSString*)name;
- (void)setName:(NSString*)s;

- (NSString*)comment;
- (void)setComment:(NSString*)s;

- (NSString*)desc;
- (void)setDesc:(NSString*)s;

- (NSString*)time;
- (void)setTime:(NSString*)s;

- (NSString*)source;
- (void)setSource:(NSString*)s;

- (NSString*)url;
- (void)setUrl:(NSString*)s;

- (NSString*)urlName;
- (void)setUrlName:(NSString*)s;


- (BOOL)includeInList;
- (void)setIncludeInList:(BOOL)b;

- (int)numberOfSubElements;

- (void)encodeWithCoder:(NSCoder *)encoder;
- (id)initWithCoder:(NSCoder *)decoder;

@end
