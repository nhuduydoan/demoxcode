//
//  DXFileManager.h
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/4/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import <Foundation/Foundation.h>
@class DXFileManager, DXFileModel;

extern NSString* const DXDownloadManagerDidDownLoadFinished;

@protocol DXFileManagerDelegate <NSObject>

@optional
- (void)fileManager:(DXFileManager*)fileManager didInsertNewItem:(DXFileModel *)fileModel;

@end

#define sFileManager [DXFileManager sharedInstance]

@interface DXFileManager : NSObject

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

#pragma mark - Files

- (NSString *)rootFolderPath;

- (void)allFileItemModels:(void (^)(NSArray<DXFileModel *> *fileItems))completionHandler;

- (NSData *)contentOfFileItem:(DXFileModel *)model;

- (NSString *)generateNewPathForFileName:(NSString *)fileName;

#pragma mark - Delegate

- (void)addDelegate:(id<DXFileManagerDelegate>)delegate;

- (void)removeDelegate:(id<DXFileManagerDelegate>)delegate;

@end
