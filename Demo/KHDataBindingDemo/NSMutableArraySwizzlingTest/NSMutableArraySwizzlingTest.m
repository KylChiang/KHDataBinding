//
//  NSMutableArraySwizzlingTest.m
//  KHDataBindDemo
//
//  Created by GevinChen on 2015/12/11.
//  Copyright © 2015年 omg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "NSMutableArray+KHSwizzle.h"

@interface NSMutableArraySwizzlingTest : XCTestCase <KHArrayObserveDelegate>

@end

@implementation NSMutableArraySwizzlingTest
{
    NSMutableArray *array;
    
    int flag;
    int runInsertObject;
    int runInsertObjects;
    int runRemoveObject;
    int runRemoveObjects;
    int runReplaceObject;
    int runUpdate;
    
}

- (void)resetFlag
{
    flag = 0;
}

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    //    [NSMutableArray load];
    array = [[NSMutableArray alloc] init];
    runInsertObject     = 1<<1;
    runInsertObjects    = 1<<2;
    runRemoveObject     = 1<<3;
    runRemoveObjects    = 1<<4;
    runReplaceObject    = 1<<5;
    runUpdate           = 1<<6;
    
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

-(void)testDelegate
{
    array.kh_delegate = self;
    
    id obj = array.kh_delegate;
    
    XCTAssert( obj == self );
    
}

- (void)testAdd
{
    //  取得原本的數量
    //  初始 array
    [array removeAllObjects];
    NSArray *strings = @[@"one",@"two",@"three",@"four",@"five",@"six"];
    [array addObjectsFromArray:strings];

    NSInteger cnt = array.count;
    
    //  指定委派
    array.kh_delegate = self;
    
    //  加入一個物件
    cnt = array.count;
    [array addObject: @"seven" ];
    //  確定有加入，數量加一
    XCTAssert( array.count == ( cnt + 1 ) );
    //  表示有呼叫到 delegate 的 method
    XCTAssert( flag & runInsertObject );
    //  檢查有沒有呼叫到其它的，有呼叫到 runInsertObject 之外的就錯
    XCTAssert( !(flag ^ runInsertObject) );
    [self resetFlag];
    
    cnt = array.count;
    NSArray *arr2 = @[ @"eight",@"nine",@"ten" ];
    [array addObjectsFromArray: arr2 ];
    XCTAssert( array.count == ( cnt + 3 ) );
    //  表示有呼叫到 delegate 的 method
    XCTAssert( flag & runInsertObjects );
    //  檢查有沒有呼叫到其它的
    XCTAssert( !(flag ^ runInsertObjects) );
    
}

- (void)testRemove
{
    //  初始 array
    [array removeAllObjects];
    NSArray *strings = @[@"one",@"two",@"three",@"four",@"five",@"six"];
    [array addObjectsFromArray:strings];
    
    //  取得原本的數量
    NSInteger cnt = array.count;
    //  指定委派
    array.kh_delegate = self;
    
    //  刪除物件
    cnt = array.count;
    [array removeObject:strings[1]];
    XCTAssert( array.count == ( cnt - 1 ) );
    //  表示有呼叫到 delegate 的 method
    XCTAssert( flag & runRemoveObject );
    //  檢查有沒有呼叫到其它的
    XCTAssert( !(flag ^ runRemoveObject) );
    [self resetFlag];
    

    //  刪除指定索引的物件
    cnt = array.count;
    [array removeObjectAtIndex:0];
    XCTAssert( array.count == (cnt - 1) );
    //  表示有呼叫到 delegate 的 method
    XCTAssert( flag & runRemoveObject);
    //  檢查有沒有呼叫到其它的
    XCTAssert( !(flag ^ runRemoveObject) );
    [self resetFlag];
    
    
    //  刪除指定索引的物件
    cnt = array.count;
    [array removeObjectsInArray:@[strings[3],strings[4],strings[5]]];
    XCTAssert( array.count == (cnt - 3) );
    //  表示有呼叫到 delegate 的 method
    XCTAssert( flag & runRemoveObjects);
    //  檢查有沒有呼叫到其它的
    XCTAssert( !(flag ^ runRemoveObjects) );
    [self resetFlag];
    
    
    //  刪除全部物件
    cnt = array.count;
    [array removeAllObjects];
    XCTAssert( array.count == 0 );
    //  表示有呼叫到 delegate 的 method
    XCTAssert( flag & runRemoveObjects );
    //  檢查有沒有呼叫到其它的
    XCTAssert( !(flag ^ runRemoveObjects) );
    [self resetFlag];
    
    // 刪除超過 index，會發生例外
    XCTAssertThrows( [array removeObjectAtIndex:1] );
}

