//
//  KHBindManage.h
//  KHDataBindingDemo
//
//  Created by GevinChen on 2017/3/16.
//  Copyright © 2017年 omg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KHCell.h"

@class KHCollectionView;
@class KHTableView;

@interface KHPairManager : NSObject
{
    //  記錄 cell - model 介接物件，linker 的數量會跟 model 一樣
    NSMutableDictionary *_pairDic;
}

@property (nonatomic,weak,nullable) KHCollectionView *collectionView;
@property (nonatomic,weak,nullable) KHTableView *tableView;

#pragma mark - Pair Info

- (void)pairWithModel:(id _Nonnull)model;

//  取得某個 model 的 cell 介接物件
- (nullable KHPairInfo*)getPairInfo:(id _Nonnull)model;

- (void) removePairInfo:(id _Nonnull)model;

- (void) replacePairInfo:(id _Nonnull)oldModel new:(id _Nonnull)newModel;


#pragma mark - Cell Size

- (CGSize)getCellSizeFor:(id _Nonnull)model;

- (void)setCellSize:(CGSize)cellSize model:(id _Nonnull)model;

- (void)setCellSize:(CGSize)cellSize models:(NSArray *_Nonnull)models;



@end
