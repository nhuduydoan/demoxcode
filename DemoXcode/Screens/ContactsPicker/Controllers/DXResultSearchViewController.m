//
//  DXResultSearchViewController.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 11/24/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXResultSearchViewController.h"
#import "DXContactModel.h"
#import "DXPickContactTableViewCell.h"
#import "NimbusCore.h"
#import "NimbusModels.h"

#define PickContactCell @"PickContactCell"

@interface DXResultSearchViewController () <NITableViewModelDelegate, NIMutableTableViewModelDelegate>

@property (nonatomic, retain) NIMutableTableViewModel *tableviewModel;
@property (nonatomic, retain) NITableViewActions *actions;

@property (strong, nonatomic) NSArray *data;

@end

@implementation DXResultSearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupTableView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - SetUp View

- (void)setupTableView {
    
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([DXPickContactTableViewCell class]) bundle:nil] forCellReuseIdentifier:PickContactCell];
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    self.tableView.editing = YES;
    self.tableView.rowHeight = 64;
    self.tableView.tableFooterView = [UIView new];
    
    self.tableView.separatorColor = [UIColor colorWithRed:223/255.f green:226/255.f blue:227/255.f alpha:1];
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsMake(0, 100, 0, 0)];
    }
    if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.tableView setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (void)setUpNonSectionedTableViewModelWithData:(NSArray *)data {
    
    NSArray *tableViewData = [self tableViewDataFromData:data];
    self.tableviewModel = [[NIMutableTableViewModel alloc] initWithListArray:tableViewData delegate:self];
    [self.tableviewModel setSectionIndexType:NITableViewModelSectionIndexNone
                                 showsSearch:NO
                                showsSummary:NO];
    
    self.data = tableViewData;
    [self setUpTableViewActionsWithData:tableViewData];
    self.tableView.dataSource = self.tableviewModel;
    [self.tableView reloadData];
    [self checkSelectedWithData:tableViewData];
}

- (void)setUpTableViewActionsWithData:(NSArray *)data {
    
    self.actions = [[NITableViewActions alloc] initWithTarget:self];
    weakify(self);
    for (id obj in data) {
        if ([obj isKindOfClass:[NSString class]]) {
            continue;
        }
        [self.actions attachToObject:obj tapBlock:^BOOL(id object, id target, NSIndexPath *indexPath) {
            id model = [object userInfo];
            if ([selfWeak.delegate respondsToSelector:@selector(pickContactsViewController:didSelectModel:)]) {
                BOOL isSelected = [selfWeak.delegate pickContactsViewController:selfWeak didSelectModel:model];
                return !isSelected;
            }
            return YES;
        }];
    }
    self.tableView.delegate = [self.actions forwardingTo:self];
}

#pragma mark - Public

- (void)reloadWithData:(NSArray *)data {
    
    [self setUpNonSectionedTableViewModelWithData:data];
}

- (void)checkSelectedWithData:(NSArray *)data {
    
    if ([self.delegate respondsToSelector:@selector(pickContactsViewController:isSelectedModel:)]) {
        for (id obj  in data) {
            if (![obj isKindOfClass:[NICellObject class]]) {
                continue;
            }
            if ([self.delegate pickContactsViewController:self isSelectedModel:[obj userInfo]]) {
                NSIndexPath *indexPath = [self.tableviewModel indexPathForObject:obj];
                [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
            }
        }
    }
}

- (void)didSelectModel:(id)model {
    
    NICellObject *cellObject = [self cellObjectForModel:model];
    if (cellObject == nil) {
        return;
    }
    
    NSIndexPath *indexPath = [self.tableviewModel indexPathForObject:cellObject];
    if (indexPath != nil) {
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
}

- (void)deSelectModel:(id)model {
    
    NICellObject *cellObject = [self cellObjectForModel:model];
    if (cellObject == nil) {
        return;
    }
    
    NSIndexPath *indexPath = [self.tableviewModel indexPathForObject:cellObject];
    if (indexPath != nil) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)scrollToContactModel:(id)model {
    
    NICellObject *cellObject = [self cellObjectForModel:model];
    if (cellObject == nil) {
        return;
    }
    
    NSIndexPath *indexPath = [self.tableviewModel indexPathForObject:cellObject];
    if (indexPath != nil) {
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

#pragma mark - Private

- (id)cellObjectForModel:(id)model {
    
    for (NICellObject *object in self.data) {
        if ([object isKindOfClass:[NICellObject class]] && [object.userInfo isEqual:model]) {
            return object;
        }
    }
    return nil;
}

- (NSArray *)tableViewDataFromData:(NSArray *)data {
    
    NSArray *arrangedData = [sApplication arrangeNonSectionedWithData:data];
    NSMutableArray *tableViewData = [NSMutableArray new];
    for (id model in arrangedData) {
        if (![model isKindOfClass:[NSString class]]) {
            NICellObject *cellObject = [NICellObject objectWithCellClass:[DXPickContactTableViewCell class] userInfo:model];
            [tableViewData addObject:cellObject];
        } else {
            [tableViewData addObject:model];
        }
    }
    return tableViewData;
}

#pragma mark - NITableViewModelDelegate

- (UITableViewCell *)tableViewModel:(NITableViewModel *)tableViewModel cellForTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath withObject:(id)object {
    return [NICellFactory tableViewModel:tableViewModel cellForTableView:tableView atIndexPath:indexPath withObject:object];
}

#pragma mark - NIMutableTableViewModelDelegate

- (BOOL)tableViewModel:(NIMutableTableViewModel *)tableViewModel canEditObject:(id)object atIndexPath:(NSIndexPath *)indexPath inTableView:(UITableView *)tableView {
    return YES;
}

#pragma mark - UITableView Delegate

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NICellObject *cellObject = [self.tableviewModel objectAtIndexPath:indexPath];
    id model = cellObject.userInfo;
    if ([self.delegate respondsToSelector:@selector(pickContactsViewController:didDeSelectModel:)]) {
        [self.delegate pickContactsViewController:self didDeSelectModel:model];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    
    if ([self.delegate respondsToSelector:@selector(didTapOnPickContactsViewController:)]) {
        [self.delegate didTapOnPickContactsViewController:self];
    }
}

- (void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [self setCellColor:[UIColor colorWithRed:235/255.f green:235/255.f blue:235/255.f alpha:1.0] forCell:cell];  //highlight colour
}

- (void)tableView:(UITableView *)tableView didUnhighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [self setCellColor:[UIColor clearColor] forCell:cell]; //normal color
}

- (void)setCellColor:(UIColor *)color forCell:(UITableViewCell *)cell {
    cell.contentView.backgroundColor = color;
    cell.backgroundColor = color;
}

@end
