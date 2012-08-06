//
//  CSSaneNetScanner.m
//  SaneNetScanner
//
//  Created by Christian Speich on 05.08.12.
//  Copyright (c) 2012 Christian Speich. All rights reserved.
//

#import "CSSaneNetScanner.h"

#import "CSSaneOption.h"

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
        case SANE_CONSTRAINT_STRING_LIST:
        {
            NSMutableArray* list = [NSMutableArray array];
            const char* const * ptr = descriptior->constraint.string_list;
            while (*ptr != NULL) {
                const char* const str = *ptr;
                
                [list addObject:[NSString stringWithUTF8String:str]];
                
                ptr++;
            }
            
            dict[@"values"] = list;
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

@property (nonatomic) NSString* documentPath;

@end

@interface CSSaneNetScanner (Progress)

- (void) showWarmUpMessage;
- (void) doneWarmUpMessage;
- (void) pageDoneMessage;
- (void) scanDoneMessage;

- (void) sendTransactionCanceledMessage;

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
    NSString* deviceName = @"10.0.1.5:mustek_usb:libusb:001:007";
    
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
    
    // Add key indicating that the module supports using the ICA Raw File
    // as a backing store for image io
//    [dict setObject:[NSNumber numberWithInt:1] forKey:@"supportsICARawFileFormat"];
    
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
    
    LogMessageCompat(@"Options %@", [CSSaneOption saneOptionsForHandle:self.saneHandle]);
    
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
        else if (strcmp(option->name, SANE_NAME_SCAN_MODE) == 0) {
            
            NSMutableDictionary* d = [NSMutableDictionary dictionary];
            
            d[@"SaneOptionNumber"] = [NSNumber numberWithInt:i];
            
            AddConstraintToDict(option, d);
            
            // Fetch current
            SANE_String_Const value = malloc(option->size);
            status = sane_control_option(self.saneHandle,
                                         i,
                                         SANE_ACTION_GET_VALUE,
                                         value, NULL);
            
            if (status != SANE_STATUS_GOOD) {
                NSLog(@"Get failed");
                assert(false);
            }
            
            d[@"current"] = [NSString stringWithUTF8String:value];
            
            LogMessageCompat(@"Found scan modes %@", d);
            deviceDict[@"SaneScanMode"] = d;
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
    NSDictionary* dict = ((__bridge NSDictionary *)(params->theDict))[@"userScanArea"];

    self.documentPath = [[dict[@"document folder"] stringByAppendingPathComponent:dict[@"document name"]] stringByAppendingPathExtension:dict[@"document extension"]];
    
    if (dict[@"ColorSyncMode"]) {
        if ([dict[@"ColorSyncMode"] isEqualToString:@"scanner.reflective.RGB.positive"])
        {
            SANE_String value = malloc(25);
            SANE_Status status;
            
            strcpy(value, "Color");
            
            status = sane_control_option(self.saneHandle,
                                         [self.deviceProperties[@"SaneScanMode"][@"SaneOptionNumber"] intValue],
                                         SANE_ACTION_SET_VALUE,
                                         value, NULL);
            
            if (status != SANE_STATUS_GOOD) {
                NSLog(@"Set failed");
                assert(false);
            }
            LogMessageCompat(@"Set scan mode to color");
        }
    }
    
    // Note: always force X=Y Resolution
    if (dict[@"ICAP_XRESOLUTION"]) {
        SANE_Int option = [dict[@"ICAP_XRESOLUTION"][@"SaneOptionNumber"] intValue];
        SANE_Option_Descriptor* descriptor = sane_get_option_descriptor(self.saneHandle, option);
        SANE_Status status;
        
        if (descriptor->type == SANE_TYPE_FIXED) {
            SANE_Word value = SANE_FIX([dict[@"ICAP_XRESOLUTION"][@"value"] doubleValue]);
            
            status = sane_control_option(self.saneHandle,
                                         option,
                                         SANE_ACTION_SET_VALUE,
                                         &value, NULL);
            
            if (status != SANE_STATUS_GOOD) {
                NSLog(@"Set failed");
                assert(false);
            }
        }
    }
    
    return noErr;
}

- (ICAError) status:(ICD_ScannerStatusPB*)params
{
    LogMessageCompat( @"status");
    
    return paramErr;
}

- (ICAError) start:(ICD_ScannerStartPB*)params
{
    LogMessageCompat(@"Start");
    SANE_Status status;
    SANE_Parameters parameters;
    NSFileHandle* file;
    
    LogMessageCompat(@"Open file %@", self.documentPath);
    NSError* error = nil;
    
    [self showWarmUpMessage];
    LogMessageCompat(@"sane_start");
    status = sane_start(self.saneHandle);
    
    if (status != SANE_STATUS_GOOD) {
        LogMessageCompat(@"sane_start failed: %s", sane_strstatus(status));
        return kICADeviceInternalErr;
    }
    
    LogMessageCompat(@"sane_get_parameters");
    status = sane_get_parameters(self.saneHandle, &parameters);
    
    if (status != SANE_STATUS_GOOD) {
        LogMessageCompat(@"sane_get_parameters failed: %s", sane_strstatus(status));
        sane_cancel(self.saneHandle);
        return kICADeviceInternalErr;
    }
    LogMessageCompat(@"sane_get_parameters: last_frame=%u, bytes_per_line=%u, pixels_per_line=%u, lines=%u, depth=%u", parameters.last_frame, parameters.bytes_per_line, parameters.pixels_per_line, parameters.lines, parameters.depth);
    
    [self doneWarmUpMessage];
    
    LogMessageCompat(@"Prepare buffers");
    int bufferSize;
    int bufferdRows;
    NSMutableData* buffer;
    
    // Choose buffer size
    //
    //  Use a buffer size around 50KiB.
    //  the size will be aligned to row boundries
    bufferdRows = MIN(50*1025 / parameters.bytes_per_line, parameters.lines);
    bufferSize = bufferdRows * parameters.bytes_per_line;
    
    buffer = [NSMutableData dataWithLength:bufferSize];
    
    LogMessageCompat(@"Choose to buffer %u rows (%u in size)", bufferdRows, bufferSize);
    
    LogMessageCompat(@"Begin reading");
    int row = 0;
    
    do {
        // Fill the buffer
        unsigned char* b = [buffer mutableBytes];
        int filled = 0;
        
        do {
            SANE_Int readBytes;
            status = sane_read(self.saneHandle,
                               &b[filled],
                               bufferSize - filled,
                               &readBytes);
            
            if (status == SANE_STATUS_EOF)
                break;
            else if (status != SANE_STATUS_GOOD) {
                NSLog(@"Read error");
                return kICADeviceInternalErr;
            }
            
            filled += readBytes;
        } while (filled < bufferSize);
        // Shrink the buffer if not fully filled
        // (may happen for the last block)
        [buffer setLength:filled];

        // Notify the image capture kit that we made progress
        ICASendNotificationPB notePB = {
            .notificationDictionary = (__bridge_retained CFMutableDictionaryRef)[@{
            (id)kICANotificationICAObjectKey: [NSNumber numberWithUnsignedInt:self.scannerObjectInfo->icaObject],
            (id)kICANotificationTypeKey: (id)kICANotificationTypeScanProgressStatus
            } mutableCopy]
        };
        
        // Send inline image data
        if (true) {
            ICDAddImageInfoToNotificationDictionary(notePB.notificationDictionary,
                                                    parameters.pixels_per_line,
                                                    parameters.lines,
                                                    parameters.bytes_per_line,
                                                    row,
                                                    bufferdRows,
                                                    (UInt32)[buffer length],
                                                    (void*)[buffer bytes]);
        }
        
        // Send the progress and check if the user
        // canceled the scan
        if (ICDSendNotificationAndWaitForReply(&notePB) == noErr)
        {
            if (notePB.replyCode == userCanceledErr) {
                LogMessageCompat(@"User canceled. Clean up...");
                sane_cancel(self.saneHandle);
                
                [self sendTransactionCanceledMessage];
                return noErr;
            }
        }
        LogMessageCompat(@"Read line %i", row);
        row+=bufferdRows;
    } while (status == SANE_STATUS_GOOD);

//    ICASendNotificationPB notePB = {
//        .notificationDictionary = (__bridge_retained CFMutableDictionaryRef)[@{
//        (id)kICANotificationICAObjectKey: [NSNumber numberWithUnsignedInt:self.scannerObjectInfo->icaObject],
//        (id)kICANotificationTypeKey: (id)kICANotificationTypeScanProgressStatus
//        } mutableCopy]
//    };
//    
//    ICDAddImageInfoToNotificationDictionary(notePB.notificationDictionary,
//                                            parameters.pixels_per_line,
//                                            parameters.lines,
//                                            parameters.bytes_per_line,
//                                            0,
//                                            parameters.lines,
//                                            (UInt32)[data length],
//                                            (void*)[data bytes]);
//    
//	ICDSendNotification( &notePB );
    
//    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
//    CGImageRef image = CGImageCreate(parameters.pixels_per_line,
//                                     parameters.lines,
//                                     8,
//                                     8,
//                                     parameters.bytes_per_line,
//                                     CGColorSpaceCreateDeviceGray(),
//                                     kCGImageAlphaNone,
//                                     provider,
//                                     NULL,
//                                     NO,
//                                     kCGRenderingIntentDefault);
//    
//    if (self.documentPath) {
//        [self writeImageAsTiff:image toFile:self.documentPath];
//    }
    
    sane_cancel(self.saneHandle);
    
    LogMessageCompat(@"Done...");
    [self pageDoneMessage];
    [self scanDoneMessage];
    
    return noErr;
}

- (void) writeImageAsTiff:(CGImageRef)image toFile:(NSString*)file
{
    int compression = NSTIFFCompressionLZW;  // non-lossy LZW compression
	CFMutableDictionaryRef mSaveMetaAndOpts = CFDictionaryCreateMutable(nil, 0,
																		&kCFTypeDictionaryKeyCallBacks,  &kCFTypeDictionaryValueCallBacks);
	CFMutableDictionaryRef tiffProfsMut = CFDictionaryCreateMutable(nil, 0,
																	&kCFTypeDictionaryKeyCallBacks,  &kCFTypeDictionaryValueCallBacks);
	CFDictionarySetValue(tiffProfsMut, kCGImagePropertyTIFFCompression, CFNumberCreate(NULL, kCFNumberIntType, &compression));
	CFDictionarySetValue(mSaveMetaAndOpts, kCGImagePropertyTIFFDictionary, tiffProfsMut);
    
	NSURL *outURL = [[NSURL alloc] initFileURLWithPath:file];
	CGImageDestinationRef dr = CGImageDestinationCreateWithURL((__bridge CFURLRef)outURL, (__bridge CFStringRef)@"public.tiff" , 1, NULL);
	CGImageDestinationAddImage(dr, image, mSaveMetaAndOpts);
	CGImageDestinationFinalize(dr);
}

@end

@implementation CSSaneNetScanner (Progress)

- (void) showWarmUpMessage
{
    // TODO: this probbably leaks the dictinonary
    ICASendNotificationPB notePB = {
        .notificationDictionary = (__bridge_retained CFMutableDictionaryRef)[@{
            (id)kICANotificationICAObjectKey: [NSNumber numberWithUnsignedInt:self.scannerObjectInfo->icaObject],
            (id)kICANotificationTypeKey: (id)kICANotificationTypeDeviceStatusInfo,
            (id)kICANotificationSubTypeKey: (id)kICANotificationSubTypeWarmUpStarted
        } mutableCopy]
    };
    
	ICDSendNotification( &notePB );
}

- (void) doneWarmUpMessage
{
    ICASendNotificationPB notePB = {
        .notificationDictionary = (__bridge_retained CFMutableDictionaryRef)[@{
        (id)kICANotificationICAObjectKey: [NSNumber numberWithUnsignedInt:self.scannerObjectInfo->icaObject],
        (id)kICANotificationTypeKey: (id)kICANotificationTypeDeviceStatusInfo,
        (id)kICANotificationSubTypeKey: (id)kICANotificationSubTypeWarmUpDone
        } mutableCopy]
    };
    
	ICDSendNotification( &notePB );
}

- (void) pageDoneMessage
{
    ICASendNotificationPB notePB = {
        .notificationDictionary = (__bridge_retained CFMutableDictionaryRef)[@{
        (id)kICANotificationICAObjectKey: [NSNumber numberWithUnsignedInt:self.scannerObjectInfo->icaObject],
        (id)kICANotificationTypeKey: (id)kICANotificationTypeScannerPageDone,
        } mutableCopy]
    };
    
    if (self.documentPath)
        ((__bridge NSMutableDictionary*)notePB.notificationDictionary)[(id)kICANotificationScannerDocumentNameKey] =self.documentPath;


	ICDSendNotification( &notePB );
}

- (void) scanDoneMessage
{
    ICASendNotificationPB notePB = {
        .notificationDictionary = (__bridge_retained CFMutableDictionaryRef)[@{
        (id)kICANotificationICAObjectKey: [NSNumber numberWithUnsignedInt:self.scannerObjectInfo->icaObject],
        (id)kICANotificationTypeKey: (id)kICANotificationTypeScannerScanDone
        } mutableCopy]
    };
    
	ICDSendNotification( &notePB );
}

- (void) sendTransactionCanceledMessage
{
    ICASendNotificationPB notePB = {
        .notificationDictionary = (__bridge_retained CFMutableDictionaryRef)[@{
        (id)kICANotificationICAObjectKey: [NSNumber numberWithUnsignedInt:self.scannerObjectInfo->icaObject],
        (id)kICANotificationTypeKey: (id)kICANotificationTypeTransactionCanceled
        } mutableCopy]
    };
    
	ICDSendNotification( &notePB );
}

@end
