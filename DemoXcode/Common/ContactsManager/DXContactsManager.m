//
//  DXContactsManager.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 11/20/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DXContactsManager.h"
#import <Contacts/Contacts.h>
#import "DXContactModel.h"

@interface DXContactsManager ()

@end

@implementation DXContactsManager

+ (instancetype)shareInstance {
    static id _instace;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!_instace) {
            _instace = [[self alloc] init];
        }
    });
    return _instace;
}

#pragma mark - Private

- (void)mainThread:(void (^)(void))block {
    if ([[NSThread currentThread] isMainThread]) {
        if (block) {
            block();
        }
        
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (block) {
                block();
            }
        });
    }
}

- (DXContactModel *)parseContactWithContact :(CNContact* )contact {
    
    NSString *fullName = [self parseNameWithContact:contact];
    NSString *birthDay = [self parseBirthDayWithContact:contact];
    UIImage *avartar = [UIImage imageWithData:contact.imageData];
    NSArray * addrArr = [self parseAddressWithContact:contact];
    NSArray *phones = [self parsePhonesWithContact:contact];
    NSArray *emails = [self parseEmailsWithContact:contact];
    DXContactModel *contactModel = [[DXContactModel alloc] initWithFullName:fullName birthDay:birthDay phones:phones emails:emails addressArray:addrArr avatar:avartar];
    return contactModel;
}

- (NSString *)parseNameWithContact:(CNContact *)contact {
    
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

- (NSArray *)parsePhonesWithContact:(CNContact *)contact {
    
    NSMutableArray *phones = [NSMutableArray new];
    for (CNLabeledValue *label in contact.phoneNumbers) {
        NSString *phone = [label.value stringValue];
        if ([phone length] > 0) {
            [phones addObject:phone];
        }
    }
    return phones;
}

- (NSArray *)parseEmailsWithContact:(CNContact *)contact {
    
    NSMutableArray *emails = [NSMutableArray new];
    for (CNLabeledValue *label in contact.emailAddresses) {
        NSString *email = label.value;
        if ([email length] > 0) {
            [emails addObject:email];
        }
    }
    return emails;
}

- (NSString *)parseBirthDayWithContact:(CNContact *)contact  {
    
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

- (NSMutableArray *)parseAddressWithContact:(CNContact *)contact {
    
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

#pragma mark - Public

- (void)requestAccessForContactAuthorizationStatusWithCompetition:(void (^)(BOOL isAccess, NSError *error))completeBlock {
    
    if (![CNContactStore class]) {
        if (completeBlock) {
            [self mainThread:^{
                completeBlock(NO, nil);
            }];
        }
        return;
    }
    
    //ios9 or later
    CNEntityType entityType = CNEntityTypeContacts;
    CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
    switch (status) {
        case CNAuthorizationStatusAuthorized: {
            if (completeBlock) {
                [self mainThread:^{
                    completeBlock(YES, nil);
                }];
            }
            return;
        }
            break;
        case CNAuthorizationStatusNotDetermined: {
            CNContactStore * contactStore = [[CNContactStore alloc] init];
            [contactStore requestAccessForEntityType:entityType completionHandler:^(BOOL granted, NSError * _Nullable error) {
                if (completeBlock) {
                    [self mainThread:^{
                        completeBlock(granted, nil);
                    }];
                }
            }];
        }
            break;
            
        case CNAuthorizationStatusDenied: {
            [self mainThread:^{
                NSError *error = [NSError errorWithDomain:@"You explicitly denied access to contact data. Please go to Settings and allow this appliaction use phone's contacts" code:-1 userInfo:nil];
                if (completeBlock){
                    completeBlock(NO, error);
                }
            }];
        }
            break;
            
        case CNAuthorizationStatusRestricted: {
            [self mainThread:^{
                NSError *error = [NSError errorWithDomain:@"You cannot change this application’s status, possibly due to active restrictions such as parental controls being in place." code:-1 userInfo:nil];
                if (completeBlock){
                    completeBlock(NO, error);
                }
            }];
        }
            break;
            
        default: {
            [self mainThread:^{
                if (completeBlock){
                    completeBlock(NO, nil);
                }
            }];
        }
            break;
    }
}

- (void)getAllContactsWithCompletion:(void (^)(NSArray *contacts))completeBlock {
    
    if (![CNContactStore class]) {
        if (completeBlock) {
            if (completeBlock) {
                [self mainThread:^{
                    completeBlock(nil);
                }];
            }
        }
        return;
    }
    
    CNContactStore *contactStore = [[CNContactStore alloc] init];
    [contactStore requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
        NSMutableArray *contactsArr = [NSMutableArray new];
        if (granted == YES) {
            //keys with fetching properties
            NSArray *keys = @[CNContactFamilyNameKey, CNContactGivenNameKey, CNContactPhoneNumbersKey, CNContactImageDataKey, CNContactEmailAddressesKey, CNContactPostalAddressesKey, CNContactBirthdayKey];
            CNContactFetchRequest *request = [[CNContactFetchRequest alloc] initWithKeysToFetch:keys];
            request.sortOrder = CNContactSortOrderUserDefault;
           [contactStore enumerateContactsWithFetchRequest:request error:&error usingBlock:^(CNContact * __nonnull contact, BOOL * __nonnull stop) {
                if (error) {
                    NSLog(@"error fetching contacts %@", error);
                } else {
                    DXContactModel *contactModel = [self parseContactWithContact:contact];
                    if (contactModel) {
                        [contactsArr addObject:contactModel];
                    }
                }
            }];
        }
        if (completeBlock) {
            [self mainThread:^{
                completeBlock(contactsArr);
            }];
        }
        
        
        //            NSArray *allContainers = [contactStore containersMatchingPredicate:nil error:&error];
        //            if (error) {
        //                if (completeBlock) {
        //                    if (completeBlock) {
        //                        [self mainThread:^{
        //                            completeBlock(nil);
        //                        }];
        //                    }
        //                }
        //                return;
        //            }
        //            for (CNContainer *container in allContainers) {
        //                NSString *containerId = container.identifier;
        //                NSPredicate *predicate = [CNContact predicateForContactsInContainerWithIdentifier:containerId];
        //                NSArray *cnContacts = [contactStore unifiedContactsMatchingPredicate:predicate keysToFetch:keys error:&error];
        //                //            cnContacts = [contactStore unifiedContactsMatchingPredicate:[CNContact predicateForContactsMatchingName:@"John Appleseed"] keysToFetch:keys error:&error];
        //                if (error) {
        //                    NSLog(@"error fetching contacts %@", error);
        //                    continue;
        //
        //                } else {
        //                    for (CNContact *contact in cnContacts) {
        //                        DXContactModel *contactModel = [self parseContactWithContact:contact];
        //                        if (contactModel) {
        //                            [contactsArr addObject:contactModel];
        //                        }
        //                    }
        //                }
        //                if (completeBlock) {
        //                    [self mainThread:^{
        //                        completeBlock(contactsArr);
        //                    }];
        //                }
        //            }
    }];
}

@end
