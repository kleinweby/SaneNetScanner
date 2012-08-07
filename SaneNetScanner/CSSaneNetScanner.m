//
//  CSSaneNetScanner.m
//  SaneNetScanner
//
//  Created by Christian Speich on 05.08.12.
//  Copyright (c) 2012 Christian Speich. All rights reserved.
//

#import "CSSaneNetScanner.h"

#import "CSSequentialDataProvider.h"

#import "CSSaneOption.h"
#import "CSSaneOptionRangeConstraint.h"

#include "sane/sane.h"

typedef enum {
    ProgressNotificationsNone,
    ProgressNotificationsWithData,
    ProgressNotificationsWithoutData
} ProgressNotifications;

@interface CSSaneNetScanner ()

@property (nonatomic, strong) NSString* prettyName;

@property (nonatomic, strong) NSMutableDictionary* deviceProperties;

@property (nonatomic) BOOL open;

@property (nonatomic) SANE_Handle saneHandle;

@property (nonatomic) NSArray* saneOptions;

@property (nonatomic) ProgressNotifications progressNotifications;
@property (nonatomic) BOOL produceFinalScan;

@property (nonatomic) NSString* colorSyncMode;

@property (nonatomic, assign) CGColorSpaceRef colorSpace;

@property (nonatomic) NSURL* rawFileURL;
@property (nonatomic) NSURL* documentURL;
@property (nonatomic) NSString* documentType;

@end

@interface CSSaneNetScanner (Progress)

- (void) showWarmUpMessage;
- (void) doneWarmUpMessage;
- (void) pageDoneMessage;
- (void) scanDoneMessage;

- (void) sendTransactionCanceledMessage;

@end

@interface CSSaneNetScanner (ICARawFile)

- (void) createColorSpaceWithSaneParameters:(SANE_Parameters*)parameters;
- (void) writeHeaderToFile:(NSFileHandle*)handle
        withSaneParameters:(SANE_Parameters*)parameters;

- (void) resaveRawFileAt:(NSURL*)url
                  asType:(NSString*)type
                   toURL:(NSURL*)url
          saneParameters:(SANE_Parameters*)parameters;

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

