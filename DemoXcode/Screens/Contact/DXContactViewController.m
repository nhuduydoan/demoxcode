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

#define ContactTableViewCell @"ContactTableViewCell"

@interface DXContactViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) UILabel *noResultLabel;

@property (strong, nonatomic) UIBarButtonItem *closeBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *searchBarButtonItem;
@property (strong, nonatomic) UISearchBar *searchBar;
@property (strong, nonatomic) UIView *navTitleView;

@property (strong, nonatomic) NSArray *originalData;
@property (strong, nonatomic) NSArray *displayData;
@property (strong, nonatomic) NSString *searchString;

@end

@implementation DXContactViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self setUpNavigationItems];
    [self setUpNoResultLabel];
    [self setUpTableView];
    [self getAllContacts];
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

- (void)getAllContacts {
    
    weakify(self);
    [sContactMngr getAllContactsWithCompletion:^(NSArray *contacts) {
        if (contacts.count == 0) {
            [self_weak_ displayNoResultlabel:YES];
        } else {
            [self_weak_ displayNoResultlabel:NO];
        }
        self_weak_.originalData = contacts.copy;
        [self_weak_ searchWithKeyword:self.searchString];
    }];
}

- (void)searchWithKeyword:(NSString *)keyword {
    
    NSArray *resArr;
    if (keyword.length == 0 || self.originalData.count == 0) {
        resArr = self.originalData.copy;
        
    } else {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"fullName CONTAINS[c] %@", keyword.lowercaseString];
        NSPredicate *compoundPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[predicate]];
         resArr = [self.originalData filteredArrayUsingPredicate:compoundPredicate];
    }
    
    self.displayData = [sApplication arrangeNonSectionedWithData:resArr];;
    [self.tableView reloadData];
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
    [self searchWithKeyword:self.searchString];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    
    [self removeSearchBar];
}

@end
