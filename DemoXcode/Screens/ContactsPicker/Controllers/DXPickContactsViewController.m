//
//  DXPickContactsViewController.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 11/22/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXPickContactsViewController.h"
#import "DXContactModel.h"
#import "DXPickContactTableViewCell.h"
#import "NimbusModels.h"

#define PickContactCell @"PickContactCell"

@interface DXPickContactsViewController () <NIMutableTableViewModelDelegate>

@property (nonatomic, retain) NIMutableTableViewModel *tableviewModel;
@property (nonatomic, retain) NITableViewActions *actions;

@property (strong, nonatomic) NSArray *data;

@end

@implementation DXPickContactsViewController

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
    
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    self.tableView.editing = YES;
    self.tableView.rowHeight = 64;
    self.tableView.tableFooterView = [UIView new];
}

- (void)setUpSectionedTableViewModelWithData:(NSArray *)data {
    
    NSArray *arrangedData = [self arrangeSectionedWithData:data];
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
    self.tableviewModel = [[NIMutableTableViewModel alloc] initWithSectionedArray:tableViewData delegate:self];
    [self.tableviewModel setSectionIndexType:NITableViewModelSectionIndexDynamic
                                 showsSearch:(arrangedData.count > 0)
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
                [self_weak_.delegate pickContactsViewController:self_weak_ didSelectModel:model];
            }
            return NO;
        }];
    }
    self.tableView.delegate = [self.actions forwardingTo:self];
}

#pragma mark - Public

- (void)reloadWithData:(NSArray *)data {
    
    [self setUpSectionedTableViewModelWithData:data];
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

- (NSArray *)arrangeSectionedWithData:(NSArray *)data {
    
    if (data.count == 0) {
        return [NSArray new];
    }
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"fullName" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    NSArray *sortedArray = [data sortedArrayUsingDescriptors:@[sortDescriptor]];
    
    NSMutableArray *arrangedData = [NSMutableArray new];
    NSMutableArray *sharpArray = [NSMutableArray new];
    NSInteger count = sortedArray.count;
    NSCharacterSet *letters = [NSCharacterSet letterCharacterSet];
    NSString *groupKey = @"";
    
    for (NSInteger i = 0; i < count; i ++) {
        DXContactModel *contact = sortedArray[i];
        NSString *name = [contact.fullName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (name.length == 0) {
            [sharpArray addObject:contact];
        } else {
            unichar firstChar = [name characterAtIndex:0];
            if (![letters characterIsMember:firstChar]) {
                // If first letter is not alphabet
                [sharpArray addObject:contact];
            } else {
                NSString *firstKey = [name substringToIndex:1].uppercaseString;
                if (![firstKey isEqualToString:groupKey]) {
                    // If First Key is new key
                    groupKey = firstKey;
                    [arrangedData addObject:groupKey];
                }
                [arrangedData addObject:contact];
            }
        }
    }
    
    if (sharpArray.count > 0) {
        [arrangedData addObject:@"#"];
        [arrangedData addObjectsFromArray:sharpArray];
    }
    
    return arrangedData;
}

- (id)objectAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger section = indexPath.section + 1;
    for (id obj in self.data) {
        if ([obj isKindOfClass:[NSString class]]) {
            section -= 1;
        }
        if (section == 0) {
            NSInteger index = [self.data indexOfObject:obj] + 1 + indexPath.row;
            return self.data[index];
        }
    }
    return nil;
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
    NICellObject *cellObject = [self objectAtIndexPath:indexPath];
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
