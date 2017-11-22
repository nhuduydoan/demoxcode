//
//  DXContactTableViewCell.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 11/20/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXContactTableViewCell.h"
#import "DXContactModel.h"

@interface DXContactAvatarLabel : UILabel

@end

@implementation DXContactAvatarLabel

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    // Not do any thing
}

- (void)setConstantBackgroundColor:(UIColor *)color {
    [super setBackgroundColor:color];
}

@end

@interface DXContactTableViewCell ()

@property (weak, nonatomic) IBOutlet UIView *avatarLayerView;
@property (weak, nonatomic) IBOutlet DXContactAvatarLabel *textAvatarLabel;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImgView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subLabel;

@end

@implementation DXContactTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    [self setUpView];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - SetUp View

- (void)setUpView {
    
    self.textAvatarLabel.textColor = [UIColor whiteColor];
    [self.textAvatarLabel setConstantBackgroundColor:[UIColor colorWithRed:173.0/255.f green:175/255.f blue:231/255.f alpha:1]];
    self.avatarLayerView.layer.cornerRadius = self.avatarLayerView.bounds.size.width / 2;
    self.subLabel.textColor = [UIColor colorWithWhite:0.75 alpha:1];
    
    UIView *selectedBackgroundView = [UIView new];
    selectedBackgroundView.backgroundColor = [UIColor colorWithWhite:0.93 alpha:1];
    self.selectedBackgroundView = selectedBackgroundView;
}

#pragma mark - Private

- (void)displayAvatarWithFullName:(NSString *)fullName {
    
    self.textAvatarLabel.alpha = 1;
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
    self.textAvatarLabel.text = avatarStr;
}

- (void)clearOldData {
    
    self.avatarImgView.image = nil;
    self.textAvatarLabel.text = @"";
    self.textAvatarLabel.alpha = 0;
    self.avatarImgView.alpha = 1;
    self.titleLabel.text = @"";
    self.subLabel.text = @"";
    CGRect frame = self.titleLabel.frame;
    frame.origin.y = 0;
    self.titleLabel.frame = frame;
}

#pragma mark - Public

- (void)displayContactModel:(DXContactModel *)contactModel {
    
    [self clearOldData];
    self.titleLabel.text = contactModel.fullName;
    if (contactModel.phones.count > 0) {
        self.subLabel.text = contactModel.phones.firstObject;
    } else {
        CGRect frame = self.titleLabel.frame;
        frame.origin.y = (self.bounds.size.height - frame.size.height) / 2;
        self.titleLabel.frame = frame;
    }
    if (contactModel.avatar) {
        self.avatarImgView.image = contactModel.avatar;
    } else {
        [self displayAvatarWithFullName:contactModel.fullName];
    }
}

@end
