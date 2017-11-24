//
//  DXContactModel.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 11/21/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXContactModel.h"

@interface DXContactModel ()

@property (strong, nonatomic, readwrite) NSString *fullName;
@property (strong, nonatomic, readwrite) NSString *birthDay;
@property (strong, nonatomic, readwrite) NSArray *phones;
@property (strong, nonatomic, readwrite) NSArray *emails;
@property (strong, nonatomic, readwrite) NSArray *addressArray;
@property (strong, nonatomic, readwrite) UIImage *avatar;

@end

@implementation DXContactModel

- (instancetype)initWithFullName:(NSString *)fullName birthDay:(NSString *)birthDay phones:(NSArray *)phones emails:(NSArray *)emails addressArray:(NSArray *)addressArray avatar:(UIImage *)image {
    self = [super init];
    if (self) {
        _fullName = fullName.copy;
        _birthDay = birthDay.copy;
        _phones = phones.copy;
        _emails = emails.copy;
        _addressArray = addressArray.copy;
        _avatar = image.copy;
    }
    return self;
}

//- (id)copy {
//    
//    DXContactModel *newObj = [[[self class] alloc] init];
//    newObj.fullName = self.fullName.copy;
//    newObj.birthDay = self.birthDay.copy;
//    newObj.phones = self.phones.copy;
//    newObj.emails = self.emails.copy;
//    newObj.addressArray = self.addressArray.copy;
//    newObj.avatar = self.avatar.copy;
//    return newObj;
//}
//
//- (id)copyWithZone:(NSZone *)zone
//{
//    id copy = [[[self class] alloc] init];
//    if (copy) {
//        // Copy NSObject subclasses
//        [copy setFullName:[self.fullName copyWithZone:zone]];
//        [copy setBirthDay:[self.birthDay copyWithZone:zone]];
//        [copy setPhones:[self.phones copyWithZone:zone]];
//        [copy setEmails:[self.emails copyWithZone:zone]];
//        [copy setAddressArray:[self.addressArray copyWithZone:zone]];
//        [copy setAvatar:self.avatar.copy];
//    }
//    return copy;
//}

@end
