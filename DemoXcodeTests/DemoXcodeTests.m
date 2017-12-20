//
//  DemoXcodeTests.m
//  DemoXcodeTests
//
//  Created by Nhữ Duy Đoàn on 12/12/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "DXDownloadManager.h"
#import "DXFileManager.h"
#import "DXDownloadComponent.h"

@interface DemoXcodeTests : XCTestCase

@property(strong, nonatomic) NSString *imageLink;

@end

@implementation DemoXcodeTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _imageLink = @"https://www.codeproject.com/KB/GDI-plus/ImageProcessing2/flip.jpg";
    sDownloadManager;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testDownloadOneLink {
    
    NSURL *imageURL = [NSURL URLWithString:_imageLink];
    NSURL *fileURL = [NSURL fileURLWithPath:[[sFileManager rootFolderPath] stringByAppendingPathComponent:@"Cun con.PNG"]];
    
    DXDownloadComponent *component = [sDownloadManager downloadURL:imageURL toFilePath:fileURL completionHandler:nil error:nil];
    XCTAssertNotNil(component, @"Component # nil");
}

- (void)testMultiDownloadOneURLWithOneThread {
    NSURL *imageURL = [NSURL URLWithString:_imageLink];
    NSURL *fileURL = [NSURL fileURLWithPath:[[sFileManager rootFolderPath] stringByAppendingPathComponent:@"Cun con.PNG"]];
    
    DXDownloadComponent *component = [sDownloadManager downloadURL:imageURL toFilePath:fileURL completionHandler:nil error:nil];
    XCTAssertNotNil(component, @"Component need to be # nil");
    
    for (int i = 0; i < 10; i ++) {
        DXDownloadComponent *component = [sDownloadManager downloadURL:imageURL toFilePath:fileURL completionHandler:nil error:nil];
        XCTAssertNil(component, @"Component need to be nil");
    }
}

- (void)testMultiDownloadOneURLWithMultiThread {
    XCTestExpectation *expect = [self expectationWithDescription:@"expect"];
    NSURL *imageURL = [NSURL URLWithString:_imageLink];
    NSURL *fileURL = [NSURL fileURLWithPath:[[sFileManager rootFolderPath] stringByAppendingPathComponent:@"Cun con.PNG"]];
    dispatch_queue_t concurrentQueue = dispatch_queue_create("concurrentqueue", DISPATCH_QUEUE_CONCURRENT);
    NSMutableArray *arr = [NSMutableArray new];
    
    dispatch_group_t group = dispatch_group_create();
    NSLog(@"Before Sleep 1");
    for (int i = 0; i < 100; i ++) {
        dispatch_group_enter(group);
        dispatch_async(concurrentQueue, ^{
            DXDownloadComponent *component = [sDownloadManager downloadURL:imageURL toFilePath:fileURL completionHandler:nil error:nil];
            if (component) {
                [arr addObject:component];
            }
            dispatch_group_leave(group);
        });
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        XCTAssertEqual(arr.count, 1, @"Components needs is once");
        [expect fulfill];
    });
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testMultiDownloadOneURLWithMultiThreadWithGroup {
    NSURL *imageURL = [NSURL URLWithString:_imageLink];
    NSURL *fileURL = [NSURL fileURLWithPath:[[sFileManager rootFolderPath] stringByAppendingPathComponent:@"Cun con.PNG"]];
    dispatch_queue_t concurrentQueue = dispatch_queue_create("concurrentqueue", DISPATCH_QUEUE_CONCURRENT);
    NSMutableArray *arr = [NSMutableArray new];
    dispatch_group_t group = dispatch_group_create();
    NSLog(@"Before Sleep 1");
    for (int i = 0; i < 100; i ++) {
        dispatch_async(concurrentQueue, ^{
            dispatch_group_enter(group);
            DXDownloadComponent *component = [sDownloadManager downloadURL:imageURL toFilePath:fileURL completionHandler:nil error:nil];
            if (component) {
                [arr addObject:component];
            }
            dispatch_group_leave(group);
        });
    }
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    NSLog(@"Xong viec roi ne");
    XCTAssertEqual(arr.count, 1, @"Components needs is once");
}

- (void)testMultiDownloadOneURLWithMultiThreadWithDispatchWait {
    NSURL *imageURL = [NSURL URLWithString:_imageLink];
    NSURL *fileURL = [NSURL fileURLWithPath:[[sFileManager rootFolderPath] stringByAppendingPathComponent:@"Cun con.PNG"]];
    NSMutableArray *arr = [NSMutableArray new];
    dispatch_block_t block = dispatch_block_create(DISPATCH_BLOCK_BARRIER, ^{
        for (int i = 0; i < 100; i ++) {
            DXDownloadComponent *component = [sDownloadManager downloadURL:imageURL toFilePath:fileURL completionHandler:nil error:nil];
            if (component) {
                [arr addObject:component];
            }
        }
        NSLog(@"Loi gi a=======");
        
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
    dispatch_block_wait(block, DISPATCH_TIME_FOREVER);
    NSLog(@"Xong viec roi ne");
    XCTAssertEqual(arr.count, 1, @"Components needs is once");
}

- (void)testMultiDownloadOneURLWithMultiThreadWithBarrier {
    XCTestExpectation *expect = [self expectationWithDescription:@"expect"];
    NSURL *imageURL = [NSURL URLWithString:_imageLink];
    NSURL *fileURL = [NSURL fileURLWithPath:[[sFileManager rootFolderPath] stringByAppendingPathComponent:@"Cun con.PNG"]];
    dispatch_queue_t concurrentQueue = dispatch_queue_create("concurrentqueue", DISPATCH_QUEUE_CONCURRENT);
    NSMutableArray *arr = [NSMutableArray new];
    
    for (int i = 0; i < 100; i ++) {
        dispatch_async(concurrentQueue, ^{
            DXDownloadComponent *component = [sDownloadManager downloadURL:imageURL toFilePath:fileURL completionHandler:nil error:nil];
            if (component) {
                [arr addObject:component];
            }
        });
    }
    
    dispatch_barrier_async(concurrentQueue, ^{
        NSLog(@"===");
        XCTAssertEqual(arr.count, 1, @"Components needs is once");
        [expect fulfill];
    });
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

@end
