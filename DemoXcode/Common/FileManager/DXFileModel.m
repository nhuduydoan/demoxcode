//
//  DXFileModel.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/4/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXFileModel.h"

@interface DXFileModel ()

@property (strong, nonatomic, readwrite) NSString *fileName;
@property (strong, nonatomic, readwrite) NSString *targetPath;

@end

@implementation DXFileModel

- (id)initWithFileName:(NSString *)fileName targetPath:(NSString *)targetPath {
    self = [super init];
    if (self) {
        _fileName = fileName;
        _targetPath = targetPath;
    }
    return self;
}

@end
