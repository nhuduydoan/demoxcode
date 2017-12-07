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
#import "DXFileManager.h"
#import "DXDownloadManager.h"

@interface DXDownloadTableViewCell () <NICell, DXDownloadComponentDelegate>

@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *subLabel;
@property (strong, nonatomic) UIProgressView *progressView;
@property (strong, nonatomic) UIButton *resumeButton;
@property (strong, nonatomic) UIButton *refreshButton;

@property (strong, nonatomic) DXDownloadComponent *component;

@end

@implementation DXDownloadTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupViews];
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

- (void)setupViews {
    self.contentView.clipsToBounds = YES;
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 0, self.contentView.bounds.size.width - 92, self.contentView.bounds.size.height/2)];
    self.titleLabel.font = [UIFont systemFontOfSize:17];
    self.titleLabel.clipsToBounds = YES;
    self.titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    [self.contentView addSubview:self.titleLabel];
    
    UIProgressView *progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(8, self.contentView.bounds.size.height/2, self.contentView.bounds.size.width - 92, 3)];
    progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    progressView.hidden = YES;
    progressView.tintColor = [UIColor blueColor];
    self.progressView = progressView;
    [self.contentView addSubview:progressView];
    
    self.subLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, self.contentView.bounds.size.height/2 + 3, self.contentView.bounds.size.width - 92, self.contentView.bounds.size.height/2 - 3)];
    self.subLabel.font = [UIFont systemFontOfSize:12];
    self.subLabel.clipsToBounds = YES;
    self.subLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1];
    self.subLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin;
    [self.contentView addSubview:self.subLabel];
    
    UIButton *resumeButton = [[UIButton alloc] initWithFrame:CGRectMake(self.contentView.bounds.size.width - 76, self.contentView.bounds.size.height/2 - 15, 30, 30)];
    resumeButton.clipsToBounds = YES;
    [resumeButton addTarget:self action:@selector(touchUpInsideResumeButton:) forControlEvents:UIControlEventTouchUpInside];
    resumeButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self.contentView addSubview:resumeButton];
    self.resumeButton = resumeButton;
    
    UIButton *refreshButton = [[UIButton alloc] initWithFrame:CGRectMake(self.contentView.bounds.size.width - 38, self.contentView.bounds.size.height/2 - 15, 30, 30)];
    refreshButton.clipsToBounds = YES;
    [refreshButton addTarget:self action:@selector(touchUpInsideRefreshButton:) forControlEvents:UIControlEventTouchUpInside];
    refreshButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self.contentView addSubview:refreshButton];
    self.refreshButton = refreshButton;
}

- (IBAction)touchUpInsideResumeButton:(id)sender {
    switch (self.component.stautus) {
        case NSURLSessionTaskStateRunning: {
            [sDownloadManager suppendComponent:self.component];
        }
            break;
        case NSURLSessionTaskStateSuspended: {
            [sDownloadManager downloadComponent:self.component];
        }
            break;
        default:
            break;
    }
}

- (IBAction)touchUpInsideRefreshButton:(id)sender {
    switch (self.component.stautus) {
        case NSURLSessionTaskStateRunning: {
            [sDownloadManager cancelComponent:self.component];
        }
            break;
        case NSURLSessionTaskStateSuspended: {
            [sDownloadManager cancelComponent:self.component];
        }
            break;
        case NSURLSessionTaskStateCanceling: {
        }
            break;
        default: [sDownloadManager downloadComponent:self.component];
            break;
    }
}

- (void)clearOldData {
    self.progressView.hidden = YES;
    self.resumeButton.hidden = NO;
    self.refreshButton.hidden = NO;
    self.subLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1];
    self.progressView.hidden = YES;
    [self.resumeButton setImage:[UIImage imageNamed:@"icon_play"] forState:UIControlStateNormal];
    [self.refreshButton setImage:[UIImage imageNamed:@"icon_cancel"] forState:UIControlStateNormal];
}

- (void)displayComponent:(DXDownloadComponent *)component {
    [self clearOldData];
    NSString *fileName = [component.response suggestedFilename];
    if (fileName.length == 0) {
        if (component.savedPath.lastPathComponent.length) {
            fileName = component.savedPath.lastPathComponent;
        } else {
            fileName = component.URL.absoluteString;
        }
    }
    
    self.progressView.progress = component.downloadProgress.fractionCompleted;
    NSString *subString;
    if (component.downloadProgress.totalUnitCount > 0) {
        subString = [NSString stringWithFormat:@"%@/%@", [self transformedValue:component.downloadProgress.completedUnitCount], [self transformedValue:component.downloadProgress.totalUnitCount]];
    } else {
        subString = [NSString stringWithFormat:@"%@", [self transformedValue:component.downloadProgress.completedUnitCount]];
    }
    switch (component.stautus) {
        case NSURLSessionTaskStateRunning: {
            subString = [NSString stringWithFormat:@"Loading... %@", subString];
            self.subLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1];
            self.progressView.hidden = NO;
            [self.resumeButton setImage:[UIImage imageNamed:@"icon_pause"] forState:UIControlStateNormal];
        }
            break;
        case NSURLSessionTaskStateSuspended: {
            self.subLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1];
            self.progressView.hidden = NO;
            subString = [NSString stringWithFormat:@"Suppended %@", subString];
        }
            break;
        case NSURLSessionTaskStateCanceling: {
            self.resumeButton.hidden = YES;
            subString = [NSString stringWithFormat:@"%@ %@", @"Canceling... ", subString];
            self.subLabel.textColor = [UIColor redColor];
            [self.refreshButton setImage:[UIImage imageNamed:@"icon_refresh"] forState:UIControlStateNormal];
        }
            break;
        case NSURLSessionTaskStateCompleted: {
            if (component.downloadError) {
                subString = [NSString stringWithFormat:@"%@ %@", @"Error! ", subString];
                self.subLabel.textColor = [UIColor redColor];
                [self.refreshButton setImage:[UIImage imageNamed:@"icon_refresh"] forState:UIControlStateNormal];
            } else {
                subString = [NSString stringWithFormat:@"%@ %@", @"Completed ", subString];
                self.subLabel.textColor = [UIColor blackColor];
                self.refreshButton.hidden = YES;
                self.resumeButton.hidden = YES;
            }
        }
            break;
        default:
            self.refreshButton.hidden = YES;
            break;
    }
    self.titleLabel.text = fileName;
    self.subLabel.text = subString;
}

- (BOOL)shouldUpdateCellWithObject:(id)object {
    DXDownloadComponent *component = [object userInfo];
    self.component.delegate = nil;
    self.component = component;
    component.delegate = self;
    [self displayComponent:component];
    return YES;
}

- (NSString *)transformedValue:(int64_t)value {
    if (value < 0 || value == NSNotFound) {
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

- (void)downloadComponent:(DXDownloadComponent *)component didChangeStatus:(NSURLSessionTaskState)status {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self displayComponent:component];
    });
}

- (void)downloadComponent:(DXDownloadComponent *)component didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self displayComponent:component];
    });
}

- (void)downloadComponent:(DXDownloadComponent *)component didFinishDownloadingToURL:(NSURL *)location {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self displayComponent:component];
    });
}

- (void)downloadComponent:(DXDownloadComponent *)component didCompleteWithError:(NSError *)error {
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
