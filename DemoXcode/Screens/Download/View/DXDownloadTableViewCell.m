//
//  DXDownloadTableViewCell.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/4/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXDownloadTableViewCell.h"
#import "NimbusModels.h"
#import "DXDownloadComponent.h"

@interface DXDownloadTableViewCell () <NICell, DXDownloadComponentDelegate>

@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *subLabel;
@property (strong, nonatomic) UIProgressView *progressView;
@property (strong, nonatomic) DXDownloadComponent *component;

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
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, self.contentView.bounds.size.width - 24, self.contentView.bounds.size.height/2)];
    self.titleLabel.font = [UIFont systemFontOfSize:17];
    self.titleLabel.clipsToBounds = YES;
    self.titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    [self.contentView addSubview:self.titleLabel];
    
    UIProgressView *progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(16, self.contentView.bounds.size.height/2, self.contentView.bounds.size.width - 28, 3)];
    progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    progressView.hidden = YES;
    self.progressView = progressView;
    [self.contentView addSubview:progressView];
    
    self.subLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, self.contentView.bounds.size.height/2 + 3, self.contentView.bounds.size.width - 24, self.contentView.bounds.size.height/2 - 3)];
    self.subLabel.font = [UIFont systemFontOfSize:12];
    self.subLabel.clipsToBounds = YES;
    self.subLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1];
    self.subLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin;
    [self.contentView addSubview:self.subLabel];
}

- (void)clearOldData {
    self.component.delegate = nil;
    self.component = nil;
    self.progressView.hidden = YES;
}

- (void)displayComponent:(DXDownloadComponent *)component {
    self.component = component;
    component.delegate = self;
    
    self.subLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1];
    self.titleLabel.text = component.downloadModel.fileName;
    NSString *subString;
    if (component.downloadTask.countOfBytesExpectedToReceive > 0) {
         subString = [NSString stringWithFormat:@"%@/%@", [self transformedValue:component.downloadTask.countOfBytesReceived], [self transformedValue:component.downloadTask.countOfBytesExpectedToReceive]];
    } else {
        subString = [NSString stringWithFormat:@"%@", [self transformedValue:component.downloadTask.countOfBytesReceived]];
    }
    
    switch (component.stautus) {
            break;
        case DXDownloadStatusRunning: {
            subString = [NSString stringWithFormat:@"Loading %@", subString];
            self.subLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1];
            self.progressView.hidden = NO;
        }
            break;
        case DXDownloadStatusPause: {
            self.subLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1];
            self.progressView.hidden = NO;
            subString = [NSString stringWithFormat:@"Pausing %@", subString];
        }
            break;
        case DXDownloadStatusCompleted: {
            self.progressView.hidden = YES;
            self.subLabel.textColor = [UIColor blackColor];
        }
            break;
        case DXDownloadStatusCancel: {
            subString = [NSString stringWithFormat:@"%@ %@", @"Download canceled", subString];
            self.progressView.hidden = YES;
            self.subLabel.textColor = [UIColor redColor];
        }
            break;
        default: {
            self.subLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1];
            self.progressView.hidden = YES;
        }
            break;
    }
    self.subLabel.text = subString;
}

- (BOOL)shouldUpdateCellWithObject:(id)object {
    DXDownloadComponent *component = [object userInfo];
    [self clearOldData];
    [self displayComponent:component];
    return YES;
}

- (NSString *)transformedValue:(uint64_t)value {
    if (value <= 0 || value >= NSNotFound) {
        return @"";
    }
    float convertedValue = value;
    int multiplyFactor = 0;
    
    NSArray *tokens = [NSArray arrayWithObjects:@"bytes", @"KB", @"MB", @"GB", @"TB", nil];
    
    while (convertedValue > 1024.0) {
        convertedValue /= 1024.0;
        multiplyFactor++;
    }
    
    return [NSString stringWithFormat:@"%.02f %@", convertedValue, [tokens objectAtIndex:multiplyFactor]];
}

#pragma mark - DXDownloadComponentDelegate

- (void)didUpdateDownloadComponent:(DXDownloadComponent *)component {
    if (self.component != component) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self displayComponent:component];
    });
}

- (void)downloadComponent:(DXDownloadComponent *)component didFinishDownloadingToURL:(NSURL *)location {
    if (self.component != component) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self displayComponent:component];
    });
}

- (void)downloadComponent:(DXDownloadComponent *)component didCompleteWithError:(NSError *)error {
    if (self.component != component) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self displayComponent:component];
        if (error && error.code != NSURLErrorCancelled) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:error.localizedDescription message:error.localizedFailureReason preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
            [[UIApplication sharedApplication].delegate.window.rootViewController presentViewController:alert animated:YES completion:nil];
        }
    });
}

@end
