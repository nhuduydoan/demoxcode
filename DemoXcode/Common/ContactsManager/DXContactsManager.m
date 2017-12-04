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

#define DXContactsCacheKey @"DXContactsCacheKey"
#define kCacheTime 300

@interface HandlerObject : NSObject

@property (nonatomic) dispatch_queue_t callBackQueue;
@property (nonatomic, copy, nonnull) void (^handlerBlock)(NSArray *contacts, NSError *error);

@end

@implementation HandlerObject

- (void)dealloc
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (id)initWithHandlerBlock:(void (^)(NSArray *, NSError *))handlerBlock callBackQueue:callBackQueue {
    self = [super init];
    if (self) {
        _callBackQueue = callBackQueue;
        _handlerBlock = handlerBlock;
    }
    return self;
}

@end

@interface DXContactsManager ()

@property (strong, nonatomic) dispatch_queue_t managerSafeQueue;
@property (strong, nonatomic) NSMutableArray *handlerObjectsArr;
@property (strong, nonatomic) NSMutableArray *savedContactsArr;
@property (strong, nonatomic) NSDate *requestDate;
@property (nonatomic) BOOL isRequesting;

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
    }
    return self;
}

- (instancetype) init {
    [super doesNotRecognizeSelector:_cmd];
    self = nil;
    return nil;
}

#pragma mark - Public

- (void)requestPermissionWithCompletionHandler:(void (^)(BOOL isAccess, NSError *error))completionHandler callBackQueue:(dispatch_queue_t)callBackQueue {
    weakify(self);
    if (![CNContactStore class]) {
        if (completionHandler) {
            [selfWeak runOnMainQueueOrQueue:callBackQueue block:^{
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey:@"Error",
                                           NSLocalizedFailureReasonErrorKey:@"This application cannot get Contacts in this IOS verion."};
                NSError *err = [NSError errorWithDomain:CNErrorDomain code:CNAuthorizationStatusDenied userInfo:userInfo];
                completionHandler(NO, err);
            }];
        }
    }
    
    CNContactStore * contactStore = [[CNContactStore alloc] init];\
    CNEntityType entityType = CNEntityTypeContacts;
    [contactStore requestAccessForEntityType:entityType completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (completionHandler) {
            [selfWeak runOnMainQueueOrQueue:callBackQueue block:^{
                completionHandler(granted, error);
            }];
        }
    }];
}

- (void)getAllContactsWithCompletionHandler:(void (^)(NSArray<DXContactModel *> *contacts, NSError *error))completionHandler callBackQueue:(dispatch_queue_t)callBackQueue {
    NSAssert(completionHandler, @"completionHandler cannot be null");
    weakify(self);
    [self requestPermissionWithCompletionHandler:^(BOOL isAccess, NSError *error) {
        if (isAccess) {
            [selfWeak allDataWithCompletionHandler:completionHandler callBackQueue:callBackQueue];
        } else {
            [selfWeak runOnMainQueueOrQueue:callBackQueue block:^{
                completionHandler(nil, error);
            }];
        }
    } callBackQueue:self.managerSafeQueue];
}

#pragma mark - Private
// NOTE: All privates methods must be run on Manager Serial Queue

- (void)allDataWithCompletionHandler:(void (^)(NSArray<DXContactModel *> *contacts, NSError *error))completionHandler callBackQueue:(dispatch_queue_t)callBackQueue {
    if (self.isRequesting) {
        // Add handler block and callback queue to objects array and will run them when reuqest contacts finish
        [self addHandlerObjectWithStartIndex:0 count:0 handlerBlock:completionHandler callBackQueue:callBackQueue];
        
    } else {
        if ([self savedRequestContactCount] > 0) {
            // If saved requested contacts is exist, get them to call handler block
            NSArray *contactsArr = [self allSavedContactsData];
            [self runOnMainQueueOrQueue:callBackQueue block:^{
                completionHandler(contactsArr, nil);
            }];
        } else {
            // Add handler block and callback queue to objects array and will run them when reuqest contacts finis
            [self addHandlerObjectWithStartIndex:0 count:0 handlerBlock:completionHandler callBackQueue:callBackQueue];
        }
        
        if (self.requestDate == nil || [[NSDate date] timeIntervalSinceDate:self.requestDate] > kCacheTime) {
            // If Have not requested data or requested data were expired, request contact from phone
            [self requestAllContacts];
        }
    }
}

- (NSInteger)savedRequestContactCount {
    return self.savedContactsArr.count;
}

- (NSArray<DXContactModel *> *)allSavedContactsData {
    NSMutableArray *contactsArr = [NSMutableArray new];
    for (NSInteger i = 0; i < self.savedContactsArr.count; i++ ) {
        CNContact *contact = [self.savedContactsArr objectAtIndex:i];
        DXContactModel *contactModel = [sApplication parseContactModelFromCNContact:contact];
        [contactsArr addObject:contactModel];
    }
    return contactsArr;
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

#pragma mark - Handler Actions

- (void)runOnManagerSerialQueue:(void (^)(void))block {
    dispatch_async(self.managerSafeQueue, ^{
        block();
    });
}

- (void)runOnMainQueueOrQueue:(dispatch_queue_t)queue block:(void (^)(void))block {
    if (!queue) {
        queue = dispatch_get_main_queue();
    }
    dispatch_async(queue, ^{
        block();
    });
}

- (void)addHandlerObjectWithStartIndex:(NSUInteger)fromIndex count:(NSUInteger)count handlerBlock:(void (^)(NSArray *contacts, NSError *error))handlerBlock callBackQueue:(dispatch_queue_t)callBackQueue {
    if (!handlerBlock) {
        return;
    }
    HandlerObject *handlerObject = [[HandlerObject alloc] initWithHandlerBlock:handlerBlock callBackQueue:callBackQueue];
    [self.handlerObjectsArr addObject:handlerObject];
}

- (void)runAndReleaseAllHandlerObjects {
    while (self.handlerObjectsArr.count > 0) {
        HandlerObject *handlerObj = self.handlerObjectsArr.firstObject;
        [self runHandlerObject:handlerObj];
        [self.handlerObjectsArr removeObjectAtIndex:0];
    }
}

- (void)runHandlerObject:(HandlerObject *)handlerObj {
    NSArray *contactsArr = [self allSavedContactsData];
    [self runOnMainQueueOrQueue:handlerObj.callBackQueue block:^{
        handlerObj.handlerBlock(contactsArr, nil);
    }];
}

#pragma mark - Request Data

- (void)requestAllContacts {
    self.isRequesting = YES;
    self.requestDate = [NSDate date];
    self.savedContactsArr = [NSMutableArray new];
    
    weakify(self);
    [self requestContactsWithCompletionHandler:^{
        selfWeak.isRequesting = NO;
        selfWeak.requestDate = [NSDate date];
        [selfWeak runAndReleaseAllHandlerObjects];
    }];
}

- (void)requestContactsWithCompletionHandler:(void (^)(void))competitionHandler {
    // This request will be run on global concurrent queue
    // Competition handler block will be executed on Manager Safe Queue
    weakify(self);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
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
        
        [contactStore enumerateContactsWithFetchRequest:request error:&err usingBlock:^(CNContact * __nonnull contact, BOOL * __nonnull stop) {
            if (contact && [selfWeak parsePhonesWithCNContact:contact].count > 0) {
                [selfWeak.savedContactsArr addObject:contact];
            }
        }];
        
        if (competitionHandler) {
            [selfWeak runOnManagerSerialQueue:^{
                competitionHandler();
            }];
        }
    });
}

@end
