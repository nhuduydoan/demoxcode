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

@property (strong, nonatomic) UIButton *getContactsButton;
@property (strong, nonatomic) UIButton *pickContactsButton;

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
    
    UILabel *txt = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 100)];
    txt.backgroundColor = [UIColor redColor];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.getContactsButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 150, 50)];
    self.getContactsButton.center = self.view.center;
    self.getContactsButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
    [self.getContactsButton addTarget:self action:@selector(touchUpInsideGetContactsButton:) forControlEvents:UIControlEventTouchUpInside];
    self.getContactsButton.layer.cornerRadius = 8;
    self.getContactsButton.backgroundColor = [UIColor colorWithRed:255/255.f green:177/255.f blue:111/255.f alpha:1];
    [self.getContactsButton setTitle:@"All Contacts" forState:UIControlStateNormal];
    
    CGRect buttonFr = self.getContactsButton.frame;
    self.pickContactsButton = [[UIButton alloc] initWithFrame:CGRectMake(buttonFr.origin.x, buttonFr.origin.y + 80, 150, 50)];
    self.pickContactsButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self.pickContactsButton addTarget:self action:@selector(touchUpInsidePickContactsButton:) forControlEvents:UIControlEventTouchUpInside];
    self.pickContactsButton.backgroundColor = [UIColor colorWithRed:255/255.f green:100/255.f blue:100/255.f alpha:1];
    
    self.pickContactsButton.layer.cornerRadius = 8;
    self.pickContactsButton.backgroundColor = [UIColor colorWithRed:255/255.f green:177/255.f blue:111/255.f alpha:1];
    [self.pickContactsButton setTitle:@"Invite Friends" forState:UIControlStateNormal];
    
    [self.view addSubview:self.getContactsButton];
    [self.view addSubview:self.pickContactsButton];
}

#pragma mark - Private

- (void)checkAndDisplayContactsViewController {
    
    weakify(self);
    [sContactMngr requestPermissionWithCompletionHandler:^(BOOL isAccess, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (isAccess) {
                DXContactViewController *controlelr = [DXContactViewController new];
                UINavigationController *navControlelr = [[UINavigationController alloc] initWithRootViewController:controlelr];
                [self_weak_ presentViewController:navControlelr animated:YES completion:nil];
            } else if (error) {
                [self_weak_ displayError:error];
            }
            [self_weak_.getContactsButton setEnabled:YES];
        });
    }];
}

- (void)checkAndDisplayContactsPickerViewController {
    
    weakify(self);
    [sContactMngr requestPermissionWithCompletionHandler:^(BOOL isAccess, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (isAccess) {
                DXInviteFriendsViewController *controlelr = [DXInviteFriendsViewController new];
                UINavigationController *navControlelr = [[UINavigationController alloc] initWithRootViewController:controlelr];
                [self_weak_ presentViewController:navControlelr animated:YES completion:nil];
            } else if (error) {
                [self_weak_ displayError:error];
            }
            [self_weak_.pickContactsButton setEnabled:YES];
        });
    }];
}

- (void)displayError:(NSError *)error {
    
    NSString *title = error.localizedDescription;
    NSString *message = error.localizedFailureReason;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:@"Setting" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
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
