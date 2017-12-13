//
//  DXSelectFriendsViewController.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/13/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXSelectFriendsViewController.h"

@interface DXSelectFriendsViewController ()

@end

@implementation DXSelectFriendsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupViews];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupViews {
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(touchUpInsideCloseBarButtonItem)];
    self.navigationItem.leftBarButtonItem = closeButton;
    self.tableView.tableFooterView = [UIView new];
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)touchUpInsideCloseBarButtonItem {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
