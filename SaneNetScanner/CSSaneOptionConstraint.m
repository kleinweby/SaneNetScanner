//
//  CSSaneOptionConstraint.m
//  SaneNetScanner
//
//  Created by Christian Speich on 06.08.12.
//  Copyright (c) 2012 Christian Speich. All rights reserved.
//

#import "CSSaneOptionConstraint.h"
#import "CSSaneOptionRangeConstraint.h"
#import "CSSaneOptionEnumConstraint.h"

@implementation CSSaneOptionConstraint

+ (id) constraintWithDescriptor:(const SANE_Option_Descriptor*)descriptor
{
    if (descriptor->constraint_type == SANE_CONSTRAINT_RANGE)
        return [[CSSaneOptionRangeConstraint alloc] initWithDescriptor:descriptor];
    else if (descriptor->constraint_type == SANE_CONSTRAINT_STRING_LIST ||
             descriptor->constraint_type == SANE_CONSTRAINT_WORD_LIST)
        return [[CSSaneOptionEnumConstraint alloc] initWithDescriptor:descriptor];
    
    return nil;
}

- (void) addToDeviceDictionary:(NSMutableDictionary*)dict
{
}

@end
