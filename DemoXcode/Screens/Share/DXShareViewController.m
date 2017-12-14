//
//  DXShareViewController.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/13/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXShareViewController.h"
#import "DXConversationModel.h"
#import "DXConversationTableViewCell.h"
#import "DXConversationManager.h"
#import "DXShareSearchResultViewController.h"
#import "DXImageManager.h"
#import "DXInviteFriendsViewController.h"

NSString* const kShareFriendViewCell = @"kShareFriendViewCell";

@interface DXShareViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating, DXShareSearchResultViewControllerDelegate>

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) UIView *sectionHeaderView;

@property (strong, nonatomic) UISearchController *searchController;
@property (strong, nonatomic) DXShareSearchResultViewController *searchResultViewController;

@property (strong, nonatomic) NSArray *data;

@end

@implementation DXShareViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupNavigationItems];
    [self setupViews];
    [self getAllData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setup Views

//- (UIStatusBarStyle)preferredStatusBarStyle {
//    return UIStatusBarStyleLightContent;
//}

- (void)setupNavigationItems {
    self.title = @"Chia sẻ";
    UIBarButtonItem *closeBarItem = [[UIBarButtonItem alloc]
                                     initWithTitle:@"Huỷ"
                                     style:UIBarButtonItemStylePlain
                                     target:self action:@selector(touchUpInsideCloseBarItem)];
    self.navigationItem.leftBarButtonItem = closeBarItem;
    self.navigationController.navigationBar.translucent = NO;
}

- (void)setupViews {
    [self setupTableView];
    [self setupSearchController];
    
    self.tableView.backgroundColor = [UIColor clearColor];
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)setupSearchController {
    self.searchResultViewController = [[DXShareSearchResultViewController alloc] init];
    self.searchResultViewController.delegate = self;
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:self.searchResultViewController];
    self.searchController.searchResultsUpdater = self;
    self.searchController.delegate = self;
    self.searchController.dimsBackgroundDuringPresentation = YES; // default is YES
    self.tableView.tableHeaderView = self.searchController.searchBar;
    [self setupSearchBar:self.searchController.searchBar];
    self.definesPresentationContext = YES;
}

- (void)setupSearchBar:(UISearchBar *)searchBar {
    
    searchBar.delegate = self;
    [searchBar sizeToFit];
    searchBar.translucent = NO;
    
    searchBar.placeholder = @"Tìm kiếm";
    UITextField *searchTextField = [searchBar valueForKey:@"searchField"];
    searchTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [searchBar setValue:@"Huỷ" forKey:@"_cancelButtonText"];
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableView];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.tableFooterView = [UIView new];
    self.tableView.rowHeight = 72;
    self.tableView.separatorColor = [UIColor colorWithRed:223/255.f green:226/255.f blue:227/255.f alpha:1];
    [self.tableView setLayoutMargins:UIEdgeInsetsZero];
    [self.tableView setSeparatorInset:UIEdgeInsetsMake(0, 66, 0, 0)];
}

#pragma mark - Private

- (void)touchUpInsideCloseBarItem {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)getAllData {
    weakify(self);
    [[DXConversationManager shareInstance] getAllConversationsWithCompletionHandler:^(NSArray *result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            selfWeak.data = result.copy;
            [selfWeak.tableView reloadData];
        });
    }];
}

- (void)hideKeyBoardScreen {
    if ([self.searchController.searchBar isFirstResponder]) {
        [self.searchController.searchBar resignFirstResponder];
    }
}

- (void)displaySelectMultiFriendsViewController {
    NSArray *contacts = [[DXConversationManager shareInstance] getContactsArray];
    DXInviteFriendsViewController *controller = [[DXInviteFriendsViewController alloc] initWithContactsArray:contacts];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)didSelectConversation:(DXConversationModel *)model {
    
    NSString *message = model.displayName;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Share to conversation" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)searchWithKeyWord:(NSString *)keyword {
    if (keyword.length == 0) {
        return;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"displayName CONTAINS[c] %@", keyword.lowercaseString];
    NSPredicate *compoundPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[predicate]];
    NSArray<DXConversationModel *> *resArr = [self.data filteredArrayUsingPredicate:compoundPredicate];
    [self.searchResultViewController reloadWithData:resArr];
}

#pragma mark - TableView Datasouce

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    }
    return self.data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DXConversationTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell == nil) {
        cell = [[DXConversationTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kShareFriendViewCell];
    }
    
    if (indexPath.section == 0) {
        UIImage *friendImage = [UIImage imageNamed:@"icon_friend"];
        [cell displayString:@"Chia sẻ cho nhiều bạn" image:friendImage];
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    } else {
        DXConversationModel *model = [self.data objectAtIndex:indexPath.row];
        [cell displayConversation:model];
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
    
    return cell;
}

#pragma mark - TableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0) { // Touch in cell : "Chia sẻ cho nhiều bạn"
        [self displaySelectMultiFriendsViewController];
        return;
    }
    
    id model = [self.data objectAtIndex:indexPath.row];
    [self didSelectConversation:model];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
//    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
//        [cell setSeparatorInset:UIEdgeInsetsMake(0, cell.bounds.size.width, 0, 0)];
//    }
//
//    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
//        [cell setLayoutMargins:UIEdgeInsetsZero];
//    }
    
    if (indexPath.row == 0 && indexPath.section == 1) {
        NSLog(@"Cell Sub views:");
        for (UIView *subView in cell.subviews) {
//            if ([subView isKindOfClass:NSClassFromString(@"_UITableViewCellSeparatorView")]) {
//                NSLog(@"%@", NSStringFromClass([subView class]));
//            }
            NSLog(@"%@", NSStringFromClass([subView class]));
            
            NSLog(@"Subs views of subview:");
            for (UIView *view in subView.subviews) {
                NSLog(@"%@", NSStringFromClass([view class]));
            }
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return 0;
    }
    return 22;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.001;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return nil;
    }
    
    if (self.sectionHeaderView == nil) {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 22)];
        view.backgroundColor = [UIColor whiteColor];
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(12, 0, view.bounds.size.width, 22)];
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        label.textColor = [UIColor colorWithRed:103/255.f green:116/255.f blue:129/255.f alpha:1];
        label.font = [UIFont systemFontOfSize:15];
        label.text = @"Trò chuyện gần đây";
        [view addSubview:label];
        self.sectionHeaderView = view;
    }
    
    return self.sectionHeaderView;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return nil;
}

#pragma mark - UISearchController Delegates

- (void)willPresentSearchController:(UISearchController *)searchController {
    self.navigationController.navigationBar.translucent = YES;
}

- (void)willDismissSearchController:(UISearchController *)searchController {
    self.navigationController.navigationBar.translucent = NO;
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *keyword = searchController.searchBar.text;
    [self searchWithKeyWord:keyword];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

#pragma mark - DXShareSearchResultViewController Delegate

- (void)shareSearchResultViewController:(UIViewController *)viewController didSelectModel:(id)model {
    [self didSelectConversation:model];
}

- (void)shareSearchResultViewControllerWillBeginDragging:(UIViewController *)viewController {
    [self hideKeyBoardScreen];
}

@end
