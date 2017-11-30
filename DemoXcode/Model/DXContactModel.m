//
//  DXContactModel.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 11/21/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXContactModel.h"
#import <Contacts/Contacts.h>

@interface DXContactModel ()

@property (strong, nonatomic, readwrite) NSString *identifier;
@property (strong, nonatomic, readwrite) NSString *fullName;
@property (strong, nonatomic, readwrite) NSString *birthDay;
@property (strong, nonatomic, readwrite) NSArray *phones;
@property (strong, nonatomic, readwrite) NSArray *emails;
@property (strong, nonatomic, readwrite) NSArray *addressArray;
@property (strong, nonatomic, readwrite) UIImage *avatar;

@end

@implementation DXContactModel

- (instancetype)initWithCNContact:(CNContact *)contact {
    self = [super init];
    if (self) {
        
        NSArray *phones = [self parsePhonesWithCNContact:contact];
        if (phones.count == 0) {
            return nil;
        }
        NSString *identifier = contact.identifier;
        NSString *fullName = [self parseNameWithCNContact:contact];
        NSString *birthDay = [self parseBirthDayWithCNContact:contact];
        UIImage *avartar = [UIImage imageWithData:contact.imageData];
        NSArray *addrArr = [self parseAddressWithCNContact:contact];
        NSArray *emails = [self parseEmailsWithCNContact:contact];
        _identifier = identifier.copy;
        _fullName = fullName.copy;
        _birthDay = birthDay.copy;
        _phones = phones.copy;
        _emails = emails.copy;
        _addressArray = addrArr.copy;
        _avatar = avartar.copy;
    }
    return self;
}

- (instancetype)initWithIdentifier:(NSString *)identifier fullName:(NSString *)fullName birthDay:(NSString *)birthDay phones:(NSArray *)phones emails:(NSArray *)emails addressArray:(NSArray *)addressArray avatar:(UIImage *)image {
    self = [super init];
    if (self) {
        _identifier = identifier.copy;
        _fullName = fullName.copy;
        _birthDay = birthDay.copy;
        _phones = phones.copy;
        _emails = emails.copy;
        _addressArray = addressArray.copy;
        _avatar = image.copy;
    }
    return self;
}

- (void)updateAvatar:(UIImage *)avatar {
    _avatar = avatar;
}

- (NSString *)parseNameWithCNContact:(CNContact *)contact {
    
    NSString *firstName =  contact.givenName;
    NSString *lastName =  contact.familyName;
    NSString *fullName;
    if (lastName == nil) {
        fullName=[NSString stringWithFormat:@"%@",firstName];
    } else if (firstName == nil) {
        fullName = [NSString stringWithFormat:@"%@",lastName];
    } else {
        fullName = [NSString stringWithFormat:@"%@ %@",firstName,lastName];
    }
    return fullName;
}

- (NSArray *)parsePhonesWithCNContact:(CNContact *)contact {
    
    NSMutableArray *phones = [NSMutableArray new];
    for (CNLabeledValue *label in contact.phoneNumbers) {
        NSString *phone = [label.value stringValue];
        if ([phone length] > 0) {
            [phones addObject:phone];
        }
    }
    return phones;
}

- (NSArray *)parseEmailsWithCNContact:(CNContact *)contact {
    
    NSMutableArray *emails = [NSMutableArray new];
    for (CNLabeledValue *label in contact.emailAddresses) {
        NSString *email = label.value;
        if ([email length] > 0) {
            [emails addObject:email];
        }
    }
    return emails;
}

- (NSString *)parseBirthDayWithCNContact:(CNContact *)contact  {
    
    NSDateComponents *birthDayComponent;
    NSString *birthDayStr;
    birthDayComponent = contact.birthday;
    if (birthDayComponent != nil) {
        birthDayComponent = contact.birthday;
        NSInteger day = [birthDayComponent day];
        NSInteger month = [birthDayComponent month];
        NSInteger year = [birthDayComponent year];
        birthDayStr = [NSString stringWithFormat:@"%ld/%ld/%ld",(long)day,(long)month,(long)year];
    }
    return birthDayStr;
}

- (NSMutableArray *)parseAddressWithCNContact:(CNContact *)contact {
    
    NSMutableArray *addrArr = [NSMutableArray new];
    CNPostalAddressFormatter *formatter = [[CNPostalAddressFormatter alloc]init];
    NSArray *addresses = contact.postalAddresses;
    for (CNLabeledValue *label in addresses) {
        CNPostalAddress *address = label.value;
        NSString *addressString = [formatter stringFromPostalAddress:address];
        if ([addressString length] > 0) {
            [addrArr addObject:addressString];
        }
    }
    
    return addrArr;
}

@end
