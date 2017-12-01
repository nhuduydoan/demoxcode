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

@property (strong, nonatomic) NSMutableArray *tableviewData;
@property (strong, nonatomic) NSMutableArray *originalData;

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
    
    NSArray *arrangedData = [sApplication arrangeSectionedWithData:data];
    NSMutableArray *tableViewData = [self tableviewDataFromData:arrangedData];
    self.tableviewData = tableViewData;
    self.tableviewModel = [[NIMutableTableViewModel alloc] initWithSectionedArray:tableViewData delegate:self];
    [self.tableviewModel setSectionIndexType:NITableViewModelSectionIndexDynamic
                                 showsSearch:(tableViewData.count > 0)
                                showsSummary:NO];
    
    self.tableView.dataSource = self.tableviewModel;
    [self setUpTableViewActionsWithData:tableViewData];
    [self.tableView reloadData];
    [self checkSelectedWithData:tableViewData];
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

#pragma mark - Public

- (void)reloadWithData:(NSArray *)data {
    
    self.originalData = data.mutableCopy;
    [self setUpSectionedTableViewModelWithData:data];
}

- (void)insertNewData:(NSArray *)data {
    
    if (data.count == 0) {
        return;
    }
    
    [self.originalData addObjectsFromArray:data];
    NSArray *sectionsArr = [sApplication sectionsArraySectionedWithData:data];
    NSArray *arrangedData = [sApplication arrangeSectionedWithData:self.originalData];
    
    for (NSArray *array in sectionsArr) {
        
        NSString *sectionTitle = array.firstObject;
        BOOL exist = [self indexOfSection:sectionTitle inData:self.tableviewData] != NSNotFound;
        NSInteger section = [self indexOfSection:sectionTitle inData:arrangedData];
        if (!exist) {
            if (section != NSNotFound) {
                [self.tableviewModel insertSectionWithTitle:sectionTitle atIndex:section];
                [self.tableView insertSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:UITableViewRowAnimationFade];
            }
        }
        NSInteger sectionPos = [arrangedData indexOfObject:sectionTitle];
        if (section != NSNotFound) {
            NSMutableArray *indexPaths = [NSMutableArray new];
            for (NSInteger i = 1; i < array.count; i++) {
                id model = array[i];
                NSInteger index = [arrangedData indexOfObject:model];
                NSInteger rowIdnex = index - sectionPos - 1;
                NICellObject *cellObject = [NICellObject objectWithCellClass:[DXPickContactTableViewCell class] userInfo:model];
                NSArray *paths = [self.tableviewModel insertObject:cellObject atRow:rowIdnex inSection:section];
                [indexPaths addObjectsFromArray:paths];
            }
            [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationBottom];
        }
        
    }
    
    self.tableviewData = [self tableviewDataFromData:arrangedData];
    [self.tableviewModel updateSectionIndex];
}

- (NSInteger)indexOfSection:(NSString *)section inData:(NSArray *)data {
    
    NSInteger index = 0;
    for (id obj in data) {
        if ([obj isKindOfClass:[NSString class]]) {
            if ([obj isEqualToString:section]) {
                return index;
            }
            index += 1;
        }
    }
    return NSNotFound;
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

- (NSMutableArray *)tableviewDataFromData:(NSArray *)data {
    
    NSMutableArray *tableViewData = [NSMutableArray new];
    for (id model in data) {
        if (![model isKindOfClass:[NSString class]]) {
            NICellObject *cellObject = [NICellObject objectWithCellClass:[DXPickContactTableViewCell class] userInfo:model];
            [tableViewData addObject:cellObject];
        } else {
            [tableViewData addObject:model];
        }
    }
    return tableViewData;
}

- (id)cellObjectForModel:(id)model {
    
    for (NICellObject *object in self.tableviewData) {
        if ([object isKindOfClass:[NICellObject class]] && [object.userInfo isEqual:model]) {
            return object;
        }
    }
    return nil;
}

- (BOOL)didSelectObject:(id)object atIndexPath:(NSIndexPath *)indexPath {
    
    id model = [object userInfo];
    if ([self.delegate respondsToSelector:@selector(pickContactsViewController:didSelectModel:)]) {
        BOOL isSelected = [self.delegate pickContactsViewController:self didSelectModel:model];
        return !isSelected;
    }
    return YES;
}

#pragma mark - NITableViewModelDelegate

- (UITableViewCell *)tableViewModel:(NITableViewModel *)tableViewModel cellForTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath withObject:(id)object {
    return [NICellFactory tableViewModel:tableViewModel cellForTableView:tableView atIndexPath:indexPath withObject:object];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    NSString *sectionTitle = [self.tableviewModel tableView:tableView titleForHeaderInSection:section];
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
    
    id cellObject = [self.tableviewModel objectAtIndexPath:indexPath];
    id model = [cellObject userInfo];
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
