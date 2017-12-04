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
 This function is unavaiable
 Please use +shareInstance instead

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
 This function loads all contacts from phone and callback async competition handler block when finished
 
 @param completionHandler : handler block for callback, has array of reult contacts and error if it were happen
 @param callBackQueue : dispatch queue which competition handler block will be executed on, if this value is null, competition will be executed on Main queue
 */
- (void)getAllContactsWithCompletionHandler:(void (^)(NSArray<DXContactModel *> *contacts, NSError *error))completionHandler callBackQueue:(dispatch_queue_t)callBackQueue;

@end
