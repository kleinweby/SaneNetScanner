//
//  CSSaneOptionRangeConstraint.m
//  SaneNetScanner
//
//  Created by Christian Speich on 06.08.12.
//  Copyright (c) 2012 Christian Speich. All rights reserved.
//

#import "CSSaneOptionRangeConstraint.h"

@interface CSSaneOptionRangeConstraint ()

@property (nonatomic, copy) NSNumber* minValue;
@property (nonatomic, copy) NSNumber* maxValue;
@property (nonatomic, copy) NSNumber* step;

@end

@implementation CSSaneOptionRangeConstraint

- (id) initWithDescriptor:(const SANE_Option_Descriptor*)descriptor
{
    self = [super init];
    if (self) {
        assert(descriptor->constraint_type == SANE_CONSTRAINT_RANGE);
        assert(descriptor->type == SANE_TYPE_INT ||
               descriptor->type == SANE_TYPE_FIXED);
        
        if (descriptor->type == SANE_TYPE_INT) {
            self.minValue = @(descriptor->constraint.range->min);
            self.maxValue = @(descriptor->constraint.range->max);
            self.step = @(descriptor->constraint.range->quant);
        }
        else {
            self.minValue = @SANE_UNFIX(descriptor->constraint.range->min);
            self.maxValue = @SANE_UNFIX(descriptor->constraint.range->max);
            self.step = @SANE_UNFIX(descriptor->constraint.range->quant);
        }
    }
    return self;
}

- (CSSaneConstraintType) type
{
    return CSSaneRangeConstraint;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@:%p> (min=%@, max=%@, step=%@)", NSStringFromClass([self class]), self, self.minValue, self.maxValue, self.step];
}

- (void) addToDeviceDictionary:(NSMutableDictionary*)dict
{
    dict[@"type"] = @"TWON_RANGE";
    dict[@"min"] = self.minValue;
    dict[@"max"] = self.maxValue;
    dict[@"stepSize"] = self.step;
}

@end