- (void)testInsert
{
    //  初始 array
    [array removeAllObjects];
    NSArray *strings = @[@"one",@"two",@"three",@"four",@"five",@"six"];
    [array addObjectsFromArray:strings];
    NSInteger cnt = array.count;
    //  指定委派
    array.kh_delegate = self;
    
    cnt = array.count;
    [array insertObject:@"seven" atIndex:3];
    XCTAssert( array.count == cnt + 1 );
    //  表示有呼叫到 delegate 的 method
    XCTAssert( flag & runInsertObject );
    //  檢查有沒有呼叫到其它的
    XCTAssert( !(flag ^ runInsertObject) );
    [self resetFlag];


    cnt = array.count;
    [array insertObjects:@[@"eight",@"nine",@"ten"] atIndexes:[NSIndexSet indexSetWithIndexesInRange:(NSRange){4,3}]];
    XCTAssert( array.count == cnt + 3 );
    //  表示有呼叫到 delegate 的 method
    XCTAssert( flag & runInsertObjects);
    //  檢查有沒有呼叫到其它的
    XCTAssert( !(flag ^ runInsertObjects) );
    [self resetFlag];

}

- (void)testReplace
{
    [array removeAllObjects];
    [array addObjectsFromArray:@[@"one",@"two",@"three",@"four",@"five",@"six"]];
    //  指定委派
    array.kh_delegate = self;
    
    [array replaceObjectAtIndex:3 withObject:@"seven"];
    NSString *string = array[3];
    //  判斷 replace 是否正確
    XCTAssert( [string isEqualToString:@"seven"] );
    //  表示有呼叫到 delegate 的 method
    XCTAssert( flag & runReplaceObject );
    //  檢查有沒有呼叫到其它的
    XCTAssert( !(flag ^ runReplaceObject) );
    [self resetFlag];

}


#pragma mark - Array delegate


// 插入
-(void)insertObject:( nonnull id)object index:( NSUInteger)index inArray:( nonnull NSMutableArray*)array
{
    NSLog(@"insertObject");
    flag = flag | runInsertObject;
}

// 插入多項
-(void)insertObjects:( nonnull NSArray*)objects indexs:( nonnull NSIndexSet*)indexes inArray:( nonnull NSMutableArray*)array
{
    NSLog(@"insertObjects");
    flag = flag | runInsertObjects;
}

// 刪除
-(void)removeObject:( nonnull id)object index:( NSUInteger)index inArray:( nonnull NSMutableArray*)array
{
    NSLog(@"removeObject");
    flag = flag | runRemoveObject;
}

// 刪除多項
-(void)removeObjects:( nonnull NSArray*)objects indexs:( nonnull NSIndexSet*)indexs inArray:( nonnull NSMutableArray*)array 
{
    NSLog(@"removeObjects");
    flag = flag | runRemoveObjects;
}

// 取代
-(void)replacedObject:( nonnull id)oldObj newObject:( nonnull id)newObj index:( NSUInteger)index inArray:( nonnull NSMutableArray*)array
{
    NSLog(@"replacedObject");
    flag = flag | runReplaceObject;
}

// 更新
-(void)update:( nonnull id)object index:( NSUInteger)index inArray:( nonnull NSMutableArray*)array
{
    NSLog(@"update");
    flag = flag | runUpdate;
}



@end
