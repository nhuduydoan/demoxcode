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


/**
 Thí function checks if URL is already being downloaded by this manager and return DXDownloadComponent instance which
 is download instance of given URL, else return nil

 @param URL : URL for download
 @return : nullable DXDownloadComponent object
 */
- (DXDownloadComponent *)downloadComponentForDownloadURL:(NSURL *)URL;

/**
 This function creates an DXDownloadComponent object for download progress from URL and save to given file path
 If this file path is exist a file, add appropriate additional number
 to the end of the file name with format <filename>(number).<extension> and save with new file name at folder
 which were specified is parent folder of the downloaded file(folder path is path which created by remove last component of file path).
 If file name do not have extention, it will be folder parent path of downloaded file, then file name and extension will be
 get from response of download progress.
 
 NOTE:
 If compenent were initilized by this function, but were resumed download by function
 -downloadURL:progress:destination:completionHandler:error
 and the destination will return an valid URL, component will save file at URL returned by destination block.
 And the completionHandler in later function will be set for component instead of the old completionHandler.
 If this URL is already downloaded by manager's shareinstance, this function will return nill and error,
 that you should use function: -downloadComponentForDownloadURL: to check component which is appropriate with
 download progress of given URL, and register to listen it's delegate if need.

 @param URL : NONnul valid URL for download progress
 @param filePath : Nonnull valid FileURL for saving to disk
 @param completionHandler : complete
 @param error : the error happen while try to create component for given URL download progress
 @return : nullable object of DXDownloadComponent class
 */
- (DXDownloadComponent *)downloadURL:(NSURL *)URL
                          toFilePath:(NSURL *)filePath
                   completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler
                               error:(NSError **)error;

/**
 This function creates an DXDownloadComponent object for download progress from given URL and save file to URL returned by destination block.
 If destination is nil, check file path of component to save file.
 If this URL is already downloaded by manager's shareinstance, this function will return nill and error

 @param URL : Nonnull valid URl to download
 @param downloadProgressBlock : nullable block for check progress of the downloading data
 @param destination : nullable block which will return FileURL to save downloaded file.
 @param completionHandler : nullable block which will be call when download finish
 @param error : the error happen while try to create component for given URL download progress
 @return : nullable DXDownloadComponent instance
 */
- (DXDownloadComponent *)downloadURL:(NSURL *)URL
                            progress:(void (^)(NSProgress *downloadProgress))downloadProgressBlock
                         destination:(NSURL *(^)(NSURL *targetPath, NSURLResponse *response))destination
                   completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler
                               error:(NSError **)error;

/**
 This function resumes download progress of given DXDownloadComponent instance.
 Like the function -resumeComponent:error: but this function overides all block of the component.

 @param component : nonnull valid instance for download progress
 @param resumeBlock : nullable block which will be call when resume download progress is begining
 @param downloadProgressBlock : nullable block for check progress of the downloading data
 @param destination : nullable block which will return file URL to save downloaded file.
 @param completionHandler : nullable block which will be call when download finish
 @param error : the error happen while try to create component for given URL download progress
 @return : YES if can resume to download
 */
- (BOOL)resumeComponent:(DXDownloadComponent *)component
            resumeBlock:(void (^)(int64_t fileOffset, int64_t expectedTotalBytes))resumeBlock
               progress:(void (^)(NSProgress *downloadProgress))downloadProgressBlock
            destination:(NSURL * (^)(NSURL *targetPath, NSURLResponse *response))destination
      completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler
                  error:(NSError **)error;

/**
 This function resumes download progress of given DXDownloadComponent instance.
 If given component contain resume data, resumes download with that data, else redownload from begining.
 If URL of downlaod intance is already downloaded by this manager, return nil and error.

 @param component : nonnull valid íntance ò dơnloading progress
 @param error the error happen while try to create component for given URL download progress
 @return : YES if can resume to download
 */
- (BOOL)resumeComponent:(DXDownloadComponent *)component
                  error:(NSError **)error;

/**
 Suppends an download component

 @param component : nonnull valid component for download progress
 */
- (void)suppendComponent:(DXDownloadComponent *)component;

/**
 Cancels an download component
 
 @param component : nonnull valid component for download progress
 */
- (void)cancelComponent:(DXDownloadComponent *)component;

/**
 Cancels all download progress of manager' shareintance
 */
- (void)cancelAllDownloads;

@end
