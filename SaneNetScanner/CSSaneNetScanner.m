//
//  CSSaneNetScanner.m
//  SaneNetScanner
//
//  Created by Christian Speich on 05.08.12.
//  Copyright (c) 2012 Christian Speich. All rights reserved.
//

#import "CSSaneNetScanner.h"

#include "sane/sane.h"
#include "sane/saneopts.h"

static void AddConstraintToDict(const SANE_Option_Descriptor* descriptior,
                                NSMutableDictionary* dict) {
    
    switch (descriptior->constraint_type) {
        case SANE_CONSTRAINT_NONE:
            break;
        case SANE_CONSTRAINT_RANGE:
            if (descriptior->type == SANE_TYPE_FIXED) {
                double min = SANE_UNFIX(descriptior->constraint.range->min);
                double max = SANE_UNFIX(descriptior->constraint.range->max);
                double quant = SANE_UNFIX(descriptior->constraint.range->quant);
                
                dict[@"type"] = @"TWON_RANGE";
                dict[@"min"] = [NSNumber numberWithDouble:min];
                dict[@"max"] = [NSNumber numberWithDouble:max];
                dict[@"stepSize"] = [NSNumber numberWithDouble:quant];
            }
            else if (descriptior->type == SANE_TYPE_INT) {
                dict[@"type"] = @"TWON_RANGE";
                dict[@"min"] = [NSNumber numberWithInt:descriptior->constraint.range->min];
                dict[@"max"] = [NSNumber numberWithInt:descriptior->constraint.range->max];
                dict[@"stepSize"] = [NSNumber numberWithInt:descriptior->constraint.range->quant];
            }
            else {
                LogMessageCompat(@"Value type not supportet!");
                assert(false);
            }
            break;
        case SANE_CONSTRAINT_WORD_LIST:
        {
            SANE_Word length = descriptior->constraint.word_list[0];
            NSMutableArray* list = [NSMutableArray arrayWithCapacity:length];
            
            for (SANE_Word i = 1; i < length + 1; i++) {
                if (descriptior->type == SANE_TYPE_FIXED) {
                    [list addObject:[NSNumber numberWithDouble:SANE_UNFIX(descriptior->constraint.word_list[i])]];
                }
                else if (descriptior->type == SANE_TYPE_INT) {
                    [list addObject:[NSNumber numberWithInt:descriptior->constraint.word_list[i]]];
                }
            }
        }
        default:
            break;
    }
}

@interface CSSaneNetScanner ()

@property (nonatomic, strong) NSString* prettyName;

@property (nonatomic, strong) NSMutableDictionary* deviceProperties;

@property (nonatomic) BOOL open;

@property (nonatomic) SANE_Handle saneHandle;

@end

@implementation CSSaneNetScanner

- (id) initWithParameters:(NSDictionary*)params;
{
    self = [super init];
    if (self) {
        LogMessageCompat(@"Params %@", params);
        
        self.open = NO;
        self.saneHandle = 0;
        
        self.prettyName = params[(NSString*)kICABonjourServiceNameKey];
    }
    return self;
}

- (ICAError) openSession:(ICD_ScannerOpenSessionPB*)params
{
    LogMessageCompat(@"Open session");
    if (self.open)
        return kICAInvalidSessionErr;    
    
    SANE_Handle handle;
    SANE_Status status;
    NSString* deviceName = @"10.0.1.5:mustek_usb:libusb:001:008";
    
    status = sane_open([deviceName UTF8String], &handle);
    
    if (status == SANE_STATUS_GOOD) {
        self.open = YES;
        self.saneHandle = handle;
        
        return noErr;
    }
    else {
        return kICADeviceInternalErr;
    }
}

- (ICAError) closeSession:(ICD_ScannerCloseSessionPB*)params
{
    LogMessageCompat(@"Close session");

    if (!self.open)
        return kICAInvalidSessionErr;
    
    sane_close(self.saneHandle);
    self.saneHandle = 0;
    self.open = NO;
    
    return noErr;
}

- (ICAError) addPropertiesToDictitonary:(NSMutableDictionary*)dict
{
    LogMessageCompat(@"addPropertiesToDictitonary:%@", dict);
    
    // Add kICAUserAssignedDeviceNameKey.  Since this key is a simple NSString,
    // the value may be of any length.  This key supercedes any name already
    // provided in the device information before, which is limited to 32 characters.
    [dict setObject:self.prettyName
             forKey:(NSString*)kICAUserAssignedDeviceNameKey];
    
    return noErr;
}

