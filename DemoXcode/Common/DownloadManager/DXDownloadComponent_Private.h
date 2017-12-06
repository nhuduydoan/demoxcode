//
//  DXDownloadComponent_Private.h
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/6/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXDownloadComponent.h"

@interface DXDownloadComponent (Private)

- (void)setDownloadTask:(NSURLSessionDownloadTask *)downloadTask;
- (void)pause;
- (void)resume;
- (void)cancel;

@end
