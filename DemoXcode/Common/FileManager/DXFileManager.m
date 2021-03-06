//
//  DXFileManager.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/4/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXFileManager.h"
#import "DXFileModel.h"

#define Files @"Files"

NSString* const DXDownloadManagerDidDownLoadFinished = @"DXDownloadManagerDidDownLoadFinished";

@interface DXFileManager ()

@property (strong, nonatomic) NSMutableSet *delegates;
@property (strong, nonatomic) NSString *dataPath;
@end

@implementation DXFileManager

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
        _delegates =  (__bridge_transfer NSMutableSet *)CFSetCreateMutable(nil, 0, nil);
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
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:Files];
    self.dataPath = dataPath;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:dataPath]) {
        NSError *error = nil;
        if(![fileManager createDirectoryAtPath:dataPath withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"Failed to create directory \"%@\". Error: %@", dataPath, error);
        }
    }
}

#pragma mark - Public

- (NSString *)rootFolderPath {
    return self.dataPath.copy;
}

- (void)allFileItemModels:(void (^)(NSArray<DXFileModel *> *fileItems))completionHandler {
    __weak typeof(self) selfWeak = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSArray *allPathComponents = [[NSFileManager defaultManager]
                                      contentsOfDirectoryAtURL:[NSURL fileURLWithPath:self.dataPath]
                                      includingPropertiesForKeys:@[NSURLNameKey,NSURLIsDirectoryKey]
                                      options:NSDirectoryEnumerationSkipsHiddenFiles error:nil];
        NSMutableArray *fileItemsArr = [NSMutableArray new];
        for (NSURL *item in allPathComponents) {
            NSString *fileName = nil;
            [item getResourceValue:&fileName forKey:NSURLNameKey error:nil];
            NSError *attributesError;
            NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[self.dataPath stringByAppendingPathComponent:fileName] error:&attributesError];
            NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
            unsigned long long size = [fileSizeNumber longLongValue];
            DXFileModel *fileItem = [[DXFileModel alloc] initWithFileName:fileName size:size];
            [fileItemsArr addObject:fileItem];
            
        }
        if (completionHandler) {
            [selfWeak runOnMainThread:^{
                completionHandler(fileItemsArr);
            }];
        }
    });
}

- (NSData *)contentOfFileItem:(DXFileModel *)model {
    
    NSString *filePath = [self.dataPath stringByAppendingPathComponent:model.fileName];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    return data;
}

- (NSString *)generateNewPathForFilePath:(NSString *)filePath {
    NSString *folderPath = [filePath stringByDeletingLastPathComponent];
    NSString *fileName = [filePath lastPathComponent];
    if (![[NSFileManager defaultManager] fileExistsAtPath:folderPath]) {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            return nil;
        }
    }
    
    //Get file name and extension
    NSString *fullName = fileName.copy;
    NSString *originalName = [fullName stringByDeletingPathExtension];
    NSString *pathExtension = [fullName pathExtension];
    NSString *path = [folderPath stringByAppendingPathComponent:fileName];
    NSInteger additionNum = 1;
    
    while ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        fullName = [[NSString stringWithFormat:@"%@(%zd)", originalName, additionNum] stringByAppendingPathExtension:pathExtension];
        path = [folderPath stringByAppendingPathComponent:fullName];
        additionNum ++;
    }
    return path;
}

#pragma mark - Private

- (void)runOnMainThread:(void (^)(void))block {
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            block();
        });
    }
}

#pragma mark - Delegate

- (void)addDelegate:(id<DXFileManagerDelegate>)delegate {
    [self.delegates addObject:delegate];
}

- (void)removeDelegate:(id<DXFileManagerDelegate>)delegate {
    [self.delegates removeObject:delegate];
}

@end
