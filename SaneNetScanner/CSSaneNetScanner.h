//
//  CSSaneNetScanner.h
//  SaneNetScanner
//
//  Created by Christian Speich on 05.08.12.
//  Copyright (c) 2012 Christian Speich. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CSSaneNetScanner : NSObject

//
// This is used for TCPIP opening
//
// Example:
// {
//     ICABonjourDeviceLocationKey = "In the magic ether";
//     ICABonjourServiceNameKey = "Virtual Scanner Bonjour";
//     ICABonjourServiceTypeKey = "_scanner._tcp.";
//     ICABonjourTXTRecordKey =     {
//         mdl = <56697274 75616c20 5363616e 6e6572>;
//         mfg = <4170706c 65>;
//         note = <496e2074 6865206d 61676963 20657468 6572>;
//         scannerAvailable = <31>;
//         txtvers = <31>;
//         ty = <4170706c 65205669 72747561 6c205363 616e6e65 72>;
//     };
//     ICADeviceBrowserDeviceRefKey = 1;
//     UUIDString = "1D279211-1D27-9211-1D27-92111D279211";
//     deviceModulePath = "/System/Library/Image Capture/Devices/VirtualScanner.app";
//     deviceModuleVersion = 16809984;
//     deviceType = scanner;
//     hostGUID = "C933C548-A19F-4084-BF09-528438D6D581";
//     hostName = "Baskarans-MBP-UniMP";
//     ipAddress = "192.168.2.9";
//     "ipAddress_v6" = "fe80::3615:9eff:fe8a:9f9c";
//     ipGUID = "";
//     ipPort = 9500;
//     "ipPort_v6" = 9500;
//     name = "Apple Virtual Scanner";
//     persistentIDString = "1D279211-1D27-9211-1D27-92111D279211";
//     transportType = "TCP/IP";
// }
//
- (id) initWithParameters:(NSDictionary*)params;

@property (nonatomic, strong, readonly) NSString* prettyName;

// ICD Callbacks
- (ICAError) openSession:(ICD_ScannerOpenSessionPB*)params;
- (ICAError) closeSession:(ICD_ScannerCloseSessionPB*)params;

- (ICAError) addPropertiesToDictitonary:(NSMutableDictionary*)dict;

- (ICAError) getParameters:(ICD_ScannerGetParametersPB*)params;
- (ICAError) setParameters:(ICD_ScannerSetParametersPB*)params;

- (ICAError) status:(ICD_ScannerStatusPB*)params;
- (ICAError) start:(ICD_ScannerStartPB*)params;

@end