- (void)dealloc
{
    if (self.open || self.saneHandle != 0) {
        LogMessageCompat(@"Deallocating but sane handle is still open");
        sane_close(self.saneHandle);
        self.saneHandle = 0;
    }
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
    // Add kICAUserAssignedDeviceNameKey.  Since this key is a simple NSString,
    // the value may be of any length.  This key supercedes any name already
    // provided in the device information before, which is limited to 32 characters.
    [dict setObject:self.prettyName
             forKey:(NSString*)kICAUserAssignedDeviceNameKey];
    
    // Add key indicating that the module supports using the ICA Raw File
    // as a backing store for image io
    [dict setObject:[NSNumber numberWithInt:1]
             forKey:@"supportsICARawFileFormat"];
    
    LogMessageCompat(@"addPropertiesToDictitonary:%@", dict);
    
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

    @"ICAP_SUPPORTEDSIZES": @{ @"current": @1, @"default": @1, @"type": @"TWON_ENUMERATION", @"value": @[ @1, @2, @3, @4, @5, @10, @0 ]},
    
    @"ICAP_UNITS": @{ @"current": @0, @"default": @0, @"type": @"TWON_ENUMERATION", @"value": @[ @0, @1, @5 ] },
    
    } mutableCopy];
        
    self.saneOptions = [CSSaneOption saneOptionsForHandle:self.saneHandle];
    
    for (CSSaneOption* option in self.saneOptions) {
        if ([option.name isEqualToString:kSaneScanResolution]) {
            NSMutableDictionary* d = [NSMutableDictionary dictionary];
            
            [option.constraint addToDeviceDictionary:d];
            d[@"current"] = option.value;
            d[@"default"] = option.value;
            
            deviceDict[@"ICAP_XRESOLUTION"] = d;
            deviceDict[@"ICAP_YRESOLUTION"] = d;
        }
        else if ([@[ kSaneTopLeftX, kSaneBottomRightX ] containsObject:option.name]) {
            // Convert to inch (will be reported as mm)
            CSSaneOptionRangeConstraint* constraint = (CSSaneOptionRangeConstraint*)option.constraint;
            double width = ([constraint.maxValue doubleValue] - [constraint.minValue doubleValue])/25.4;
            
            // If already exists look if the new width is smaller and update if so
            if (deviceDict[@"ICAP_PHYSICALWIDTH"]) {
                if ([deviceDict[@"ICAP_PHYSICALWIDTH"][@"value"] doubleValue] > width) {
                    deviceDict[@"ICAP_PHYSICALWIDTH"] = @{
                        @"type": @"TWON_ONEVALUE",
                        @"value": [NSNumber numberWithDouble:width]
                    };
                }
            }
            // Not present yes, so set
            else {
                deviceDict[@"ICAP_PHYSICALWIDTH"] = @{
                    @"type": @"TWON_ONEVALUE",
                    @"value": [NSNumber numberWithDouble:width]
                };
            }
        }
        else if ([@[ kSaneTopLeftY, kSaneBottomRightY ] containsObject:option.name]) {
            // Convert to inch (will be reported as mm)
            CSSaneOptionRangeConstraint* constraint = (CSSaneOptionRangeConstraint*)option.constraint;
            double height = ([constraint.maxValue doubleValue] - [constraint.minValue doubleValue])/25.4;
            
            // If already exists look if the new width is smaller and update if so
            if (deviceDict[@"ICAP_PHYSICALHEIGHT"]) {
                if ([deviceDict[@"ICAP_PHYSICALHEIGHT"][@"value"] doubleValue] > height) {
                    deviceDict[@"ICAP_PHYSICALHEIGHT"] = @{
                    @"type": @"TWON_ONEVALUE",
                    @"value": [NSNumber numberWithDouble:height]
                    };
                }
            }
            // Not present yes, so set
            else {
                deviceDict[@"ICAP_PHYSICALHEIGHT"] = @{
                @"type": @"TWON_ONEVALUE",
                @"value": [NSNumber numberWithDouble:height]
                };
            }
        }
        else {
            LogMessageCompat(@"Option %@ not exported", option);
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
    
    LogMessageCompat(@"Updated parameters %@", dict);
    
    return noErr;
}

- (ICAError) setParameters:(ICD_ScannerSetParametersPB*)params
{
    LogMessageCompat(@"Set params: %@", params->theDict);
    NSDictionary* dict = ((__bridge NSDictionary *)(params->theDict))[@"userScanArea"];

    
    {
        NSString* documentPath = dict[@"document folder"];
        documentPath = [documentPath stringByAppendingPathComponent:dict[@"document name"]];
        documentPath = [documentPath stringByAppendingPathExtension:dict[@"document extension"]];
        
        if (documentPath) {
            self.documentURL = [NSURL fileURLWithPath:documentPath];
            self.documentType = dict[@"document format"];
        }
        
        // RAW is not requested, so we need a temporary raw file
        if (![self.documentType isEqualToString:@"com.apple.ica.raw"] && !self.rawFileURL) {
            self.rawFileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingFormat:@"scan-raw-%@.ica", [[NSUUID UUID] UUIDString]]];
        }
    }
        
    int unit = [dict[@"ICAP_UNITS"][@"value"] intValue];
        
    for (CSSaneOption* option in self.saneOptions) {
        if ([option.name isEqualToString:kSaneScanMode] && dict[@"ColorSyncMode"]) {
            NSString* syncMode = dict[@"ColorSyncMode"];
            if ([syncMode isEqualToString:@"scanner.reflective.RGB.positive"]) {
                option.value = @"Color";
            }
            else {
                LogMessageCompat(@"Unkown colorsyncmode %@", syncMode);
            }
        }
        // X and Y resolution are always equal
        else if ([option.name isEqualToString:kSaneScanResolution] && (dict[@"ICAP_XRESOLUTION"] || dict[@"ICAP_XRESOLUTION"])) {
            if (unit == 1 /* Centimeter */) {
                // Convert dpcm to dpi
                // 1 dpcm = 2,54 dpi
                option.value = [NSNumber numberWithDouble:[dict[@"ICAP_XRESOLUTION"][@"value"] doubleValue] / 2.54];
            }
            else if (unit == 0 /* Inches */) {
                // Great nothing to to here =)
                option.value = dict[@"ICAP_XRESOLUTION"][@"value"];
            }
        }
        else if ([option.name isEqualToString:kSanePreview] && dict[@"scan mode"]) {
            if ([dict[@"scan mode"] isEqualToString:@"overview"]) {
                option.value = @1;
            }
            else {
                option.value = @0;
            }
        }
        else if ([option.name isEqualToString:kSaneTopLeftX] && dict[@"offsetX"]) {
            if (unit == 1 /* Centimeter */) {
                // Convert cm to mm
                option.value = [NSNumber numberWithDouble:[dict[@"offsetX"] doubleValue] * 10];
            }
            else if (unit == 0 /* Inches */) {
                // Convert inches to mm
                option.value = [NSNumber numberWithDouble:[dict[@"offsetX"] doubleValue] * 25.4];
            }
        }
        else if ([option.name isEqualToString:kSaneTopLeftY] && dict[@"offsetY"]) {
            if (unit == 1 /* Centimeter */) {
                // Convert cm to mm
                option.value = [NSNumber numberWithDouble:[dict[@"offsetX"] doubleValue] * 10];
            }
            else if (unit == 0 /* Inches */) {
                // Convert inches to mm
                option.value = [NSNumber numberWithDouble:[dict[@"offsetX"] doubleValue] * 25.4];
            }
        }
        else if ([option.name isEqualToString:kSaneBottomRightX] && dict[@"width"]) {
            double value = [dict[@"offsetX"] doubleValue] + [dict[@"width"] doubleValue];
            if (unit == 1 /* Centimeter */) {
                // Convert cm to mm
                option.value = [NSNumber numberWithDouble:value * 10];
            }
            else if (unit == 0 /* Inches */) {
                // Convert inches to mm
                option.value = [NSNumber numberWithDouble:value * 25.4];
            }
        }
        else if ([option.name isEqualToString:kSaneBottomRightY] && dict[@"height"]) {
            double value = [dict[@"offsetY"] doubleValue] + [dict[@"height"] doubleValue];
            if (unit == 1 /* Centimeter */) {
                // Convert cm to mm
                option.value = [NSNumber numberWithDouble:value * 10];
            }
            else if (unit == 0 /* Inches */) {
                // Convert inches to mm
                option.value = [NSNumber numberWithDouble:value * 25.4];
            }
        }
    }
        
    if ([dict[@"progressNotificationWithData"] boolValue]) {
        self.progressNotifications = ProgressNotificationsWithData;
    }
    else if ([dict[@"progressNotificationNoData"] boolValue]) {
        self.progressNotifications = ProgressNotificationsWithoutData;
    }
    else {
        self.progressNotifications = ProgressNotificationsNone;
    }
    
    if ([dict[@"scan mode"] isEqualToString:@"overview"])
        self.produceFinalScan = NO;
    else
        self.produceFinalScan = YES;
    
    self.colorSyncMode = dict[@"ColorSyncMode"];
    
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
    
    
    LogMessageCompat(@"Prepare raw file");
    NSFileHandle* rawFileHandle;
    
    if (![self.documentType isEqualToString:@"com.apple.ica.raw"]) {
        [[NSFileManager defaultManager] createFileAtPath:[self.rawFileURL path]
                                                contents:nil
                                              attributes:nil];
        rawFileHandle = [NSFileHandle fileHandleForWritingAtPath:[self.rawFileURL path]];
    }
    else {
        [[NSFileManager defaultManager] createFileAtPath:[self.documentURL path]
                                                contents:nil
                                              attributes:nil];
        rawFileHandle = [NSFileHandle fileHandleForWritingAtPath:[self.documentURL path]];
    }
    
    [self createColorSpaceWithSaneParameters:&parameters];
    
    // Write header
    [self writeHeaderToFile:rawFileHandle
         withSaneParameters:&parameters];

    
    LogMessageCompat(@"Prepare buffers");
    int bufferSize;
    int bufferdRows;
    NSMutableData* buffer;
    
    // Choose buffer size
    //
    //  Use a buffer size around 50KiB.
    //  the size will be aligned to row boundries
    bufferdRows = MIN(500*1025 / parameters.bytes_per_line, parameters.lines);
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

        // Means we have to save the data somewhere
        if (self.produceFinalScan) {
            [rawFileHandle writeData:buffer];
        }
        
        // Notify the image capture kit that we made progress
        if (self.progressNotifications != ProgressNotificationsNone) {
            ICASendNotificationPB notePB = {};
            NSMutableDictionary* d = [@{
                                      (id)kICANotificationICAObjectKey: [NSNumber numberWithUnsignedInt:self.scannerObjectInfo->icaObject],
                                      (id)kICANotificationTypeKey: (id)kICANotificationTypeScanProgressStatus
                                      } mutableCopy];
            
            notePB.notificationDictionary = (__bridge CFMutableDictionaryRef)d;
            
            // Add image with data
            if (self.progressNotifications == ProgressNotificationsWithData) {
                ICDAddImageInfoToNotificationDictionary(notePB.notificationDictionary,
                                                        parameters.pixels_per_line,
                                                        parameters.lines,
                                                        parameters.bytes_per_line,
                                                        row,
                                                        bufferdRows,
                                                        (UInt32)[buffer length],
                                                        (void*)[buffer bytes]);
            }
            // Add image info without data
            else {
                ICDAddImageInfoToNotificationDictionary(notePB.notificationDictionary,
                                                        parameters.pixels_per_line,
                                                        parameters.lines,
                                                        parameters.bytes_per_line,
                                                        row,
                                                        bufferdRows,
                                                        0,
                                                        NULL);
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
        }
        LogMessageCompat(@"Read line %i", row);
        row+=bufferdRows;
    } while (status == SANE_STATUS_GOOD);

    // We now need to read the raw file and produce a formatted version
    if (self.produceFinalScan) {
        if (![self.documentType isEqualToString:@"com.apple.ica.raw"]) {
            [self resaveRawFileAt:self.rawFileURL
                           asType:self.documentType
                            toURL:self.documentURL
                   saneParameters:&parameters];
        }
    }
    
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
    ICASendNotificationPB notePB = {};
    NSMutableDictionary* dict = [@{
            (id)kICANotificationICAObjectKey: [NSNumber numberWithUnsignedInt:self.scannerObjectInfo->icaObject],
            (id)kICANotificationTypeKey: (id)kICANotificationTypeDeviceStatusInfo,
            (id)kICANotificationSubTypeKey: (id)kICANotificationSubTypeWarmUpStarted
    } mutableCopy];
    notePB.notificationDictionary = (__bridge CFMutableDictionaryRef)dict;
    
	ICDSendNotification( &notePB );
}

