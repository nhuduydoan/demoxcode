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
    return [UINib nibWithNibName:@"AAAAA" bundle:nil];
}

- (BOOL)shouldUpdateCellWithObject:(id)object {
    
    return YES;
}

@end


@interface DXShowPickedCollectionViewCell () <NICollectionViewCell>

@property (weak, nonatomic) IBOutlet UIView *imageCoverView;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImgView;

@end

@implementation DXShowPickedCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    [self setupView];
}

#pragma mark - SetUp View

- (void)setupView {
    self.imageCoverView.layer.cornerRadius = self.imageCoverView.bounds.size.width / 2;
}

#pragma mark - Private

- (void)clearOldData {
    self.avatarImgView.image = nil;
}

#pragma mark - Public

- (void)displayContactModel:(DXContactModel *)model {
    
    [self clearOldData];
    self.avatarImgView.image = model.avatar;
}

- (BOOL)shouldUpdateCellWithObject:(id)object {
    
    DXContactModel *contactModel = [object userInfo];
    [self displayContactModel:contactModel];
    return YES;
}

@end
