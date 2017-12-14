//
//  ShareRootViewController.m
//  ShareExtension
//
//  Created by Nhữ Duy Đoàn on 12/14/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "ShareRootViewController.h"
#import "DXShareViewController.h"
#import "DXShareViewController.h"
#import "DXShareNavigationController.h"
#import "ZLShareExtensionManager.h"

@interface ShareRootViewController ()

@end

@implementation ShareRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [ZLShareExtensionManager shareInstance].extensionContext = self.extensionContext;
}


- (BOOL)isContentValid {
    // Do validation of contentText and/or NSExtensionContext attachments here
    return YES;
}

- (void)didSelectPost {
    // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    
    // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
    [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
}

- (NSArray *)configurationItems {
    // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
    return @[];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    DXShareViewController *controller = [DXShareViewController new];
    __weak typeof(self) selfWeak = self;
    controller.completeBlock = ^{
        [selfWeak didSelectPost];
    };
    DXShareNavigationController *navController = [[DXShareNavigationController alloc] initWithRootViewController:controller];
    [self presentViewController:navController animated:YES completion:nil];
}

@end
