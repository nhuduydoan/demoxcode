//
//  DXHomeViewController.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 11/20/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXHomeViewController.h"
#import "DXContactViewController.h"
#import "DXContactsManager.h"

@interface DXHomeViewController ()

@property (weak, nonatomic) IBOutlet UIButton *getContactsButton;

@end

@implementation DXHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = @"Get Contact";
    [self setUpGetContactsButton];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setup View

- (void)setUpGetContactsButton {
    
    self.getContactsButton.layer.cornerRadius = 8;
    self.getContactsButton.backgroundColor = [UIColor colorWithRed:255/255.f green:177/255.f blue:111/255.f alpha:1];
}

#pragma mark - Private

- (void)checkAndDisplayContactsViewController {
    
    weakify(self);
    [sContactMngr requestAccessForContactAuthorizationStatusWithCompetition:^(BOOL isAccess, NSError *error) {
        if (isAccess) {
            DXContactViewController *controlelr = [DXContactViewController new];
            UINavigationController *navControlelr = [[UINavigationController alloc] initWithRootViewController:controlelr];
            [self_weak_ presentViewController:navControlelr animated:YES completion:nil];
        } else if (error) {
            NSString *message = error.domain;
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error" message:message preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action){
                // Ok action example
            }];
            UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:@"Setting" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
                // Other action
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                [alertController dismissViewControllerAnimated:YES completion:nil];
            }];
            [alertController addAction:okAction];
            [alertController addAction:settingsAction];
            [self_weak_ presentViewController:alertController animated:YES completion:nil];
        }
        [self_weak_.getContactsButton setEnabled:YES];
        
    }];
}

#pragma mark - Actions

- (IBAction)touchUpInsideGetContactsButton:(id)sender {
    
    [self.getContactsButton setEnabled:NO];
    [self checkAndDisplayContactsViewController];
}

@end
