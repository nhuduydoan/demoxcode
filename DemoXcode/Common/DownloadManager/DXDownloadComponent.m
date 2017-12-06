//
//  DXDownloadComponent.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/5/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXDownloadComponent.h"
#import "DXFileManager.h"
#import <MobileCoreServices/MobileCoreServices.h>

NSString *const DXDownloadManagerBeginDownLoad = @"DXDownloadManagerBeginDownLoad";
NSString *const DXDownloadManagerDidDownLoadFinished = @"DXDownloadManagerDidDownLoadFinished";
NSString *const DXDownloadComponentKey = @"DXDownloadComponentKey";

@interface DXDownloadComponent ()

@property (strong, nonatomic, readwrite) NSString *fileName;
@property (strong, nonatomic, readwrite) NSURL *URL;
@property (nonatomic, readwrite) DXDownloadStatus stautus;
@property (nonatomic, readwrite) int64_t receivedData;
@property (nonatomic, readwrite) int64_t expectedTotalData;
@property (nonatomic, readwrite) NSError *downloadError;

@property (strong, nonatomic, readwrite) NSURLSessionDownloadTask *downloadTask;

@end

@implementation DXDownloadComponent

- (void)dealloc {
    [self cleanUpForTask:self.downloadTask];
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (id)initWithDownloadURL:(NSURL *)downloadURL fileName:(NSString *)fileName {
    self = [super init];
    if (self) {
        _fileName = fileName;
        _URL = downloadURL;
        _stautus = DXDownloadStatusPause;
    }
    return self;
}

#pragma mark - Protected

- (void)setDownloadTask:(NSURLSessionDownloadTask *)downloadTask {
    [self cleanUpForTask:_downloadTask];
    _downloadTask = downloadTask;
    [self addObverForTask:_downloadTask];
}

- (void)resume {
    [self.downloadTask resume];
    [[NSNotificationCenter defaultCenter] postNotificationName:DXDownloadManagerBeginDownLoad object:self userInfo:@{DXDownloadComponentKey:self}];
}

- (void)pause {
    [self.downloadTask suspend];
}

- (void)cancel {
    [self.downloadTask cancel];
}

#pragma mark - Observer

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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([object isKindOfClass:[NSURLSessionTask class]]) {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(state))]) {
            // For change state of downloadtask
            DXDownloadStatus newStatus = DXDownloadStatusPause;
            switch ([change[@"new"] integerValue]) {
                case NSURLSessionTaskStateRunning: newStatus = DXDownloadStatusRunning;
                    break;
                case NSURLSessionTaskStateSuspended: newStatus = DXDownloadStatusPause;
                    break;
                case NSURLSessionTaskStateCompleted: newStatus = DXDownloadStatusCompleted;
                    break;
                case NSURLSessionTaskStateCanceling: newStatus = DXDownloadStatusCancel;
                    break;
                default:
                    break;
            }
            self.stautus = newStatus;
            if ([self.delegate respondsToSelector:@selector(downloadComponent:didChangeStatus:)]){
                [self.delegate downloadComponent:self didChangeStatus:newStatus];
            }
            return;
        }
        
        int64_t receivedBytes = self.downloadTask.countOfBytesReceived;;
        int64_t expectedTotalData = self.downloadTask.countOfBytesExpectedToReceive;;
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(countOfBytesReceived))]) {
             receivedBytes = [change[@"new"] longLongValue];
        } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(countOfBytesExpectedToReceive))]) {
            expectedTotalData = [change[@"new"] longLongValue];
        }
        self.receivedData = receivedBytes;
        self.expectedTotalData = expectedTotalData;
        int64_t didWriteBytes = expectedTotalData - self.receivedData;
        
        if ([self.delegate respondsToSelector:@selector(downloadComponent:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:)]) {
            [self.delegate downloadComponent:self didWriteData:didWriteBytes totalBytesWritten:receivedBytes totalBytesExpectedToWrite:expectedTotalData];
        }
    }
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    
    NSLog(@"===Download didFinish===");
    //Update new file name, extension
    CFStringRef mimeType = (__bridge CFStringRef) [downloadTask.response MIMEType];
    CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType, NULL);
    NSString *extension = (__bridge NSString *) UTTypeCopyPreferredTagWithClass(uti, kUTTagClassFilenameExtension);
    if (uti) CFRelease(uti);
    NSString *fileName = [downloadTask.response suggestedFilename];
    if ([extension length] > 0) {
        fileName = [[fileName stringByDeletingPathExtension] stringByAppendingPathExtension:extension];
    }
    NSString *filePath = [sFileManager generateNewPathForFileName:self.fileName];
    self.fileName = filePath.lastPathComponent;
    NSURL *savedURL = [NSURL fileURLWithPath:filePath];
    NSError *error = nil;
    [[NSFileManager defaultManager] moveItemAtURL:location toURL:savedURL error:&error];
    if (!error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:DXDownloadManagerDidDownLoadFinished object:self userInfo:@{DXDownloadComponentKey:self}];
        self.stautus = DXDownloadStatusCompleted;
        self.receivedData = downloadTask.countOfBytesReceived;
    } else {
        self.receivedData = 0;
        self.stautus = DXDownloadStatusCancel;
    }
    self.expectedTotalData = downloadTask.countOfBytesExpectedToReceive;
    if ([self.delegate respondsToSelector:@selector(downloadComponent:didFinishDownloadingToURL:)]) {
        [self.delegate downloadComponent:self didFinishDownloadingToURL:savedURL];
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
    NSLog(@"");
    self.receivedData = task.countOfBytesReceived;
    self.expectedTotalData = task.countOfBytesExpectedToReceive;
    if (error) {
        self.receivedData = 0;
        self.stautus = DXDownloadStatusCancel;
        self.downloadError = error;
    } else {
        if (self.expectedTotalData < 0) {
            self.expectedTotalData = self.receivedData;
        }
    }
    if ([self.delegate respondsToSelector:@selector(downloadComponent:didCompleteWithError:)]) {
        [self.delegate downloadComponent:self didCompleteWithError:error];
    }
    
    // Remove download task when download finish
    [self setDownloadTask:nil];
}

@end
