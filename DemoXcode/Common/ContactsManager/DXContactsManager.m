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
#import "NIinMemoryCache.h"

#define kMaxCount 50
#define DXContactsCacheKey @"DXContactsCacheKey"
#define kCacheTime 300

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

@property (strong, nonatomic) NIMemoryCache *memoryCache;
@property (nonatomic) BOOL isRequesting;
@property (strong, nonatomic) NSDate *requestDate;

@property (strong, nonatomic) NSMutableArray *handlerObjectsArr;
@property (strong, nonatomic) NSMutableArray *recentRequestContacts;


@end

@implementation DXContactsManager

+ (instancetype)shareInstance {
    static id _instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] initSharedInstance];
    });
    return _instance;
}

- (instancetype)initSharedInstance {
    
    self = [super init];
    if (self) {
        _managerSafeQueue = dispatch_queue_create("RequestContactQueue", DISPATCH_QUEUE_SERIAL);
        dispatch_async(_managerSafeQueue, ^{
            self.managerSafeThread = [NSThread currentThread];
        });
        _handlerObjectsArr = [NSMutableArray new];
        _memoryCache = [[NIMemoryCache alloc] initWithCapacity:1];
    }
    return self;
}

#pragma mark - Public

- (void)requestPermissionWithCompletionHandler:(void (^)(BOOL isAccess, NSError *error))completionHandler {
    
    weakify(self);
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
                [self_weak_ runOnManagerSerialQueue:^{
                    completionHandler(granted, error);
                }];
            }
        }];
    }];
}

- (void)getAllComtactsWithCompletionHandler:(void (^)(NSArray *contacts, NSError *error, BOOL isFinished))completionHandler isMultiCalback:(BOOL)isMultiCalback {
    
    NSAssert(completionHandler, @"completionHandler cannot be null");
    if (isMultiCalback) {
        [self getAllDataFromIndex:0 multiCallBackWithHandler:completionHandler];
    } else {
        NSMutableArray *contactsArr = [NSMutableArray new];
        [self getAllDataFromIndex:0 multiCallBackWithHandler:^(NSArray *contacts, NSError *error, BOOL isFinished) {
            if (contacts.count) {
                [contactsArr addObjectsFromArray:contacts];
            }
            if (isFinished) {
                completionHandler(contactsArr, error, YES);
            }
        }];
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
        NSInteger lastPosition = fromIndex + count;
        if ([self recentRequestContactCount] >= lastPosition) {
            NSMutableArray *contactsArr = [NSMutableArray new];
            for (NSInteger i = fromIndex; i < lastPosition; i++ ) {
                CNContact *contact = [self recentRequestContactAtIndex:i];
                DXContactModel *contactModel = [sApplication parseContactModelWithCNContact:contact];
                [contactsArr addObject:contactModel];
            }
            completionHandler(contactsArr, nil, NO);
        } else {
            [self addHandlerObjectWithStartIndex:fromIndex count:count withHandler:completionHandler];
        }
        
    } else {
        NSArray *cacheData = [self cacheContactsData];
        if (cacheData != nil) {
            BOOL isFinish = NO;
            NSUInteger lastPosition = fromIndex + count;
            if (cacheData.count <= lastPosition) {
                isFinish = YES;
                lastPosition = cacheData.count;
            }
            NSMutableArray *contactsArr = [NSMutableArray new];
            for (NSInteger i = fromIndex; i < lastPosition; i++ ) {
                CNContact *contact = [cacheData objectAtIndex:i];
                DXContactModel *contactModel = [sApplication parseContactModelWithCNContact:contact];
                if (contact) {
                    [contactsArr addObject:contactModel];
                }
            }
            completionHandler(contactsArr, nil, isFinish);
        } else {
            [self addHandlerObjectWithStartIndex:fromIndex count:count withHandler:completionHandler];
        }
        if (!self.requestDate || [[NSDate date] timeIntervalSinceDate:self.requestDate] > kCacheTime) {
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
        if ([self recentRequestContactCount] > lastIndex) {
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
    if (lastPosition >= [self recentRequestContactCount]) {
        lastPosition = [self recentRequestContactCount];
        if (!self.isRequesting) {
            isFinished = YES;
        }
    }
    NSMutableArray *contactsArr = [NSMutableArray new];
    for (NSInteger i = handlerObj.startIndex; i < lastPosition; i++ ) {
        CNContact *contact = [self recentRequestContactAtIndex:i];
        DXContactModel *contactModel = [sApplication parseContactModelWithCNContact:contact];
        [contactsArr addObject:contactModel];
    }
    if (contactsArr.count == 0) {
        isFinished = YES;
    }
    handlerObj.handlerBlock(contactsArr, nil, isFinished);
}

#pragma mark - Request

- (void)requestAllContacts {
    
    self.isRequesting = YES;
    self.requestDate = [NSDate date];
    self.recentRequestContacts = [NSMutableArray new];
    
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
        if (contact && [self_weak_ parsePhonesWithCNContact:contact].count > 0) {
            [self_weak_.recentRequestContacts addObject:contact];
            count++;
            if (count >= kMaxCount) {
                [self_weak_ checkAndRunHandlerObjects];
                count = 0;
            }
        }
    }];
    
    [self storeCacheContactsData:self.recentRequestContacts.copy];
    self.isRequesting = NO;
    self.requestDate = [NSDate date];
    [self runAndReleaseAllHandlerObjects];
    [self.recentRequestContacts removeAllObjects];
    self.recentRequestContacts = nil;
}

- (NSInteger)recentRequestContactCount {
    return self.recentRequestContacts.count;
}

- (id)recentRequestContactAtIndex:(NSUInteger)index {
    id obj = [self.recentRequestContacts objectAtIndex:index];
    return obj;
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

#pragma mark - Cache

- (void)storeCacheContactsData:(NSArray *)contactsData {
    [self.memoryCache storeObject:contactsData withName:DXContactsCacheKey];
}

- (NSArray *)cacheContactsData {
    NSArray *arr = [self.memoryCache objectWithName:DXContactsCacheKey];
    return arr;
}

@end
