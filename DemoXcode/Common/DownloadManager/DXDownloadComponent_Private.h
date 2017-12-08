//
//  DXDownloadComponent_Private.h
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/6/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXDownloadComponent.h"

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

- (void)setDownloadProgressBlock:(void (^)(NSProgress *))downloadProgressBlock;

- (void) setResumeBlock:(void (^)(DXDownloadComponent *, int64_t, int64_t))resumeBlock;

- (void)setDestinationBlock:(NSURL *(^)(NSURL *, NSURLResponse *))destinationBlock;

- (void)setCompletionHandler:(void (^)(NSURLResponse *, NSURL *, NSError *))completionHandler;

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
