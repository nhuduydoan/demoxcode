//
//  DXApplication.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 11/27/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXApplication.h"
#import "DXContactModel.h"
#import "NIinMemoryCache.h"
#import <Contacts/Contacts.h>

@interface DXApplication ()

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

#pragma mark - Sort Contacts

- (NSArray<NSArray *> *)sectionsArraySectionedWithData:(NSArray<DXContactModel *> *)data {
    
    if (data.count == 0) {
        return nil;
    }
    
    NSArray *sortedArray = [self sortArrayFromArray:data];
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
    [sectionsArr addObject:section];
    
    return sectionsArr;
}

- (NSArray *)arrangeSectionedWithData:(NSArray<DXContactModel *> *)data {
    
    if (data.count == 0) {
        return data;
    }
    
    NSArray *sections = [self sectionsArraySectionedWithData:data];
    NSMutableArray *arrangedArray = [NSMutableArray new];
    for (NSArray *section in sections) {
        [arrangedArray addObjectsFromArray:section];
    }
    return arrangedArray;
}

- (NSArray *)arrangeNonSectionedWithData:(NSArray<DXContactModel *> *)data {
    
    if (data.count == 0) {
        return [NSMutableArray new];
    }
    
    NSArray *sortedArray = [self sortArrayFromArray:data];
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

- (NSArray<DXContactModel *> *)sortArrayFromArray:(NSArray<DXContactModel *> *)array {
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"fullName" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    NSArray *sortedArray = [array sortedArrayUsingDescriptors:@[sortDescriptor]];
    return sortedArray;
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

#pragma mark - Parse Contact

- (id)parseContactModelFromCNContact:(CNContact *)contact {
    
    NSArray *phones = [self parsePhonesWithCNContact:contact];
    if (phones.count == 0) {
        return nil;
    }
    
    NSString *identifier = contact.identifier;
    NSString *fullName = [self parseNameWithCNContact:contact];
    NSString *birthDay = [self parseBirthDayWithCNContact:contact];
    NSArray *addrArr = [self parseAddressWithCNContact:contact];
    NSArray *emails = [self parseEmailsWithCNContact:contact];
    UIImage *avartar = [UIImage imageWithData:contact.imageData];
    
    DXContactModel *contactModel = [[DXContactModel alloc] initWithIdentifier:identifier fullName:fullName birthDay:birthDay phones:phones emails:emails addressArray:addrArr avatar:avartar];
    return contactModel;
}

- (NSString *)parseNameWithCNContact:(CNContact *)contact {
    
    NSString *firstName =  contact.givenName;
    NSString *lastName =  contact.familyName;
    NSString *fullName;
    if (lastName == nil) {
        fullName = [NSString stringWithFormat:@"%@", firstName];
    } else if (firstName == nil) {
        fullName = [NSString stringWithFormat:@"%@", lastName];
    } else {
        fullName = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
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
