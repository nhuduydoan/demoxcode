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
#import "Reachability.h"

#define RequestTimeOutInterval 60

#pragma mark - ====================DXDownloadComponent Category====================

@interface DXDownloadComponent (Private)

/**
 This property represents the download and will be nil when download completed
 */
@property (strong, nonatomic, readwrite) NSURLSessionDownloadTask *downloadTask;


- (id)initWithURL:(NSURL *)URL savedPath:(NSURL *)savedPath;

- (id)initWithURL:(NSURL *)URL
         progress:(void (^)(NSProgress *downloadProgress))downloadProgressBlock
      destination:(NSURL *(^)(NSURL *targetPath, NSURLResponse *response))destination
completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler;

- (void)setDownloadError:(NSError *)downloadError;

- (void)setDownloadProgressBlock:(void (^)(NSProgress *downloadProgress))downloadProgressBlock;

- (void)setResumeBlock:(void (^)(int64_t fileOffset, int64_t expectedTotalBytes))resumeBlock;

- (void)setDestinationBlock:(NSURL *(^)(NSURL *targetPath, NSURLResponse *response))destinationBlock;

- (void)setCompletionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler;

- (void)resume;

- (void)suppend;

- (void)cancel;

- (void)downloadTask:(NSURLSessionDownloadTask *)downloadTask
   didResumeAtOffset:(int64_t)fileOffset
  expectedTotalBytes:(int64_t)expectedTotalBytes;

- (void)downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location;

- (void)task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error;

@end

#pragma mark - ========================DXDownloadManager========================

@interface DXDownloadManager () <NSURLSessionDownloadDelegate>

@property (strong, nonatomic) NSURLSession *sessionManager;
@property (strong, nonatomic) NSMutableSet<DXDownloadComponent *> *downloadsArr;
@property (strong, nonatomic) Reachability *networkManager;
@property (strong, nonatomic) NSDate *disConnectedDate;
@property (strong, nonatomic) dispatch_queue_t managerSerialQueue;
@property (nonatomic) BOOL isCheckingRequestTimeOut;

@end

@implementation DXDownloadManager

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
        _managerSerialQueue = dispatch_queue_create("ManagerSerialQueue", DISPATCH_QUEUE_SERIAL);
        _downloadsArr = [NSMutableSet new];
        [self initSessionManager];
        weakify(self);
        _networkManager = [Reachability reachabilityForInternetConnection];
        _networkManager.reachabilityBlock = ^(Reachability *reachability, SCNetworkConnectionFlags flags) {
            [selfWeak didChangeNetworkStatus];
        };
        [_networkManager startNotifier];
        [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(applicationWillEnterForeground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
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
    return configuration;
}

#pragma mark - Private

- (void)applicationWillEnterForeground:(NSNotification *)notification {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), self.managerSerialQueue, ^{
        if (self.networkManager && ![self.networkManager isReachable]) {
            self.disConnectedDate = [NSDate date];
            if (!self.isCheckingRequestTimeOut) {
                self.isCheckingRequestTimeOut = YES;
                [self checkRequestTimeOut];
            }
        }
    });
}

- (NSError *)errorWhenIsDownloadingURL:(NSURL *)URL {
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey:@"Failure to start download",
                               NSLocalizedFailureReasonErrorKey:[NSString stringWithFormat:@"This file is being downloaded by another task: %@", URL.absoluteString]};
    NSError *error = [NSError errorWithDomain:@"" code:DXErrorDownloadingSameFile userInfo:userInfo];
    return error;
}

- (NSError *)networkNotConnectedError {
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey:@"Network not connected",
                               NSLocalizedFailureReasonErrorKey:@"Network not connected"};
    NSError *error = [NSError errorWithDomain:@"" code:DXErrorNetworkNotConected userInfo:userInfo];
    return error;
}

- (NSError *)requestTimeOutError {
    NSDictionary *userInfo = @{NSLocalizedFailureReasonErrorKey:@"The request timed out."};
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:DXErrorNetworkTimedOut userInfo:userInfo];
    return error;
}

