//
//  DXShowPickedViewController.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 11/23/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXShowPickedViewController.h"
#import "DXShowPickedCollectionViewCell.h"
#import "DXContactModel.h"
#import "NimbusCollections.h"

#define ShowPickedCell @"ShowPickedCell"

@interface DXShowPickedViewController () <UICollectionViewDelegate>

@property (strong, nonatomic) UICollectionView *collectionView;
@property (nonatomic, strong) NIMutableCollectionViewModel *collectionViewModel;
@property (nonatomic, retain) NICollectionViewActions *actions;

@property (strong, nonatomic) NSMutableArray *data;

@end

@implementation DXShowPickedViewController

- (id)init {
    self = [super init];
    if (self) {
        [self setupCollectionViewModel];
        [self setupCollectionView];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - SetUp View {

- (void)setupCollectionViewModel {
    
    self.actions = [[NICollectionViewActions alloc] initWithTarget:self];
    self.data = [NSMutableArray new];
    NSMutableArray *tableViewData = [NSMutableArray new];
    weakify(self);
    for (id model in self.data) {
        DXShowPickedCollectionViewCellObject *obj = [[DXShowPickedCollectionViewCellObject alloc] initWithModel:model];
        [tableViewData addObject:obj];
        
        [self.actions attachToObject:obj tapBlock:^BOOL(id object, id target, NSIndexPath *indexPath) {
            id model = [object userInfo];
            if ([self_weak_.delegate respondsToSelector:@selector(showPickedViewController:didSelectModel:)]) {
                [self_weak_.delegate showPickedViewController:self_weak_ didSelectModel:model];
            }
            return NO;
        }];
    }
    self.collectionViewModel = [[NIMutableCollectionViewModel alloc] initWithListArray:tableViewData delegate:(id)[NICollectionViewCellFactory class]];
}

- (void)setupCollectionView {
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(46, 46);
    layout.minimumInteritemSpacing = 8;
    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
    self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.collectionView setBackgroundColor:[UIColor clearColor]];
    [self.view addSubview:self.collectionView];
    
    self.collectionView.dataSource = self.collectionViewModel;
    self.collectionView.delegate = self;
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.contentInset = UIEdgeInsetsMake(0, 8, 0, 8);
    [self.collectionView reloadData];
}

#pragma mark - Public

- (NSArray *)pickedModels {
    return self.data.copy;
}

- (BOOL)isPickedModel:(id)model {
    return [self.data containsObject:model];
}

- (void)addPickedModel:(id)model {
    
    if ([self.data containsObject:model]) {
        return;
    }
    
    [self.data addObject:model];
    DXShowPickedCollectionViewCellObject *obj = [[DXShowPickedCollectionViewCellObject alloc] initWithModel:model];
    NSArray *indexPaths = [self.collectionViewModel addObject:obj];
    [self.collectionView insertItemsAtIndexPaths:indexPaths];
}

- (void)removePickedModel:(id)model {
    
    if (self.data.count == 0) {
        return;
    }
    
    NSInteger index = [self.data indexOfObject:model];
    if (index != NSNotFound) {
        [self.data removeObject:model];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        NSArray *indexPaths = [self.collectionViewModel removeObjectAtIndexPath:indexPath];
        [self.collectionView deleteItemsAtIndexPaths:indexPaths];
    }
}

#pragma mark - UICollectionView Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    id model = [self.data objectAtIndex:indexPath.row];
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    if ([self.delegate respondsToSelector:@selector(showPickedViewController:didSelectModel:)]) {
        [self.delegate showPickedViewController:self didSelectModel:model];
    }
}

@end
