//
//  ViewController.m
//  DataBindTest
//
//  Created by GevinChen on 2015/8/30.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import "ViewController.h"
#import "UserData.h"
#import "MyCell.h"
#import "UserCell.h"
#import "TableViewBindHelper.h"

@interface ViewController () <HelperEventDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UIButton *addBtn;
@property (weak, nonatomic) IBOutlet UIButton *removeBtn;
@property (weak, nonatomic) IBOutlet UIButton *insertBtn;
@property (weak, nonatomic) IBOutlet UIButton *update;


@end

/*
 第一個要試 tableView
 一個 cell 對映一個 property，當作一般 ui 使用
 ui 的 interaction 會反饋回 model
 
 第二個要試 tableView
 多個 cell，當 model 資料改了， cell 馬上反應
 
 以上兩者最重要的是要處理 reuse 的問題
 
 */

@implementation ViewController
{
    
    TableViewBindHelper* tableBindHelper;
    
    TableViewBindHelper* tableBindHelper2;
    
    CKHObserverMutableArray* users;
    
    NSNumber* _uidTemp;
    
    UserData *_user;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    [self loadTableView];
    
    /////////////////////////////////////////
    
    [self loadTableView2];
    
}

-(void)loadTableView
{
    
    tableBindHelper = [TableViewBindHelper new];
    tableBindHelper.tableView = self.tableView;
    [tableBindHelper addEventListener: self ];
    _user = [UserData new];
    _user.name = @"shit";
    _user.age = @18;
    _user.money = @10000;
    _user.address = @"you motherfucker, asshole. ";
    _user.mobile = @"0988776655";
    _user.male = YES;
    _user.userDescription = @"aaa\nbbb\nccc";
    _user.hasJoin = NO;

    [tableBindHelper registerNib:@"MyCell"];
    
//    __weak typeof(_user) wuser = _user;
//    
//    [tableBindHelper addModel:_user identifier:@"textCell" assingMap:@{@"title":@"姓名",@"text":@"name"}];
//    [tableBindHelper addModel:_user identifier:@"textCell" assingMap:@{@"title":@"年齡",@"text":@"age"}];
//    [tableBindHelper addModel:_user identifier:@"textCell" assingMap:@{@"title":@"財產",@"text":@"money"}];
//    
//    [tableBindHelper addModel:_user identifier:@"textCell" assingMap:@{@"title":@"地址",@"text":@"address"}];
//    [tableBindHelper addModel:_user identifier:@"textCell" assingMap:@{@"title":@"手機",@"text":@"mobile"}];
//    [tableBindHelper addModel:_user identifier:@"textViewCell" assingMap:@{@"titleLabel.text":@"自我介紹",@"textView.text":@"userDescription"}];
//    [tableBindHelper addModel:_user identifier:@"switchCell" assingMap:@{@"title":@"性別",@"isOnSw.on":@"male"}];
}

-(void)loadTableView2
{

    //-------------------------------------------------
    //    資料產生
    NSArray* nameStr = @[@"A", @"B", @"C", @"D", @"E",  @"F", @"G", @"H",@"I", @"J",@"K",@"L",@"M",@"N",@"O",@"P",@"Q",];
    users = [[CKHObserverMutableArray alloc] init ];
    for ( int i=0 ; i<20; i++) {
        UserData *user = [UserData new ];
        user.uid = @( i );
        user.name = nameStr[ arc4random() % nameStr.count ];
        user.age = @( i );
        user.money = @( arc4random() % 10000 );
        user.address = [NSString stringWithFormat:@"%d 地址 ajdjdjakldjg;alkdsjf",i];
        user.mobile = [NSString stringWithFormat:@"%d 手機 284968604",i];
        user.male = arc4random() % 2;
        user.userDescription = [NSString stringWithFormat:@"%d\n介紹 ajdjdjakldjg;alkdsjf",i];
        [users addObject:user];
    }
    //-------------------------------------------------
    
    tableBindHelper2 = [TableViewBindHelper new];
    tableBindHelper2.tableView = self.tableView;
    [tableBindHelper2 addEventListener: self ];
    [tableBindHelper2 registerNib:@"UserCell"];
    [tableBindHelper2 setIdentifier:@"userCell" mappingModel:[UserData class]];
    [tableBindHelper2 bindArray:users];
    
//    for ( int i=0; i<users.count; i++) {
//        [tableBindHelper2 addModel:users[i] identifier:@"userCell"];
//    }
}


#pragma mark - API

// 模擬 api 非同步呼叫，3秒後才回應
- (void)userJoinActivity:(UserData*)user
{
    user.hasJoin = YES;
    [tableBindHelper2 performSelector:@selector(refresh:) withObject:user afterDelay:3 ];
}

#pragma mark - UI Event

-(void)tableViewEvent:(const NSString*)event userInfo:(id)userInfo
{
    if (event == CellEventJoin ) {
        UserData* user = userInfo;
        [self userJoinActivity: user ];
    }
    
    if ( event == ButtonCellButtonClickEvent ) {
//        [self userJoinActivity: user ];
        NSLog(@"fuck you");
    }
    
    if ( event == MyCellSwitchChanged ) {
        UISwitch* sw = userInfo;
        _user.male = sw.on;
        NSLog(@"user male:%d", _user.male );
    }
}


- (IBAction)addClick:(id)sender {
    
    
    
}

- (IBAction)removeClick:(id)sender {
    [users removeObjectAtIndex: 1 ];
}

- (IBAction)insertClick:(id)sender {
    
    NSArray* nameStr = @[@"A", @"B", @"C", @"D", @"E",  @"F", @"G", @"H",@"I", @"J",@"K",@"L",@"M",@"N",@"O",@"P",@"Q",];
    UserData *user = [UserData new ];
    user.uid = @( 99 );
    user.name = nameStr[ arc4random() % nameStr.count ];
    user.age = @(78 );
    user.money = @( arc4random() % 10000 );
    user.address = [NSString stringWithFormat:@"%d 地址 ajdjdjakldjg;alkdsjf",99];
    user.mobile = [NSString stringWithFormat:@"%d 手機 284968604",99];
    user.male = arc4random() % 2;
    user.userDescription = [NSString stringWithFormat:@"%d\n介紹 ajdjdjakldjg;alkdsjf",99];
    [users insertObject:user atIndex:2];
}

- (IBAction)updateClick:(id)sender {
    
    
    
}







@end

