//
//  CSSaneOption.h
//  SaneNetScanner
//
//  Created by Christian Speich on 06.08.12.
//  Copyright (c) 2012 Christian Speich. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "sane/sane.h"
#import "CSSaneOptionConstraint.h"

extern NSString* kSaneScanResolution;
extern NSString* kSaneScanMode;
extern NSString* kSanePreview;
extern NSString* kSaneTopLeftX;
extern NSString* kSaneTopLeftY;
extern NSString* kSaneBottomRightX;
extern NSString* kSaneBottomRightY;

@interface CSSaneOption : NSObject

+ (NSArray*) saneOptionsForHandle:(SANE_Handle)handle;

@property (nonatomic, copy, readonly) NSString* name;

// The Value may be an string or an number
// Note: setting it will talk to the device
// getting it may do also so
@property (nonatomic, copy) id value;

@property (nonatomic, strong, readonly) CSSaneOptionConstraint* constraint;

@end
