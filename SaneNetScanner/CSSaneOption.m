//
//  CSSaneOption.m
//  SaneNetScanner
//
//  Created by Christian Speich on 06.08.12.
//  Copyright (c) 2012 Christian Speich. All rights reserved.
//

#import "CSSaneOption.h"

@interface CSSaneOption ()

@property (nonatomic, copy) NSString* name;
@property (nonatomic) SANE_Handle saneHandle;
@property (nonatomic) SANE_Int saneOptionNumber;

@property (nonatomic) const SANE_Option_Descriptor* descriptor;

- (void) _fetchValue;
- (void) _setValue;

@end

@implementation CSSaneOption

@synthesize value = _value;

+ (NSArray*) saneOptionsForHandle:(SANE_Handle)handle
{
    SANE_Int number;
    NSMutableArray* options = [NSMutableArray array];
    
    for (number = 0;; number++) {
        const SANE_Option_Descriptor* descriptor =
        sane_get_option_descriptor(handle, number);
        
        // Last descriptor
        if (descriptor == NULL)
            break;
        
        // Discard group
        if (descriptor->type == SANE_TYPE_GROUP)
            continue;
        
        [options addObject:[[self alloc] initWithHandle:handle
                                                 number:number
                                          andDescriptor:descriptor]];
    }
    
    return options;
}

- (id)initWithHandle:(SANE_Handle)handle
              number:(SANE_Int)number
       andDescriptor:(const SANE_Option_Descriptor*)descriptor
{
    self = [super init];
    if (self) {
        self.name = [NSString stringWithUTF8String:descriptor->name];
        
        self.descriptor = descriptor;
        self.saneHandle = handle;
        self.saneOptionNumber = number;
        
        [self _fetchValue];
    }
    return self;
}

- (void) setValue:(id)value
{
    if ([value isEqual:_value])
        return;
    
    _value = value;
    [self _setValue];
}

- (void) _fetchValue
{
    if (self.descriptor->type == SANE_TYPE_FIXED) {
        SANE_Fixed *values;
        SANE_Status status;
        
        values = malloc(self.descriptor->size);
        
        status = sane_control_option(self.saneHandle,
                                     self.saneOptionNumber,
                                     SANE_ACTION_GET_VALUE,
                                     values, 0);
        
        if (status != SANE_STATUS_GOOD) {
            LogMessageCompat(@"Failed get %@: %s", self, sane_strstatus(status));
            return;
        }
        
        // Only one value
        if (self.descriptor->size == sizeof(SANE_Int)) {
            _value = [NSNumber numberWithDouble:SANE_UNFIX(values[0])];
        }
        // Multiple values
        else {
            NSUInteger numberOfValues = self.descriptor->size/sizeof(SANE_Int);
            NSMutableArray* valueArray = [NSMutableArray arrayWithCapacity:numberOfValues];
            
            for (NSUInteger i = 0; i < numberOfValues; i++) {
                [valueArray addObject:
                 [NSNumber numberWithDouble:SANE_UNFIX(values[i])]];
            }
            
            _value = valueArray;
        }
        
        free(values);
    }
    else if (self.descriptor->type == SANE_TYPE_INT) {
        SANE_Int *values;
        SANE_Status status;
        
        values = malloc(self.descriptor->size);
        
        status = sane_control_option(self.saneHandle,
                                     self.saneOptionNumber,
                                     SANE_ACTION_GET_VALUE,
                                     values, 0);
        
        if (status != SANE_STATUS_GOOD) {
            LogMessageCompat(@"Failed get %@: %s", self, sane_strstatus(status));
            return;
        }
        
        // Only one value
        if (self.descriptor->size == sizeof(SANE_Int)) {
            _value = [NSNumber numberWithInt:values[0]];
        }
        // Multiple values
        else {
            NSUInteger numberOfValues = self.descriptor->size/sizeof(SANE_Int);
            NSMutableArray* valueArray = [NSMutableArray arrayWithCapacity:numberOfValues];
            
            for (NSUInteger i = 0; i < numberOfValues; i++) {
                [valueArray addObject:
                 [NSNumber numberWithDouble:values[i]]];
            }
            
            _value = valueArray;
        }
        
        free(values);
    }
    else if (self.descriptor->type == SANE_TYPE_STRING) {
        SANE_String value;
        SANE_Status status;
        
        value = malloc(self.descriptor->size);
        
        assert(value);
        
        status = sane_control_option(self.saneHandle,
                                     self.saneOptionNumber,
                                     SANE_ACTION_GET_VALUE,
                                     value, 0);
        
        if (status != SANE_STATUS_GOOD) {
            LogMessageCompat(@"Failed get %@: %s", self, sane_strstatus(status));
            return;
        }
        
        _value = [NSString stringWithUTF8String:value];
        free(value);
    }
    else {
        LogMessageCompat(@"Unsupported type %@", self);
    }
}

- (void) _setValue
{
    
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"<SaneOption:%p> (name=%@, value=%@)", self, self.name, self.value];
}

@end
