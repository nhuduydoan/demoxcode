//
//  DXShowPickedCollectionViewCell.h
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 11/23/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NimbusCollections.h"
@class DXContactModel;

@interface DXShowPickedCollectionViewCellObject : NSObject <NICollectionViewNibCellObject>

- (instancetype)initWithModel:(id)model;

@end


@interface DXShowPickedCollectionViewCell : UICollectionViewCell 

- (void)displayContactModel:(DXContactModel *)model;

@end
