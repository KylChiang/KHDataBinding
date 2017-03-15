//
//  NSMutableArraySwizzlingTest.m
//  KHDataBindDemo
//
//  Created by GevinChen on 2015/12/11.
//  Copyright © 2015年 omg. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSMutableArray+KHSwizzle.h"

@interface NSMutableArraySwizzlingTest : XCTestCase <KHArrayObserveDelegate>

@end

@implementation NSMutableArraySwizzlingTest
{
    NSMutableArray *array;
    int delegateCall;
}

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
//    [NSMutableArray load];
    array = [[NSMutableArray alloc] init];
    delegateCall = 0;
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
    NSInteger cnt = array.count;
    
    //  指定委派
    array.kh_delegate = self;
    
    //  加入一個物件
    NSObject *object = [NSObject new];
    [array addObject: object ];
    
    //  確定有加入，數量加一
    XCTAssert( array.count == ( cnt + 1 ) );
    //  表示有呼叫到 delegate 的 method
    XCTAssert( delegateCall == 1 );
    
    NSArray *arr2 = @[ [NSObject new],[NSObject new],[NSObject new] ];
    
    [array addObjectsFromArray: arr2 ];
    
    XCTAssert( array.count == ( cnt + 4 ) );
    //  表示有呼叫到 delegate 的 method
    XCTAssert( delegateCall == 2 );
    
}

- (void)testRemove
{
    //  取得原本的數量
    NSInteger cnt = array.count;
    //  指定委派
    array.kh_delegate = self;
    
    //  建立物件並加入
    NSObject *object[5];
    for (int i=0; i<5; i++) {
        object[i] = [NSObject new];
        [array addObject:object[i]];
    }
    
    NSInteger cnt_afterAdd = array.count;
    
    //  刪除物件
    [array removeObject:object[3]];
    
    XCTAssert( array.count == ( cnt_afterAdd - 1 ) );
    XCTAssert( delegateCall == 3 );
    
    delegateCall = -1;
    //  刪除指定索引的物件
    [array removeObjectAtIndex:0];
    
    XCTAssert( array.count == (cnt_afterAdd - 2) );
    XCTAssert( delegateCall == 3 );
    
    delegateCall = -1;
    //  刪除全部物件
    [array removeAllObjects];
    
    XCTAssert( array.count == 0 );
    XCTAssert( delegateCall == 4 );
    
    // 刪除超過 index，會發生例外
    XCTAssertThrows( [array removeObjectAtIndex:1] );
}

- (void)testInsert
{


}

- (void)testReplace
{
    
}


#pragma mark - Array delegate

// 插入
-(void)arrayInsert:(NSMutableArray *)array insertObject:(id)object index:(NSIndexPath *)index
{
    delegateCall = 1;
    
}

// 新增多項
-(void)arrayInsertSome:(NSMutableArray *)array insertObjects:(NSArray *)objects indexes:(NSArray *)indexes
{
    delegateCall = 2;
}

// 刪除
-(void)arrayRemove:( nonnull NSArray*)array removeObject:( nonnull id)object index:( nonnull NSIndexPath*)index
{
    delegateCall = 3;
}

// 刪除全部
-(void)arrayRemoveAll:( nonnull NSArray*)array indexs:(NSArray*)indexs
{
    delegateCall = 4;
}

// 取代
-(void)arrayReplace:( nonnull NSArray*)array newObject:( nonnull id)newObj replacedObject:( nonnull id)oldObj index:( nonnull NSIndexPath*)index
{
    delegateCall = 6;
}

// 更新
-(void)arrayUpdate:( nonnull NSArray*)array update:( nonnull id)object index:( nonnull NSIndexPath*)index
{
    delegateCall = 7;
}

// 更新全部
-(void)arrayUpdateAll:( nonnull NSArray*)array
{
    delegateCall = 8;
}


@end
