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
#import "DXInviteFriendsViewController.h"

@interface DXHomeViewController ()

@property (weak, nonatomic) IBOutlet UIButton *getContactsButton;
@property (weak, nonatomic) IBOutlet UIButton *pickContactsButton;

@end

@implementation DXHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = @"Get Contact";
    [self setUpView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setup View

- (void)setUpView {
    
    self.getContactsButton.layer.cornerRadius = 8;
    self.getContactsButton.backgroundColor = [UIColor colorWithRed:255/255.f green:177/255.f blue:111/255.f alpha:1];
    self.pickContactsButton.layer.cornerRadius = 8;
    self.pickContactsButton.backgroundColor = [UIColor colorWithRed:255/255.f green:177/255.f blue:111/255.f alpha:1];
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
            [self_weak_ displayError:error];
        }
        [self_weak_.getContactsButton setEnabled:YES];
        
    }];
}

- (void)checkAndDisplayContactsPickerViewController {
    
    weakify(self);
    [sContactMngr requestAccessForContactAuthorizationStatusWithCompetition:^(BOOL isAccess, NSError *error) {
        if (isAccess) {
            DXInviteFriendsViewController *controlelr = [DXInviteFriendsViewController new];
            UINavigationController *navControlelr = [[UINavigationController alloc] initWithRootViewController:controlelr];
            [self_weak_ presentViewController:navControlelr animated:YES completion:nil];
        } else if (error) {
            [self_weak_ displayError:error];
        }
        [self_weak_.pickContactsButton setEnabled:YES];
        
    }];
}

- (void)displayError:(NSError *)error {
    
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
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Actions

- (IBAction)touchUpInsideGetContactsButton:(id)sender {
    
    [self.getContactsButton setEnabled:NO];
    [self checkAndDisplayContactsViewController];
}

- (IBAction)touchUpInsidePickContactsButton:(id)sender {
    
    [self.pickContactsButton setEnabled:NO];
    [self checkAndDisplayContactsPickerViewController];
}

@end
