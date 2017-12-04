//
//  DXDownloadTableViewCell.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/4/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXDownloadTableViewCell.h"
#import "NimbusModels.h"
#import "DXDownloadModel.h"

@interface DXDownloadTableViewCell () <NICell>

@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *subLabel;

@end

@implementation DXDownloadTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupChildLabels];
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

- (void)setupChildLabels {
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, self.bounds.size.width - (16 + 8), self.contentView.bounds.size.height/2)];
    self.titleLabel.clipsToBounds = YES;
    self.titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    [self.contentView addSubview:self.titleLabel];
    
    self.subLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, self.contentView.bounds.size.height/2, self.bounds.size.width - (16 + 8), self.contentView.bounds.size.height/2)];
    self.subLabel.clipsToBounds = YES;
    self.subLabel.textColor = [UIColor colorWithWhite:0.75 alpha:1];
    self.subLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin;
    [self.contentView addSubview:self.subLabel];
}

- (void)displayDownloadModel:(DXDownloadModel *)model {
    
}

- (BOOL)shouldUpdateCellWithObject:(id)object {
    DXDownloadModel *model = [object userInfo];
    [self displayDownloadModel:model];
    return YES;
}

@end
