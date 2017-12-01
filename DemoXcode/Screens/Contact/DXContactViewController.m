//
//  DXContactViewController.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 11/20/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXContactViewController.h"
#import "DXContactsManager.h"
#import "DXContactModel.h"
#import "DXContactTableViewCell.h"
#import "DXContactsDetailViewController.h"
#import "SVPullToRefresh.h"

#define ContactTableViewCell @"ContactTableViewCell"

@interface DXContactViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) UILabel *noResultLabel;

@property (strong, nonatomic) UIBarButtonItem *closeBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *searchBarButtonItem;
@property (strong, nonatomic) UISearchBar *searchBar;
@property (strong, nonatomic) UIView *navTitleView;

@property (strong, nonatomic) NSMutableArray *originalData;
@property (strong, nonatomic) NSArray *displayData;
@property (strong, nonatomic) NSString *searchString;

@end

@implementation DXContactViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.originalData = [NSMutableArray new];
    [self setUpNavigationItems];
    [self setUpNoResultLabel];
    [self setUpTableView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - SetUp View

-(void)viewDidLayoutSubviews {
    
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsMake(0, 60, 0, 0)];
    }
    
    if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.tableView setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (void)setUpNavigationItems {
    
    self.title = @"All Contacts";
    
    self.closeBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(touchUpCloseBarButtonItem)];
    self.navigationItem.leftBarButtonItem = self.closeBarButtonItem;
    
    self.searchBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"item_search"] style:UIBarButtonItemStylePlain target:self action:@selector(touchUpSearchBarButtonItem)];
    self.navigationItem.rightBarButtonItem = self.searchBarButtonItem;
}

- (void)setUpTableView {
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableView];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 64;
    [self.tableView registerClass:[DXContactTableViewCell class] forCellReuseIdentifier:ContactTableViewCell];
    self.tableView.separatorColor = [UIColor colorWithWhite:0.85 alpha:1];
    self.tableView.tableHeaderView = [UIView new];
    self.tableView.tableFooterView = [UIView new];
    weakify(self);
    [self.tableView addPullToRefreshWithActionHandler:^{
        [self_weak_ reloadData];
    }];
    [self_weak_ reloadData];
    
    [self.tableView addInfiniteScrollingWithActionHandler:^{
        [self_weak_ loadMoreData];
    }];
}

- (void)setUpNoResultLabel {
    
    self.noResultLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1];
    self.noResultLabel.hidden = YES;
}

- (UISearchBar *)setUpSearchBar {
    
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
    searchBar.showsCancelButton = YES;
    searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    UITextField *searchField = [searchBar valueForKey:@"searchField"];
    searchField.clearButtonMode = UITextFieldViewModeWhileEditing;
    searchField.backgroundColor = [UIColor colorWithWhite:0.93 alpha:1.0];
    searchField.textColor = [UIColor blackColor];
    searchField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Search your friends"];
    UILabel *placeholderLabel = [searchField valueForKey:@"placeholderLabel"];
    placeholderLabel.textColor = [UIColor colorWithWhite:0.75 alpha:1.0];
    
    return searchBar;
}

- (void)displayNoResultlabel:(BOOL)display {
    
    [self.noResultLabel setHidden:!display];
}

- (void)displaySearchBar {
    
    if (!self.searchBar) {
        self.searchBar = [self setUpSearchBar];
    }
    
    if (!self.navTitleView) {
        self.navTitleView = self.navigationItem.titleView;
    }
    
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.rightBarButtonItem = nil;
    self.navigationItem.titleView = self.searchBar;
    self.searchBar.delegate = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.searchBar becomeFirstResponder];
    });
}

- (void)removeSearchBar {
    
    if ([self.searchBar isFirstResponder]) {
        [self.searchBar resignFirstResponder];
    }
    
    self.searchBar.delegate = nil;
    [self.searchBar removeFromSuperview];
    self.navigationItem.titleView = self.navTitleView;
    self.navigationItem.leftBarButtonItem = self.closeBarButtonItem;
    self.navigationItem.rightBarButtonItem = self.searchBarButtonItem;
}

#pragma mark - Action

