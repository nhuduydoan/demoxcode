//
//  DXContactModel.h
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 11/21/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class CNContact;

@interface DXContactModel : NSObject

@property (strong, nonatomic, readonly) NSString *identifier;
@property (strong, nonatomic, readonly) NSString *fullName;
@property (strong, nonatomic, readonly) NSString *birthDay;
@property (strong, nonatomic, readonly) NSArray *phones;
@property (strong, nonatomic, readonly) NSArray *emails;
@property (strong, nonatomic, readonly) NSArray *addressArray;
@property (strong, nonatomic, readonly) UIImage *avatar;

- (instancetype)initWithCNContact:(CNContact *)contact;
- (void)updateAvatar:(UIImage *)avatar;

@end
