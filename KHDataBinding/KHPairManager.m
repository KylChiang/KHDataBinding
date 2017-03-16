//
//  KHBindManage.m
//  KHDataBindingDemo
//
//  Created by GevinChen on 2017/3/16.
//  Copyright © 2017年 omg. All rights reserved.
//

#import "KHPairManager.h"

@implementation KHPairManager



- (instancetype)init
{
    self = [super init];
    [self initImpl];
    return self;
}



- (void)initImpl
{
    _pairDic   = [[NSMutableDictionary alloc] initWithCapacity: 5 ];
}



#pragma mark - Pair Info

- (KHPairInfo*)createNewPairInfo
{
    KHPairInfo *pairInfo = [[KHPairInfo alloc] init];
    return pairInfo;
}

- (void)pairWithModel:(id)model
{
    //  防呆，避免加入兩次 pairInfo
    KHPairInfo *pairInfo = [self getPairInfo:model];
    if ( !pairInfo ) {
        pairInfo = [self createNewPairInfo];
        NSValue *myKey = [NSValue valueWithNonretainedObject:model];
        _pairDic[myKey] = pairInfo;
    }
    pairInfo.collectionView = self.collectionView;
    pairInfo.tableView = self.tableView;
    pairInfo.model = model;
}

- (void) removePairInfo:(id)object
{
    NSValue *myKey = [NSValue valueWithNonretainedObject:object];
    KHPairInfo *pairInfo = _pairDic[myKey];
    pairInfo.model = nil;
    pairInfo.tableView = nil;
    pairInfo.collectionView = nil;
    
    [_pairDic removeObjectForKey:myKey];
}

- (void) replacePairInfo:(id)oldModel new:(id)newModel
{
    NSValue *oldKey = [NSValue valueWithNonretainedObject:oldModel];
    KHPairInfo *pairInfo = _pairDic[oldKey];
    [_pairDic removeObjectForKey:oldKey];
    pairInfo.model = newModel;
    NSValue *newKey = [NSValue valueWithNonretainedObject:newModel];
    _pairDic[newKey] = pairInfo;
}

//  取得某個 model 的 cell 介接物件
- (nullable KHPairInfo*)getPairInfo:(id _Nonnull)model
{
    NSValue *myKey = [NSValue valueWithNonretainedObject:model];
    return _pairDic[myKey];
}


#pragma mark - Cell Size

- (CGSize)getCellSizeFor:(id _Nonnull)model
{
    KHPairInfo *pairInfo = [self getPairInfo:model];
    return pairInfo.cellSize;
}

- (void)setCellSize:(CGSize)cellSize model:(id _Nonnull)model
{
    KHPairInfo *pairInfo = [self getPairInfo:model];
    if ( !pairInfo ) {
        [self pairWithModel:model];
        pairInfo = [self getPairInfo:model];
    }
    pairInfo.cellSize = cellSize;
}

- (void)setCellSize:(CGSize)cellSize models:(NSArray *_Nonnull)models
{
    for ( id model in models ) {
        [self setCellSize:cellSize model:model];
    }
}



@end