- (ICAError) getParameters:(ICD_ScannerGetParametersPB*)params
{
    LogMessageCompat(@"Get params");
    NSMutableDictionary* dict = (__bridge NSMutableDictionary*)(params->theDict);
    
    if (!dict)
        return paramErr;
    
    NSMutableDictionary* deviceDict = [@{
    @"functionalUnits": @{
    @"availableFunctionalUnitTypes" : @[ @0 ]
    },
    @"selectedFunctionalUnitType": @0,
//    @"CAP_AUTOFEED": @{ @"type": @"TWON_ONEVALUE", @"value": @1 },
//    @"CAP_DUPLEX": @{ @"type": @"TWON_ONEVALUE", @"value": @2 },
//    @"CAP_DUPLEXENABLED": @{ @"type": @"TWON_ONEVALUE", @"value": @0 },
//    @"CAP_FEEDERENABLED": @{ @"type": @"TWON_ONEVALUE", @"value": @0 },
                                       @"ICAP_SUPPORTEDSIZES": @{ @"current": @1, @"default": @1, @"type": @"TWON_ENUMERATION", @"value": @[ @1, @2, @3, @4, @5, @10, @0 ]},
    
    
    @"ICAP_UNITS": @{ @"current": @1, @"default": @0, @"type": @"TWON_ENUMERATION", @"value": @[ @0, @1, @5 ] },
    
    } mutableCopy];
    
    SANE_Status status;
    
    for (int i = 0;; i++) {
        const SANE_Option_Descriptor* option = sane_get_option_descriptor(self.saneHandle, i);
        
        if (option == NULL)
            break;
        
        if (option->type == SANE_TYPE_GROUP)
            LogMessageCompat(@"Group %s", option->title);
        
        if (option->name == NULL)
            continue;
        
        LogMessageCompat(@"Option %s", option->name);
        
        if (strcmp(option->name, SANE_NAME_SCAN_RESOLUTION) == 0) {
            LogMessageCompat(@"Found resolution.");
            NSMutableDictionary* d = [NSMutableDictionary dictionary];
            
            AddConstraintToDict(option, d);
            
            d[@"SaneOptionNumber"] = [NSNumber numberWithInt:i];
            
            // Fetch current
            SANE_Word value;
            status = sane_control_option(self.saneHandle,
                                         i,
                                         SANE_ACTION_GET_VALUE,
                                         &value, NULL);
            
            if (status != SANE_STATUS_GOOD) {
                NSLog(@"Get failed");
                assert(false);
            }
            
            if (option->type == SANE_TYPE_FIXED) {
                d[@"current"] = [NSNumber numberWithDouble:SANE_UNFIX(value)];
            }
            
            deviceDict[@"ICAP_XRESOLUTION"] = d;
            deviceDict[@"ICAP_YRESOLUTION"] = d;
        }
        else if (strcmp(option->name, SANE_NAME_SCAN_TL_X) == 0) {
            if (option->constraint_type == SANE_CONSTRAINT_RANGE) {
                double unitsPerInch;
                double width;
                
                if (option->unit == SANE_UNIT_MM)
                    unitsPerInch = 25.4;
                else
                    unitsPerInch = 72.0;
                
                if (option->type == SANE_TYPE_FIXED) {
                    width = SANE_UNFIX(option->constraint.range->max);
                }
                else if (option->type == SANE_TYPE_INT) {
                    width = option->constraint.range->max;
                }
                
                width = width/unitsPerInch;
        
                deviceDict[@"ICAP_PHYSICALWIDTH"] = @{
                    @"type": @"TWON_ONEVALUE",
                    @"value": [NSNumber numberWithDouble:width]
                };
            }
        }
        else if (strcmp(option->name, SANE_NAME_SCAN_TL_Y) == 0) {
            double unitsPerInch;
            double height;
            
            if (option->unit == SANE_UNIT_MM)
                unitsPerInch = 25.4;
            else
                unitsPerInch = 72.0;
            
            if (option->constraint_type == SANE_CONSTRAINT_RANGE) {
                if (option->type == SANE_TYPE_FIXED) {
                    height = SANE_UNFIX(option->constraint.range->max);
                }
                else if (option->type == SANE_TYPE_INT) {
                    height = (int)option->constraint.range->max;
                }
            }
            
            height = height/unitsPerInch;
            
            deviceDict[@"ICAP_PHYSICALHEIGHT"] = @{
                @"type": @"TWON_ONEVALUE",
                @"value": [NSNumber numberWithDouble:height]
            };
        }
    }
    
    // The bitdepth was not an option from the device
    // now we have to infer from the scan mode.
    if (deviceDict[@"ICAP_BITDEPTH"] == nil) {
        deviceDict[@"ICAP_BITDEPTH"] =  @{
            @"current": @1,
            @"default": @1,
            @"type":
            @"TWON_ENUMERATION",
            @"value": @[ @1, @8 ]
        };
    }
    
    [dict setObject:deviceDict
             forKey:@"device"];
    self.deviceProperties = deviceDict;
    
    return noErr;
}

- (ICAError) setParameters:(ICD_ScannerSetParametersPB*)params
{
    LogMessageCompat(@"Set params: %@", params->theDict);

    return paramErr;
}

- (ICAError) status:(ICD_ScannerStatusPB*)params
{
    LogMessageCompat( @"status");
    
    return paramErr;
}

- (ICAError) start:(ICD_ScannerStartPB*)params
{
    LogMessageCompat(@"Start");
    
    return paramErr;
}

@end