- (void) doneWarmUpMessage
{
    ICASendNotificationPB notePB = {};
    NSMutableDictionary* dict = [@{
        (id)kICANotificationICAObjectKey: [NSNumber numberWithUnsignedInt:self.scannerObjectInfo->icaObject],
        (id)kICANotificationTypeKey: (id)kICANotificationTypeDeviceStatusInfo,
        (id)kICANotificationSubTypeKey: (id)kICANotificationSubTypeWarmUpDone
    } mutableCopy];
    notePB.notificationDictionary = (__bridge CFMutableDictionaryRef)dict;
    
	ICDSendNotification( &notePB );
}

- (void) pageDoneMessage
{
    ICASendNotificationPB notePB = {};
    NSMutableDictionary* dict = [@{
        (id)kICANotificationICAObjectKey: [NSNumber numberWithUnsignedInt:self.scannerObjectInfo->icaObject],
        (id)kICANotificationTypeKey: (id)kICANotificationTypeScannerPageDone,
    } mutableCopy];
    notePB.notificationDictionary = (__bridge CFMutableDictionaryRef)dict;
    
    if (self.documentURL)
        ((__bridge NSMutableDictionary*)notePB.notificationDictionary)[(id)kICANotificationScannerDocumentNameKey] = [self.documentURL path];


	ICDSendNotification( &notePB );
}

