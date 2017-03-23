//
//  KHDataBindDemoTests.m
//  KHDataBindDemoTests
//
//  Created by GevinChen on 2015/10/15.
//  Copyright (c) 2015年 omg. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "KHCell.h"
#import "UserInfoCell.h"
#import "KHDataBinding.h"

@interface KHDataBindDemoTests : XCTestCase

@end

@implementation KHDataBindDemoTests
{
    KHTableDataBinding *bindHelper;
    UITableView *tableView;
}

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    tableView = [[UITableView alloc] initWithFrame:(CGRect){100,100,100,100} style:UITableViewStylePlain];
    bindHelper = [[KHTableDataBinding alloc] initWithTableView: tableView delegate:nil registerClass:nil ];
    
    
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testTargetAction {
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
    
    // test TargetAction
//    __block BOOL btnClick = NO;
    //  檢查加入是否正常
    [bindHelper addEvent:UIControlEventTouchUpInside cell:[UserInfoCell class] propertyName:@"btn" handler:^(id sender, id model) {
        NSLog(@"btn click");
//        btnClick = YES;
    }];
    
//    XCTAssert( btnClick );
    
    //  檢查刪除
    [bindHelper removeEvent:UIControlEventTouchUpInside cell:[UserInfoCell class] propertyName:@"btn"];
    
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
