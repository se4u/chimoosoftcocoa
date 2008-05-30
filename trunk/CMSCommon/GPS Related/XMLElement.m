//
//  XMLElement.m
//  Terrabrowser
//
//  Created by Ryan on Mon May 10 2004.
//  Copyright (c) 2004 Chimoosoft. All rights reserved.
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

#import "XMLElement.h"


@implementation XMLElement

+ (id)XMLElementWithName:(NSString*)s {
	XMLElement * e = [[XMLElement alloc] init];
	[e setElementName:s];
	return [e autorelease];
}

// designated initializer
- (id)init {
    if (self = [super init]) {
		elementName = [[NSString stringWithString:@""] retain];
		
	} else {  //an error occured
		[self release];
		return nil;
	}

	showCheck = YES;
	
    return self;
}


- (void)setElementName:(NSString*)s {
	if (elementName != s) {
		[elementName release];
		elementName = [s retain];
	}
}

- (NSString*)elementName {
	return elementName;
}


// set attributes of this element, for example, in <gpx version="1.0">, version is an attribute
- (void)setAttributes:(NSDictionary*)attributeDict {
	if (attributes != attributeDict) {
		[attributes release];
		attributes = [attributeDict retain];
	}
}

// adds an object to the list of subelements.  Could be a Waypoint object, or
// an XMLElement object.
- (void)addElementToList:(id)element {
	if (subList == nil) {
		subList = [[NSMutableArray arrayWithCapacity:10] retain];
	}

	if (element != nil)	[subList addObject:element];
}

// used for elements which only have one occurence
- (void)setElement:(id)element forKey:(id)key {
	if ((element == nil) || (key == nil)) {
		return;
	}
	
	if (otherElements == nil) {
		otherElements = [[NSMutableDictionary dictionaryWithCapacity:10] retain];
	}

	[otherElements setObject:element forKey:key];
}


- (id)elementForKey:(id)key {
	return [otherElements objectForKey:key];
}

- (NSArray*)list {
	return (NSArray*)subList;
}

- (NSEnumerator *)objectEnumerator {
	return [subList objectEnumerator];
}

- (NSEnumerator *)elementKeyEnumerator {
	return [otherElements keyEnumerator];
}


// returns string of all attributes and their values.
// these are the items which occur *within* the tag itself,
// for example, lat and lon.
//
// Subclasses should override this method if they have additional 
// attributes to add which aren't stored in the dictionary.
- (NSString*)attributeString {
	id key;
	
	NSMutableString * attrString = [NSMutableString stringWithCapacity:50];
	
	NSEnumerator *enumerator = [attributes keyEnumerator];
	while (key = [enumerator nextObject]) {
		[attrString appendFormat:@" %@=\"%@\"", key, [attributes objectForKey:key]];
	}
	
	return attrString;
}

// returns a gpx string representing this element, and
// possibly all the elements below it.  For example,
// for a <trk> element, it will also print out all the
// <trkseg> and <trkpt> elements
//
// see http://www.topografix.com/gpx.asp for more information
//
- (NSString*)gpxString {
	NSMutableString * s = [NSMutableString stringWithCapacity:200];	
	
	[s appendFormat:@"<%@%@>\n", elementName, [self attributeString]];
	
	// Loop through each key in the otherElements dictionary and output it.  This way,
	// even elements which we don't actually use will be saved and re-written to the
	// file so they aren't lost.
	
	NSEnumerator *enumerator = [otherElements keyEnumerator];
	id key, obj;
	
	while ((key = [enumerator nextObject])) {
		[s appendFormat:@" <%@>%@</%@>\n", key, [otherElements objectForKey:key] , key];
	}
	
	// now go down to the next level if we have any sub elements.  For example,
	// if our tag name is <trk>, we might have sume <trkseg> elements.
	
	enumerator = [subList objectEnumerator];
	while (obj = [enumerator nextObject]) {
		[s appendFormat:@"%@\n", [obj gpxString]];
	}
	
	[s appendFormat:@"</%@>", elementName];
	
	return s;
}	




// Returns the number of individuals in the subelements list
// recursively down the tree.  For example, if this is a track,
// then it will return the number of trackpoints by looking at 
// each tracksegment and counting the points.
- (int)numberOfSubElements {
	if ((subList == nil) || ([subList count] == 0)) return 1;
	
	NSEnumerator * enumerator = [subList objectEnumerator];
	id element;
	int count = 0;
	while (element = [enumerator nextObject]) {
		count += [(XMLElement*)element numberOfSubElements];
	}
	
	return count;
}

#pragma mark -
#pragma mark Accessors for Bindings

- (NSString*)name { return [self elementForKey:@"name"]; }
- (void)setName:(NSString*)s { [self setElement:s forKey:@"name"]; }

- (NSString*)comment { return [self elementForKey:@"cmt"]; }
- (void)setComment:(NSString*)s { [self setElement:s forKey:@"cmt"]; }

- (NSString*)desc { return [self elementForKey:@"desc"]; }
- (void)setDesc:(NSString*)s { [self setElement:s forKey:@"desc"]; }

- (NSString*)time { return [self elementForKey:@"time"]; }
- (void)setTime:(NSString*)s { [self setElement:s forKey:@"time"]; }

- (NSString*)source { return [self elementForKey:@"source"]; }
- (void)setSource:(NSString*)s { [self setElement:s forKey:@"source"]; }

- (NSString*)url { return [self elementForKey:@"url"]; }
- (void)setUrl:(NSString*)s { [self setElement:s forKey:@"url"]; }

- (NSString*)urlName { return [self elementForKey:@"urlname"]; }
- (void)setUrlName:(NSString*)s { [self setElement:s forKey:@"urlname"]; }


- (BOOL)includeInList { return showCheck; }
- (void)setIncludeInList:(BOOL)b { showCheck = b; }


- (void)encodeWithCoder:(NSCoder *)encoder {
	//[super encodeWithCoder:encoder];
	[encoder encodeValueOfObjCType:@encode(BOOL) at:&showCheck];
	[encoder encodeObject:elementName];
	[encoder encodeObject:subList];
	[encoder encodeObject:otherElements];
	[encoder encodeObject:attributes];
}

- (id)initWithCoder:(NSCoder *)decoder {
	//self = [super initWithCoder:decoder];
	self = [super init];
	[decoder decodeValueOfObjCType:@encode(BOOL) at:&showCheck];
	elementName = [[decoder decodeObject] retain];
	subList = [[decoder decodeObject] retain];
	otherElements = [[decoder decodeObject] retain];
	attributes = [[decoder decodeObject] retain];
	return self;
}


- (void)dealloc {
	[subList release];
	[otherElements release];
	[attributes release];
}

@end