- (void)didChangeNetworkStatus {
    if (![self.networkManager isReachable]) {
        dispatch_async(self.managerSerialQueue, ^{
            self.disConnectedDate = [NSDate date];
            if (!self.isCheckingRequestTimeOut) {
                self.isCheckingRequestTimeOut = YES;
                [self checkRequestTimeOut];
            }
        });
    } else {
        @synchronized(self) {
            self.disConnectedDate = nil;
            for (DXDownloadComponent *component in self.downloadsArr) {
                [component resume];
            }
        }
    }
}

- (void)checkRequestTimeOut {
    if (!self.disConnectedDate) {
        self.isCheckingRequestTimeOut = NO;
        return;
    }
    
    __block BOOL isBackgroundState = NO;
    dispatch_sync(dispatch_get_main_queue(), ^{
       isBackgroundState = [UIApplication sharedApplication].applicationState == UIApplicationStateBackground;
    });
    if (isBackgroundState) {
        self.disConnectedDate = nil;
        self.isCheckingRequestTimeOut = NO;
        return;
    }
    
    if ([[NSDate date] timeIntervalSinceDate:self.disConnectedDate] >= RequestTimeOutInterval) {
        @synchronized(self) {
            for (DXDownloadComponent *component in self.downloadsArr) {
                [component setDownloadError:[self requestTimeOutError]];
                [component cancel];
            }
        }
        self.isCheckingRequestTimeOut = NO;
        return;
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), self.managerSerialQueue, ^{
        [self checkRequestTimeOut];
    });
}

