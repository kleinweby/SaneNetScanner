//
//  CSSequentialDataProvider.h
//  SaneNetScanner
//
//  Created by Christian Speich on 07.08.12.
//  Copyright (c) 2012 Christian Speich. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CSSequentialDataProvider : NSObject

+ (CGDataProviderRef) createDataProviderWithFileAtURL:(NSURL*)url
                                        andHardOffset:(NSUInteger)hardoffset;

@end
