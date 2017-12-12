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
    DXErrorSaveFailed               = -1,
    DXErrorDownloadingSameFile      = -2,
    DXErrorCancelingDownload        = -3,
    DXErrorNetworkNotConected       = -4,
    DXErrorNetworkTimedOut          = -5
};

@protocol DXDownloadComponentDelegate <NSObject>

@optional

/**
 This function will be called when download progress of this instance changes status

 @param component : this DXDownloadComponent instance
 @param status : current NSURLSessionTaskState type status
 */
- (void)downloadComponent:(DXDownloadComponent *)component
          didChangeStatus:(NSURLSessionTaskState)status;

/**
 This function will be called when new data have been writen to tmp disk
 And will be called multiple times while downloading is processing

 @param component : this DXDownloadComponent instance
 @param bytesWritten : newly writen data
 @param totalBytesWritten : all writen data of this download progress
 @param totalBytesExpectedToWrite : total expected data to write
 */
- (void)downloadComponent:(DXDownloadComponent *)component
             didWriteData:(int64_t)bytesWritten
        totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite;

/**
 This function will be called when download instance begins resume download with resume data

 @param component : this DXDownloadComponent instance
 @param fileOffset : offset of resume data
 @param expectedTotalBytes total expected data to write
 */
- (void)downloadComponent:(DXDownloadComponent *)component
        didResumeAtOffset:(int64_t)fileOffset
       expectedTotalBytes:(int64_t)expectedTotalBytes;

/**
 This function will be called when data has just been downloaded and saved to disk
 If given FileURL return by destinationblock and filepath is invalid, data will be
 saved in tmp folder and will be lost after download progress is finished

 @param component : this DXDownloadComponent instance
 @param location : FileURL save data
 */
- (void)downloadComponent:(DXDownloadComponent *)component
didFinishDownloadingAndSaveToURL:(NSURL *)location;

/**
  This function will be called when download procress finished

 @param component : This DXDownloadComponent instance
 @param error : The error occurred while download data
 */
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


// An download instance can be add multiple delegate
#pragma mark - Delegate

- (void)addDelegate:(id<DXDownloadComponentDelegate>)delegate;

- (void)removeDelegate:(id<DXDownloadComponentDelegate>)delegate;

@end
