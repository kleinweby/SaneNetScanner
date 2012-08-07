//
//  CSSequentialDataProvider.m
//  SaneNetScanner
//
//  Created by Christian Speich on 07.08.12.
//  Copyright (c) 2012 Christian Speich. All rights reserved.
//

#import "CSSequentialDataProvider.h"

@interface CSSequentialDataProvider ()

- (size_t) getBytes:(void*)buffer
             ofSize:(size_t)size;
- (off_t) skipBytes:(size_t)size;
- (void) rewind;

@property (nonatomic) FILE* fileHandle;
@property (nonatomic) NSUInteger hardOffset;

@end

static size_t __getBytes(void *info, void *buffer, size_t size)
{
    CSSequentialDataProvider* provider = (__bridge CSSequentialDataProvider*)info;
    
    return [provider getBytes:buffer ofSize:size];
}

static off_t __skipBytes(void *info, off_t size)
{
    CSSequentialDataProvider* provider = (__bridge CSSequentialDataProvider*)info;

    return [provider skipBytes:size];
}

static void __rewind(void *info)
{
    CSSequentialDataProvider* provider = (__bridge CSSequentialDataProvider*)info;

    [provider rewind];
}

static void __releaseProvider(void *info)
{
    CSSequentialDataProvider* provider = CFBridgingRelease(info);
#pragma unused(provider)
}

static CGDataProviderSequentialCallbacks callbacks = {0, __getBytes, __skipBytes, __rewind, __releaseProvider};

@implementation CSSequentialDataProvider

+ (CGDataProviderRef) createDataProviderWithFileAtURL:(NSURL*)url
                                        andHardOffset:(NSUInteger)hardoffset
{
    CSSequentialDataProvider* callbackObject = [[self alloc] initWithURL:url andHardOffset:hardoffset];
    
    return CGDataProviderCreateSequential((void*)CFBridgingRetain(callbackObject), &callbacks);
}

- (id)initWithURL:(NSURL*)url andHardOffset:(NSUInteger)hardOffset
{
    self = [super init];
    if (self) {
        self.fileHandle = fopen([[url path] fileSystemRepresentation], "r");
        [self rewind];
    }
    return self;
}

- (size_t) getBytes:(void*)buffer
             ofSize:(size_t)size
{
    return fread(buffer, 1, size, self.fileHandle);
}

- (off_t) skipBytes:(size_t)size
{
    return fseek(self.fileHandle, size, SEEK_CUR);
}

- (void) rewind
{
    fseek(self.fileHandle, self.hardOffset, SEEK_SET);
}

@end
