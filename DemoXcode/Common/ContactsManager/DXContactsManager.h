//
//  DXContactsManager.h
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 11/20/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import <Foundation/Foundation.h>

#define sContactMngr [DXContactsManager shareInstance]

@interface DXContactsManager : NSObject

+ (instancetype)shareInstance;

- (void)requestPermissionWithCompletionHandler:(void (^)(BOOL isAccess, NSError *error))completeBlock;

/**
This function get get all contacts from phone and return in competition handler block, if an error were happend, return its and null data in handler block.
 The competition handler block will be multiable callbacked with each piece of data or will be callbacked one time with all data when load finished all finished .

 @param completionHandler : block for callback.  When load finished all data, isFinished variable will be set YES
 @param isMultiCalback : multi calback handler block while load data or callback it once time when finish load data
 */
- (void)getAllComtactsWithCompletionHandler:(void (^)(NSArray *contacts, NSError *error, BOOL isFinished))completionHandler isMultiCalback:(BOOL)isMultiCalback;

/**
 This function loads more data and call back async competition handler block once time when finish
 
 @param fromIndex : index which data will load more from
 @param count : max count of data will be return in callback handler
 @param completionHandler : block for callback. If data is last piece of all contacts data, isFinished variable will be set YES, that mean do not have any data for loadmore.
 */
- (void)loadMoreContactsFromIndex:(NSUInteger)fromIndex count:(NSUInteger)count withCompletionHandler:(void (^)(NSArray *contacts, NSError *error, BOOL isFinished))completionHandler;

@end
