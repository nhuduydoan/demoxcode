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

@interface DXShowPickedViewController () <UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NIMutableCollectionViewModel *collectionViewModel;

@property (strong, nonatomic) NSMutableArray *data;

@end

@implementation DXShowPickedViewController

- (id)init {
    self = [super init];
    if (self) {
        [self setupCollectionViewModel];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self setupCollectionView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - SetUp View {

- (void)setupCollectionViewModel {
    
    self.data = [NSMutableArray new];
    NSMutableArray *tableViewData = [NSMutableArray new];
    for (id model in self.data) {
//        NICollectionViewCellObject *object = [NICollectionViewCellObject objectWithCellClass:[DXShowPickedCollectionViewCell class] userInfo:model];
        DXShowPickedCollectionViewCellObject *obj = [[DXShowPickedCollectionViewCellObject alloc] initWithModel:model];
        [tableViewData addObject:obj];
    }
    self.collectionViewModel = [[NIMutableCollectionViewModel alloc] initWithListArray:tableViewData delegate:(id)[NICollectionViewCellFactory class]];
    [self.collectionView reloadData];
}

- (void)setupCollectionView {
    
    self.collectionView.dataSource = self.collectionViewModel;
    self.collectionView.delegate = self;
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.contentInset = UIEdgeInsetsMake(0, 8, 0, 8);
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
//    NICollectionViewCellObject *object = [NICollectionViewCellObject objectWithCellClass:[DXShowPickedCollectionViewCell class] userInfo:model];
    DXShowPickedCollectionViewCellObject *obj = [[DXShowPickedCollectionViewCellObject alloc] initWithModel:model];
    NSArray *indexPaths = [self.collectionViewModel addObject:obj];
    [self.collectionView insertItemsAtIndexPaths:indexPaths];
}

- (void)removePickedModel:(id)model {
    
    if (self.data.count == 0) {
        return;
    }
    
    [self.data removeObject:model];
    NSInteger index = [self.data indexOfObject:model];
    if (index != NSNotFound) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        NSArray *indexPaths = [self.collectionViewModel removeObjectAtIndexPath:indexPath];
        [self.collectionView deleteItemsAtIndexPaths:indexPaths];
        [self.collectionView reloadData];
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
