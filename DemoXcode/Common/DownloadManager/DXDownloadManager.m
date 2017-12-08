//
//  DXDownloadManager.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/1/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXDownloadManager.h"
#import "DXFileManager.h"
#import "DXDownloadComponent.h"
#import "DXDownloadComponent_Private.h"

#import "AFURLSessionManager.h"

@interface DXDownloadManager () <NSURLSessionDownloadDelegate>

@property (strong, nonatomic) NSURLSession *sessionManager;
@property (strong, nonatomic) NSMutableSet<DXDownloadComponent *> *downloadsArr;
@property (strong, nonatomic) dispatch_queue_t downloadQueue;

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

- (NSURLSessionConfiguration *)backgroundURLSessionConfiguration {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"DXDownloadManagerSession"];
    
    configuration.HTTPShouldSetCookies = YES;
    configuration.requestCachePolicy = NSURLRequestUseProtocolCachePolicy;
    configuration.allowsCellularAccess = YES;
    configuration.timeoutIntervalForRequest = 10.0;
    configuration.timeoutIntervalForResource = 10.0;
    configuration.URLCache = [NSURLCache sharedURLCache];
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

- (BOOL)isDownloadingURL:(NSURL *)URL toFilePath:(NSURL *)filePath {
    __block BOOL isContain = NO;
    dispatch_sync(self.downloadQueue, ^{
        for (DXDownloadComponent *com in self.downloadsArr) {
            if ([com.URL isEqual:URL] && com.savedPath  && [com.savedPath isEqual:filePath]) {
                isContain = YES;
                break;
            }
        }
    });
    return isContain;
}

#pragma mark - Download

- (DXDownloadComponent *)downloadURL:(NSURL *)URL
                          toFilePath:(NSURL *)filePath
                   completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler {
    NSParameterAssert(URL && URL.scheme && URL.host);
    NSParameterAssert(filePath && [filePath isFileURL]);
    
    if ([self isDownloadingURL:URL toFilePath:filePath]) {
        if (completionHandler) {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey:@"Failure to download ",
                                       NSLocalizedFailureReasonErrorKey:@"This URL is downloading with same file path, please check again"};
            NSError *error = [NSError errorWithDomain:@"" code:DXErrorDownloadingSameFile userInfo:userInfo];
            completionHandler(nil, nil, error);
        }
        return nil;
    }
    
    DXDownloadComponent *component = [[DXDownloadComponent alloc] initWithURL:URL savedPath:filePath];
    [component setCompletionHandler:completionHandler];
    [self resumeComponent:component];
    return component;
}

- (DXDownloadComponent *)downloadURL:(NSURL *)URL
                            progress:(void (^)(NSProgress *downloadProgress))downloadProgressBlock
                         destination:(NSURL *(^)(NSURL *targetPath, NSURLResponse *response))destination
                   completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler {
    NSParameterAssert(URL && URL.scheme && URL.host);
    
    DXDownloadComponent *component = [[DXDownloadComponent alloc] initWithURL:URL
                                                                     progress:downloadProgressBlock
                                                                  destination:destination
                                                            completionHandler:completionHandler];
    [self resumeComponent:component];
    return component;
}

- (void)resumeComponent:(DXDownloadComponent *)component
            resumeBlock:(void (^)(DXDownloadComponent *component, int64_t fileOffset, int64_t expectedTotalBytes))resumeBlock
               progress:(void (^)(NSProgress *downloadProgress)) downloadProgressBlock
            destination:(NSURL * (^)(NSURL *targetPath, NSURLResponse *response))destination
      completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler {
    
    [component setResumeBlock:resumeBlock];
    [component setDownloadProgressBlock:downloadProgressBlock];
    [component setDestinationBlock:destination];
    [component setCompletionHandler:completionHandler];
    [self resumeComponent:component];
}

- (void)resumeComponent:(DXDownloadComponent *)component {
    NSParameterAssert(component.URL && component.URL.scheme && component.URL.host);
    
    if (component.stautus == NSURLSessionTaskStateCanceling
        || component.stautus == NSURLSessionTaskStateRunning) {
        return;
    }
    
    weakify(self);
    [self runOndownloadQueue:^{
        if (component.downloadTask && component.stautus == NSURLSessionTaskStateSuspended) {
            [component resume];
            [selfWeak.downloadsArr addObject:component];
            return;
        }
        
        NSURLSessionDownloadTask *downloadTask;
        if (component.resumeData.length) {
            // This component have data for resume, resume with resume data
            downloadTask = [selfWeak.sessionManager downloadTaskWithResumeData:component.resumeData];
        } else {
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:component.URL];
            [request setHTTPMethod:@"GET"];
            downloadTask = [selfWeak.sessionManager downloadTaskWithRequest:request];
        }
        
        [component setDownloadTask:downloadTask];
        [downloadTask resume];
        [selfWeak.downloadsArr addObject:component];
    }];
}

- (void)suppendComponent:(DXDownloadComponent *)component {
    [self runOndownloadQueue:^{
        [component suppend];
    }];
}

- (void)cancelComponent:(DXDownloadComponent *)component {
    [self runOndownloadQueue:^{
        [component cancel];
    }];
}

- (void)cancelAllDownloads {
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
    
    // Added these lines...
    NSLog(@"DiskCache: %@ of %@", @([[NSURLCache sharedURLCache] currentDiskUsage]), @([[NSURLCache sharedURLCache] diskCapacity]));
    NSLog(@"MemoryCache: %@ of %@", @([[NSURLCache sharedURLCache] currentMemoryUsage]), @([[NSURLCache sharedURLCache] memoryCapacity]));
    
    
    for (DXDownloadComponent *component in self.downloadsArr) {
        if (component.downloadTask == downloadTask) {
            [component downloadTask:downloadTask didFinishDownloadingToURL:location];
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

@end
