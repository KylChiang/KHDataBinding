//
//  ViewController.m
//  DataBindTest
//
//  Created by GevinChen on 2015/8/30.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import "ViewController.h"
#import "MyCell.h"
#import "TableViewBindHelper.h"
#import "APIOperation.h"
#import "UserModel.h"
@interface ViewController () <HelperEventDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UIButton *addBtn;
@property (weak, nonatomic) IBOutlet UIButton *removeBtn;
@property (weak, nonatomic) IBOutlet UIButton *insertBtn;
@property (weak, nonatomic) IBOutlet UIButton *update;
@property (weak, nonatomic) IBOutlet UITextField *keywordText;
@property (weak, nonatomic) IBOutlet UIButton *searchBtn;


@end

@implementation ViewController
{
    
    TableViewBindHelper* tableBindHelper;
    
    CKHObserveableArray* models;
    
//    APIOperation *api;
    
    NSOperationQueue *queue;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    queue = [[NSOperationQueue alloc] init];
    
    tableBindHelper = [TableViewBindHelper new];
    tableBindHelper.tableView = self.tableView;
    models = [[CKHObserveableArray alloc ] init];
    [tableBindHelper bindArray: models ];
    [tableBindHelper setCellSelectedHandle:self action:@selector(tableViewCellSelected:index:)];

    [self loadTableView4];
}

//-(void)loadTableView
//{
//    // case 一種 model 對映多種 cell
//    // 或是說 建立另一種對映每個 cell 的 model , ex: TextCellModel , SwitchCellModel
//    // 然後就各別填入值，因為像這種的用法比較算特例
//
//    _user = [UserData new];
//    _user.name = @"shit";
//    _user.age = @18;
//    _user.money = @10000;
//    _user.address = @"you motherfucker, asshole. ";
//    _user.mobile = @"0988776655";
//    _user.male = YES;
//    _user.userDescription = @"aaa\nbbb\nccc";
//    _user.hasJoin = NO;
//
//    
//    CKHCellModel *nameModel = [CKHCellModel new];
//    nameModel.nibName = @"MyCell";
//    nameModel.identifier = @"textCell";
//    nameModel.onLoadBlock = ^( TextFieldCell *cell, id model ){
//        cell.titleLabel.text = @"姓名";
//        cell.textField.text = _user.name;
//    };
//    [users addObject: nameModel ];
//    
//    CKHCellModel *ageModel = [CKHCellModel new];
//    ageModel.nibName = @"MyCell";
//    ageModel.identifier = @"textCell";
//    ageModel.onLoadBlock = ^( TextFieldCell *cell, id model ){
//        cell.titleLabel.text = @"年齡";
//        cell.textField.text = [_user.age stringValue];
//    };
//    [users addObject: ageModel ];
//    
//    CKHCellModel *sexModel = [CKHCellModel new];
//    sexModel.nibName = @"MyCell";
//    sexModel.identifier = @"switchCell";
//    sexModel.onLoadBlock = ^( SwitchCell *cell, id model ){
//        cell.titleLabel.text = @"性別";
//        cell.sw.on = _user.male;
//    };
//    [users addObject: sexModel ];
//    
//    
//    //---------------------------------------------
//    tableBindHelper = [TableViewBindHelper new];
//    tableBindHelper.tableView = self.tableView;
//    [tableBindHelper addEventListener: self ];
//    [tableBindHelper bindArray:users];
//    
//    
//    
//}

//-(void)loadTableView2
//{
//    // case 一種 model 對映一種 cell，一般的使用方式
//    //-------------------------------------------------
//    //    資料產生
//    users = [[CKHObserveableArray alloc] init ];
//    for ( int i=0 ; i<20; i++) {
//        UserData *user = [UserData new ];
//        user.uid = @( i );
//        user.name = nameStr[ arc4random() % nameStr.count ];
//        user.age = @( i );
//        user.money = @( arc4random() % 10000 );
//        user.address = [NSString stringWithFormat:@"%d 地址 ajdjdjakldjg;alkdsjf",i];
//        user.mobile = [NSString stringWithFormat:@"%d 手機 284968604",i];
//        user.male = arc4random() % 2;
//        user.userDescription = [NSString stringWithFormat:@"%d\n介紹 ajdjdjakldjg;alkdsjf",i];
//        [users addObject:user];
//    }
//    //-------------------------------------------------
//    
//    tableBindHelper = [TableViewBindHelper new];
//    tableBindHelper.tableView = self.tableView;
//    [tableBindHelper addEventListener: self ];
//    [tableBindHelper bindArray:users];
//    
//}

//-(void)loadTableView3
//{
//    for ( int i=0 ; i<10; i++ ) {
//        UITableCellModel *model = [UITableCellModel new];
//        model.text = [NSString stringWithFormat:@"shit %02d", i ];
//        model.detail = @"fuck you";
//        model.cellStyle = UITableViewCellStyleValue1;
//        [users addObject: model ];
//    }
//    
//    tableBindHelper = [TableViewBindHelper new];
//    tableBindHelper.tableView = self.tableView;
//    [tableBindHelper bindArray: users ];
//    
//}

-(void)loadTableView4
{
    

    
}


#pragma mark - API

// 第一，我必須要建一個 MovieModel，讓 json 可以轉成一個實體 object
// 第二，我必須要建一個 MovieCell，讓 model 可以把資料填入
//

- (void)userQuery
{
    
    //  http://api.randomuser.me/?results=10

    NSDictionary* param = @{@"results": @10 };
    APIOperation *api = [[APIOperation alloc] init];
    api.debug = YES;
    api.contentType = @"appllication/json";
    [api GET:@"http://api.randomuser.me/" param:param body:nil response:^(APIOperation *api, id responseObject) {
        NSArray *results = responseObject[@"results"];
        NSArray *users = [KVCModel convertArray:results toClass:[UserModel class]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [models addObjectsFromArray: users ];
        });
    } fail:^(APIOperation *api, NSError *error) {
        NSLog(@"error !");
    }];
    
    [queue addOperation: api ];
    
}



#pragma mark - UI


#pragma mark - UI Event

-(void)tableViewCellSelected:(UITableView*)tableView index:(NSIndexPath*)index
{
    NSLog(@"cell click %ld",index.row );
}

//-(void)tableViewEvent:(const NSString*)event userInfo:(id)userInfo
//{
//    if (event == CellEventJoin ) {
//        UserData* user = userInfo;
//        [self userJoinActivity: user ];
//    }
//}

- (IBAction)searchClick:(id)sender {
    [self userQuery ];
}

- (IBAction)addClick:(id)sender {
    
}

- (IBAction)removeClick:(id)sender {

}

- (IBAction)insertClick:(id)sender {
    
    
}

- (IBAction)updateClick:(id)sender {
    
}







@end

