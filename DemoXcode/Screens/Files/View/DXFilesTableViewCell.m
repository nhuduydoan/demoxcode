//
//  DXFilesTableViewCell.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/4/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXFilesTableViewCell.h"
#import "DXFileModel.h"
#import "NimbusModels.h"
#import "DXFileManager.h"
#import "DXImageManager.h"

@interface DXFilesTableViewCell () <NICell>

@property (strong, nonatomic) UIImageView *avatarView;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *subLabel;

@end

@implementation DXFilesTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupAvatar];
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

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect frame = self.avatarView.frame;
    frame.size.height = self.contentView.bounds.size.height;
    frame.size.width = frame.size.height;
    self.avatarView.frame = frame;
}

- (void)setupAvatar {
    self.avatarView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 0, 50, self.contentView.bounds.size.height)];
    self.avatarView.clipsToBounds = YES;
    [self.contentView addSubview:self.avatarView];
}

- (void)setupChildLabels {
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(70, 0, self.bounds.size.width - 80, self.contentView.bounds.size.height/2)];
    self.titleLabel.clipsToBounds = YES;
    self.titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    [self.contentView addSubview:self.titleLabel];
    
    self.subLabel = [[UILabel alloc] initWithFrame:CGRectMake(70, self.contentView.bounds.size.height/2, self.bounds.size.width - 80, self.contentView.bounds.size.height/2)];
    self.subLabel.font = [UIFont systemFontOfSize:12];
    self.subLabel.clipsToBounds = YES;
    self.subLabel.textColor = [UIColor colorWithWhite:0.75 alpha:1];
    self.subLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin;
    [self.contentView addSubview:self.subLabel];
}

- (NSString *)transformedValue:(uint64_t)value {
    float convertedValue = value;
    int multiplyFactor = 0;
    
    NSArray *tokens = [NSArray arrayWithObjects:@"bytes", @"KB", @"MB", @"GB", @"TB", nil];
    
    while (convertedValue > 1024.0) {
        convertedValue /= 1024.0;
        multiplyFactor++;
    }
    
    return [NSString stringWithFormat:@"%.02f %@", convertedValue, [tokens objectAtIndex:multiplyFactor]];
}

- (void)displayModel:(DXFileModel *)model {
    self.titleLabel.text = model.fileName;
    self.subLabel.text = [self transformedValue:model.size];
    if (!model.thumnail && [self pathExtensionIsImageExtension:model.fileName.pathExtension]) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSData *data = [sFileManager contentOfFileItem:model];
            UIImage *img = [UIImage imageWithData:data];
            UIImage *thumnail = [sImageManager avatarImageFromOriginalImage:img];
            model.thumnail = thumnail;
            dispatch_async(dispatch_get_main_queue(), ^{
                self.avatarView.image = model.thumnail;
                self.avatarView.contentMode = UIViewContentModeScaleAspectFit;
            });
        });
    }
}

- (BOOL)shouldUpdateCellWithObject:(id)object {
    DXFileModel *model = [object userInfo];
    [self displayModel:model];
    return YES;
}

- (BOOL)pathExtensionIsImageExtension:(NSString *)pathExtension {
    return [pathExtension.lowercaseString isEqualToString:@"jpg"] || [pathExtension.lowercaseString isEqualToString:@"jpeg"] || [pathExtension.lowercaseString isEqualToString:@"png"];
}

@end
