//
//  NSArray+KHSwizzle.h
//  KHDataBindDemo
//
//  Created by GevinChen on 2015/12/10.
//  Copyright © 2015年 omg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol KHArrayObserveDelegate

// 新增
-(void)arrayAdd:( nonnull NSMutableArray*)array newObject:( nonnull id)object index:( nonnull NSIndexPath*)index;

// 新增多項
-(void)arrayAdd:( nonnull NSMutableArray*)array newObjects:( nonnull NSArray*)objects indexs:( nonnull NSArray*)indexs;

// 刪除
-(void)arrayRemove:( nonnull NSMutableArray*)array removeObject:( nonnull id)object index:( nonnull NSIndexPath*)index;

// 刪除全部
-(void)arrayRemoveAll:( nonnull NSMutableArray*)array indexs:( nonnull NSArray*)indexs;

// 插入
-(void)arrayInsert:( nonnull NSMutableArray*)array insertObject:( nonnull id)object index:( nonnull NSIndexPath*)index;

// 取代
-(void)arrayReplace:( nonnull NSMutableArray*)array newObject:( nonnull id)newObj replacedObject:( nonnull id)oldObj index:( nonnull NSIndexPath*)index;

// 更新
-(void)arrayUpdate:( nonnull NSMutableArray*)array update:( nonnull id)object index:( nonnull NSIndexPath*)index;

// 更新全部
-(void)arrayUpdateAll:( nonnull NSMutableArray*)array;

@end


@interface NSMutableArray (KHSwizzle)

@property (nonatomic) id<KHArrayObserveDelegate> kh_delegate;
@property (nonatomic) NSInteger section;

- (void)kh_addObject:(id)object;

- (void)kh_addObjectsFromArray:(NSArray*)otherArray;

- (void)kh_removeObject:(id)anObject;

- (void)kh_removeLastObject;

- (void)kh_removeObjectAtIndex:(NSUInteger)index;

- (void)kh_removeAllObjects;

- (void)kh_insertObject:(id)anObject atIndex:(NSUInteger)index;

- (void)kh_replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject;

- (void)update:(nonnull id)anObject;

- (void)updateAll;

@end
