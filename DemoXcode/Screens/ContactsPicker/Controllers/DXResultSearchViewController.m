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
}

- (void)setUpNonSectionedTableViewModelWithData:(NSArray *)data {
    
    NSArray *arrangedData = [self arrangeNonSectionedWithData:data];
    NSMutableArray *tableViewData = [NSMutableArray new];
    for (id model in arrangedData) {
        if (![model isKindOfClass:[NSString class]]) {
            NICellObject *cellObject = [NICellObject objectWithCellClass:[DXPickContactTableViewCell class] userInfo:model];
            [tableViewData addObject:cellObject];
        } else {
            [tableViewData addObject:model];
        }
    }
    
    self.data = tableViewData;
    self.tableviewModel = [[NIMutableTableViewModel alloc] initWithListArray:tableViewData delegate:self];
    [self.tableviewModel setSectionIndexType:NITableViewModelSectionIndexNone
                                 showsSearch:NO
                                showsSummary:NO];
    
    self.tableView.dataSource = self.tableviewModel;
    [self setUpTableViewActionsWithData:tableViewData];
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
            if ([self_weak_.delegate respondsToSelector:@selector(pickContactsViewController:didSelectModel:)]) {
                [self_weak_.delegate pickContactsViewController:self didSelectModel:model];
            }
            return NO;
        }];
    }
    self.tableView.delegate = [self.actions forwardingTo:self];
}

#pragma mark - Public

- (void)reloadWithData:(NSArray *)data {
    
    [self setUpNonSectionedTableViewModelWithData:data];
    [self.tableView reloadData];
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

- (NSArray *)arrangeNonSectionedWithData:(NSArray *)data {
    
    if (data.count == 0) {
        return [NSArray new];
    }
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"fullName" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    NSArray *sortedArray = [data sortedArrayUsingDescriptors:@[sortDescriptor]];
    
    NSMutableArray *alphabetArray = [NSMutableArray new];
    NSMutableArray *sharpArray = [NSMutableArray new];
    NSCharacterSet *letters = [NSCharacterSet letterCharacterSet];
    
    for (DXContactModel *contact in sortedArray) {
        NSString *name = [contact.fullName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (name.length == 0) {
            [sharpArray addObject:contact];
        } else {
            unichar firstChar = [name characterAtIndex:0];
            if ([letters characterIsMember:firstChar]) {
                // If first letter is alphabet
                [alphabetArray addObject:contact];
            } else {
                // If first letter is not alphabet
                [sharpArray addObject:contact];
            }
        }
    }
    
    if (sharpArray.count > 0) {
        [alphabetArray addObjectsFromArray:sharpArray];
    }
    return alphabetArray;
}

#pragma mark - NITableViewModelDelegate

- (UITableViewCell *)tableViewModel:(NITableViewModel *)tableViewModel cellForTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath withObject:(id)object {
    UITableViewCell *cell = [NICellFactory tableViewModel:tableViewModel cellForTableView:tableView atIndexPath:indexPath withObject:object];
    if ([self.delegate respondsToSelector:@selector(pickContactsViewController:isSelectedModel:)]) {
        BOOL isSelected = [self.delegate pickContactsViewController:self isSelectedModel:[object userInfo]];
        if (isSelected) {
            [tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        }
    }
    return cell;
}

#pragma mark - NIMutableTableViewModelDelegate

- (BOOL)tableViewModel:(NIMutableTableViewModel *)tableViewModel canEditObject:(id)object atIndexPath:(NSIndexPath *)indexPath inTableView:(UITableView *)tableView {
    return YES;
}

#pragma mark - UITableView Delegate

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    NICellObject *cellObject = [self.data objectAtIndex:indexPath.row];
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

@end
