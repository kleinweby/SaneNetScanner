//
//  CSSaneOptionEnumConstraint.m
//  SaneNetScanner
//
//  Created by Christian Speich on 06.08.12.
//  Copyright (c) 2012 Christian Speich. All rights reserved.
//

#import "CSSaneOptionEnumConstraint.h"

@interface CSSaneOptionEnumConstraint ()

@property (nonatomic, copy) NSArray* values;

@end

@implementation CSSaneOptionEnumConstraint

- (id) initWithDescriptor:(const SANE_Option_Descriptor*)descriptor
{
    self = [super init];
    if (self) {
        assert(descriptor->constraint_type == SANE_CONSTRAINT_STRING_LIST ||
               descriptor->constraint_type == SANE_CONSTRAINT_WORD_LIST);
        
        if (descriptor->constraint_type == SANE_CONSTRAINT_WORD_LIST) {
            SANE_Word length = descriptor->constraint.word_list[0];
            NSMutableArray* values = [NSMutableArray arrayWithCapacity:length];
            
            for (SANE_Word i = 1; i < length + 1; i++) {
                if (descriptor->type == SANE_TYPE_FIXED) {
                    [values addObject:@SANE_UNFIX(descriptor->constraint.word_list[i])];
                }
                else if (descriptor->type == SANE_TYPE_INT) {
                    [values addObject:@(descriptor->constraint.word_list[i])];
                }
                else {
                    assert(false);
                }
            }
            
            self.values = values;
        }
        else {
            NSMutableArray* values = [NSMutableArray array];
            const char* const * ptr = descriptor->constraint.string_list;
            
            while (*ptr != NULL) {
                const char* const str = *ptr;
                
                [values addObject:@(str)];
                
                ptr++;
            }
            
            self.values = values;
        }
    }
    return self;
}

- (CSSaneConstraintType) type
{
    return CSSaneEnumConstraint;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@:%p> %@", NSStringFromClass([self class]), self, self.values];
}

@end