- (BOOL)isDownloadingURL:(NSURL *)URL {
    for (DXDownloadComponent *com in self.downloadsArr) {
        if ([com.URL isEqual:URL]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - Download

- (DXDownloadComponent *)downloadComponentForDownloadURL:(NSURL *)URL {
    if (!URL || !URL.scheme || !URL.host) {
        return nil;
    }
    @synchronized (self) {
        DXDownloadComponent *component;
        for (DXDownloadComponent *com in self.downloadsArr) {
            if ([com.URL isEqual:URL]) {
                component = com;
                break;
            }
        }
        return component;
    }
}

- (DXDownloadComponent *)downloadURL:(NSURL *)URL
                          toFilePath:(NSURL *)filePath
                   completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler
                               error:(NSError **)error {
    NSParameterAssert(URL && URL.scheme && URL.host);
    NSParameterAssert(filePath && [filePath isFileURL]);
    
    if (![self.networkManager isReachable]) {
        if (error) {
            *error = [self networkNotConnectedError];
        }
        return nil;
    }
    
    @synchronized (self) {
        DXDownloadComponent *component;
        if ([self isDownloadingURL:URL]) { // This URL is being downloaded by self now
            if (error) {
                *error = [self errorWhenIsDownloadingURL:URL];;
            }
        } else {
            component = [[DXDownloadComponent alloc] initWithURL:URL savedPath:filePath];
            [component setCompletionHandler:completionHandler];
            [self startDownloadWithComponent:component];
        }
        return component;
    }
}

- (DXDownloadComponent *)downloadURL:(NSURL *)URL
                            progress:(void (^)(NSProgress *downloadProgress))downloadProgressBlock
                         destination:(NSURL *(^)(NSURL *targetPath, NSURLResponse *response))destination
                   completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler
                               error:(NSError **)error {
    NSParameterAssert(URL && URL.scheme && URL.host);
    
    if (![self.networkManager isReachable]) {
        if (error) {
            *error = [self networkNotConnectedError];
        }
        return nil;
    }
    
    @synchronized (self) {
        DXDownloadComponent *component;
        if ([self isDownloadingURL:URL]) { // This URL is being downloaded now
            if (error) {
                *error = [self errorWhenIsDownloadingURL:URL];
            }
        } else {
            component = [[DXDownloadComponent alloc] initWithURL:URL
                                                        progress:downloadProgressBlock
                                                     destination:destination
                                               completionHandler:completionHandler];
            [self startDownloadWithComponent:component];
        }
        return component;
    }
}

- (BOOL)resumeComponent:(DXDownloadComponent *)component
            resumeBlock:(void (^)(int64_t fileOffset, int64_t expectedTotalBytes))resumeBlock
               progress:(void (^)(NSProgress *downloadProgress)) downloadProgressBlock
            destination:(NSURL * (^)(NSURL *targetPath, NSURLResponse *response))destination
      completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler
                  error:(NSError **)error {
    NSParameterAssert(component && component.URL && component.URL.scheme && component.URL.host);
    
    if (![self.networkManager isReachable]) {
        if (error) {
            *error = [self networkNotConnectedError];
        }
        return NO;
    }
    
    [component setResumeBlock:resumeBlock];
    [component setDownloadProgressBlock:downloadProgressBlock];
    [component setDestinationBlock:destination];
    [component setCompletionHandler:completionHandler];
    return [self resumeComponent:component error:error];
}

- (BOOL)resumeComponent:(DXDownloadComponent *)component error:(NSError **)error {
    NSParameterAssert(component && component.URL && component.URL.scheme && component.URL.host);
    
    if (![self.networkManager isReachable]) {
        if (error) {
            *error = [self networkNotConnectedError];
        }
        return NO;
    }
    
    if (component.stautus == NSURLSessionTaskStateCanceling) {
        if (error) {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey:@"Failure to start download",
                                       NSLocalizedFailureReasonErrorKey:[NSString stringWithFormat:@"This file is being canceled: %@", component.URL.absoluteString]};
            *error = [NSError errorWithDomain:@"" code:DXErrorCancelingDownload userInfo:userInfo];
        }
        return NO;
    }
    
    if (component.stautus == component.stautus == NSURLSessionTaskStateRunning) {
        return YES;
    }
    
    @synchronized (self) {
        BOOL success = NO;
        if (component.downloadTask && component.stautus == NSURLSessionTaskStateSuspended) {
            [component setDownloadError:nil];
            [component resume];
            [self.downloadsArr addObject:component];
            success = YES;
        } else if ([self isDownloadingURL:component.URL]) { // This URL is already being downloaded now
            if (error) {
                *error = [self errorWhenIsDownloadingURL:component.URL];;
            }
        } else {
            [component setDownloadError:nil];
            [self startDownloadWithComponent:component];
            success = YES;
        }
        return success;
    }
}

- (void)startDownloadWithComponent:(DXDownloadComponent *)component {
    
    NSURLSessionDownloadTask *downloadTask;
    if (component.resumeData.length) {
        // This component have data for resume, resume with resume data
        downloadTask = [self.sessionManager downloadTaskWithResumeData:component.resumeData];
    } else {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:component.URL];
        [request setHTTPMethod:@"GET"];
        downloadTask = [self.sessionManager downloadTaskWithRequest:request];
    }
    
    [component setDownloadTask:downloadTask];
    [component resume];
    [self.downloadsArr addObject:component];
}

- (void)suppendComponent:(DXDownloadComponent *)component {
    NSParameterAssert(component);
    @synchronized (self) {
        if (component.stautus == NSURLSessionTaskStateRunning) {
            [component suppend];
            [self.downloadsArr removeObject:component];
        }
    }
}

- (void)cancelComponent:(DXDownloadComponent *)component {
    NSParameterAssert(component);
    @synchronized(self) {
        if (component.stautus == NSURLSessionTaskStateRunning || component.stautus == NSURLSessionTaskStateSuspended) {
            [component cancel];
        }
    }
}

- (void)cancelAllDownloads {
    @synchronized (self) {
        for (DXDownloadComponent *component in self.downloadsArr) {
            [self cancelComponent:component];
        }
    }
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session
      downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes {
    
    @synchronized (self) {
        for (DXDownloadComponent *component in self.downloadsArr) {
            if (component.downloadTask == downloadTask) {
                [component downloadTask:downloadTask
                      didResumeAtOffset:fileOffset
                     expectedTotalBytes:expectedTotalBytes];
            }
        }
    }
}

- (void)URLSession:(NSURLSession *)session
      downloadTask: (NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL * _Nonnull)location {
    
    @synchronized (self) {
        for (DXDownloadComponent *component in self.downloadsArr) {
            if (component.downloadTask == downloadTask) {
                [component downloadTask:downloadTask didFinishDownloadingToURL:location];
            }
        }
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(nonnull NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error {

    @synchronized(self) {
        DXDownloadComponent *component;
        for (DXDownloadComponent *com in self.downloadsArr) {
            if (com.downloadTask == task) {
                if (com.downloadError) { // For Saving file fail and Request time out error
                    error = com.downloadError;
                }
                [com task:task didCompleteWithError:error];
                component = com;
                break;
            }
        }
        if (component) {
            [self.downloadsArr removeObject:component];
        }
    }
}

@end
