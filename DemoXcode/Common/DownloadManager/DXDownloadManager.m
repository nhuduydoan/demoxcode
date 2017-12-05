//
//  DXDownloadManager.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/1/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXDownloadManager.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "DXFileManager.h"
#import "DXDownloadModel.h"
#import "DXDownloadComponent.h"

@interface DXDownloadManager () <NSURLSessionDownloadDelegate>

@property (strong, nonatomic) NSURLSession *sessionManager;
@property (strong, nonatomic) NSProgress *downloadProgress;
@property (strong, nonatomic) NSMutableSet<DXDownloadComponent *> *downloadsArr;

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
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        _sessionManager = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
        _downloadsArr = [NSMutableSet new];
    }
    return self;
}

- (instancetype) init {
    [super doesNotRecognizeSelector:_cmd];
    self = nil;
    return nil;
}

#pragma mark - Download


- (DXDownloadComponent  *)downloadWithModel:(DXDownloadModel *)model {
    if (model.request) {
        NSParameterAssert(model.request.URL && model.request.URL.scheme && model.request.URL.host);
    } else {
        NSParameterAssert(model.URL && model.URL.scheme && model.URL.host);
    }
    
    DXDownloadComponent *component = [self omponentDownloadForModel:model];
    if (component && component.downloadTask) {
        switch (component.downloadTask.state) {
            case NSURLSessionTaskStateRunning:
                return component;
                break;
            case NSURLSessionTaskStateSuspended:
                [component.downloadTask resume];
                return component;
                break;
            default:
                [self.downloadsArr removeObject:component];
                break;
        }
    }
    
    NSMutableURLRequest *request = model.request;
    if (!request) {
        request = [NSMutableURLRequest requestWithURL:model.URL];
        request.HTTPMethod = @"GET";
    }
    NSURLSessionDownloadTask *downloadTask = [self.sessionManager downloadTaskWithRequest:request];
    DXDownloadComponent *newComponent = [[DXDownloadComponent alloc] initWithDownloadModel:model downloadTask:downloadTask];
    [newComponent resume];
    [self.downloadsArr addObject:newComponent];
    return newComponent;
}

- (DXDownloadComponent *)omponentDownloadForModel:(DXDownloadModel *)model {
    for (DXDownloadComponent *component in self.downloadsArr) {
        if ([component.downloadModel isEqual:model]) {
            return component;
        }
    }
    return nil;
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session
      downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    NSLog(@"%f: %lld / %lld", (float)totalBytesWritten/totalBytesExpectedToWrite , totalBytesWritten, totalBytesExpectedToWrite);
    for (DXDownloadComponent *component in self.downloadsArr) {
        if (component.downloadTask == downloadTask) {
            [component URLSession:session downloadTask:downloadTask
                     didWriteData:bytesWritten
                totalBytesWritten:totalBytesWritten
        totalBytesExpectedToWrite:totalBytesExpectedToWrite];
        }
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:
(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL * _Nonnull)location {
    
    for (DXDownloadComponent *component in self.downloadsArr) {
        if (component.downloadTask == downloadTask) {
            [component URLSession:session downloadTask:downloadTask didFinishDownloadingToURL:location];
        }
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(nonnull NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error {
    
    for (DXDownloadComponent *component in self.downloadsArr) {
        if (component.downloadTask == task) {
            [component URLSession:session task:task didCompleteWithError:error];
        }
    }
    
    NSURLSessionTaskState state = task.state;
    NSLog(@"");
}

@end
