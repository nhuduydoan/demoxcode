//
//  DXDownloadComponent.h
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/5/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DXDownloadModel.h"
@class DXDownloadComponent;

typedef NS_ENUM(NSUInteger) {
    DXDownloadStatusNone        = 0,
    DXDownloadStatusRunning     = 1,
    DXDownloadStatusPause       = 2,
    DXDownloadStatusCancel      = 3,
    DXDownloadStatusCompleted   = 4
}DXDownloadStatus;

extern NSString *const DXDownloadManagerBeginDownLoad;
extern NSString *const DXDownloadManagerDidDownLoadFinished;
extern NSString *const DXDownloadComponentKey; 

@protocol DXDownloadComponentDelegate <NSObject>
@optional
- (void)didUpdateDownloadComponent:(DXDownloadComponent *)component;
- (void)downloadComponent:(DXDownloadComponent *)component didFinishDownloadingToURL:(NSURL *)location;
- (void)downloadComponent:(DXDownloadComponent *)component didCompleteWithError:(NSError *)error;

@end

@interface DXDownloadComponent : NSObject

@property (weak, nonatomic) id<DXDownloadComponentDelegate> delegate;

@property (strong, nonatomic, readonly) DXDownloadModel *downloadModel;
@property (strong, nonatomic, readonly) NSURLSessionTask *downloadTask;
@property (nonatomic) DXDownloadStatus stautus;

- (id)initWithDownloadModel:(DXDownloadModel *)downloadModel downloadTask:(NSURLSessionDownloadTask *)downloadTask;

- (void)pause;

- (void)resume;

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite;

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location;

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error;

@end
