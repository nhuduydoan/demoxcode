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

- (void)requestAccessForContactAuthorizationStatusWithCompetition:(void (^)(BOOL isAccess, NSError *error))completeBlock;

- (void)getAllContactsWithCompletion:(void (^)(NSArray *contacts))completeBlock;

@end
