//
//  KHDataBindDemoTests.m
//  KHDataBindDemoTests
//
//  Created by GevinChen on 2015/10/15.
//  Copyright (c) 2015年 omg. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "KHBindHelper.h"
#import "UserInfoCell.h"

@interface KHDataBindDemoTests : XCTestCase

@end

@implementation KHDataBindDemoTests
{
    KHTableBindHelper *bindHelper;
    UITableView *tableView;
}

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    tableView = [[UITableView alloc] initWithFrame:(CGRect){100,100,100,100} style:UITableViewStylePlain];
    bindHelper = [[KHTableBindHelper alloc] initWithTableView: tableView ];
    
    
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testTargetAction {
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
    
    // test TargetAction
    
    //  檢查加入是否正常
    [bindHelper addTarget:self action:@selector(testAction:model:) event:UIControlEventTouchUpInside cell:[UserInfoCell class] propertyName:@"btn"];
    id target = [bindHelper getTargetByAction:@selector(testAction:model:) cell:[UserInfoCell class] propertyName:@"btn"];
    XCTAssertEqual( self, target );

    //  取未加入過的 method
    target = [bindHelper getTargetByAction:@selector(testAction2:model:) cell:[UserInfoCell class] propertyName:@"sw"];
    XCTAssert( target == nil );

    //  檢查刪除
    [bindHelper removeTarget:self action:@selector(testAction:model:) cell:[UserInfoCell class] propertyName:@"btn"];
    target = [bindHelper getTargetByAction:@selector(testAction:model:) cell:[UserInfoCell class] propertyName:@"btn"];
    XCTAssert( target == nil );

}

- (void)testRemoveTarget
{
    [bindHelper addTarget:self action:@selector(testAction:model:) event:UIControlEventTouchUpInside cell:[UserInfoCell class] propertyName:@"btn"];
    [bindHelper addTarget:self action:@selector(testAction2:model:) event:UIControlEventValueChanged cell:[UserInfoCell class] propertyName:@"sw"];

    //  刪除對 btn 的監聽，target 應該要取得 nil
    [bindHelper removeTarget:self cell:[UserInfoCell class] propertyName:@"btn"];
    id target = [bindHelper getTargetByAction:@selector(testAction:model:) cell:[UserInfoCell class] propertyName:@"btn"];
    XCTAssert( target == nil );
    
    //  刪除對 btn 的監聽後，sw 的監聽應該還要存在
    target = [bindHelper getTargetByAction:@selector(testAction2:model:) cell:[UserInfoCell class] propertyName:@"sw"];
    XCTAssert( target == self );
    
    //  刪除對 sw 的監聽
    [bindHelper removeTarget:self cell:[UserInfoCell class] propertyName:@"sw"];
    
    //  刪除對 sw 的監聽後，target 應該要為 nil
    target = [bindHelper getTargetByAction:@selector(testAction2:model:) cell:[UserInfoCell class] propertyName:@"sw"];
    XCTAssert( target == nil );
}


- (void)testAction:(id)sender model:(id)model
{
    
}

- (void)testAction2:(id)sender model:(id)model
{
    
}


- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
