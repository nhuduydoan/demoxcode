//
//  DXDownloadComponent.h
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/5/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import <Foundation/Foundation.h>
@class DXDownloadComponent, DXDownloadManager;

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
didFinishDownloadingToURL:(NSURL *)location;

- (void)downloadComponent:(DXDownloadComponent *)component
     didCompleteWithError:(NSError *)error;

@end

@interface DXDownloadComponent : NSObject

@property (strong, nonatomic, readonly) NSURL *URL;
@property (strong, nonatomic, readonly) NSURL *savedPath;
@property (nonatomic, readonly) NSURLSessionTaskState stautus;
@property (nonatomic, readonly) NSURLResponse *response;
@property (nonatomic, readonly) NSError *downloadError;
@property (nonatomic, readonly) NSData *resumeData;
@property (nonatomic, strong, readonly) NSProgress *downloadProgress;

@property (weak, nonatomic) id<DXDownloadComponentDelegate> delegate;

/**
 Init function is unavaiable
 @return nil every time
 */
- (instancetype)init NS_UNAVAILABLE;

@end
