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
@property (nonatomic) dispatch_queue_t callBackQueue;
@property (nonatomic, copy, nonnull) void (^handlerBlock)(NSArray *contacts, NSError *error, BOOL isFinished);

@end

@implementation HandlerObject

- (void)dealloc
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (id)initWithStartIndex:(NSUInteger)startIndex count:(NSUInteger)count callBackQueue:callBackQueue handlerBlock:(void (^)(NSArray *, NSError *, BOOL))handlerBlock {
    NSAssert(count, @"Maxcount cannot be 0");
    self = [super init];
    if (self) {
        _startIndex = startIndex;
        _count = count;
        _callBackQueue = callBackQueue;
        _handlerBlock = handlerBlock;
    }
    return self;
}

@end

@interface DXContactsManager ()

@property (strong, nonatomic) dispatch_queue_t managerSafeQueue;

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
        _handlerObjectsArr = [NSMutableArray new];
        _memoryCache = [[NIMemoryCache alloc] initWithCapacity:1];
    }
    return self;
}

#pragma mark - Public

- (void)requestPermissionWithCompletionHandler:(void (^)(BOOL isAccess, NSError *error))completionHandler callBackQueue:(dispatch_queue_t)callBackQueue {
    
    weakify(self);
    [self runOnManagerSerialQueue:^{
        if (![CNContactStore class]) {
            if (completionHandler) {
                [self_weak_ runOnQueueOrDefault:callBackQueue block:^{
                    NSDictionary *userInfo = @{NSLocalizedDescriptionKey:@"Error",
                                               NSLocalizedFailureReasonErrorKey:@"This application cannot get Contacts in this IOS verion."};
                    NSError *err = [NSError errorWithDomain:CNErrorDomain code:CNAuthorizationStatusDenied userInfo:userInfo];
                    completionHandler(NO, err);
                }];
            }
        }
        
        CNEntityType entityType = CNEntityTypeContacts;
        CNContactStore * contactStore = [[CNContactStore alloc] init];
        [contactStore requestAccessForEntityType:entityType completionHandler:^(BOOL granted, NSError * _Nullable error) {
            if (completionHandler) {
                [self_weak_ runOnQueueOrDefault:callBackQueue block:^{
                    completionHandler(granted, error);
                }];
            }
        }];
    }];
}

- (void)getAllComtactsWithCompletionHandler:(void (^)(NSArray *contacts, NSError *error, BOOL isFinished))completionHandler callBackQueue:(dispatch_queue_t)callBackQueue multiCallBack:(BOOL)multiCallBack {
    
    NSAssert(completionHandler, @"completionHandler cannot be null");
    if (multiCallBack) {
        [self getAllDataFromIndex:0 multiCallBackWithHandler:completionHandler callBackQueue:callBackQueue];
    } else {
        NSMutableArray *contactsArr = [NSMutableArray new];
        [self getAllDataFromIndex:0 multiCallBackWithHandler:^(NSArray *contacts, NSError *error, BOOL isFinished) {
            if (contacts.count) {
                [contactsArr addObjectsFromArray:contacts];
            }
            if (isFinished) {
                completionHandler(contactsArr, error, YES);
            }
        } callBackQueue:callBackQueue];
    }
}

- (void)getAllDataFromIndex:(NSUInteger)fromIndex multiCallBackWithHandler:(void (^)(NSArray *contacts, NSError *error, BOOL isFinished))completionHandler callBackQueue:(dispatch_queue_t)callBackQueue {
    
    weakify(self);
    [self loadMoreContactsFromIndex:fromIndex count:kMaxCount withCompletionHandler:^(NSArray *contacts, NSError *error, BOOL isFinished) {
        completionHandler(contacts, error, isFinished);
        if (!isFinished) {
            NSInteger nextStartIndex = fromIndex + contacts.count;
            [self_weak_ getAllDataFromIndex:nextStartIndex multiCallBackWithHandler:^(NSArray *contacts, NSError *error, BOOL isFinished) {
                completionHandler(contacts, error, isFinished);
            } callBackQueue:callBackQueue];
        }
    } callBackQueue:callBackQueue];
}

- (void)loadMoreContactsFromIndex:(NSUInteger)fromIndex count:(NSUInteger)count withCompletionHandler:(void (^)(NSArray *contacts, NSError *error, BOOL isFinished))completionHandler callBackQueue:(dispatch_queue_t)callBackQueue {
    
    NSAssert(completionHandler, @"completionHandler cannot be null");
    NSAssert(count, @"Maxcount cannot be 0");
    if (count > kMaxCount) {
        count = kMaxCount;
    }
    
    weakify(self);
    [self requestPermissionWithCompletionHandler:^(BOOL isAccess, NSError *error) {
        if (isAccess) {
            [self_weak_ getDataFromIndex:fromIndex count:count callBackQueue:callBackQueue completionHandler:completionHandler];
        } else {
            [self_weak_ runOnQueueOrDefault:callBackQueue block:^{
                completionHandler(nil, error, YES);
            }];
        }
    } callBackQueue:self.managerSafeQueue];
}

// NOTE: All privates methods must be run on Manager Serial Queue
#pragma mark - Private

- (void)checkQueue {
    NSLog(@"%@", dispatch_get_current_queue());
    if (dispatch_get_current_queue() != self.managerSafeQueue) {
        NSLog(@"===== Loi Queue, Xem lai ngay di ku=======");
    }
}

