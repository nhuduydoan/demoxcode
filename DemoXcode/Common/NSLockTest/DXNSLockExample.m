//
//  DXNSLockExample.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/11/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXNSLockExample.h"
#import "DXTestModel.h"
#import "DXImageManager.h"

@interface DXNSLockExample ()

@property (strong, nonatomic) NSMutableSet *componentsArr;
@property (strong, nonatomic) dispatch_queue_t concurrentQueue;
@property (strong, nonatomic) NSLock *arrLock;

@end

@implementation DXNSLockExample

+ (id)sharedInstance {
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] initSharedInstance];
    });
    return instance;
}

- (id)init {
    [super doesNotRecognizeSelector:_cmd];
    self = nil;
    return nil;
}

- (id)initSharedInstance {
    self = [super init];
    if (self) {
        _componentsArr = [NSMutableSet new];
        _arrLock = [[NSLock alloc] init];
        _arrLock.name = @"LockChoVuiThoi";
        _concurrentQueue = dispatch_queue_create("LockQueueNeEm", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (BOOL)checkExistingURL:(NSURL *)URL {
    for (id obj in self.componentsArr) {
        if ([obj isEqual:URL]) {
            return YES;
        }
    }
    return NO;
}

- (DXTestModel *)startDoSomesthingsWithURL:(NSURL *)URL {
    [self.arrLock lock];
    BOOL exist = [self checkExistingURL:URL];
    DXTestModel *model;
    if (!exist) {
        model = [DXTestModel new];
        UIImage *img = [sImageManager titleImageFromString:@"ABC"];
        model.URL = URL.copy;
        model.avatar = img;
        [self.componentsArr addObject:URL];
    }
    [self.arrLock unlock];
    return model;
}

- (DXTestModel *)doSomeThingsAhihi:(NSURL *)URL {
    [self.arrLock lock];
    BOOL exist = [self checkExistingURL:URL];
    if (exist) {
        return nil;
    }
    DXTestModel *model = [DXTestModel new];
    UIImage *img = [sImageManager titleImageFromString:@"ABC"];
    model.avatar = img;
    model.URL = URL.copy;
    [self.componentsArr addObject:URL];
    [self.arrLock unlock];
    return model;
}

- (NSInteger)testSycnchronized {
//    @synchronized(self) {
//    [self.arrLock lock];
    dispatch_sync(self.concurrentQueue, ^{
        for (id obj in self.componentsArr) {
            if ([obj isKindOfClass:[NSURL class]]) {
                
            }
        }
        sleep(1);
//    [self.arrLock unlock];
    });
    return 0;
//    }
}

- (NSInteger)testNoSycnchronized {
//    @synchronized(self) {
//    [self.arrLock lock];
    dispatch_sync(self.concurrentQueue, ^{
//        sleep(1);
        for (id obj in self.componentsArr) {
            if ([obj isKindOfClass:[NSURL class]]) {
                
            }
        }
//    [self.arrLock unlock];
    });
    return 0;
//    }
}

@end
