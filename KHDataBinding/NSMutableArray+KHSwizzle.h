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
-(void)insertObject:( nonnull id)object index:(NSUInteger)index inArray:( nonnull NSMutableArray*)array ;

// 插入多項
-(void)insertObjects:( nonnull NSArray*)objects indexs:( nonnull NSIndexSet*)indexs inArray:( nonnull NSMutableArray*)array;

// 刪除
-(void)removeObject:( nonnull id)object index:(NSUInteger)index inArray:( nonnull NSMutableArray*)array;

// 刪除多項
-(void)removeObjects:( nonnull NSArray*)objects indexs:( nonnull NSIndexSet*)indexs inArray:( nonnull NSMutableArray*)array ;

// 取代
-(void)replacedObject:( nonnull id)oldObj newObject:( nonnull id)newObj index:(NSUInteger)index inArray:( nonnull NSMutableArray*)array;

// 更新
-(void)update:( nonnull id)object index:(NSUInteger)index inArray:( nonnull NSMutableArray*)array;


@end


@interface NSMutableArray (KHSwizzle)

@property (nonatomic,nullable,weak) id<KHArrayObserveDelegate> kh_delegate;
@property (nonatomic) NSInteger kh_section;
@property (nonatomic) BOOL removeObjectsFlag;

- (void)kh_addObjectsFromArray:(NSArray *_Nullable)otherArray;

- (void)kh_insertObject:(id _Nonnull)anObject atIndex:(NSUInteger)index;

- (void)kh_removeObjectAtIndex:(NSUInteger)index;

- (void)kh_removeAllObjects;

- (void)kh_replaceObjectAtIndex:(NSUInteger)index withObject:(id _Nonnull)anObject;

- (void)update:(nonnull id)anObject;


@end
