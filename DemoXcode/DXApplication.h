//
//  DXApplication.h
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 11/27/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define sApplication [DXApplication sharedInstance]

@interface DXApplication : NSObject

+ (id)sharedInstance;

- (UIImage *)avatarImageFromOriginalImage:(UIImage *)image;
- (UIImage *)avatarImageFromFullName:(NSString *)fullName;

@end
