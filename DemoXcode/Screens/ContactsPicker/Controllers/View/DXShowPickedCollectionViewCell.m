//
//  DXShowPickedCollectionViewCell.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 11/23/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXShowPickedCollectionViewCell.h"
#import "DXContactModel.h"

@interface DXShowPickedCollectionViewCellObject ()

@property (strong, nonatomic) id userInfo;

@end

@implementation DXShowPickedCollectionViewCellObject

- (instancetype)initWithModel:(id)model
{
    self = [super init];
    if (self) {
        self.userInfo = model;
    }
    return self;
}

- (UINib *)collectionViewCellNib {
    return [UINib nibWithNibName:NSStringFromClass([DXShowPickedCollectionViewCell class]) bundle:nil];
}

- (BOOL)shouldUpdateCellWithObject:(id)object {
    
    return YES;
}

@end


@interface DXShowPickedCollectionViewCell () <NICollectionViewNibCellObject>

@property (weak, nonatomic) IBOutlet UIView *imageCoverView;
@property (weak, nonatomic) IBOutlet UILabel *textAvatarLabel;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImgView;

@end

@implementation DXShowPickedCollectionViewCell

- (UINib *)collectionViewCellNib {
    return [UINib nibWithNibName:NSStringFromClass([DXShowPickedCollectionViewCell class]) bundle:nil];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    [self setupView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.imageCoverView.layer.cornerRadius = self.imageCoverView.bounds.size.width / 2;
}

#pragma mark - SetUp View

- (void)setupView {
    
    self.textAvatarLabel.textColor = [UIColor whiteColor];
    self.textAvatarLabel.backgroundColor = [UIColor colorWithRed:173.0/255.f green:175/255.f blue:231/255.f alpha:1];
    self.textAvatarLabel.alpha = 0;
    self.avatarImgView.alpha = 1;
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
    self.avatarImgView.alpha = 1;
    self.textAvatarLabel.text = @"";
    self.textAvatarLabel.alpha = 0;
}

#pragma mark - Public

- (void)displayContactModel:(DXContactModel *)model {
    
    [self clearOldData];
    if (model.avatar) {
        self.avatarImgView.image = model.avatar;
    } else {
        [self displayAvatarWithFullName:model.fullName];
    }
}

- (BOOL)shouldUpdateCellWithObject:(id)object {
    
    DXContactModel *contactModel = [object userInfo];
    [self displayContactModel:contactModel];
    return YES;
}

@end
