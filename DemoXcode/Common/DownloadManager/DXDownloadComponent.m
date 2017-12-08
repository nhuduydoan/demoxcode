//
//  DXDownloadComponent.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/5/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXDownloadComponent.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "DXDownloadManager.h"

@interface DXDownloadComponent ()

@property (strong, nonatomic, readwrite) NSURL *URL;
@property (strong, nonatomic, readwrite) NSURL *savedPath;
@property (nonatomic, readwrite) NSURLSessionTaskState stautus;
@property (nonatomic, readwrite) NSURLResponse *response;
@property (nonatomic, readwrite) NSError *downloadError;
@property (nonatomic, readwrite) NSData *resumeData;
@property (strong, nonatomic, readwrite) NSProgress *downloadProgress;

@property (nonatomic, copy, readwrite) void (^downloadProgressBlock)(NSProgress *downloadProgress);
@property (nonatomic, copy, readwrite) NSURL *(^destinationBlock)(NSURL *targetPath, NSURLResponse *response);
@property (nonatomic, copy, readwrite) void (^resumeBlock)(DXDownloadComponent *DXDownloadComponent, int64_t fileOffset, int64_t expectedTotalBytes);
@property (nonatomic, copy, readwrite) void (^completionHandler)(NSURLResponse *response, NSURL *filePath, NSError *error);

@property (strong, nonatomic, readwrite) NSURLSessionDownloadTask *downloadTask;

@end

@implementation DXDownloadComponent

- (void)dealloc {
    [self cleanUpForTask:self.downloadTask];
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (instancetype) init {
    [super doesNotRecognizeSelector:_cmd];
    self = nil;
    return nil;
}

- (id)initWithURL:(NSURL *)URL savedPath:(NSURL *)savedPath {
    self = [super init];
    if (self) {
        _URL = URL;
        _savedPath = savedPath;
        _stautus = NSURLSessionTaskStateSuspended;
        _downloadProgress =  [NSProgress new];
    }
    return self;
}

- (id)initWithURL:(NSURL *)URL
         progress:(void (^)(NSProgress *downloadProgress))downloadProgressBlock
      destination:(NSURL *(^)(NSURL *targetPath, NSURLResponse *response))destination
completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler {
    self = [super init];
    if (self) {
        _URL = URL;
        _stautus = NSURLSessionTaskStateSuspended;
        _downloadProgressBlock = downloadProgressBlock;
        _destinationBlock = destination;
        _completionHandler = completionHandler;
        _downloadProgress =  [NSProgress new];
    }
    return self;
}

#pragma mark - Download

- (void)resume {
    [self.downloadTask resume];
}

- (void)suppend {
    [self.downloadTask suspend];
}

- (void)cancel {
    [self.downloadTask cancel];
}

#pragma mark - Private

- (void)addObverForTask:(NSURLSessionDownloadTask *)task {
    [task addObserver:self
           forKeyPath:NSStringFromSelector(@selector(countOfBytesReceived))
              options:NSKeyValueObservingOptionNew
              context:NULL];
    [task addObserver:self
           forKeyPath:NSStringFromSelector(@selector(countOfBytesExpectedToReceive))
              options:NSKeyValueObservingOptionNew
              context:NULL];
    [task addObserver:self
           forKeyPath:NSStringFromSelector(@selector(state))
              options:NSKeyValueObservingOptionNew
              context:NULL];
}

- (void)cleanUpForTask:(NSURLSessionTask *)task {
    [task removeObserver:self forKeyPath:NSStringFromSelector(@selector(countOfBytesReceived))];
    [task removeObserver:self forKeyPath:NSStringFromSelector(@selector(countOfBytesExpectedToReceive))];
    [task removeObserver:self forKeyPath:NSStringFromSelector(@selector(state))];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {\
    if ([object isKindOfClass:[NSURLSessionTask class]]) {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(state))]) {
            // For change state of downloadtask
            self.stautus = self.downloadTask.state;
            if ([self.delegate respondsToSelector:@selector(downloadComponent:didChangeStatus:)]){
                [self.delegate downloadComponent:self didChangeStatus:self.stautus];
            }
            return;
        }
        
        // For change progress of download
        int64_t receivedBytes = self.downloadProgress.completedUnitCount;
        int64_t expectedTotalData = self.downloadProgress.totalUnitCount;
        int64_t didWriteBytes = 0;
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(countOfBytesReceived))]) {
            receivedBytes = [change[@"new"] longLongValue];
            didWriteBytes = receivedBytes - self.downloadProgress.completedUnitCount;
            self.downloadProgress.completedUnitCount = receivedBytes;
        } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(countOfBytesExpectedToReceive))]) {
            expectedTotalData = [change[@"new"] longLongValue];
            self.downloadProgress.totalUnitCount = expectedTotalData;
        }
        
        if (self.downloadProgressBlock) {
            self.downloadProgressBlock(self.downloadProgress);
        }
        
        if ([self.delegate respondsToSelector:@selector(downloadComponent:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:)]) {
            [self.delegate downloadComponent:self didWriteData:didWriteBytes totalBytesWritten:receivedBytes totalBytesExpectedToWrite:expectedTotalData];
        }
    }
}

