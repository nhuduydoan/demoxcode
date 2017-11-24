//
//  DXInviteFriendsViewController.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 11/23/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXInviteFriendsViewController.h"
#import "DXContactsManager.h"
#import "DXContactModel.h"
#import "DXShowPickedViewController.h"
#import "DXPickContactsViewController.h"
#import "DXResultSearchViewController.h"

@interface DXInviteFriendsViewController () <UISearchBarDelegate, DXPickContactsViewControllerDelegate, DXShowPickedViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UIView *contentView;

@property (strong, nonatomic) UISearchBar *searchBar;
@property (strong, nonatomic) DXShowPickedViewController *showPickedViewController;
@property (strong, nonatomic) DXPickContactsViewController *pickContactsViewController;
@property (strong, nonatomic) DXResultSearchViewController *searchResultViewController;

@property (strong, nonatomic) NSArray *originalData;

@end

@implementation DXInviteFriendsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.originalData = [NSArray new];
    [self setupNavigationBarItems];
    [self setupHeaderView];
    [self setupPickContactsViewController];
    [self setupSearchResultViewController];
    [self getAllContactsData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - SetUp View

- (void)setupNavigationBarItems {
    
    self.title = @"Invite Friends";
    self.navigationController.navigationBar.translucent = NO;
    UIBarButtonItem *closeBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(touchUpCloseBarButtonItem)];
    self.navigationItem.leftBarButtonItem = closeBarButtonItem;
}

- (void)setupHeaderView {
    
    self.headerView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1];
    self.showPickedViewController = [DXShowPickedViewController new];
    [self setUpSearchBar];
}

- (void)setUpSearchBar {
    
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, self.headerView.bounds.size.height - 40, self.view.bounds.size.width, 40)];
    searchBar.delegate = self;
    searchBar.backgroundImage = [UIImage new];
    searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    
    UITextField *searchField = [searchBar valueForKey:@"searchField"];
    searchField.clearButtonMode = UITextFieldViewModeWhileEditing;
    searchField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Search your friends"];
    UILabel *placeholderLabel = [searchField valueForKey:@"placeholderLabel"];
    placeholderLabel.textColor = [UIColor colorWithWhite:0.75 alpha:1.0];
    
    [self.headerView addSubview:searchBar];
    self.searchBar = searchBar;
}

- (void)setupPickContactsViewController {
    
    DXPickContactsViewController *controller = [[DXPickContactsViewController alloc] init];
    controller.delegate = self;
    [self addChildViewController:controller];
    [controller didMoveToParentViewController:self];
    controller.view.frame = self.contentView.bounds;
    controller.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.contentView insertSubview:controller.view atIndex:0];
    self.pickContactsViewController = controller;
}

- (void)setupSearchResultViewController {
    
    DXResultSearchViewController *controller = [[DXResultSearchViewController alloc] init];
    controller.delegate = self;
    self.searchResultViewController = controller;
}

- (void)displaySearchResultViewController:(BOOL)isShow {
    
    if (isShow) {
        [self addChildViewController:self.searchResultViewController];
        [self.searchResultViewController didMoveToParentViewController:self];
        self.searchResultViewController.view.frame = self.contentView.bounds;
        self.searchResultViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.contentView addSubview:self.searchResultViewController.view];
        
    } else {
        [self.searchResultViewController removeFromParentViewController];
        [self.searchResultViewController didMoveToParentViewController:nil];
        [self.searchResultViewController.view removeFromSuperview];
    }
}

