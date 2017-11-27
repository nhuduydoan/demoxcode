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
    
    self.tableView.separatorColor = [UIColor colorWithRed:223/255.f green:226/255.f blue:227/255.f alpha:1];
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsMake(0, 100, 0, 0)];
    }
    if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.tableView setLayoutMargins:UIEdgeInsetsZero];
    }
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
    [self.tableView reloadData];
    
    if ([self.delegate respondsToSelector:@selector(pickContactsViewController:isSelectedModel:)]) {
        for (id obj  in tableViewData) {
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

- (void)setUpTableViewActionsWithData:(NSArray *)data {
    
    self.actions = [[NITableViewActions alloc] initWithTarget:self];
    for (id obj in data) {
        if ([obj isKindOfClass:[NSString class]]) {
            continue;
        }
        [self.actions attachToObject:obj tapSelector:@selector(didSelectObject:atIndexPath:)];
    }
    self.tableView.delegate = [self.actions forwardingTo:self];
}

- (BOOL)didSelectObject:(id)object atIndexPath:(NSIndexPath *)indexPath {
    
    id model = [object userInfo];
    if ([self.delegate respondsToSelector:@selector(pickContactsViewController:didSelectModel:)]) {
        BOOL isSelected = [self.delegate pickContactsViewController:self didSelectModel:model];
        return !isSelected;
    }
    return YES;
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
    
    NSMutableArray *alphabetArray = [NSMutableArray new];
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
                    [alphabetArray addObject:groupKey];
                }
                [alphabetArray addObject:contact];
            }
        }
    }
    
    if (sharpArray.count > 0) {
        [sharpArray insertObject:@"#" atIndex:0];
        [sharpArray addObjectsFromArray:alphabetArray];
    }
    
    return sharpArray;
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

- (NSString *)titleForSection:(NSInteger)section {
    
    NSInteger index = 0;
    for (id obj in self.data) {
        if ([obj isKindOfClass:[NSString class]]) {
            if (index == section) {
                return obj;
            } else {
                index += 1;
            }
        }
    }
    return nil;
}

#pragma mark - NITableViewModelDelegate

- (UITableViewCell *)tableViewModel:(NITableViewModel *)tableViewModel cellForTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath withObject:(id)object {
    return [NICellFactory tableViewModel:tableViewModel cellForTableView:tableView atIndexPath:indexPath withObject:object];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    NSString *sectionTitle = [self titleForSection:section];
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 10)];
    view.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.9];
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 20, 10)];
    
    titleLabel.text = sectionTitle;
    titleLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    [view addSubview:titleLabel];
    return view;
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
