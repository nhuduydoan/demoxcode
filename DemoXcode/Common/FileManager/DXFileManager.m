//
//  DXFileManager.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/4/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXFileManager.h"
#import "DXDownloadModel.h"
#import "DXFileModel.h"

#define Files @"Files"

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

- (NSString *)rootFolderTargetPath {
    return self.dataPath.copy;
}

- (NSString *)generateNewPathForTargetPath:(NSString *)targetPath fileName:(NSString *)fileName {
    
    //Get file name and extension
    NSString *originalName = [fileName stringByDeletingPathExtension];
    NSString *pathExtension = [fileName pathExtension];
    NSString *dir = [self.dataPath stringByAppendingPathComponent:targetPath];
    NSError *error;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir])
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:&error];
    
    if (error) {
        return nil;
    }
    
    //Try to save with origin file name
    NSString *path = [dir stringByAppendingPathComponent:fileName];
    //Check if file has exist
    NSInteger additionFileName = 1;
    while ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        //Append "(_additionFileName_)" to the file name
        NSString *newFileName = [originalName stringByAppendingString:[NSString stringWithFormat:@"(%ld)", (long)additionFileName]];
        path = [dir stringByAppendingPathComponent:[newFileName stringByAppendingPathExtension:pathExtension]];
        additionFileName += 1;
    }
    
    return path;
}

#pragma mark - Delegate

- (void)addDelegate:(id<DXFileManagerDelegate>)delegate {
    [self.delegates addObject:delegate];
}

- (void)removeDelegate:(id<DXFileManagerDelegate>)delegate {
    [self.delegates removeObject:delegate];
}

@end
