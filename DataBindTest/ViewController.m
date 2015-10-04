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
#import "UserProfile.h"
#import "TableViewBindHelper.h"
#import "APIOperation.h"

@interface ViewController () <HelperEventDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UIButton *addBtn;
@property (weak, nonatomic) IBOutlet UIButton *removeBtn;
@property (weak, nonatomic) IBOutlet UIButton *insertBtn;
@property (weak, nonatomic) IBOutlet UIButton *update;


@end

@implementation ViewController
{
    
    TableViewBindHelper* tableBindHelper;
    
    CKHObserveableArray* users;
    
    NSNumber* _uidTemp;
    
    NSArray* nameStr;
    
    UserData *_user;
    
    int way;
    
    APIOperation *api;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    nameStr = @[@"A", @"B", @"C", @"D", @"E",  @"F", @"G", @"H",@"I", @"J",@"K",@"L",@"M",@"N",@"O",@"P",@"Q",];
    users = [CKHObserveableArray new];
    
    way = 3;
    
    switch (way) {
        case 0:
            [self loadTableView];
            break;
        case 1:
            [self loadTableView2];
            break;
        case 2:
            [self loadTableView3];
            break;
        case 3:
            [self loadTableView4];
            break;
    }

    

}

-(void)loadTableView
{
    // case 一種 model 對映多種 cell
    // 或是說 建立另一種對映每個 cell 的 model , ex: TextCellModel , SwitchCellModel
    // 然後就各別填入值，因為像這種的用法比較算特例

    _user = [UserData new];
    _user.name = @"shit";
    _user.age = @18;
    _user.money = @10000;
    _user.address = @"you motherfucker, asshole. ";
    _user.mobile = @"0988776655";
    _user.male = YES;
    _user.userDescription = @"aaa\nbbb\nccc";
    _user.hasJoin = NO;

    
    CKHCellModel *nameModel = [CKHCellModel new];
    nameModel.nibName = @"MyCell";
    nameModel.identifier = @"textCell";
    nameModel.onLoadBlock = ^( TextFieldCell *cell, id model ){
        cell.titleLabel.text = @"姓名";
        cell.textField.text = _user.name;
    };
    [users addObject: nameModel ];
    
    CKHCellModel *ageModel = [CKHCellModel new];
    ageModel.nibName = @"MyCell";
    ageModel.identifier = @"textCell";
    ageModel.onLoadBlock = ^( TextFieldCell *cell, id model ){
        cell.titleLabel.text = @"年齡";
        cell.textField.text = [_user.age stringValue];
    };
    [users addObject: ageModel ];
    
    CKHCellModel *sexModel = [CKHCellModel new];
    sexModel.nibName = @"MyCell";
    sexModel.identifier = @"switchCell";
    sexModel.onLoadBlock = ^( SwitchCell *cell, id model ){
        cell.titleLabel.text = @"性別";
        cell.sw.on = _user.male;
    };
    [users addObject: sexModel ];
    
    
    //---------------------------------------------
    tableBindHelper = [TableViewBindHelper new];
    tableBindHelper.tableView = self.tableView;
    [tableBindHelper addEventListener: self ];
    [tableBindHelper bindArray:users];
    
    
    
}

-(void)loadTableView2
{
    // case 一種 model 對映一種 cell，一般的使用方式
    //-------------------------------------------------
    //    資料產生
    users = [[CKHObserveableArray alloc] init ];
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
    
    tableBindHelper = [TableViewBindHelper new];
    tableBindHelper.tableView = self.tableView;
    [tableBindHelper addEventListener: self ];
    [tableBindHelper bindArray:users];
    
}

-(void)loadTableView3
{
    for ( int i=0 ; i<10; i++ ) {
        UITableCellModel *model = [UITableCellModel new];
        model.text = [NSString stringWithFormat:@"shit %02d", i ];
        model.detail = @"fuck you";
        model.cellStyle = UITableViewCellStyleValue1;
        [users addObject: model ];
    }
    
    tableBindHelper = [TableViewBindHelper new];
    tableBindHelper.tableView = self.tableView;
    [tableBindHelper bindArray: users ];
    
}

