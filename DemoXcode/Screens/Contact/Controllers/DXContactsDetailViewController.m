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
@property (strong, nonatomic) UIImageView *avatarImgView;
@property (strong, nonatomic) UILabel *nameTitle;
@property (strong, nonatomic) UILabel *fullNameLabel;
@property (strong, nonatomic) UILabel *birthDayTitle;
@property (strong, nonatomic) UILabel *birthDaylabel;
@property (strong, nonatomic) UILabel *phoneTitle;
@property (strong, nonatomic) UILabel *phoneLabel;
@property (strong, nonatomic) UILabel *emailTitle;
@property (strong, nonatomic) UILabel *emailLabel;
@property (strong, nonatomic) UILabel *addressTitle;
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
    [self setupViews];
    [self setUpColor];
    [self displayContactModel:self.contactModel];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - SetUp View

- (void)setupViews {
    
    self.avatarView = [[UIView alloc] initWithFrame:CGRectMake(10, 10, 60, 60)];
    self.avatarView.layer.cornerRadius = 30;
    self.avatarView.clipsToBounds = YES;
    self.avatarImgView = [[UIImageView alloc] initWithFrame:self.avatarView.bounds];
    [self.avatarView addSubview:self.avatarImgView];
    [self.view addSubview:self.avatarView];
    
    CGRect frame = CGRectMake(80, 10, self.view.bounds.size.width - 90, 20);
    self.nameTitle = [[UILabel alloc] initWithFrame:frame];
    self.nameTitle.text = @"Full Name";
    self.nameTitle.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    frame.origin.y = frame.origin.y + frame.size.height + 10;
    self.fullNameLabel = [[UILabel alloc] initWithFrame:frame];
    self.fullNameLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.nameTitle];
    [self.view addSubview:self.fullNameLabel];
    
    frame.origin.x = 40;
    frame.size.width = self.view.bounds.size.width - 50;
    frame.origin.y = frame.origin.y + frame.size.height + 20;
    self.birthDayTitle = [[UILabel alloc] initWithFrame:frame];
    self.birthDayTitle.text = @"Birth Day";
    self.birthDayTitle.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    frame.origin.y = frame.origin.y + frame.size.height + 10;
    self.birthDaylabel = [[UILabel alloc] initWithFrame:frame];
    self.birthDaylabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.birthDayTitle];
    [self.view addSubview:self.birthDaylabel];
    
    frame.origin.y = frame.origin.y + frame.size.height + 20;
    self.phoneTitle = [[UILabel alloc] initWithFrame:frame];
    self.phoneTitle.text = @"Phone Number";
    self.phoneTitle.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    frame.origin.y = frame.origin.y + frame.size.height + 10;
    self.phoneLabel = [[UILabel alloc] initWithFrame:frame];
    self.phoneLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.phoneTitle];
    [self.view addSubview:self.phoneLabel];
    
    frame.origin.y = frame.origin.y + frame.size.height + 20;
    self.emailTitle = [[UILabel alloc] initWithFrame:frame];
    self.emailTitle.text = @"Email";
    self.emailTitle.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    frame.origin.y = frame.origin.y + frame.size.height + 10;
    self.emailLabel = [[UILabel alloc] initWithFrame:frame];
    self.emailLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.emailTitle];
    [self.view addSubview:self.emailLabel];
    
    frame.origin.y = frame.origin.y + frame.size.height + 20;
    self.addressTitle = [[UILabel alloc] initWithFrame:frame];
    self.addressTitle.text = @"Address";
    self.addressTitle.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    frame.origin.y = frame.origin.y + frame.size.height + 10;
    self.addressLabel = [[UILabel alloc] initWithFrame:frame];
    self.addressLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.addressTitle];
    [self.view addSubview:self.addressLabel];
}

- (void)setUpColor {
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.fullNameLabel.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    self.birthDaylabel.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    self.phoneLabel.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    self.emailLabel.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    self.addressLabel.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
//    self.avatarView.backgroundColor = [UIColor lightGrayColor];
    self.avatarImgView.backgroundColor = [UIColor redColor];
}

- (void)displayContactModel:(DXContactModel *)contactModel {
    
    self.fullNameLabel.text = contactModel.fullName;
    self.birthDaylabel.text = contactModel.birthDay;
    self.phoneLabel.text = contactModel.phones.firstObject;
    self.emailLabel.text = contactModel.emails.firstObject;
    self.addressLabel.text = contactModel.addressArray.firstObject;
    self.avatarImgView.image = contactModel.avatar;
}

@end