- (void)getDataFromIndex:(NSUInteger)fromIndex count:(NSUInteger)count callBackQueue:(dispatch_queue_t)callBackQueue completionHandler:(void (^)(NSArray *contacts, NSError *error, BOOL isFinished))completionHandler {
    
    [self checkQueue];
    if (self.isRequesting) {
        NSLog(@" ==== Requesting ===");
        NSInteger lastPosition = fromIndex + count;
        if ([self recentRequestContactCount] >= lastPosition) {
            NSMutableArray *contactsArr = [NSMutableArray new];
            for (NSInteger i = fromIndex; i < lastPosition; i++ ) {
                CNContact *contact = [self recentRequestContactAtIndex:i];
                DXContactModel *contactModel = [sApplication parseContactModelWithCNContact:contact];
                [contactsArr addObject:contactModel];
            }
            [self runOnQueueOrDefault:callBackQueue block:^{
                completionHandler(contactsArr, nil, NO);
            }];
        } else {
            [self addHandlerObjectWithStartIndex:fromIndex count:count handlerBlock:completionHandler callBackQueue:callBackQueue];
        }
        
    } else {
        NSArray *cacheData = [self cacheContactsData];
        if (cacheData != nil) {
            NSLog(@"==== Requestested====");
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
            [self runOnQueueOrDefault:callBackQueue block:^{
                completionHandler(contactsArr, nil, isFinish);
            }];
        } else {
            [self addHandlerObjectWithStartIndex:fromIndex count:count handlerBlock:completionHandler callBackQueue:callBackQueue];
        }
        if (!cacheData || !self.requestDate || [[NSDate date] timeIntervalSinceDate:self.requestDate] > kCacheTime) {
            NSLog(@"====Go to request====");
            [self requestAllContacts];
        }
    }
}

- (void)runOnManagerSerialQueue:(void (^)(void))block {
    dispatch_async(self.managerSafeQueue, ^{
        block();
    });
}

- (void)runOnQueueOrDefault:(dispatch_queue_t)queue block:(void (^)(void))block {
    
    if (!queue) {
        queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    }
    dispatch_async(queue, ^{
        block();
    });
}

- (id)addHandlerObjectWithStartIndex:(NSUInteger)fromIndex count:(NSUInteger)count handlerBlock:(void (^)(NSArray *contacts, NSError *error, BOOL isFinished))handlerBlock callBackQueue:(dispatch_queue_t)callBackQueue {
    
    if (!handlerBlock) {
        return nil;
    }
    
    HandlerObject *handlerObject = [[HandlerObject alloc] initWithStartIndex:fromIndex count:count callBackQueue:callBackQueue handlerBlock:handlerBlock];
    [self.handlerObjectsArr addObject:handlerObject];
    return handlerObject;
}

- (void)checkAndRunHandlerObjects {
    
    for (NSInteger i = 0; i < self.handlerObjectsArr.count; i++) {
        HandlerObject *handlerObj = self.handlerObjectsArr[i];
        NSInteger lastIndex = handlerObj.startIndex + handlerObj.count - 1;
        if ([self recentRequestContactCount] > lastIndex) {
            [self runHandlerObject:handlerObj];
            [self.handlerObjectsArr removeObjectAtIndex:i];
            i--;
        }
    }
}

- (void)runAndReleaseAllHandlerObjects {
    
    while (self.handlerObjectsArr.count > 0) {
        HandlerObject *handlerObj = self.handlerObjectsArr.firstObject;
        [self runHandlerObject:handlerObj];
        [self.handlerObjectsArr removeObjectAtIndex:0];
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
    [self runOnQueueOrDefault:handlerObj.callBackQueue block:^{
        handlerObj.handlerBlock(contactsArr, nil, isFinished);
    }];
}

#pragma mark - Request

- (void)requestAllContacts {
    
    NSLog(@"===Start request====");
    self.isRequesting = YES;
    self.requestDate = [NSDate date];
    self.recentRequestContacts = [NSMutableArray new];
    
    weakify(self);
    [self requestContactsWithCompletionHandler:^{
        [self_weak_ storeCacheContactsData:self_weak_.recentRequestContacts.copy];
        self_weak_.isRequesting = NO;
        self_weak_.requestDate = [NSDate date];
        [self_weak_ runAndReleaseAllHandlerObjects];
        [self_weak_.recentRequestContacts removeAllObjects];
        self_weak_.recentRequestContacts = nil;
        NSLog(@"===Request finished====");
    }];
}

- (void)requestContactsWithCompletionHandler:(void (^)(void))competitionHandler {
    
    weakify(self);
    [self runOnQueueOrDefault:nil block:^{
        
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
        
        [contactStore enumerateContactsWithFetchRequest:request error:&err usingBlock:^(CNContact * __nonnull contact, BOOL * __nonnull stop) {
            if (contact && [self_weak_ parsePhonesWithCNContact:contact].count > 0) {
                [self_weak_.recentRequestContacts addObject:contact];
                count++;
                if (count >= kMaxCount) {
                    count = 0;
                    [self_weak_ runOnManagerSerialQueue:^{
                        [self_weak_ checkAndRunHandlerObjects];
                    }];
                }
            }
        }];
        
        if (competitionHandler) {
            [self_weak_ runOnManagerSerialQueue:^{
                competitionHandler();
            }];
        }
    }];
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
