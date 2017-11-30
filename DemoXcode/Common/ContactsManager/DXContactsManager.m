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

#define kMaxCount 50

@interface HandlerObject : NSObject

@property (nonatomic) NSUInteger startIndex;
@property (nonatomic) NSUInteger count;
@property (nonatomic, copy, nonnull) void (^handlerBlock)(NSArray *contacts, NSError *error, BOOL isFinished);

@end

@implementation HandlerObject

- (id)initWithStartIndex:(NSUInteger)startIndex count:(NSUInteger)count handlerBlock:(void (^)(NSArray *, NSError *, BOOL))handlerBlock {
    NSAssert(count, @"Maxcount cannot be 0");
    self = [super init];
    if (self) {
        _startIndex = startIndex;
        _count = count;
        _handlerBlock = handlerBlock;
    }
    return self;
}

@end

@interface DXContactsManager ()

@property (strong, nonatomic) dispatch_queue_t managerSafeQueue;
@property (strong, nonatomic) NSThread *managerSafeThread;
@property (strong, nonatomic) NSMutableArray *allCacheContacts;
@property (strong, nonatomic) NSDate *requestDate;
@property (nonatomic) BOOL isRequesting;
@property (strong, nonatomic) NSMutableArray *handlerObjectsArr;

@end

@implementation DXContactsManager

+ (instancetype)shareInstance {
    static id _instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] initShareInstance];
    });
    return _instance;
}

- (instancetype)initShareInstance {
    
    self = [super init];
    if (self) {
        _allCacheContacts = [NSMutableArray new];
        _handlerObjectsArr = [NSMutableArray new];
        _managerSafeQueue = dispatch_queue_create("RequestContactQueue", DISPATCH_QUEUE_SERIAL);
        dispatch_async(_managerSafeQueue, ^{
            self.managerSafeThread = [NSThread currentThread];
        });
    }
    return self;
}

#pragma mark - Public

- (void)requestPermissionWithCompletionHandler:(void (^)(BOOL isAccess, NSError *error))completionHandler {
    
    [self runOnManagerSerialQueue:^{
        if (![CNContactStore class]) {
            if (completionHandler) {
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey:@"Error",
                                           NSLocalizedFailureReasonErrorKey:@"This application cannot get Contacts in this IOS verion."};
                NSError *err = [NSError errorWithDomain:CNErrorDomain code:CNAuthorizationStatusDenied userInfo:userInfo];
                completionHandler(NO, err);
            }
        }
        
        CNEntityType entityType = CNEntityTypeContacts;
        CNContactStore * contactStore = [[CNContactStore alloc] init];
        [contactStore requestAccessForEntityType:entityType completionHandler:^(BOOL granted, NSError * _Nullable error) {
            if (completionHandler) {
                completionHandler(granted, error);
            }
        }];
    }];
}

- (void)getAllComtactsWithCompletionHandler:(void (^)(NSArray *contacts, NSError *error, BOOL isFinished))completionHandler isMultiCalback:(BOOL)isMultiCalback {
    
    NSAssert(completionHandler, @"completionHandler cannot be null");
    if (isMultiCalback) {
        NSMutableArray *contactsArr = [NSMutableArray new];
        [self getAllDataFromIndex:0 multiCallBackWithHandler:^(NSArray *contacts, NSError *error, BOOL isFinished) {
            if (contacts.count) {
                [contactsArr addObjectsFromArray:contacts];
            }
            if (isFinished) {
                completionHandler(contactsArr, error, YES);
            }
        }];
    } else {
        [self getAllDataFromIndex:0 multiCallBackWithHandler:completionHandler];
    }
}

- (void)getAllDataFromIndex:(NSUInteger)fromIndex multiCallBackWithHandler:(void (^)(NSArray *contacts, NSError *error, BOOL isFinished))completionHandler {
    
    weakify(self);
    [self loadMoreContactsFromIndex:fromIndex count:kMaxCount withCompletionHandler:^(NSArray *contacts, NSError *error, BOOL isFinished) {
        completionHandler(contacts, error, isFinished);
        if (!isFinished) {
            NSInteger nextStartIndex = fromIndex + contacts.count;
            [self_weak_ getAllDataFromIndex:nextStartIndex multiCallBackWithHandler:^(NSArray *contacts, NSError *error, BOOL isFinished) {
                completionHandler(contacts, error, isFinished);
            }];
        }
    }];
}

- (void)loadMoreContactsFromIndex:(NSUInteger)fromIndex count:(NSUInteger)count withCompletionHandler:(void (^)(NSArray *contacts, NSError *error, BOOL isFinished))completionHandler {
    
    NSAssert(completionHandler, @"completionHandler cannot be null");
    NSAssert(count, @"Maxcount cannot be 0");
    if (count > kMaxCount) {
        count = kMaxCount;
    }
    
    weakify(self);
    [self requestPermissionWithCompletionHandler:^(BOOL isAccess, NSError *error) {
        if (isAccess) {
            [self_weak_ runOnManagerSerialQueue:^{
                [self_weak_ getDataFromIndex:fromIndex count:count completionHandler:completionHandler];
            }];
        } else {
            completionHandler(nil, error, YES);
        }
    }];
}

// NOTE: All privates methods must be run on Manager Serial Queue
#pragma mark - Private

