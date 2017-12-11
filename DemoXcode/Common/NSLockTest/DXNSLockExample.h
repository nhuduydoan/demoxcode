//
//  DXNSLockExample.h
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/11/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import <Foundation/Foundation.h>
@class DXTestModel;

@interface DXNSLockExample : NSObject

+ (id)sharedInstance;

- (id)init NS_UNAVAILABLE;


- (DXTestModel *)startDoSomesthingsWithURL:(NSURL *)URL;

- (DXTestModel *)doSomeThingsAhihi:(NSURL *)URL;

- (NSInteger)testSycnchronized;

- (NSInteger)testNoSycnchronized;

@end
