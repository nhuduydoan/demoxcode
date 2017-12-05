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

@property (strong, nonatomic, readwrite) DXDownloadModel *downloadModel;
@property (strong, nonatomic, readwrite) NSURLSessionTask *downloadTask;

@end

@implementation DXDownloadComponent

- (void)dealloc {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (id)initWithDownloadModel:(DXDownloadModel *)downloadModel downloadTask:(NSURLSessionDownloadTask *)downloadTask {
    self = [super init];
    if (self) {
        _downloadModel = downloadModel;
        _downloadTask = downloadTask;
    }
    return self;
}

- (void)pause {
    [self.downloadTask suspend];
    self.stautus = DXDownloadStatusPause;
}

- (void)resume {
    [self.downloadTask resume];
    self.stautus = DXDownloadStatusRunning;
    [[NSNotificationCenter defaultCenter] postNotificationName:DXDownloadManagerBeginDownLoad object:self userInfo:@{DXDownloadComponentKey:self}];
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    
    if ([self.delegate respondsToSelector:@selector(didUpdateDownloadComponent:)]) {
        [self.delegate didUpdateDownloadComponent:self];
    }
}

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
    NSString *filePath = [sFileManager generateNewPathForFileName:self.downloadModel.fileName];
    [self.downloadModel updateFileName:filePath.lastPathComponent];
    NSURL *savedURL = [NSURL fileURLWithPath:filePath];
    NSError *error = nil;
    [[NSFileManager defaultManager] moveItemAtURL:location toURL:savedURL error:&error];
    if (!error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:DXDownloadManagerDidDownLoadFinished object:self userInfo:@{DXDownloadComponentKey:self}];
        self.stautus = DXDownloadStatusCompleted;
    } else {
        self.stautus = DXDownloadStatusCancel;
    }
    if ([self.delegate respondsToSelector:@selector(downloadComponent:didFinishDownloadingToURL:)]) {
        [self.delegate downloadComponent:self didFinishDownloadingToURL:savedURL];
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
    NSLog(@"");
    if (error) {
        self.stautus = DXDownloadStatusCancel;
    }
    if ([self.delegate respondsToSelector:@selector(downloadComponent:didCompleteWithError:)]) {
        [self.delegate downloadComponent:self didCompleteWithError:error];
    }
}

@end
