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

@interface DXDownloadManager () <NSURLSessionDownloadDelegate>

@property (strong, nonatomic) NSURLSession *sessionManager;
@property (strong, nonatomic) NSMutableSet<DXDownloadComponent *> *downloadsArr;
@property (strong, nonatomic) dispatch_queue_t downloadQueue;

@end

@implementation DXDownloadManager

static UIBackgroundTaskIdentifier bgTask;

- (void)dealloc {
    for (DXDownloadComponent *component in self.downloadsArr) {
        [component cancel];
    }
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
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"DXDownloadManagerSession"];
    config.discretionary = YES;
    _sessionManager = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
}

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

- (void)downloadComponent:(DXDownloadComponent *)component {
    NSParameterAssert(component.URL && component.URL.scheme && component.URL.host);
    
    weakify(self);
    [self runOndownloadQueue:^{
        switch (component.stautus) {
            case DXDownloadStatusRunning:
                return;
                break;
            case DXDownloadStatusPause:
                if (component.downloadTask) {
                    [component resume];
                    return;
                }
                break;
            default:
                break;
        }
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:component.URL];
        NSURLSessionDownloadTask *downloadTask = [selfWeak.sessionManager downloadTaskWithRequest:request];
        [component setDownloadTask:downloadTask];
        [component resume];
        [selfWeak.downloadsArr addObject:component];
    }];
}

- (void)cancelDownload:(DXDownloadComponent *)component {
    [component cancel];
}

- (void)suppendDownload:(DXDownloadComponent *)component {
    [component pause];
}

- (void)resumeDowmload:(DXDownloadComponent *)component {
    [component resume];
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session
      downloadTask: (NSURLSessionDownloadTask *)downloadTask
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
    
    weakify(self);
    [self runOndownloadQueue:^{
        for (DXDownloadComponent *component in selfWeak.downloadsArr) {
            if (component.downloadTask == task) {
                [component URLSession:session task:task didCompleteWithError:error];
                [selfWeak.downloadsArr removeObject:component];
                break;
            }
        }
    }];
    
    if (error) {
        id data = [[error userInfo] valueForKey:NSURLSessionDownloadTaskResumeData];
        NSLog(@"");
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {
    
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error {
    if (session == self.sessionManager) {
        weakify(self);
        [self runOndownloadQueue:^{
            selfWeak.sessionManager = nil;
            [selfWeak initSessionManager];
        }];
    }
}

@end
