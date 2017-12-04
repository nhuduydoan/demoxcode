//
//  DXFilesViewController.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/4/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXFilesViewController.h"
#import "NimbusModels.h"
#import "DXFileModel.h"
#import "DXFilesTableViewCell.h"
#import "DXFileManager.h"
#import "DXDownloadManager.h"

@interface DXFilesViewController () <DXFileManagerDelegate, DXDownloadManagerDelegate>

@property (nonatomic, retain) NIMutableTableViewModel *tableviewModel;
@property (nonatomic, retain) NITableViewActions *actions;

@property (strong, nonatomic) NSMutableArray *originalData;

@end

@implementation DXFilesViewController

- (void)dealloc {
    [sFileManager removeObject:self];
    [sDownloadManager removeObject:self];
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [sFileManager addDelegate:self];
    [sDownloadManager addDelegate:self];
    [self setupTableView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupTableView {
    self.tableView.backgroundColor = [UIColor clearColor];
    self.view.backgroundColor = [UIColor whiteColor];
    self.tableView.rowHeight = 44;
    self.tableView.tableHeaderView = [UIView new];
    self.tableView.tableFooterView = [UIView new];
    
    self.tableView.separatorColor = [UIColor colorWithRed:223/255.f green:226/255.f blue:227/255.f alpha:1];
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsMake(0, 16, 0, 0)];
    }
    if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.tableView setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (void)reloadWithData {
//    self.originalData = data.mutableCopy;
//    [self setupTableViewModelWithData:data];
}

- (void)setupTableViewModelWithData:(NSArray *)data {
    NSMutableArray *tableViewData = [self tableviewDataFromData:data];
    self.tableviewModel = [[NIMutableTableViewModel alloc] initWithSectionedArray:tableViewData delegate:(id)[NICellFactory class]];
    [self.tableviewModel setSectionIndexType:NITableViewModelSectionIndexDynamic
                                 showsSearch:(tableViewData.count > 0)
                                showsSummary:NO];
    
    self.tableView.dataSource = self.tableviewModel;
    [self setupTableViewActionsWithData:tableViewData];
    [self.tableView reloadData];
}

- (void)setupTableViewActionsWithData:(NSArray *)data {
    self.actions = [[NITableViewActions alloc] initWithTarget:self];
    for (id obj in data) {
        if ([obj isKindOfClass:[NSString class]]) {
            continue;
        }
        weakify(self);
        [self.actions attachToObject:obj tapBlock:^BOOL(id object, id target, NSIndexPath *indexPath) {
            DXFileModel *model = [object userInfo];
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:model.fileName preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
            [selfWeak presentViewController:alertController animated:YES completion:nil];
            return NO;
        }];
    }
    self.tableView.delegate = [self.actions forwardingTo:self];
}

- (NSMutableArray *)tableviewDataFromData:(NSArray *)data {
    NSMutableArray *tableViewData = [NSMutableArray new];
    for (id model in data) {
        if (![model isKindOfClass:[NSString class]]) {
            NICellObject *cellObject = [NICellObject objectWithCellClass:[DXFilesTableViewCell class] userInfo:model];
            [tableViewData addObject:cellObject];
        } else {
            [tableViewData addObject:model];
        }
    }
    return tableViewData;
}

#pragma mark - DXFileManager Delegate

- (void)fileManager:(DXFileManager *)fileManager didInsertNewItem:(DXFileModel *)fileModel {
    [self reloadWithData];
}

- (void)downloadManager:(DXDownloadManager *)downloaderManager downloadDidFinish:(NSURL *)filePath {
    [self reloadWithData];
}

@end
