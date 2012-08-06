//
//  CSSaneOptionRangeConstraint.h
//  SaneNetScanner
//
//  Created by Christian Speich on 06.08.12.
//  Copyright (c) 2012 Christian Speich. All rights reserved.
//

#import "CSSaneOptionConstraint.h"

@interface CSSaneOptionRangeConstraint : CSSaneOptionConstraint

- (id) initWithDescriptor:(const SANE_Option_Descriptor*)descriptor;

@property (nonatomic, copy, readonly) NSNumber* minValue;
@property (nonatomic, copy, readonly) NSNumber* maxValue;
@property (nonatomic, copy, readonly) NSNumber* step;

@end
