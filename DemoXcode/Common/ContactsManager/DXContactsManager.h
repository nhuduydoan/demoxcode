//
//  DXContactsManager.h
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 11/20/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import <Foundation/Foundation.h>
@class DXContactModel;

#define sContactMngr [DXContactsManager shareInstance]

@interface DXContactsManager : NSObject

/**
 Alloc and init and manager Object for using
 Please use this function to create new object

 @return : nil able
 */
+ (instancetype)shareInstance;

/**
 This function is avaiable
 Please user +shareInstance instead

 @return : alway nil
 */
- (id)init NS_UNAVAILABLE;

/**
 This function reuqest permisstion to check access of CNContacts

 @param completeBlock : completition handler block wil be called when requesting is finished
 if isAccess is NO, an error will be attached
 @param callBackQueue : dispatch queue which competition handler block will be executed on, if this value is null, competition will be executed on Main queue
 */
- (void)requestPermissionWithCompletionHandler:(void (^)(BOOL isAccess, NSError *error))completeBlock callBackQueue:(dispatch_queue_t)callBackQueue;

/**
 This function loads more data and call back async competition handler block once time when finish
 
 @param fromIndex : index which data will load more from
 @param count : max count of data will be return in callback handler
 @param completionHandler : block for callback. If data is last piece of all contacts data, isFinished variable will be set YES, that mean do not have any data for loadmore. @param callBackQueue : dispatch queue which competition handler block will be executed on, if this value is null, competition will be executed on Main queue
 */
- (void)loadMoreContactsFromIndex:(NSUInteger)fromIndex count:(NSUInteger)count withCompletionHandler:(void (^)(NSArray<DXContactModel *> *contacts, NSError *error, BOOL isFinished))completionHandler callBackQueue:(dispatch_queue_t)callBackQueue;

@end
