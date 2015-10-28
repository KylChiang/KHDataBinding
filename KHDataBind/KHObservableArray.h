//
//  KHObservableArray.h
//  KHDataBindDemo
//
//  Created by GevinChen on 2015/10/27.
//  Copyright © 2015年 omg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class KHObservableArray;

@protocol KHObserveArrayDelegate

// 新增
-(void)arrayAdd:( nonnull KHObservableArray*)array newObject:( nonnull id)object index:( nonnull NSIndexPath*)index;

// 新增多項
-(void)arrayAdd:( nonnull KHObservableArray*)array newObjects:( nonnull NSArray*)objects indexs:( nonnull NSArray*)indexs;

// 刪除
-(void)arrayRemove:( nonnull KHObservableArray*)array removeObject:( nonnull id)object index:( nonnull NSIndexPath*)index;

// 刪除全部
-(void)arrayRemoveAll:( nonnull KHObservableArray*)array indexs:(NSArray*)indexs;

// 插入
-(void)arrayInsert:( nonnull KHObservableArray*)array insertObject:( nonnull id)object index:( nonnull NSIndexPath*)index;

// 取代
-(void)arrayReplace:( nonnull KHObservableArray*)array newObject:( nonnull id)newObj replacedObject:( nonnull id)oldObj index:( nonnull NSIndexPath*)index;

// 更新
-(void)arrayUpdate:( nonnull KHObservableArray*)array update:( nonnull id)object index:( nonnull NSIndexPath*)index;

// 更新全部
-(void)arrayUpdateAll:( nonnull KHObservableArray*)array;

@end


@interface KHObservableArray : NSMutableArray
{
    NSMutableArray *_backArray;
}

@property (nonatomic) NSInteger section;
@property (nonatomic,nullable) id delegate;

-( nonnull instancetype)init;

-( nonnull instancetype)initWithArray:( nullable NSArray *)array;

-(void)update:( nonnull id )object;

-(void)updateAll;

@end

