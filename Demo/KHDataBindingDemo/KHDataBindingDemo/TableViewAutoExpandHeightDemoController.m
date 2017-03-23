//
//  TableViewAutoExpandHeightDemoController.m
//  KHDataBindingDemo
//
//  Created by GevinChen on 2017/3/21.
//  Copyright © 2017年 omg. All rights reserved.
//

#import "TableViewAutoExpandHeightDemoController.h"

// Models
#import "UserModel.h"

// Views
#import "UserInfoCell.h"
#import "MyTableHeaderView.h"
#import "ShowArrayDataCell.h"
#import "ShowDictDataCell.h"
#import "ShowDictData2Cell.h"
#import "TextInputView.h"
#import "UISwitchCellView.h"

// Utilities
#import "APIOperation.h"
#import "KHTableView.h"

@interface TableViewAutoExpandHeightDemoController ()

@end

@implementation TableViewAutoExpandHeightDemoController
{
    //  user model array
    NSMutableArray<UserModel*> *userList;
    NSMutableArray<UserModel*> *tempUserList;
    
    //  other section array
    NSMutableArray *itemList;
    NSMutableArray *itemList2;
    NSMutableArray *itemList3;
    
    //  operation queue for api call
    NSOperationQueue *apiQueue;
}


#pragma mark - Initializers

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self initializeDefaultProperties];
    }
    
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self initializeDefaultProperties];
    }
    
    return self;
}

- (void)initializeDefaultProperties
{
    apiQueue = [NSOperationQueue mainQueue];
    tempUserList = [[NSMutableArray alloc] initWithCapacity:10];
}

- (void)dealloc
{
    NSLog(@"%@....dealloc",NSStringFromClass([self class]));
}

- (void)viewDidLoad 
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - API

- (void)fetchUsers
{
    //  @todo:之後改用 AFNetworking 3.0
    //  使用自訂的 http connection handle
    //--------------------------------------------------
    NSDictionary *param = @{@"results": @20 };
    APIOperation *api = [[APIOperation alloc] init];
    api.debug = YES;
    //    __weak typeof(self) w_self = self;
    [api GET:@"http://api.randomuser.me/" param:param body:nil response:^(APIOperation *api, id responseObject) {
        NSArray *results = responseObject[@"results"];
        NSArray *users = [KVCModel convertArray:results toClass:[UserModel class] keyCorrespond:nil];
        for ( int i=0; i<users.count; i++) {
            UserModel *model = users[i];
            model.testNum = 0;
        }        
        [tempUserList addObjectsFromArray: users ];
    } fail:^(APIOperation *api, NSError *error) {
        NSLog(@"error !");
    }];
    [apiQueue addOperation: api ];
}



@end
