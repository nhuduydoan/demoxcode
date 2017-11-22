//
//  DXDemoGCD.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 11/22/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXDemoGCD.h"

@implementation DXDemoGCD

- (void)test_dispatch_group_async {
    
    dispatch_queue_t concurrentQueue = dispatch_queue_create("concurrentqueue", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_group_t gropQueue;
    
    dispatch_group_async(gropQueue, concurrentQueue, ^{
        
    });
    
    dispatch_group_wait(gropQueue, 0);
}


@end
