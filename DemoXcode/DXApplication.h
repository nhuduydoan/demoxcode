//
//  DXApplication.h
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 11/27/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "DXContactModel.h"
@class CNContact;

#define sApplication [DXApplication sharedInstance]

@interface DXApplication : NSObject

+ (id)sharedInstance;

- (UIImage *)avatarImageFromOriginalImage:(UIImage *)image;
- (UIImage *)avatarImageFromFullName:(NSString *)fullName;
- (UIImage *)imageFromString:(NSString *)string;

- (NSArray *)sectionsArraySectionedWithData:(NSArray *)data;
- (NSArray *)arrangeSectionedWithData:(NSArray *)data;
- (NSArray *)arrangeNonSectionedWithData:(NSArray *)data;

- (id)parseContactModelWithCNContact:(CNContact *)contact;

@end
