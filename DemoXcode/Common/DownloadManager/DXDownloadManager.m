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
#import "DXDownloadComponent.h"
#import "DXDownloadComponent_Private.h"

#import "AFURLSessionManager.h"

@interface DXDownloadManager () <NSURLSessionDownloadDelegate>

@property (strong, nonatomic) NSURLSession *sessionManager;
@property (strong, nonatomic) NSMutableSet<DXDownloadComponent *> *downloadsArr;
@property (strong, nonatomic) dispatch_queue_t downloadQueue;

@property (strong, nonatomic) AFURLSessionManager  *afManager;

@end

@implementation DXDownloadManager

static UIBackgroundTaskIdentifier bgTask;

- (void)dealloc {
    [self.sessionManager invalidateAndCancel];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (id)sharedInstance {
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self.class alloc] initSharedInstance];
    });
    return instance;
}

- (instancetype) init {
    [super doesNotRecognizeSelector:_cmd];
    self = nil;
    return nil;
}

- (instancetype)initSharedInstance {
    self = [super init];
    if (self) {
        _downloadQueue = dispatch_queue_create("DXDownLoadManagerQueue", DISPATCH_QUEUE_SERIAL);
        _downloadsArr = [NSMutableSet new];
        [self initSessionManager];
        [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

- (void)initSessionManager {
    NSURLSessionConfiguration *config = [self backgroundURLSessionConfiguration];
    _sessionManager = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
}


- (NSURLCache *)defaultURLCache {
    return [[NSURLCache alloc] initWithMemoryCapacity:20 * 1024 * 1024
                                         diskCapacity:256 * 1024 * 1024
                                             diskPath:@"com.nhuduydoan.downloadmanager"];
}

- (NSURLSessionConfiguration *)backgroundURLSessionConfiguration {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"DXDownloadManagerSession"];
    
    configuration.HTTPShouldSetCookies = YES;
    configuration.requestCachePolicy = NSURLRequestUseProtocolCachePolicy;
    configuration.allowsCellularAccess = YES;
    configuration.timeoutIntervalForRequest = 60.0;
    configuration.URLCache = [self defaultURLCache];
    return configuration;
}

#pragma mark - Private

- (void)runOndownloadQueue:(void (^)(void))block {
    dispatch_sync(self.downloadQueue, ^{
        block();
    });
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"DXDownLoadManagerTask" expirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
}

#pragma mark - Download

- (DXDownloadComponent *)downloadURL:(NSURL *)URL
                          toFilePath:(NSURL *)filePath
                   completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler {
    
    DXDownloadComponent *component = [[DXDownloadComponent alloc] initWithURL:URL savedPath:filePath];
    [component setCompletionHandler:completionHandler];
    [self downloadComponent:component];
    return component;
}

- (DXDownloadComponent *)downloadURL:(NSURL *)URL
                            progress:(void (^)(NSProgress *downloadProgress))downloadProgressBlock
                         destination:(NSURL *(^)(NSURL *targetPath, NSURLResponse *response))destination
                   completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler {
    
    DXDownloadComponent *component = [[DXDownloadComponent alloc] initWithURL:URL
                                                                     progress:downloadProgressBlock
                                                                  destination:destination
                                                            completionHandler:completionHandler];
    [self downloadComponent:component];
    return component;
}

- (void)downloadComponent:(DXDownloadComponent *)component {
    NSParameterAssert(component.URL && component.URL.scheme && component.URL.host);
    
    weakify(self);
    [self runOndownloadQueue:^{
        if (component.downloadTask) {
            if (component.downloadTask.state == NSURLSessionTaskStateSuspended) {
                [component resume];
                [selfWeak.downloadsArr addObject:component];
                return;
            } else if (component.downloadTask.state == NSURLSessionTaskStateRunning) {
                return;
            }
        }
        
        NSURLSessionDownloadTask *downloadTask;
        if (component.resumeData.length) {
            downloadTask = [selfWeak.sessionManager downloadTaskWithResumeData:component.resumeData];
        } else {
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:component.URL];
            downloadTask = [selfWeak.sessionManager downloadTaskWithRequest:request];
        }
        
        [component setDownloadTask:downloadTask];
        [downloadTask resume];
        [selfWeak.downloadsArr addObject:component];
    }];
}

- (void)suppendComponent:(DXDownloadComponent *)component {
    [component pause];
}

- (void)cancelComponent:(DXDownloadComponent *)component {
    [component cancel];
}

- (void)cancelAllDownloadComponents {
    weakify(self);
    [self runOndownloadQueue:^{
        for (DXDownloadComponent *component in selfWeak.downloadsArr) {
            [component cancel];
        }
    }];
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session
      downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes {
    
    for (DXDownloadComponent *component in self.downloadsArr) {
        if (component.downloadTask == downloadTask) {
            [component downloadTask:downloadTask
                didResumeAtOffset:fileOffset
               expectedTotalBytes:expectedTotalBytes];
        }
    }
}

- (void)URLSession:(NSURLSession *)session
      downloadTask: (NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL * _Nonnull)location {
    
    for (DXDownloadComponent *component in self.downloadsArr) {
        if (component.downloadTask == downloadTask) {
            [component downloadTask:downloadTask
        didFinishDownloadingToURL:location];
        }
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(nonnull NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error {
    
    weakify(self);
    [self runOndownloadQueue:^{
        for (DXDownloadComponent *component in selfWeak.downloadsArr) {
            if (component.downloadTask == task) {
                [component task:task didCompleteWithError:error];
                [selfWeak.downloadsArr removeObject:component];
                break;
            }
        }
    }];
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error {
}

@end
