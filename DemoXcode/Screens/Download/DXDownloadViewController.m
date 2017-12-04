//
//  DXDownloadViewController.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/1/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXDownloadViewController.h"
#import "NimbusModels.h"
#import "DXDownloadManager.h"
#import "DXDownloadTableViewCell.h"
#import "DXDownloadModel.h"
#import "MBProgressHUD.h"

//https://www.codeproject.com/KB/GDI-plus/ImageProcessing2/flip.jpg
//https://img.wikinut.com/img/1hs8kgtkkw3x-9gc/jpeg/0/a-natural-scene-by-me.jpeg
//http://bigwol.com/wp-content/uploads/2014/03/natural-scenery-Taiwan.jpg
//https://upload.wikimedia.org/wikipedia/commons/f/fe/Jaljala_Lake,_a_natural_beauty_of_Rolpa,_Nepal..JPG

@interface DXDownloadViewController () <DXDownloadManagerDelegate>

@property (strong, nonatomic) UIBarButtonItem *addBarButtonItem;
@property (nonatomic, retain) NIMutableTableViewModel *tableviewModel;
@property (nonatomic, retain) NITableViewActions *actions;

@property (strong, nonatomic) NSMutableArray *originalData;

@end

@implementation DXDownloadViewController

- (void)dealloc {
    [sDownloadManager removeDelegate:self];
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupNavigationItems];
    [sDownloadManager addDelegate:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - SetUp Views

- (void)setupNavigationItems {
    self.addBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStyleDone target:self action:@selector(touchUpInSideAddBarButtonItem)];
    self.navigationItem.rightBarButtonItem = self.addBarButtonItem;
}

- (void)setupTableView {
    self.view.backgroundColor = [UIColor whiteColor];
    self.tableView.backgroundColor = [UIColor clearColor];
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

- (void)reloadWithData:(NSArray *)data {
    self.originalData = data.mutableCopy;
    [self setupTableViewModelWithData:data];
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
            DXDownloadModel *model = [object userInfo];
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
            NICellObject *cellObject = [NICellObject objectWithCellClass:[DXDownloadTableViewCell class] userInfo:model];
            [tableViewData addObject:cellObject];
        } else {
            [tableViewData addObject:model];
        }
    }
    return tableViewData;
}

#pragma mark - Actions

- (void)touchUpInSideAddBarButtonItem {
    
    weakify(self);
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:@"Download" message:@"Chose a file to download" preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *cuncon = [UIAlertAction actionWithTitle:@"Anh Cun con" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *imageLink = @"https://www.codeproject.com/KB/GDI-plus/ImageProcessing2/flip.jpg";
        NSURL *imageURL = [NSURL URLWithString:imageLink];
        DXDownloadModel *model = [[DXDownloadModel alloc] initWithDownloadURL:imageURL targetPath:nil fileName:@"Cun con.JPG"];
        [selfWeak startDownloadModel:model];
    }];
    UIAlertAction *caycoi = [UIAlertAction actionWithTitle:@"Anh Cay coi" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *imageLink = @"https://img.wikinut.com/img/1hs8kgtkkw3x-9gc/jpeg/0/a-natural-scene-by-me.jpeg";
        NSURL *imageURL = [NSURL URLWithString:imageLink];
        DXDownloadModel *model = [[DXDownloadModel alloc] initWithDownloadURL:imageURL targetPath:nil fileName:@"Hinh Cay.JPEG"];
        [selfWeak startDownloadModel:model];
    }];
    UIAlertAction *dongNui = [UIAlertAction actionWithTitle:@"Anh Donw hoa" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *imageLink = @"http://bigwol.com/wp-content/uploads/2014/03/natural-scenery-Taiwan.jpg";
        NSURL *imageURL = [NSURL URLWithString:imageLink];
        DXDownloadModel *model = [[DXDownloadModel alloc] initWithDownloadURL:imageURL targetPath:nil fileName:@"Canh Nui.JPG"];
        [selfWeak startDownloadModel:model];
    }];
    UIAlertAction *hoa = [UIAlertAction actionWithTitle:@"Anh Hoa co" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        NSString *imageLink = @"https://upload.wikimedia.org/wikipedia/commons/f/fe/Jaljala_Lake,_a_natural_beauty_of_Rolpa,_Nepal..JPG";
        NSURL *imageURL = [NSURL URLWithString:imageLink];
        DXDownloadModel *model = [[DXDownloadModel alloc] initWithDownloadURL:imageURL targetPath:nil fileName:@"Dong Hoa.JPG"];
        [selfWeak startDownloadModel:model];
    }];
    [actionSheet addAction:cuncon];
    [actionSheet addAction:caycoi];
    [actionSheet addAction:dongNui];
    [actionSheet addAction:hoa];
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:actionSheet animated:YES completion:nil];
}

- (void)startDownloadModel:(DXDownloadModel *)model {
    [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    [sDownloadManager downloadWithModel:model];
}

#pragma mark - DXDownloadManager Delegate

- (void)downloadManager:(DXDownloadManager *)downloaderManager downloadDidFinish:(NSURL *)filePath {
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
    });
}

@end
