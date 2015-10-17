//
//  ViewController.m
//  DataBindTest
//
//  Created by GevinChen on 2015/8/30.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import "ViewController.h"
#import "MyCell.h"
#import "KHTableViewBindHelper.h"
#import "APIOperation.h"
#import "UserModel.h"
#import "AFNetworking.h"
#import "MyAPISerializer.h"

@interface ViewController ()

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
    
    KHTableViewBindHelper* tableBindHelper;
    
    KHObservableArray* models;
    
//    APIOperation *api;
    
    NSOperationQueue *queue;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    queue = [[NSOperationQueue alloc] init];
    
    tableBindHelper = [KHTableViewBindHelper new];
    tableBindHelper.tableView = self.tableView;
    models = [[KHObservableArray alloc ] init];
    [tableBindHelper bindArray: models ];
    [tableBindHelper setCellSelectedHandle:self action:@selector(tableViewCellSelected:index:)];
    [tableBindHelper addTarget:self action:@selector(btnclick:model:) event:UIControlEventTouchUpInside];
    [tableBindHelper addTarget:self action:@selector(valueChanged:model:) event:UIControlEventValueChanged];
    [self loadTableView4];
}

-(void)loadTableView4
{
    

    
}


#pragma mark - API

//  第一，我必須要建一個 MovieModel，讓 json 可以轉成一個實體 object
//  第二，我必須要建一個 MovieCell，讓 model 可以把資料填入
//

- (void)userQuery
{
    
    //  http://api.randomuser.me/?results=10

    //  使用自訂的 http connection handle
    //--------------------------------------------------
//    NSDictionary* param = @{@"results": @10 };
//    APIOperation *api = [[APIOperation alloc] init];
//    api.debug = YES;
//    [api GET:@"http://api.randomuser.me/" param:param body:nil response:^(APIOperation *api, id responseObject) {
//        NSArray *results = responseObject[@"results"];
//        NSArray *users = [KVCModel convertArray:results toClass:[UserModel class]];
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [models addObjectsFromArray: users ];
//        });
//    } fail:^(APIOperation *api, NSError *error) {
//        NSLog(@"error !");
//    }];
//    [queue addOperation: api ];
    
    //  使用 AFNetworking
    //--------------------------------------------------
//    MyAPISerializer *serializer = [MyAPISerializer new];
//    MyAPIUnSerializer *unserializer = [MyAPIUnSerializer new];
//    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
//    manager.requestSerializer = serializer;
//    manager.responseSerializer = unserializer;
//    [manager GET:@"http://api.randomuser.me/?results=10" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
//        NSArray *results = responseObject[@"results"];
//        NSArray *users = [KVCModel convertArray:results toClass:[UserModel class]];
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [models addObjectsFromArray: users ];
//        });
//    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//        NSLog(@"error!");
//    }];
    
    //  使用 AFHTTPRequestOperation
    //--------------------------------------------------
    MyAPISerializer *serializer = [MyAPISerializer new];
    NSMutableURLRequest *request = [serializer requestWithMethod:@"POST" URLString:@"http://api.randomuser.me/?results=5" parameters:nil];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request ];
    operation.responseSerializer = [MyAPIUnSerializer new];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSArray *results = responseObject[@"results"];
        NSArray *users = [KVCModel convertArray:results toClass:[UserModel class]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [models addObjectsFromArray: users ];
        });
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"error!!");
    }];
    [queue addOperation: operation ];
    
}



#pragma mark - UI


#pragma mark - UI Event

-(void)tableViewCellSelected:(UITableView*)tableView index:(NSIndexPath*)index
{
    NSLog(@"cell click %ld",index.row );
}

- (void)btnclick:(id)sender model:(KHCellModel*)model
{
    printf("btn click %ld\n", model.index.row );
}

- (void)valueChanged:(id)sender model:(KHCellModel*)model
{
    printf("value changed %ld\n", model.index.row );
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

