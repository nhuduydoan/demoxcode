//
//  DXImageManager.h
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/3/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import <Foundation/Foundation.h>
@class DXContactModel;

#define sImageManager [DXImageManager sharedInstance]

@interface DXImageManager : NSObject

+ (id)sharedInstance;

- (void)avatarForCNContact:(DXContactModel *)contact withCompletionHandler:(void (^)(UIImage *iamge))completionHande;
- (UIImage *)titleImageFromString:(NSString *)string;

@end
