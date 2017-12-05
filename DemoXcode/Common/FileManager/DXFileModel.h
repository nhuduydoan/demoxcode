//
//  DXFileModel.h
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/4/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DXFileModel : NSObject

@property (strong, nonatomic, readonly) NSString *fileName;
@property (nonatomic, readonly) unsigned long long size;

- (id)initWithFileName:(NSString *)fileName size:(unsigned long long)size;

@end
