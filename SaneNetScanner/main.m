//
//  main.m
//  SaneNetScanner
//
//  Created by Christian Speich on 05.08.12.
//  Copyright (c) 2012 Christian Speich. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ICD_Trampolins.h"
#import "sane/sane.h"

int main(int argc, char *argv[])
{
    int status = 0;
    SANE_Status saneStatus;
    
    saneStatus = sane_init(NULL, NULL);
    
    if (saneStatus != SANE_STATUS_GOOD) {
        NSLog(@"Sane init failed");
        return -1;
    }
    
#ifdef DEBUG
    gICDScannerCallbackFunctions.f_ICD_ScannerOpenUSBDevice = ICD_ScannerOpenUSBDevice;
#endif
    
    gICDScannerCallbackFunctions.f_ICD_ScannerOpenFireWireDeviceWithIORegPath = NULL;
    
    gICDScannerCallbackFunctions.f_ICD_ScannerOpenTCPIPDevice                 = ICD_ScannerOpenTCPIPDevice;
    gICDScannerCallbackFunctions.f_ICD_ScannerCloseDevice                     = ICD_ScannerCloseDevice;
    gICDScannerCallbackFunctions.f_ICD_ScannerPeriodicTask                    = NULL;
    gICDScannerCallbackFunctions.f_ICD_ScannerGetObjectInfo                   = NULL;
    gICDScannerCallbackFunctions.f_ICD_ScannerCleanup                         = ICD_ScannerCleanup;
    gICDScannerCallbackFunctions.f_ICD_ScannerGetPropertyData                 = NULL;   // Unused
    gICDScannerCallbackFunctions.f_ICD_ScannerSetPropertyData                 = NULL;   // Unused
    gICDScannerCallbackFunctions.f_ICD_ScannerReadFileData                    = ICD_ScannerReadFileData;
    gICDScannerCallbackFunctions.f_ICD_ScannerWriteDataToFile                 = NULL;   // Unused
    gICDScannerCallbackFunctions.f_ICD_ScannerWriteFileData                   = NULL;   // Unused
    gICDScannerCallbackFunctions.f_ICD_ScannerSendMessage                     = NULL;
    gICDScannerCallbackFunctions.f_ICD_ScannerAddPropertiesToCFDictionary     = ICD_ScannerAddPropertiesToCFDictionary;
    
    gICDScannerCallbackFunctions.f_ICD_ScannerOpenSession                     = ICD_ScannerOpenSession;
    gICDScannerCallbackFunctions.f_ICD_ScannerCloseSession                    = ICD_ScannerCloseSession;
    gICDScannerCallbackFunctions.f_ICD_ScannerInitialize                      = NULL;   // Unused
    gICDScannerCallbackFunctions.f_ICD_ScannerGetParameters                   = ICD_ScannerGetParameters;
    gICDScannerCallbackFunctions.f_ICD_ScannerSetParameters                   = ICD_ScannerSetParameters;
    gICDScannerCallbackFunctions.f_ICD_ScannerStatus                          = ICD_ScannerStatus;
    gICDScannerCallbackFunctions.f_ICD_ScannerStart                           = ICD_ScannerStart;
    
    status = ICD_ScannerMain(argc, (const char **)argv);

    sane_exit();
    
    return status;
}
