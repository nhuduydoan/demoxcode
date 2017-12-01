//
//  DXDownloadManager.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/1/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXDownloadManager.h"
#import "DXDownloadModel.h"

#define Downloads @"Downloads"

@interface DXDownloadManager ()

@property (strong, nonatomic) NSString *dataPath;

@end

@implementation DXDownloadManager

+ (id)sharedInstance {
    
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self.class alloc] initSharedInstance];
    });
    return instance;
}

- (instancetype)initSharedInstance {
    
    self = [super init];
    if (self) {
        [self setupDataFolder];
    }
    return self;
}

- (instancetype) init {
    [super doesNotRecognizeSelector:_cmd];
    self = nil;
    return nil;
}

- (void)setupDataFolder {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:Downloads];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:dataPath]) {
        NSError *error = nil;
        if(![fileManager createDirectoryAtPath:dataPath withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"Failed to create directory \"%@\". Error: %@", dataPath, error);
            return;
        }
    }
    _dataPath = dataPath;
}

#pragma mark - Public

@end
