//
//  AMStandardEnumerator.h
//  Mandy
//
//  Created by Andreas on Mon Aug 04 2003.
//  Copyright (c) 2003 Andreas Mayer. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef int (*CountMethod)(id, SEL);
typedef id (*NextObjectMethod)(id, SEL, int);

@interface AMStandardEnumerator : NSEnumerator {
	id collection;
	SEL countSelector;
	SEL nextObjectSelector;
	CountMethod count;
	NextObjectMethod nextObject;
	int position;
}

- (id)initWithCollection:(id)theCollection countSelector:(SEL)theCountSelector objectAtIndexSelector:(SEL)theObjectSelector;


@end