- (NSString *)generateNewFilePathForPath:(NSString *)filePath {
    NSString *targetPath = [filePath stringByDeletingLastPathComponent];
    NSString *fileName = [filePath lastPathComponent];
    if (![[NSFileManager defaultManager] fileExistsAtPath:targetPath]) {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:targetPath withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            return nil;
        }
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return filePath;
    }
    
    //Get file name and extension
    NSString *originalName = [fileName stringByDeletingPathExtension];
    NSString *pathExtension = [fileName pathExtension];
    NSString *path = [targetPath stringByAppendingPathComponent:fileName];
    NSInteger additionNum = 1;
    
    while ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        fileName = [[NSString stringWithFormat:@"%@(%zd)", originalName, additionNum] stringByAppendingPathExtension:pathExtension];
        path = [targetPath stringByAppendingPathComponent:fileName];
        additionNum ++;
    }
    return path;
}

#pragma mark - Protected

- (void)setDownloadTask:(NSURLSessionDownloadTask *)downloadTask {
    [self cleanUpForTask:_downloadTask];
    _downloadTask = downloadTask;
    [self addObverForTask:downloadTask];
}

- (void)setCompletionHandler:(void (^)(NSURLResponse *, NSURL *, NSError *))completionHandler {
    _completionHandler = completionHandler;
}

- (void)downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes {
    
    if (self.resumeBlock) {
        self.resumeBlock(self, fileOffset, expectedTotalBytes);
    }
    
    if ([self.delegate respondsToSelector:@selector(downloadComponent:didResumeAtOffset:expectedTotalBytes:)]) {
        [self.delegate downloadComponent:self didResumeAtOffset:fileOffset expectedTotalBytes:expectedTotalBytes];
    }
}

- (void)downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    
    NSURL *savedURL = nil;
    
    if (self.destinationBlock) {
        NSURL *url = self.destinationBlock(location.copy, downloadTask.response);
        if (url && [url isFileURL]) { // If saved url from block is valid, get it
            savedURL = url.copy;
        }
    }
    
    if (savedURL == nil) {
        if (self.savedPath && [self.savedPath isFileURL]) { // Check and fix savedpath which were given when init component
            NSString *savedPath = [self.savedPath path];
            if ([savedPath pathExtension].length == 0) {
                //Update new file name, extension if saved path do not contain them
                CFStringRef mimeType = (__bridge CFStringRef) [downloadTask.response MIMEType];
                CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType, NULL);
                NSString *extension = (__bridge NSString *) UTTypeCopyPreferredTagWithClass(uti, kUTTagClassFilenameExtension);
                if (uti) CFRelease(uti);
                NSString *fileName = [downloadTask.response suggestedFilename];
                if ([extension length] > 0) {
                    fileName = [[fileName stringByDeletingPathExtension] stringByAppendingPathExtension:extension];
                }
                savedPath = [savedPath stringByAppendingPathComponent:fileName];
            }
            // Check and genarate new path with additional number
            savedPath = [self generateNewFilePathForPath:savedPath];
            savedURL = [NSURL fileURLWithPath:savedPath];
        }
    }
    
    NSError *error = nil;
    if (savedURL && [savedURL isFileURL]) {
        [[NSFileManager defaultManager] moveItemAtURL:location toURL:savedURL error:&error];
        self.downloadError = error;
        if (error) {
            savedURL = location.copy;
        }
    } else {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey:@"Failure to save file ",
                                   NSLocalizedFailureReasonErrorKey:@"Cannot save file because saved file path is invalid"};
        NSError *error = [NSError errorWithDomain:@"" code:DXErrorSaveFailed userInfo:userInfo];
        self.downloadError = error;
        savedURL = location.copy;
    }
    self.savedPath = savedURL.copy;
    if ([self.delegate respondsToSelector:@selector(downloadComponent:didFinishDownloadingToURL:)]) {
        [self.delegate downloadComponent:self didFinishDownloadingToURL:savedURL];
    }
}

- (void)task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error) {
        // Keep all blocks for resume download
        self.downloadError = error;
        NSData *resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
        self.resumeData = resumeData;
    } else {
        // Release all blocks
        self.resumeData = nil;
        self.completionHandler = nil;
        self.destinationBlock = nil;
        self.downloadProgressBlock = nil;
        self.resumeBlock = nil;
    }
    self.stautus = self.downloadTask.state;
    if (self.completionHandler) {
        self.completionHandler(task.response, self.savedPath.copy, error);
    }
    
    if ([self.delegate respondsToSelector:@selector(downloadComponent:didCompleteWithError:)]) {
        [self.delegate downloadComponent:self didCompleteWithError:self.downloadError.copy];
    }
    // Remove download task when download finish
    [self setDownloadTask:nil];
}

@end