- (void) scanDoneMessage
{
    ICASendNotificationPB notePB = {};
    NSMutableDictionary* dict = [@{
        (id)kICANotificationICAObjectKey: [NSNumber numberWithUnsignedInt:self.scannerObjectInfo->icaObject],
        (id)kICANotificationTypeKey: (id)kICANotificationTypeScannerScanDone
    } mutableCopy];
    notePB.notificationDictionary = (__bridge CFMutableDictionaryRef)dict;
    
	ICDSendNotification( &notePB );
}

- (void) sendTransactionCanceledMessage
{
    ICASendNotificationPB notePB = {};
    NSMutableDictionary* dict = [@{
        (id)kICANotificationICAObjectKey: [NSNumber numberWithUnsignedInt:self.scannerObjectInfo->icaObject],
        (id)kICANotificationTypeKey: (id)kICANotificationTypeTransactionCanceled
    } mutableCopy];
    notePB.notificationDictionary = (__bridge CFMutableDictionaryRef)dict;
    
	ICDSendNotification( &notePB );
}

@end

@implementation CSSaneNetScanner (ICARawFile)

- (void) createColorSpaceWithSaneParameters:(SANE_Parameters*)parameters
{
    NSString* profilePath = [NSTemporaryDirectory() stringByAppendingFormat:@"vs-%d",getpid()];

    self.colorSpace = ICDCreateColorSpace(3 * parameters->depth,
                                          3,
                                          self.scannerObjectInfo->icaObject,
                                          (__bridge CFStringRef)(self.colorSyncMode),
                                          NULL,
                                          (char*)[profilePath fileSystemRepresentation]);
}

