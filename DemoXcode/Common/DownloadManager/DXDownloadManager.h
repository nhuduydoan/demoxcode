//
//  DXDownloadManager.h
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/1/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import <Foundation/Foundation.h>
@class DXDownloadModel ,DXDownloadComponent;

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

- (DXDownloadComponent *)downloadWithModel:(DXDownloadModel *)model;
- (DXDownloadComponent *)omponentDownloadForModel:(DXDownloadModel *)model;

@end
