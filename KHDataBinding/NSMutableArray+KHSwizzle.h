//
//  NSMutableArray+KHSwizzle.h
//
//  Created by GevinChen on 2015/12/10.
//  Copyright © 2015年 omg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol KHArrayObserveDelegate

// 插入
-(void)arrayInsert:( nonnull NSMutableArray*)array insertObject:( nonnull id)object index:( nonnull NSIndexPath*)index;

// 插入多項
//-(void)arrayInsertSome:( nonnull NSMutableArray*)array insertObjects:( nonnull NSArray*)objects indexes:( nonnull NSArray*)indexes;

// 刪除
-(void)arrayRemove:( nonnull NSMutableArray*)array removeObject:( nonnull id)object index:( nonnull NSIndexPath*)index;

// 刪除多項
//-(void)arrayRemoveSome:( nonnull NSMutableArray*)array removeObjects:( nonnull NSArray*)objects indexs:( nonnull NSArray*)indexs;

// 取代
-(void)arrayReplace:( nonnull NSMutableArray*)array newObject:( nonnull id)newObj replacedObject:( nonnull id)oldObj index:( nonnull NSIndexPath*)index;

// 更新
-(void)arrayUpdate:( nonnull NSMutableArray*)array update:( nonnull id)object index:( nonnull NSIndexPath*)index;

// 更新全部
//-(void)arrayUpdateAll:( nonnull NSMutableArray*)array;

@end


@interface NSMutableArray (KHSwizzle)

@property (nonatomic,nullable,weak) id<KHArrayObserveDelegate> kh_delegate;
@property (nonatomic) NSInteger kh_section;

// Gevin note: 最後會呼叫多次的 insertObject，但是我不想這樣，所以多了一個 isInsertMulti 旗標來判斷現在是加入多項
- (void)kh_addObjectsFromArray:(NSArray *_Nullable)otherArray;

- (void)kh_insertObject:(id _Nonnull)anObject atIndex:(NSUInteger)index;

//- (void)kh_insertObjects:(NSArray  *_Nonnull)objects atIndexes:(NSIndexSet  *_Nonnull)indexs;

- (void)kh_removeObjectAtIndex:(NSUInteger)index;

- (void)kh_removeAllObjects;

- (void)kh_replaceObjectAtIndex:(NSUInteger)index withObject:(id _Nonnull)anObject;

- (void)update:(nonnull id)anObject;

//- (void)updateAll;

@end
