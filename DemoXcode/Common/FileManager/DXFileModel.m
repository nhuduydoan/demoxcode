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
@property (nonatomic, readwrite) int64_t size;

@end

@implementation DXFileModel

- (id)initWithFileName:(NSString *)fileName size:(unsigned long long)size {
    self = [super init];
    if (self) {
        _fileName = fileName;
        _size = size;
    }
    return self;
}

@end
