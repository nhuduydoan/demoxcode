//
//  DXDownloadManager.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/1/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXDownloadManager.h"
#import "DXDownloadModel.h"
#import "AFURLSessionManager.h"
#import "DXFileManager.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface DXDownloadManager ()

@property (strong, nonatomic) NSMutableSet *delegates;
@property (strong, nonatomic) AFURLSessionManager *sessionManager;

@end

@implementation DXDownloadManager

+ (id)sharedInstance {
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self.class alloc] initSharedInstance];
    });
    return instance;
}

- (instancetype)initSharedInstance {
    self = [super init];
    if (self) {
        _sessionManager = [[AFURLSessionManager alloc] init];
        _delegates =  (__bridge_transfer NSMutableSet *)CFSetCreateMutable(nil, 0, nil);
    }
    return self;
}

- (instancetype) init {
    [super doesNotRecognizeSelector:_cmd];
    self = nil;
    return nil;
}

#pragma mark - Download


- (void)downloadWithModel:(DXDownloadModel *)model {
    
    if (model.request) {
        NSParameterAssert(model.request.URL && model.request.URL.scheme && model.request.URL.host);
    } else {
        NSParameterAssert(model.URL && model.URL.scheme && model.URL.host);
    }
    
    NSMutableURLRequest *request = model.request;
    if (!request) {
        request = [NSMutableURLRequest requestWithURL:model.URL];
        request.HTTPMethod = @"GET";
    }
    
    
    NSURL *(^destinationBLock)(NSURL *targetPath, NSURLResponse *response) = ^(NSURL *targetPath, NSURLResponse *response) {
        //Update new file name, extension
        CFStringRef mimeType = (__bridge CFStringRef) [response MIMEType];
        CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType, NULL);
        NSString *extension = (__bridge NSString *) UTTypeCopyPreferredTagWithClass(uti, kUTTagClassFilenameExtension);
        if (uti) CFRelease(uti);
        NSString *fileName = [response suggestedFilename];
        if ([extension length] > 0) {
            fileName = [[fileName stringByDeletingPathExtension] stringByAppendingPathExtension:extension];
        }
        NSString *filePath = [sFileManager generateNewPathForTargetPath:model.targetPath fileName:fileName];return [NSURL URLWithString:filePath];
    };
    
    void(^completionBLock)(NSURLResponse *response, NSURL *filePath, NSError *error) = ^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        
        if (error) {
            [[NSFileManager defaultManager] removeItemAtURL:filePath error:nil];
        } else {
            NSLog(@"File downloaded to: %@", filePath);
            [self callDelegateDownloadDidfinish:filePath.copy];
        }
    };
    
    NSURLSessionDownloadTask *downloadTask =
    [self.sessionManager downloadTaskWithRequest:request
                                        progress:nil
                                     destination:destinationBLock
                               completionHandler:completionBLock];
    
//    [self.sessionManager setDownloadTaskDidFinishDownloadingBlock:^NSURL * _Nullable(NSURLSession * _Nonnull session, NSURLSessionDownloadTask * _Nonnull downloadTask, NSURL * _Nonnull location) {
//        return nil;
//    }];
    
    [downloadTask resume];
}

#pragma mark - Private

#pragma mark - Delegate

- (void)addDelegate:(id<DXDownloadManagerDelegate>)delegate {
    [self.delegates addObject:delegate];
}

- (void)removeDelegate:(id<DXDownloadManagerDelegate>)delegate {
    [self.delegates removeObject:delegate];
}

- (void)callDelegateDownloadDidfinish:(NSURL *)filePath {
    for (id<DXDownloadManagerDelegate> delegate in self.delegates) {
        if ([delegate respondsToSelector:@selector(downloadManager:downloadDidFinish:)]) {
            [delegate downloadManager:self downloadDidFinish:filePath];
        }
    }
}

@end
