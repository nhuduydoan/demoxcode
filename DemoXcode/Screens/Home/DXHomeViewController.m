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
@property (strong, nonatomic) UIButton *downloadButton;

@end

@implementation DXHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = @"Contacts";
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
    
    UIButton *getContactsButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 150, 50)];
    getContactsButton.center = self.view.center;
    getContactsButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
    [getContactsButton addTarget:self action:@selector(touchUpInsideGetContactsButton:) forControlEvents:UIControlEventTouchUpInside];
    getContactsButton.layer.cornerRadius = 8;
    getContactsButton.backgroundColor = [UIColor colorWithRed:255/255.f green:177/255.f blue:111/255.f alpha:1];
    [getContactsButton setTitle:@"All Contacts" forState:UIControlStateNormal];
    self.getContactsButton = getContactsButton;
    
    CGRect buttonFr = self.getContactsButton.frame;
    UIButton *pickButton = [[UIButton alloc] initWithFrame:CGRectMake(buttonFr.origin.x, buttonFr.origin.y + 80, 150, 50)];
    pickButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    [pickButton addTarget:self action:@selector(touchUpInsidePickContactsButton:) forControlEvents:UIControlEventTouchUpInside];
    pickButton.backgroundColor = [UIColor colorWithRed:255/255.f green:100/255.f blue:100/255.f alpha:1];
    pickButton.layer.cornerRadius = 8;
    pickButton.backgroundColor = [UIColor colorWithRed:255/255.f green:177/255.f blue:111/255.f alpha:1];
    [pickButton setTitle:@"Invite Friends" forState:UIControlStateNormal];
    self.pickContactsButton = pickButton;
    
    buttonFr = self.pickContactsButton.frame;
    UIButton *downloadButton = [[UIButton alloc] initWithFrame:CGRectMake(buttonFr.origin.x, buttonFr.origin.y + 80, 150, 50)];
    downloadButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    [downloadButton addTarget:self action:@selector(touchUpInsidePickContactsButton:) forControlEvents:UIControlEventTouchUpInside];
    downloadButton.backgroundColor = [UIColor colorWithRed:255/255.f green:100/255.f blue:100/255.f alpha:1];
    downloadButton.layer.cornerRadius = 8;
    downloadButton.backgroundColor = [UIColor colorWithRed:255/255.f green:177/255.f blue:111/255.f alpha:1];
    [downloadButton setTitle:@"Invite Friends" forState:UIControlStateNormal];
    
    
    [self.view addSubview:self.getContactsButton];
    [self.view addSubview:self.pickContactsButton];
}

#pragma mark - Private

- (void)checkAndDisplayContactsViewController {
    
    __weak typeof(self) selfWeak = self;
    [sContactMngr requestPermissionWithCompletionHandler:^(BOOL isAccess, NSError *error) {
        if (isAccess) {
            DXContactViewController *controlelr = [DXContactViewController new];
            UINavigationController *navControlelr = [[UINavigationController alloc] initWithRootViewController:controlelr];
            [selfWeak presentViewController:navControlelr animated:YES completion:nil];
        } else if (error) {
            [selfWeak displayError:error];
        }
        [selfWeak.getContactsButton setEnabled:YES];
    } callBackQueue:dispatch_get_main_queue()];
}

- (void)checkAndDisplayContactsPickerViewController {
    
    __weak typeof(self) selfWeak = self;
    [sContactMngr requestPermissionWithCompletionHandler:^(BOOL isAccess, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (isAccess) {
                DXInviteFriendsViewController *controlelr = [DXInviteFriendsViewController new];
                UINavigationController *navControlelr = [[UINavigationController alloc] initWithRootViewController:controlelr];
                [selfWeak presentViewController:navControlelr animated:YES completion:nil];
            } else if (error) {
                [selfWeak displayError:error];
            }
            [selfWeak.pickContactsButton setEnabled:YES];
        });
    } callBackQueue:dispatch_get_main_queue()];
}

- (void)displayDownloadViewController {
    
    DXInviteFriendsViewController *controlelr = [DXInviteFriendsViewController new];
    UINavigationController *navControlelr = [[UINavigationController alloc] initWithRootViewController:controlelr];
    [self presentViewController:navControlelr animated:YES completion:^{
        [self.downloadButton setEnabled:YES];
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

- (IBAction)touchUpInsideDownloadButton:(id)sender {
    
    [self.downloadButton setEnabled:NO];
    [self displayDownloadViewController];
}

@end
