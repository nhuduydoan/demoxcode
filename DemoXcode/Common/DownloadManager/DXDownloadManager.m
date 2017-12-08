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

#import "AFURLSessionManager.h"

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

@interface DXDownloadManager () <NSURLSessionDownloadDelegate>

@property (strong, nonatomic) NSURLSession *sessionManager;
@property (strong, nonatomic) NSMutableSet<DXDownloadComponent *> *downloadsArr;
@property (strong, nonatomic) dispatch_queue_t downloadManagerQueue;

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
        _downloadsArr = [NSMutableSet new];
        [self initSessionManager];
        [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        _downloadManagerQueue = dispatch_queue_create("DXDownLoadManagerQueue", DISPATCH_QUEUE_SERIAL);
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

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"DXDownLoadManagerTask" expirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
}

- (BOOL)isDownloadingURL:(NSURL *)URL {
    BOOL isContain = NO;
    for (DXDownloadComponent *com in self.downloadsArr) {
        if ([com.URL isEqual:URL]) {
            isContain = YES;
            break;
        }
    }
    if (!isContain) {
        NSLog(@"=== Add === %zd", self.downloadsArr.count);
    }
    return isContain;
}

- (NSError *)errorWhenIsDownloadingURL:(NSURL *)URL {
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey:@"Failure to start download",
                               NSLocalizedFailureReasonErrorKey:[NSString stringWithFormat:@"This file is being downloaded by another task: %@", URL.absoluteString]};
    NSError *error = [NSError errorWithDomain:@"" code:DXErrorDownloadingSameFile userInfo:userInfo];
    return error;
}

#pragma mark - Download

- (DXDownloadComponent *)downloadComponentForDownloadURL:(NSURL *)URL {
    DXDownloadComponent *component;
    for (DXDownloadComponent *com in self.downloadsArr) {
        if ([com.URL isEqual:URL]) {
            component = com;
            break;
        }
    }
    return component;
}

- (DXDownloadComponent *)downloadURL:(NSURL *)URL
                          toFilePath:(NSURL *)filePath
                   completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler
                               error:(NSError **)error {
    NSParameterAssert(URL && URL.scheme && URL.host);
    NSParameterAssert(filePath && [filePath isFileURL]);
    
    if ([self isDownloadingURL:URL]) {
        // This URL is downloading now
        if (error) {
            *error = [self errorWhenIsDownloadingURL:URL];;
        }
        return nil;
    }
    
    DXDownloadComponent *component = [[DXDownloadComponent alloc] initWithURL:URL savedPath:filePath];
    [component setCompletionHandler:completionHandler];
    [self resumeComponent:component error:nil];
    return component;
}

- (DXDownloadComponent *)downloadURL:(NSURL *)URL
                            progress:(void (^)(NSProgress *downloadProgress))downloadProgressBlock
                         destination:(NSURL *(^)(NSURL *targetPath, NSURLResponse *response))destination
                   completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler
                               error:(NSError **)error {
    NSParameterAssert(URL && URL.scheme && URL.host);
    
    if ([self isDownloadingURL:URL]) {
        // This URL is downloading now
        if (error) {
            *error = [self errorWhenIsDownloadingURL:URL];
        }
        return nil;
    }
    
    DXDownloadComponent *component = [[DXDownloadComponent alloc] initWithURL:URL
                                                                     progress:downloadProgressBlock
                                                                  destination:destination
                                                            completionHandler:completionHandler];
    [self resumeComponent:component error:error];
    return component;
}

- (BOOL)resumeComponent:(DXDownloadComponent *)component 
            resumeBlock:(void (^)(int64_t fileOffset, int64_t expectedTotalBytes))resumeBlock
               progress:(void (^)(NSProgress *downloadProgress)) downloadProgressBlock
            destination:(NSURL * (^)(NSURL *targetPath, NSURLResponse *response))destination
      completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler
                  error:(NSError **)error {
    
    [component setResumeBlock:resumeBlock];
    [component setDownloadProgressBlock:downloadProgressBlock];
    [component setDestinationBlock:destination];
    [component setCompletionHandler:completionHandler];
    return [self resumeComponent:component error:error];
}

- (BOOL)resumeComponent:(DXDownloadComponent *)component error:(NSError **)error {
    NSParameterAssert(component.URL && component.URL.scheme && component.URL.host);
    
    if ([self isDownloadingURL:component.URL]) {
        // This URL is downloading now
        if (error) {
            *error = [self errorWhenIsDownloadingURL:component.URL];;
        }
        return NO;
    }
    
    if (component.stautus == NSURLSessionTaskStateCanceling) {
        if (error) {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey:@"Failure to start download",
                                   NSLocalizedFailureReasonErrorKey:[NSString stringWithFormat:@"This file is being canceled: %@", component.URL.absoluteString]};
        *error = [NSError errorWithDomain:@"" code:DXErrorCancelingDownload userInfo:userInfo];
    }
        return error;
        return NO;
    }
    
    if (component.stautus == component.stautus == NSURLSessionTaskStateRunning) {
        return YES;
    }
    
    if (component.downloadTask && component.stautus == NSURLSessionTaskStateSuspended) {
        [component resume];
        [self.downloadsArr addObject:component];
        return YES;
    }
    
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
    return YES;
}

- (void)suppendComponent:(DXDownloadComponent *)component {
    
    if (component.stautus == NSURLSessionTaskStateRunning) {
        [component suppend];
        [self.downloadsArr removeObject:component];
    }
}

- (void)cancelComponent:(DXDownloadComponent *)component {
    @synchronized(self) {
        if (component.stautus == NSURLSessionTaskStateRunning || component.stautus == NSURLSessionTaskStateSuspended) {
            [component cancel];
        }
    }
}

- (void)cancelAllDownloads {
    for (DXDownloadComponent *component in self.downloadsArr) {
        [self cancelComponent:component];
    }
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
            [component downloadTask:downloadTask didFinishDownloadingToURL:location];
        }
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(nonnull NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error {
    
    DXDownloadComponent *component;
    for (DXDownloadComponent *com in self.downloadsArr) {
        if (com.downloadTask == task) {
            [com task:task didCompleteWithError:error];
            component = com;
            break;
        }
    }
    if (component) {
        [self.downloadsArr removeObject:component];
    }
}

@end
