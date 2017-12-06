//
//  DXDownloadComponent.h
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/5/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import <Foundation/Foundation.h>
@class DXDownloadComponent;

typedef NS_ENUM(NSUInteger) {
    DXDownloadStatusPause       = 0,
    DXDownloadStatusRunning     = 1,
    DXDownloadStatusCancel      = 2,
    DXDownloadStatusCompleted   = 3
}DXDownloadStatus;

extern NSString *const DXDownloadManagerBeginDownLoad;
extern NSString *const DXDownloadManagerDidDownLoadFinished;
extern NSString *const DXDownloadComponentKey; 

@protocol DXDownloadComponentDelegate <NSObject>
@optional
- (void)downloadComponent:(DXDownloadComponent *)component didChangeStatus:(DXDownloadStatus)status;
- (void)downloadComponent:(DXDownloadComponent *)component didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite;
- (void)downloadComponent:(DXDownloadComponent *)component didFinishDownloadingToURL:(NSURL *)location;
- (void)downloadComponent:(DXDownloadComponent *)component didCompleteWithError:(NSError *)error;

@end

@interface DXDownloadComponent : NSObject

@property (strong, nonatomic, readonly) NSString *fileName;
@property (strong, nonatomic, readonly) NSURL *URL;
@property (nonatomic, readonly) DXDownloadStatus stautus;
@property (nonatomic, readonly) int64_t receivedData;
@property (nonatomic, readonly) int64_t expectedTotalData;
@property (nonatomic, readonly) NSError *downloadError;

/**
 This property represents the download and will be manage by DownloadManager
 If stautus value is DXDownloadStatusCancel or DXDownloadStatusCompleted, downloadTask will be nil
 */
@property (strong, nonatomic, readonly) NSURLSessionDownloadTask *downloadTask;

@property (weak, nonatomic) id<DXDownloadComponentDelegate> delegate;

- (id)initWithDownloadURL:(NSURL *)downloadURL fileName:(NSString *)fileName;

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location;

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error;

@end
