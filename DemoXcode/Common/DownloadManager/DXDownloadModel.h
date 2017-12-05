//
//  DXDownloadModel.h
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/1/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DXDownloadModel : NSObject

@property (strong, nonatomic, readonly) NSString *fileName;

@property (strong, nonatomic, readonly) NSURL *URL;
@property (strong, nonatomic, readonly) NSMutableURLRequest *request;

@property (strong, nonatomic, readonly) NSURLSessionDownloadTask *downloadTask;

- (id)initWithDownloadURL:(NSURL *)downloadURL fileName:(NSString *)fileName;
- (void)updateFileName:(NSString *)fileName;

@end
