//
//  CSSaneOptionConstraint.h
//  SaneNetScanner
//
//  Created by Christian Speich on 06.08.12.
//  Copyright (c) 2012 Christian Speich. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "sane/sane.h"

typedef enum {
    CSSaneRangeConstraint,
    CSSaneEnumConstraint
} CSSaneConstraintType;

@interface CSSaneOptionConstraint : NSObject

+ (id) constraintWithDescriptor:(const SANE_Option_Descriptor*)descriptor;

@property (nonatomic, readonly) CSSaneConstraintType type;

- (void) addToDeviceDictionary:(NSMutableDictionary*)dict;

@end
