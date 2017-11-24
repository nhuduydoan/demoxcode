//
//  DXPickContactTableViewCell.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 11/20/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXPickContactTableViewCell.h"
#import "NimbusModels.h"
#import "DXContactModel.h"
#import "DXContactAvatarLabel.h"

@interface DXPickContactTableViewCell () <NICell>

@property (strong, nonatomic) UIView *avatarLayerView;
@property (strong, nonatomic) DXContactAvatarLabel *textAvatarLabel;
@property (strong, nonatomic) UIImageView *avatarImgView;
@property (strong, nonatomic) UILabel *titleLabel;

@end

@implementation DXPickContactTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setUpView];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - SetUp View

- (void)setUpView {
    
    self.shouldIndentWhileEditing = YES;
    [self setupAvatarView];
    [self setupChildLabels];
}

- (void)setupAvatarView {
    
    self.avatarLayerView = [[UIView alloc] initWithFrame:CGRectMake(9, 9, 46, 46)];
    self.avatarLayerView.clipsToBounds = YES;
    self.avatarLayerView.layer.cornerRadius = self.avatarLayerView.bounds.size.width / 2;
    self.avatarImgView = [[UIImageView alloc] initWithFrame:self.avatarLayerView.bounds];
    [self.avatarLayerView addSubview:self.avatarImgView];
    self.textAvatarLabel = [[DXContactAvatarLabel alloc] initWithFrame:self.avatarLayerView.bounds];
    self.textAvatarLabel.textAlignment = NSTextAlignmentCenter;
    self.textAvatarLabel.font = [UIFont systemFontOfSize:18 weight:1];
    self.textAvatarLabel.textColor = [UIColor whiteColor];
    [self.textAvatarLabel setConstantBackgroundColor:[UIColor colorWithRed:173.0/255.f green:175/255.f blue:231/255.f alpha:1]];
    [self.avatarLayerView addSubview:self.textAvatarLabel];
    [self.contentView addSubview:self.avatarLayerView];
}

- (void)setupChildLabels {
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(61, (self.bounds.size.height - 32)/2, self.bounds.size.width - (16 + 61), 32)];
    self.titleLabel.clipsToBounds = YES;
    self.titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.contentView addSubview:self.titleLabel];
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
}

#pragma mark - Public

- (void)displayContactModel:(DXContactModel *)contactModel {
    
    [self clearOldData];
    self.titleLabel.text = contactModel.fullName;
    if (contactModel.avatar) {
        self.avatarImgView.image = contactModel.avatar;
    } else {
        [self displayAvatarWithFullName:contactModel.fullName];
    }
}

- (BOOL)shouldUpdateCellWithObject:(id)object {
    
    DXContactModel *contactModel = [object userInfo];
    [self displayContactModel:contactModel];
    return YES;
}

@end
