//
//  DXDownloadComponent.h
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/5/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import <Foundation/Foundation.h>
@class DXDownloadComponent, DXDownloadManager;

typedef NS_ENUM(NSInteger, DXDownloadErrorCode) {
    DXErrorSaveFailed = -1,
    DXErrorDownloadingSameFile = -2,
    DXErrorCancelingDownload = -3
};

@protocol DXDownloadComponentDelegate <NSObject>

@optional
- (void)downloadComponent:(DXDownloadComponent *)component
          didChangeStatus:(NSURLSessionTaskState)status;

- (void)downloadComponent:(DXDownloadComponent *)component
             didWriteData:(int64_t)bytesWritten
        totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite;

- (void)downloadComponent:(DXDownloadComponent *)component
        didResumeAtOffset:(int64_t)fileOffset
       expectedTotalBytes:(int64_t)expectedTotalBytes;

- (void)downloadComponent:(DXDownloadComponent *)component
didFinishDownloadingAndSaveToURL:(NSURL *)location;

- (void)downloadComponent:(DXDownloadComponent *)component
     didCompleteWithError:(NSError *)error;

@end

@interface DXDownloadComponent : NSObject

@property (strong, nonatomic, readonly) NSURL *URL;
@property (strong, nonatomic, readonly) NSURL *savedPath;
@property (nonatomic, readonly) NSURLSessionTaskState stautus;
@property (strong, nonatomic, readonly) NSURLResponse *response;
@property (strong, nonatomic, readonly) NSError *downloadError;
@property (strong, nonatomic, readonly) NSData *resumeData;
@property (strong, nonatomic, readonly) NSProgress *downloadProgress;

/**
 Init function is unavaiable
 @return nil every time
 */
- (instancetype)init NS_UNAVAILABLE;

#pragma mark - Delegate

- (void)addDelegate:(id<DXDownloadComponentDelegate>)delegate;

- (void)removeDelegate:(id<DXDownloadComponentDelegate>)delegate;

@end
