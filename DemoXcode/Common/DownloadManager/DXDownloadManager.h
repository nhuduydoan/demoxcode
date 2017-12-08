//
//  DXDownloadManager.h
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/1/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import <Foundation/Foundation.h>
@class DXDownloadComponent;

#define sDownloadManager [DXDownloadManager sharedInstance]

@interface DXDownloadManager : NSObject

/**
 Alloc and init and manager Object for using
 Please use this function to create new object
 
 @return : nil able
 */
+ (id)sharedInstance;

/**
 This function is avaiable
 Please user +shareInstance instead
 
 @return : alway nil
 */
- (instancetype)init NS_UNAVAILABLE;

#pragma mark - Download

- (DXDownloadComponent *)downloadComponentForDownloadURL:(NSURL *)URL;

- (DXDownloadComponent *)downloadURL:(NSURL *)URL
                          toFilePath:(NSURL *)filePath
                   completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler
                               error:(NSError **)error;

- (DXDownloadComponent *)downloadURL:(NSURL *)URL
                            progress:(void (^)(NSProgress *downloadProgress))downloadProgressBlock
                         destination:(NSURL *(^)(NSURL *targetPath, NSURLResponse *response))destination
                   completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler
                               error:(NSError **)error;

- (BOOL)resumeComponent:(DXDownloadComponent *)component
            resumeBlock:(void (^)(int64_t fileOffset, int64_t expectedTotalBytes))resumeBlock
               progress:(void (^)(NSProgress *downloadProgress))downloadProgressBlock
            destination:(NSURL * (^)(NSURL *targetPath, NSURLResponse *response))destination
      completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler
                  error:(NSError **)error;

- (BOOL)resumeComponent:(DXDownloadComponent *)component
                  error:(NSError **)error;

- (void)suppendComponent:(DXDownloadComponent *)component;

- (void)cancelComponent:(DXDownloadComponent *)component;

- (void)cancelAllDownloads;

@end
