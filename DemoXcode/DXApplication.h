//
//  DXApplication.h
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 11/27/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class CNContact;

#define sApplication [DXApplication sharedInstance]

@interface DXApplication : NSObject

+ (id)sharedInstance;

- (NSArray *)sectionsArraySectionedWithData:(NSArray *)data;
- (NSArray *)arrangeSectionedWithData:(NSArray *)data;
- (NSArray *)arrangeNonSectionedWithData:(NSArray *)data;

- (id)parseContactModelWithCNContact:(CNContact *)contact;

@end