- (void)displayShowPickedViewController:(BOOL)isShow {
    
    CGRect headerFrame = self.headerView.frame;
    CGRect contentFrame = self.contentView.frame;
    if (isShow) {
        headerFrame = CGRectMake(0, 0, self.view.bounds.size.width, 94);
    } else {
        headerFrame = CGRectMake(0, 0, self.view.bounds.size.width, 40);
    }
    contentFrame = CGRectMake(0, headerFrame.size.height, self.view.bounds.size.width, self.view.bounds.size.height - headerFrame.size.height);
    
    [UIView animateWithDuration:0.2 animations:^{
        self.headerView.frame = headerFrame;
        self.contentView.frame = contentFrame;
    } completion:^(BOOL finished) {
        self.headerView.frame = headerFrame;
        self.contentView.frame = contentFrame;
        if (isShow) {
            [self addChildViewController:self.showPickedViewController];
            [self.showPickedViewController didMoveToParentViewController:self];
            self.showPickedViewController.view.frame = CGRectMake(0, 6, self.headerView.bounds.size.width, 48);
            self.showPickedViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [self.headerView insertSubview:self.showPickedViewController.view atIndex:0];
        } else {
            [self.showPickedViewController removeFromParentViewController];
            [self.showPickedViewController didMoveToParentViewController:nil];
            [self.showPickedViewController.view removeFromSuperview];
        }
    }];
}

#pragma mark - Private

- (void)getAllContactsData {
    
    weakify(self);
    [sContactMngr getAllContactsWithCompletion:^(NSArray *contacts) {
        self_weak_.originalData = contacts.copy;
        [self_weak_.pickContactsViewController reloadWithData:contacts];
    }];
}

- (void)searchWithKeyWord:(NSString *)keyword {
    
    if (keyword.length == 0) {
        [self displaySearchResultViewController:NO];
        return;
    }
    
    if (!self.searchResultViewController.view.window) {
        // If SearchResultViewController is not displayed, display it
        [self displaySearchResultViewController:YES];
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"fullName CONTAINS[c] %@", keyword.lowercaseString];
    NSPredicate *compoundPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[predicate]];
    NSArray *resArr = [self.originalData filteredArrayUsingPredicate:compoundPredicate];
    [self.searchResultViewController reloadWithData:resArr];
}

- (BOOL)isSelectedModel:(id)model {
    return [self.showPickedViewController isPickedModel:model];
}

- (void)selectModel:(id)model {
    
    [self.showPickedViewController addPickedModel:model];
    [self.pickContactsViewController didSelectModel:model];
    [self.searchResultViewController didSelectModel:model];
    if (self.showPickedViewController.pickedModels.count == 1) {
        [self displayShowPickedViewController:YES];
    }
}

- (void)deSelectModel:(id)model {
    
    [self.showPickedViewController removePickedModel:model];
    [self.pickContactsViewController deSelectModel:model];
    [self.searchResultViewController deSelectModel:model];
    if (self.showPickedViewController.pickedModels.count == 0) {
        [self displayShowPickedViewController:NO];
    }
}

- (void)hideKeyBoard {
    
    if ([self.searchBar isFirstResponder]) {
        [self.searchBar resignFirstResponder];
    }
}

#pragma mark - Action

- (void)touchUpCloseBarButtonItem {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UISearchBar Delegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self searchWithKeyWord:searchText];
}

#pragma mark - DXPickContactsViewControllerDelegate

- (BOOL)pickContactsViewController:(DXPickContactsViewController *)controller isSelectedModel:(id)model {
    return [self isSelectedModel:model];
}

- (void)pickContactsViewController:(DXPickContactsViewController *)controller didSelectModel:(id)model {
    
    [self selectModel:model];
    [self hideKeyBoard];
}

- (void)pickContactsViewController:(DXPickContactsViewController *)controller didDeSelectModel:(id)model {
    [self deSelectModel:model];
    [self hideKeyBoard];
}

- (void)didTapOnPickContactsViewController:(DXPickContactsViewController *)controller {
    [self hideKeyBoard];
}

#pragma mark - DXShowPickedViewControllerDelegate

- (void)showPickedViewController:(DXShowPickedViewController *)controller didSelectModel:(id)model {
    [self.pickContactsViewController scrollToContactModel:model];
}

@end
