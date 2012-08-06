//
//  ICD_Trampolins.h
//  SaneNetScanner
//
//  Created by Christian Speich on 05.08.12.
//  Copyright (c) 2012 Christian Speich. All rights reserved.
//

#ifdef DEBUG
// This USB scanner is only ussed for debugging, when run inside Xcode
ICAError ICD_ScannerOpenUSBDevice(UInt32 locationID,
                                  ScannerObjectInfo* newDeviceObjectInfo);
#endif

ICAError ICD_ScannerOpenTCPIPDevice(CFDictionaryRef params,
                                    ScannerObjectInfo* newDeviceObjectInfo);

ICAError ICD_ScannerCloseDevice(ScannerObjectInfo* deviceObjectInfo);
ICAError ICD_ScannerCleanup(ScannerObjectInfo* objectInfo);

//ICAError ICD_ScannerPeriodicTask(ScannerObjectInfo* deviceObjectInfo);

//ICAError ICD_ScannerGetObjectInfo(const ScannerObjectInfo* parentInfo,
//                                   UInt32 index,
//                                   ScannerObjectInfo* newInfo);

ICAError ICD_ScannerReadFileData(const ScannerObjectInfo* objectInfo,
                                 UInt32 dataType,
                                 Ptr buffer,
                                 UInt32 offset,
                                 UInt32* length);

//ICAError ICD_ScannerSendMessage(const ScannerObjectInfo* objectInfo,
//                                 ICD_ScannerObjectSendMessagePB* pb,
//                                 ICDCompletion completion);

ICAError ICD_ScannerAddPropertiesToCFDictionary(ScannerObjectInfo* objectInfo,
                                                CFMutableDictionaryRef dict);

ICAError ICD_ScannerOpenSession(const ScannerObjectInfo* deviceObjectInfo,
                                ICD_ScannerOpenSessionPB* pb);
ICAError ICD_ScannerCloseSession(const ScannerObjectInfo* deviceObjectInfo,
                                 ICD_ScannerCloseSessionPB* pb);

ICAError ICD_ScannerGetParameters(const ScannerObjectInfo* deviceObjectInfo,
                                  ICD_ScannerGetParametersPB* pb);

ICAError ICD_ScannerSetParameters(const ScannerObjectInfo* deviceObjectInfo,
                                  ICD_ScannerSetParametersPB* pb);

ICAError ICD_ScannerStatus(const ScannerObjectInfo* deviceObjectInfo,
                           ICD_ScannerStatusPB* pb);
ICAError ICD_ScannerStart(const ScannerObjectInfo* deviceObjectInfo,
                          ICD_ScannerStartPB* pb);