- (void)touchUpCloseBarButtonItem {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)touchUpSearchBarButtonItem {
    
    [self displaySearchBar];
}

#pragma mark  - Private

- (void)reloadData {
    
    [self displayNoResultlabel:NO];
    [self.searchBar setText:nil];
    [self.originalData removeAllObjects];
    self.displayData = [NSArray new];
    [self.tableView reloadData];
    weakify(self);
    [sContactMngr loadMoreContactsFromIndex:0 count:50 withCompletionHandler:^(NSArray *contacts, NSError *error, BOOL isFinished) {
        if (contacts.count) {
            [self_weak_.originalData addObjectsFromArray:contacts];
            [self_weak_ filterWithKeyword:self_weak_.searchString];
            [self_weak_.tableView reloadData];
        }
        if (self_weak_.originalData.count == 0) {
            [self_weak_ displayNoResultlabel:YES];
        } else {
            [self_weak_ displayNoResultlabel:NO];
        }
        if(error) {
            self_weak_.noResultLabel.text = error.localizedFailureReason;
        } else {
            self_weak_.noResultLabel.text = @"No result";
        }
        [self_weak_.tableView.pullToRefreshView stopAnimating];
        [self_weak_.tableView.infiniteScrollingView setEnabled:!isFinished];
    } callBackQueue:dispatch_get_main_queue()];
}

-  (void)loadMoreData {
    
    weakify(self);
    [sContactMngr loadMoreContactsFromIndex:self.originalData.count count:20 withCompletionHandler:^(NSArray *contacts, NSError *error, BOOL isFinished) {
        [self_weak_ insertData:contacts];
        [self_weak_.tableView.infiniteScrollingView stopAnimating];
        [self_weak_.tableView.infiniteScrollingView setEnabled:!isFinished];
    } callBackQueue:dispatch_get_main_queue()];
}

- (void)insertData:(NSArray *)data {
    
    if (data.count == 0) {
        return;
    }
    
    [self.originalData addObjectsFromArray:data];
    [self filterWithKeyword:self.searchString];
    
    NSMutableArray *indexPaths = [NSMutableArray new];
    for (id obj in data) {
        NSInteger index = [self.displayData indexOfObject:obj];
        if (index != NSNotFound) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            [indexPaths addObject:indexPath];
        }
    }
    
    if (indexPaths.count > 0) {
        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)filterWithKeyword:(NSString *)keyword {
    
    NSArray *resArr;
    if (keyword.length == 0 || self.originalData.count == 0) {
        resArr = self.originalData.copy;
        
    } else {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"fullName CONTAINS[c] %@", keyword.lowercaseString];
        NSPredicate *compoundPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[predicate]];
         resArr = [self.originalData filteredArrayUsingPredicate:compoundPredicate];
    }
    
    self.displayData = [sApplication arrangeNonSectionedWithData:resArr];
}

- (void)displayContactModel:(DXContactModel *)contactModel {
    
    DXContactsDetailViewController *controller = [[DXContactsDetailViewController alloc] initWithContactModell:contactModel];
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark - TableView Datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.displayData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    DXContactTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ContactTableViewCell];
    DXContactModel *contactModel = [self.displayData objectAtIndex:indexPath.row];
    [cell displayContactModel:contactModel];
    return cell;
}

#pragma mark - Tableview Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.navigationItem.titleView == self.searchBar && self.searchString.length == 0) {
        [self removeSearchBar];
    } else {
        if ([self.searchBar isFirstResponder]) {
            [self.searchBar resignFirstResponder];
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    DXContactModel *contactModel = [self.displayData objectAtIndex:indexPath.row];
    [self displayContactModel:contactModel];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    
    if (self.navigationItem.titleView == self.searchBar && self.searchString.length == 0) {
        [self removeSearchBar];
    } else {
        if ([self.searchBar isFirstResponder]) {
            [self.searchBar resignFirstResponder];
        }
    }
}

#pragma mark - UISearchBar Delegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    
    self.searchString = searchText;
    [self filterWithKeyword:self.searchString];
    [self.tableView reloadData];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    
    [self removeSearchBar];
}

@end