- (void) writeHeaderToFile:(NSFileHandle*)handle
        withSaneParameters:(SANE_Parameters*)parameters
{
    ICARawFileHeader h;
    
    h.imageDataOffset      = sizeof(ICARawFileHeader);
    h.version              = 1;
    h.imageWidth           = parameters->pixels_per_line;
    h.imageHeight          = parameters->lines;
    h.bytesPerRow          = parameters->bytes_per_line;
    h.bitsPerComponent     = parameters->depth;
    h.bitsPerPixel         = 3 * parameters->depth;
    h.numberOfComponents   = 3;
    h.cgColorSpaceModel    = CGColorSpaceGetModel(self.colorSpace);
    h.bitmapInfo           = kCGImageAlphaNone;
    h.dpi                  = 75;
    h.orientation          = 1;
    strlcpy(h.colorSyncModeStr, [self.colorSyncMode UTF8String], sizeof(h.colorSyncModeStr));
    
    [handle writeData:[NSData dataWithBytesNoCopy:&h
                                           length:sizeof(ICARawFileHeader)
                                     freeWhenDone:NO]];
}

- (void) resaveRawFileAt:(NSURL*)url
                  asType:(NSString*)type
                   toURL:(NSURL*)destUrl
          saneParameters:(SANE_Parameters*)parameters
{
    CGImageDestinationRef dest = CGImageDestinationCreateWithURL((__bridge CFURLRef)destUrl, (__bridge CFStringRef)type, 1, nil);
    CGDataProviderRef provider = [CSSequentialDataProvider createDataProviderWithFileAtURL:url
                                                                             andHardOffset:sizeof(ICARawFileHeader)];
    
    CGImageRef image = CGImageCreate(parameters->pixels_per_line,
                                     parameters->lines,
                                     parameters->depth,
                                     3 * parameters->depth,
                                     parameters->bytes_per_line,
                                     self.colorSpace,
                                     kCGImageAlphaNone,
                                     provider,
                                     NULL,
                                     NO, kCGRenderingIntentDefault);
    
    CGImageDestinationAddImage(dest, image, nil);
    
    
    CGImageDestinationFinalize(dest);
}

@end
