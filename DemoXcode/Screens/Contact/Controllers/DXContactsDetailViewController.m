//
//  DXContactsDetailViewController.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 11/21/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXContactsDetailViewController.h"
#import "DXContactModel.h"

@interface DXContactsDetailViewController ()

@property (strong, nonatomic) UIView *avatarView;
@property (strong, nonatomic) UILabel *avatarTextLabel;
@property (strong, nonatomic) UIImageView *avatarImgView;
@property (strong, nonatomic) UILabel *fullNameLabel;
@property (strong, nonatomic) UILabel *birthDaylabel;
@property (strong, nonatomic) UILabel *phoneLabel;
@property (strong, nonatomic) UILabel *emailLabel;
@property (strong, nonatomic) UILabel *addressLabel;

@property (strong, nonatomic) DXContactModel *contactModel;

@end

@implementation DXContactsDetailViewController

- (instancetype)initWithContactModell:(DXContactModel *)contactModel {
    self = [super init];
    if (self) {
        _contactModel = contactModel;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.navigationController.navigationBar.translucent = NO;
    [self setUpColor];
    [self displayContactModel:self.contactModel];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - SetUp View

- (void)setupViews {
    
    self.avatarView = [[UIView alloc] initWithFrame:CGRectMake(0, 20, self.view.bounds.size.width, 50)];
}

- (void)setUpColor {
    
    self.fullNameLabel.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    self.birthDaylabel.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    self.phoneLabel.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    self.emailLabel.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    self.addressLabel.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    self.avatarTextLabel.textColor = [UIColor whiteColor];
    [self.avatarTextLabel setBackgroundColor:[UIColor colorWithRed:173.0/255.f green:175/255.f blue:231/255.f alpha:1]];
    self.avatarView.layer.cornerRadius = self.avatarView.bounds.size.width / 2;
    self.avatarTextLabel.alpha = 0;
}

- (void)displayContactModel:(DXContactModel *)contactModel {
    
    self.fullNameLabel.text = contactModel.fullName;
    self.birthDaylabel.text = contactModel.birthDay;
    self.phoneLabel.text = contactModel.phones.firstObject;
    self.emailLabel.text = contactModel.emails.firstObject;
    self.addressLabel.text = contactModel.addressArray.firstObject;
    if (contactModel.avatar) {
        self.avatarImgView.image = contactModel.avatar;
    } else {
        [self displayAvatarWithFullName:contactModel.fullName];
    }
}

- (void)displayAvatarWithFullName:(NSString *)fullName {
    
    self.avatarTextLabel.alpha = 1;
    self.avatarImgView.alpha = 0;
    
    NSString *avatarStr = @"";
    NSString *name = [fullName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    while ([name rangeOfString:@"  "].length > 0) {
        name = [name stringByReplacingOccurrencesOfString:@"  " withString:@" "];
    }
    
    if (fullName.length == 0) {
        return;
    }
    
    NSArray *words = [name componentsSeparatedByString:@" "];
    for (NSInteger i = 0; i < 3 && i < words.count; i ++) {
        NSString *character = [[words objectAtIndex:i] substringToIndex:1];
        avatarStr = [avatarStr stringByAppendingString:character.uppercaseString];
    }
    self.avatarTextLabel.text = avatarStr;
}

@end
