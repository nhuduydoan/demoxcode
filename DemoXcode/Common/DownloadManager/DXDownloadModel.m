//
//  DXDownloadModel.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/1/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXDownloadModel.h"

@interface DXDownloadModel ()

@property (strong, nonatomic, readwrite) NSString *fileName;

@property (strong, nonatomic, readwrite) NSURL *URL;
@property (strong, nonatomic, readwrite) NSMutableURLRequest *request;

@end

@implementation DXDownloadModel

- (id)initWithDownloadURL:(NSURL *)downloadURL fileName:(NSString *)fileName {
    self = [super init];
    if (self) {
        _URL = downloadURL;
        _fileName = fileName;
    }
    return self;
}

- (void)updateFileName:(NSString *)fileName {
    _fileName = fileName;
}

@end
