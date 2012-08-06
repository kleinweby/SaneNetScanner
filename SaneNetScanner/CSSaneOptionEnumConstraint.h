//
//  CSSaneOptionEnumConstraint.h
//  SaneNetScanner
//
//  Created by Christian Speich on 06.08.12.
//  Copyright (c) 2012 Christian Speich. All rights reserved.
//

#import "CSSaneOptionConstraint.h"

@interface CSSaneOptionEnumConstraint : CSSaneOptionConstraint

- (id) initWithDescriptor:(const SANE_Option_Descriptor*)descriptor;

@property (nonatomic, copy, readonly) NSArray* values;

@end
