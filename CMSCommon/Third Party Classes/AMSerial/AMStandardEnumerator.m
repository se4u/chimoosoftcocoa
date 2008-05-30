//
//  AMStandardEnumerator.m
//  Mandy
//
//  Created by Andreas on Mon Aug 04 2003.
//  Copyright (c) 2003 Andreas Mayer. All rights reserved.
//

#import "AMStandardEnumerator.h"


@implementation AMStandardEnumerator


- (id)initWithCollection:(id)theCollection countSelector:(SEL)theCountSelector objectAtIndexSelector:(SEL)theObjectSelector
{
	if (self = [super init]) {
		collection = [theCollection retain];
		countSelector = theCountSelector;
		count = (CountMethod)[collection methodForSelector:countSelector];
		nextObjectSelector = theObjectSelector;
		nextObject = (NextObjectMethod)[collection methodForSelector:nextObjectSelector];
		position = 0;
	}
	return self;
}

- (void)dealloc
{
	[collection release];
	[super dealloc];
}

- (id)nextObject
{
	if (position >= count(collection, countSelector))
		return nil;

	return (nextObject(collection, nextObjectSelector, position++));
}

- (NSArray *)allObjects
{
	NSArray *result = [[[NSMutableArray alloc] init] autorelease];
	id object;
	while (object = [self nextObject])
		[(NSMutableArray *)result addObject:object];
	return result;
}

@end
