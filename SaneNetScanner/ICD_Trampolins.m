//
//  ICD_Trampolins.c
//  SaneNetScanner
//
//  Created by Christian Speich on 05.08.12.
//  Copyright (c) 2012 Christian Speich. All rights reserved.
//

#include <stdio.h>
#include "ICD_Trampolins.h"
#import "CSSaneNetScanner.h"

#ifdef DEBUG

const UInt32 fakeLocation =  0xDEADBEEF;

// This USB scanner is only ussed for debugging, when run inside Xcode
ICAError ICD_ScannerOpenUSBDevice(UInt32 locationID,
                                  ScannerObjectInfo* newDeviceObjectInfo)
{
    ICAError  err = paramErr;

    // If the location id is zero we're launched by xcode (debug)
    if (locationID == 0)
    {        
        err = ICDConnectUSBDevice(fakeLocation);
    }
    // This is the fake device we just connected
    else if (locationID == fakeLocation) {
        return ICD_ScannerOpenTCPIPDevice((__bridge CFDictionaryRef)(@{
            (NSString*)kICABonjourServiceNameKey: @"Mustek 1200 CU",
            (NSString*)kICABonjourServiceTypeKey: @"_sane-scanner._tcp",
            (NSString*)kICABonjourTXTRecordKey: @{
                @"saned": [@"YES" dataUsingEncoding:NSUTF8StringEncoding],
                @"ty": [@"Mustek 1200 CU" dataUsingEncoding:NSUTF8StringEncoding],
                @"name": [@"Mustek 1200 CU" dataUsingEncoding:NSUTF8StringEncoding],
                @"deviceName": [@"mustek_usb:libusb:001:008" dataUsingEncoding:NSUTF8StringEncoding],
            },
            (NSString*)kICADeviceBrowserDeviceRefKey: @1,
            @"UUIDString": @"1D279211-1D27-9211-1D27-92111D279211",
            @"ipAddress": @"10.0.1.5",
            @"ipPort": @9500,
            @"name": @"Mustek 1200 CU",
            @"transportType": @"TCP/IP"
        }),
                                          newDeviceObjectInfo);
    }
    
    return err;
}

#endif

ICAError ICD_ScannerOpenTCPIPDevice(CFDictionaryRef params,
                                    ScannerObjectInfo* newDeviceObjectInfo)
{
    CSSaneNetScanner* scanner;
    
    // Create the scanner
    scanner = [[CSSaneNetScanner alloc] initWithParameters:(__bridge NSDictionary *)(params)];
    
    if (!scanner)
        return paramErr;
    
    // Populate the scanner structure
    newDeviceObjectInfo->privateData = (Ptr)CFBridgingRetain(scanner);
    scanner.scannerObjectInfo = newDeviceObjectInfo;
    newDeviceObjectInfo->flags = 0;
    // All scanner clients are based on ImageCaptureCore framework, which dynamically determines
    // size of thumbnails. So, we do not need to know the exact size of the thumbnail. Set this
    // to 1 if we have a thumbnail.
    newDeviceObjectInfo->thumbnailSize = 1;
    
    newDeviceObjectInfo->dataSize = 0;
    
    // Obvious, right?
    newDeviceObjectInfo->icaObjectInfo.objectType = kICADevice;
    newDeviceObjectInfo->icaObjectInfo.objectSubtype = kICADeviceScanner;
    
    // Set the device name
    // TODO: set the device name
    strlcpy((char*)newDeviceObjectInfo->name, [scanner.prettyName UTF8String], sizeof(newDeviceObjectInfo->name));

    // Now set the creation date
    NSDateFormatter* df  = [[NSDateFormatter alloc] initWithDateFormat:@"%Y:%m:%d %H:%M:%S" allowNaturalLanguage:YES];
    NSDate* d = [NSDate date];
    NSString* ds = [df stringFromDate:d];
    
    if (ds)
        strlcpy((char*)(newDeviceObjectInfo->creationDate),
                [ds UTF8String],
                sizeof(newDeviceObjectInfo->creationDate));
    else
        strlcpy((char*)(newDeviceObjectInfo->creationDate),
                "0000:00:00 00:00:00",
                sizeof(newDeviceObjectInfo->creationDate) );
        
    return noErr;
}

ICAError ICD_ScannerCloseDevice(ScannerObjectInfo* deviceObjectInfo)
{
    assert(false);
}

ICAError ICD_ScannerCleanup(ScannerObjectInfo* objectInfo)
{
    assert(false);
}

ICAError ICD_ScannerReadFileData(const ScannerObjectInfo* objectInfo,
                                 UInt32 dataType,
                                 Ptr buffer,
                                 UInt32 offset,
                                 UInt32* length)
{
    assert(false);
}

ICAError ICD_ScannerAddPropertiesToCFDictionary(ScannerObjectInfo* objectInfo,
                                                CFMutableDictionaryRef dict)
{
    CSSaneNetScanner* scanner = (__bridge CSSaneNetScanner*)(void*)(objectInfo->privateData);
    
    return [scanner addPropertiesToDictitonary:(__bridge NSMutableDictionary*)dict];
}

ICAError ICD_ScannerOpenSession(const ScannerObjectInfo* deviceObjectInfo,
                                ICD_ScannerOpenSessionPB* pb)
{
    CSSaneNetScanner* scanner = (__bridge CSSaneNetScanner*)(void*)(deviceObjectInfo->privateData);
    
    return [scanner openSession:pb];
}

ICAError ICD_ScannerCloseSession(const ScannerObjectInfo* deviceObjectInfo,
                                 ICD_ScannerCloseSessionPB* pb)
{
    CSSaneNetScanner* scanner = (__bridge CSSaneNetScanner*)(void*)(deviceObjectInfo->privateData);
    
    return [scanner closeSession:pb];
}

ICAError ICD_ScannerGetParameters(const ScannerObjectInfo* deviceObjectInfo,
                                  ICD_ScannerGetParametersPB* pb)
{
    CSSaneNetScanner* scanner = (__bridge CSSaneNetScanner*)(void*)(deviceObjectInfo->privateData);
    
    return [scanner getParameters:pb];
}

ICAError ICD_ScannerSetParameters(const ScannerObjectInfo* deviceObjectInfo,
                                  ICD_ScannerSetParametersPB* pb)
{
    CSSaneNetScanner* scanner = (__bridge CSSaneNetScanner*)(void*)(deviceObjectInfo->privateData);
    
    return [scanner setParameters:pb];
}

ICAError ICD_ScannerStatus(const ScannerObjectInfo* deviceObjectInfo,
                           ICD_ScannerStatusPB* pb)
{
    CSSaneNetScanner* scanner = (__bridge CSSaneNetScanner*)(void*)(deviceObjectInfo->privateData);
    
    return [scanner status:pb];
}

ICAError ICD_ScannerStart(const ScannerObjectInfo* deviceObjectInfo,
                          ICD_ScannerStartPB* pb)
{
    CSSaneNetScanner* scanner = (__bridge CSSaneNetScanner*)(void*)(deviceObjectInfo->privateData);
    
    return [scanner start:pb];
}