- (void)getDataFromIndex:(NSUInteger)fromIndex count:(NSUInteger)count completionHandler:(void (^)(NSArray *contacts, NSError *error, BOOL isFinished))completionHandler {
    
    if (self.isRequesting) {
        if (self.allCacheContacts.count >=  fromIndex + count) {
            NSArray *contactsArr = [self arrayContactFromIndex:fromIndex lastIndex:(fromIndex + count - 1)];
            completionHandler(contactsArr, nil, NO);
        } else {
            [self addHandlerObjectWithStartIndex:fromIndex count:count withHandler:completionHandler];
        }
        
    } else {
        if (self.requestDate != nil) {
            BOOL isFinish = NO;
            NSUInteger lastPosition = fromIndex + count;
            if (self.allCacheContacts.count <= lastPosition) {
                isFinish = YES;
                lastPosition = self.allCacheContacts.count;
            }
            NSArray *contactsArr = [self arrayContactFromIndex:fromIndex lastIndex:(lastPosition - 1)];
            completionHandler(contactsArr, nil, isFinish);
        } else {
            [self addHandlerObjectWithStartIndex:fromIndex count:count withHandler:completionHandler];
        }
        if (!self.requestDate || [[NSDate date] timeIntervalSinceDate:self.requestDate] > 120) {
            [self requestAllContacts];
        }
    }
}

- (void)runOnManagerSerialQueue:(void (^)(void))block {
    
    if ([NSThread currentThread] == self.managerSafeThread) {
        block();
    } else {
        dispatch_async(self.managerSafeQueue, ^{
            block();
        });
    }
}

- (id)addHandlerObjectWithStartIndex:(NSUInteger)fromIndex count:(NSUInteger)count withHandler:(void (^)(NSArray *contacts, NSError *error, BOOL isFinished))handler {
    
    if (!handler) {
        return nil;
    }
    
    HandlerObject *handlerObject = [[HandlerObject alloc] initWithStartIndex:fromIndex count:count handlerBlock:handler];
    [self.handlerObjectsArr addObject:handlerObject];
    return handlerObject;
}

- (void)checkAndRunHandlerObjects {
    
    NSInteger i =  self.handlerObjectsArr.count - 1;
    for (; i >= 0; i--) {
        HandlerObject *handlerObj = self.handlerObjectsArr[i];
        NSInteger lastIndex = handlerObj.startIndex + handlerObj.count - 1;
        if (self.allCacheContacts.count > lastIndex) {
            [self runHandlerObject:handlerObj];
            [self.handlerObjectsArr removeObjectAtIndex:i];
        }
    }
}

- (void)runAndReleaseAllHandlerObjects {
    
    NSInteger i =  self.handlerObjectsArr.count - 1;
    for (; i >= 0; i--) {
        HandlerObject *handlerObj = self.handlerObjectsArr[i];
        [self runHandlerObject:handlerObj];
        [self.handlerObjectsArr removeObjectAtIndex:i];
    }
}

- (void)runHandlerObject:(HandlerObject *)handlerObj {
    
    BOOL isFinished = NO;
    NSInteger lastPosition = handlerObj.startIndex + handlerObj.count;
    if (lastPosition >= self.allCacheContacts.count) {
        lastPosition = self.allCacheContacts.count;
        if (!self.isRequesting) {
            isFinished = YES;
        }
    }
    NSArray *contactsArr = [self arrayContactFromIndex:handlerObj.startIndex lastIndex:lastPosition - 1];
    if (contactsArr.count == 0) {
        isFinished = YES;
    }
    handlerObj.handlerBlock(contactsArr, nil, isFinished);
}

- (NSArray *)arrayContactFromIndex:(NSUInteger)fromIndex lastIndex:(NSUInteger)lastIndex {
    
    if (self.allCacheContacts.count == 0) {
        return nil;
    }
    NSMutableArray *contactsArr = [NSMutableArray new];
    for (NSInteger i = fromIndex; i <= lastIndex; i++ ) {
        DXContactModel *contactModel = self.allCacheContacts[i];
        [contactsArr addObject:contactModel];
    }
    return contactsArr;
}

- (void)requestAllContacts {
    
    self.isRequesting = YES;
    self.requestDate = [NSDate date];
    [self.allCacheContacts removeAllObjects];
    //keys with fetching properties
    NSArray *keys = @[CNContactFamilyNameKey,
                      CNContactGivenNameKey,
                      CNContactPhoneNumbersKey,
                      CNContactImageDataKey,
                      CNContactEmailAddressesKey,
                      CNContactPostalAddressesKey,
                      CNContactBirthdayKey];
    CNContactFetchRequest *request = [[CNContactFetchRequest alloc] initWithKeysToFetch:keys];
    request.sortOrder = CNContactSortOrderUserDefault;
    CNContactStore *contactStore = [[CNContactStore alloc] init];
    NSError *err;
    __block NSInteger count;
    weakify(self);
    [contactStore enumerateContactsWithFetchRequest:request error:&err usingBlock:^(CNContact * __nonnull contact, BOOL * __nonnull stop) {
        if (contact) {
            DXContactModel *contactModel = [[DXContactModel alloc] initWithCNContact:contact];
            if (contactModel) {
                count++;
                [self_weak_.allCacheContacts addObject:contactModel];
                if (count >= kMaxCount) {
                    [self_weak_ checkAndRunHandlerObjects];
                    count = 0;
                }
            }
        }
    }];
    self.isRequesting = NO;
    self.requestDate = [NSDate date];
    [self runAndReleaseAllHandlerObjects];
}

@end
