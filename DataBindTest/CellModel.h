//
//  CellModel.h
//  DataBindTest
//
//  Created by GevinChen on 2015/9/26.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import "DataBinder.h"

@interface CellModel : DataBinder

@property (nonatomic) float height;
@property (nonatomic) id dataModel;
@property (nonatomic) NSString* identifier;
@property (nonatomic) NSString* nibName;
@property (nonatomic) NSIndexPath* index;

// 為了讓 controller 邏輯乾淨，cell定義還是放在 cellModel 裡吧
- (void)cellConfig:(UITableViewCell*)cell index:(NSIndexPath*)index;


@end