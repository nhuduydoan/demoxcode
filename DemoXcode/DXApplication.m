//
//  DXApplication.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 11/27/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXApplication.h"
#import "DXContactModel.h"

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
            _instace = [[self.class alloc] initSharedInstance];
        }
    });
    return _instace;
}

- (instancetype)initSharedInstance
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

#pragma mark - Public

-(UIImage *)avatarImageFromFullName:(NSString *)fulleName {
    
    NSString *avatarString = [self avatarStringFromFullName:fulleName];
    NSDictionary *textAttributes = @{NSFontAttributeName:[UIFont systemFontOfSize:44 weight:UIFontWeightRegular],
                                     NSForegroundColorAttributeName:[UIColor whiteColor]};
    CGSize size = [avatarString sizeWithAttributes:textAttributes];
    int randColor = rand() % 8;
    UIColor *backgroundColor = self.avatarBGColors[randColor];
    CGRect rect = CGRectMake(0, 0, 100, 100);
    UIBezierPath* textPath = [UIBezierPath bezierPathWithRect:rect];
    
    UIGraphicsBeginImageContextWithOptions(rect.size,NO,0.0);
    //Fill background color
    [backgroundColor setFill];
    [textPath fill];
    //Draw Srting
    [avatarString drawAtPoint:CGPointMake(rect.size.width/2 - size.width/2, rect.size.height/2 - size.height/2) withAttributes:textAttributes];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
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

- (UIImage *)imageFromString:(NSString *)string {
    
    NSDictionary *textAttributes = @{NSFontAttributeName:[UIFont systemFontOfSize:17]};
    CGSize size = [string sizeWithAttributes:textAttributes];
    UIGraphicsBeginImageContextWithOptions(size,NO,0.0);
    [string drawAtPoint:CGPointMake(0, 0) withAttributes:textAttributes];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (NSArray *)sectionsArrayWhenArrangeSectionedWithData:(NSArray *)data {
    
    if (data.count == 0) {
        return nil;
    }
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"fullName" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    NSArray *sortedArray = [data sortedArrayUsingDescriptors:@[sortDescriptor]];
    NSMutableArray *sectionsArr = [NSMutableArray new];
    NSMutableArray *section = [NSMutableArray new];
    DXContactModel *firstModel = sortedArray.firstObject;
    NSString *groupKey = [self groupKeyForString:firstModel.fullName];
    [section addObject:groupKey];
    
    for (DXContactModel *contact in sortedArray) {
        NSString *checkKey = [self groupKeyForString:contact.fullName];
        if (![checkKey isEqualToString:groupKey]) {
            [sectionsArr addObject:section];
            section = [NSMutableArray new];
            groupKey = checkKey;
            [section addObject:checkKey];
        }
        [section addObject:contact];
    }
    
    return sectionsArr;
}

- (NSArray *)arrangeSectionedWithData:(NSArray *)data {
    
    if (data.count == 0) {
        return data;
    }
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"fullName" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    NSArray *sortedArray = [data sortedArrayUsingDescriptors:@[sortDescriptor]];
    NSMutableArray *arrangedArray = [NSMutableArray new];
    NSString *groupKey = @"";
    
    for (DXContactModel *contact in sortedArray) {
        NSString *checkKey = [self groupKeyForString:contact.fullName] ;
        if (![checkKey isEqualToString:groupKey]) {
            groupKey = checkKey;
            [arrangedArray addObject:checkKey];
        }
        [arrangedArray addObject:contact];
    }
    
    return arrangedArray;
}

- (NSString *)groupKeyForString:(NSString *)string {
    
    NSString *checkString = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (checkString.length == 0) {
        return @"#";
    }
    unichar firstChar = [checkString characterAtIndex:0];
    if (![[NSCharacterSet letterCharacterSet] characterIsMember:firstChar]) {
        return @"#";
    }
    NSString *groupKey = [string substringToIndex:1].uppercaseString;
    return groupKey;
}

- (NSArray *)arrangeNonSectionedWithData:(NSArray *)data {
    
    if (data.count == 0) {
        return [NSMutableArray new];
    }
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"fullName" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    NSArray *sortedArray = [data sortedArrayUsingDescriptors:@[sortDescriptor]];
    NSMutableArray *arrangedArray = [NSMutableArray new];
    NSString *groupKey = @"";
    
    for (DXContactModel *contact in sortedArray) {
        NSString *checkKey = [self groupKeyForString:contact.fullName] ;
        if (![checkKey isEqualToString:groupKey]) {
            groupKey = checkKey;
        }
        [arrangedArray addObject:contact];
    }
    return arrangedArray;
}

@end