-(void)loadTableView4
{
    
    NSOperationQueue *queue = [NSOperationQueue mainQueue];
    for ( int i=0; i<15; i++ ) {
        api = [[APIOperation alloc] initWithDomain:@"http://uifaces.com/" requestSerializer:nil responseSerializer:^id(APIOperation *api, NSData *data) {
            NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil ];
            return dic;
        }];
        api.title = @"下載 user profile";
        [api requestMethod:@"GET" api:@"api/v1/random" param:nil body:nil response:^(APIOperation *api, id responseObject) {
//            printf("receive:\n%s\n", [[responseObject description] UTF8String] );
            UserProfile *userp = [UserProfile new];
            userp.username = responseObject[@"username"];
            userp.image_urls = [ImageSet new];
            NSDictionary *dic = responseObject[@"image_urls"];
            userp.image_urls.normal = dic[@"normal"];
            userp.image_urls.bigger = dic[@"bigger"];
            userp.image_urls.mini = dic[@"mini"];
            userp.image_urls.epic = dic[@"epic"];
            [users addObject: userp ];
        } fail:^(APIOperation *api, NSError *error) {
            printf("error!!\n");
        }];
        [queue addOperation: api ];
        printf("api start\n");
    }
    
    tableBindHelper = [TableViewBindHelper new];
    tableBindHelper.tableView = self.tableView;
    [tableBindHelper bindArray: users ];


    
}


#pragma mark - API

// 模擬 api 非同步呼叫，3秒後才回應
- (void)userJoinActivity:(UserData*)user
{
    user.hasJoin = YES;
    [tableBindHelper reloadData:user];
}

#pragma mark - UI Event


-(void)tableViewEvent:(const NSString*)event userInfo:(id)userInfo
{
    if (event == CellEventJoin ) {
        UserData* user = userInfo;
        [self userJoinActivity: user ];
    }
}


- (IBAction)addClick:(id)sender {
    
    
    
}

- (IBAction)removeClick:(id)sender {
//    [users removeObjectAtIndex: arc4random() % users.count ];
    id model = users[ arc4random() % users.count ];
    [users removeObject: model ];
}

- (IBAction)insertClick:(id)sender {
    
    if ( way == 2 ) {
        UITableCellModel *model = [UITableCellModel new];
        model.text = [NSString stringWithFormat:@"shit !!%d", arc4random() % 100 ];
        model.detail = @"fuck you";
        model.cellStyle = UITableViewCellStyleValue1;
        [users insertObject:model atIndex:3 ];
    }
    if ( way == 1 ) {
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
}

- (IBAction)updateClick:(id)sender {
    
    int idx = arc4random() % users.count;
    
    if ( way == 1 ) {
        UserData *user = users[ idx ];
        user.uid = @( arc4random() % 100 );
        user.name = nameStr[ arc4random() % nameStr.count ];
        user.age = @( arc4random() % 99 );
        user.money = @( arc4random() % 10000 );
        user.address = [NSString stringWithFormat:@"%ld 地址 new ", users.count ];
        user.mobile = [NSString stringWithFormat:@"%ld 手機 new ",users.count];
        user.male = arc4random() % 2;
        user.userDescription = [NSString stringWithFormat:@"%ld\n介紹 ajdjdjakldjg;alkdsjf",users.count];
        [users update: user ];
    }
    if (way == 2 ) {
        UITableCellModel *model = users[ idx ];
        model.text = [NSString stringWithFormat:@"shit !!%d", arc4random() % 100 ];
        model.detail = @"fuck you";
        model.cellStyle = UITableViewCellStyleValue1;
        [users update: model ];

    }
    
}







@end

