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


/**
 Get avatar image from cache for contact model
 If no image in cache, draw new image from original avatar or draw an image from contact's full name

 @param contact : non null contact model
 @param completionHande : block which will be execute when get/create avatar image finished
 */
- (void)avatarForCNContact:(DXContactModel *)contact withCompletionHandler:(void (^)(UIImage *iamge))completionHande;


/**
 Draw an image with clear background color and size 100x100, text is given string

 @param string : string for drawing
 @return : nullable image
 */
- (UIImage *)titleImageFromString:(NSString *)string;
- (UIImage *)avatarImageFromOriginalImage:(UIImage *)image;

@end
