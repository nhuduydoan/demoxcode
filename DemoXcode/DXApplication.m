//
//  DXApplication.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 11/27/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXApplication.h"

#define kMakeColor(r,g,b,a) [UIColor colorWithRed:r/255.f green:g/255.f blue:b/255.f alpha:a]

@interface DXApplication ()

@property (strong, nonatomic) NSArray *avatarBGColors;

@end

@implementation DXApplication

+ (id)sharedInstance {
    static id _instace;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!_instace) {
            _instace = [[self.class alloc] init];
        }
    });
    return _instace;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setUpAvatarBGColors];
    }
    return self;
}

- (void)setUpAvatarBGColors {
    
    NSMutableArray *colorsArr = [NSMutableArray new];
    UIColor *color1 = kMakeColor(152, 193, 213, 1);
    UIColor *color2 = kMakeColor(140, 205, 188, 1);
    UIColor *color3 = kMakeColor(122, 196, 216, 1);
    UIColor *color4 = kMakeColor(238, 179, 148, 1);
    UIColor *color5 = kMakeColor(239, 155, 155, 1);
    UIColor *color6 = kMakeColor(197, 165, 150, 1);
    UIColor *color7 = kMakeColor(173, 175, 231, 1);
    UIColor *color8 = kMakeColor(171, 176, 193, 1);
    [colorsArr addObject:color1];
    [colorsArr addObject:color2];
    [colorsArr addObject:color3];
    [colorsArr addObject:color4];
    [colorsArr addObject:color5];
    [colorsArr addObject:color6];
    [colorsArr addObject:color7];
    [colorsArr addObject:color8];
    self.avatarBGColors = colorsArr.copy;
}

- (UIImage *)avatarImageFromOriginalImage:(UIImage *)image {
    
    CGFloat width, height;
    if (image.size.width > image.size.height) {
        height = 100;
        width = image.size.width/image.size.height * 100;
    } else {
        width = 100;
        height = image.size.width/image.size.height * 100;
    }
    
    if (image.imageOrientation == UIImageOrientationLeft || image.imageOrientation == UIImageOrientationRight) {
        CGFloat x = width;
        width = height;
        height = x;
    }
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), YES, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(context);
    [image drawInRect:CGRectMake(0, 0, width, height)];
    UIGraphicsPopContext();
    UIImage *avartar = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return avartar;
}

-(UIImage *)avatarImageFromFullName:(NSString *)fulleName {
    
    int randColor = rand() % 8;
    UIColor *backgroundColor = self.avatarBGColors[randColor];
    UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    textLabel.backgroundColor = backgroundColor;
    textLabel.textAlignment = NSTextAlignmentCenter;
    textLabel.font = [UIFont systemFontOfSize:44 weight:UIFontWeightRegular];
    textLabel.textColor = [UIColor whiteColor];
    NSString *avatarString = [self avatarStringFromFullName:fulleName];
    textLabel.text = avatarString;
    
    UIGraphicsBeginImageContext(textLabel.bounds.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [textLabel.layer renderInContext:context];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

- (NSString *)avatarStringFromFullName:(NSString *)fullName {
    
    NSString *avatarStr = @"";
    if (fullName.length == 0) {
        return avatarStr;
    }
    
    BOOL isFirstKey = YES;
    NSCharacterSet *characterSet = [NSCharacterSet alphanumericCharacterSet];
    NSCharacterSet *spaceSet = [NSCharacterSet whitespaceCharacterSet];
    
    for (NSInteger i = 0; i < fullName.length; i++) {
        unichar character = [fullName characterAtIndex:i];
        if (isFirstKey && [characterSet characterIsMember:character]) {
            NSString *addKey = [fullName substringFromIndex:i];
            addKey = [addKey substringToIndex:1];
            avatarStr = [avatarStr stringByAppendingString:addKey.uppercaseString];
            if (avatarStr.length >= 2) {
                break;
            }
            isFirstKey = NO;
        } else if ([spaceSet characterIsMember:character]) {
            isFirstKey = YES;
        }
    }
    
    if (avatarStr.length == 0) {
        for (NSInteger i = 0; i < fullName.length; i++) {
            unichar character = [fullName characterAtIndex:i];
            if (![spaceSet characterIsMember:character]) {
                NSString *addKey = [fullName substringFromIndex:i];
                addKey = [addKey substringToIndex:1];
                avatarStr = [avatarStr stringByAppendingString:addKey];
                if (avatarStr.length >= 2) {
                    break;
                }
                isFirstKey = NO;
            } else {
                isFirstKey = YES;
            }
        }
    }
    
    return avatarStr;
}

@end
