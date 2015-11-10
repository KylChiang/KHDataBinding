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
#import "UserInfoCell.h"

//#import "AFNetworking.h"
//#import "MyAPISerializer.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UIButton *btnStopRefresh;
@property (weak, nonatomic) IBOutlet UIButton *btnQuery;


@end

@implementation ViewController
{
    
    KHTableViewBindHelper* tableBindHelper;
    
    KHObservableArray* models;
    
    NSOperationQueue *queue;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    queue = [[NSOperationQueue alloc] init];
    
    tableBindHelper = [KHTableViewBindHelper new];
    tableBindHelper.tableView = self.tableView;
    models = [[KHObservableArray alloc ] init];
    [tableBindHelper bindArray: models ];
    tableBindHelper.delegate = self;
    tableBindHelper.enableRefreshHeader = YES;
    tableBindHelper.enableRefreshFooter = YES;
    [tableBindHelper addTarget:self
                        action:@selector(btnclick:model:)
                         event:UIControlEventTouchUpInside 
                          cell:[UserInfoCell class] 
                  propertyName:@"btn"];
    [tableBindHelper addTarget:self
                        action:@selector(valueChanged:model:)
                         event:UIControlEventValueChanged 
                          cell:[UserInfoCell class]
                  propertyName:@"sw"];
    
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
    NSDictionary* param = @{@"results": @10 };
    APIOperation *api = [[APIOperation alloc] init];
    api.debug = YES;
    [api GET:@"http://api.randomuser.me/" param:param body:nil response:^(APIOperation *api, id responseObject) {
        NSArray *results = responseObject[@"results"];
        NSArray *users = [KVCModel convertArray:results toClass:[UserModel class]];
        for ( int i=0; i<users.count; i++) {
            UserModel *user = users[i];
            user.cellClass = [UserInfoCell class];

        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [models addObjectsFromArray: users ];
        });
        [tableBindHelper refreshCompleted];
    } fail:^(APIOperation *api, NSError *error) {
        NSLog(@"error !");
        [tableBindHelper refreshCompleted];
    }];
    [queue addOperation: api ];
    
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
//    MyAPISerializer *serializer = [MyAPISerializer new];
//    NSMutableURLRequest *request = [serializer requestWithMethod:@"POST" URLString:@"http://api.randomuser.me/?results=10" parameters:nil];
//    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request ];
//    operation.responseSerializer = [MyAPIUnSerializer new];
//    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
//        NSArray *results = responseObject[@"results"];
//        NSArray *users = [KVCModel convertArray:results toClass:[UserModel class]];
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [models addObjectsFromArray: users ];
//        });
//    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//        NSLog(@"error!!");
//    }];
//    [queue addOperation: operation ];
    
}



#pragma mark - UI


#pragma mark - Table Bind Event

- (void)refreshTrigger:(UITableView*)tableView
{
    NSLog(@"refresh");
    [models removeAllObjects];
    [self userQuery];
//    [tableBindHelper refreshCompleted];
}

- (void)loadMoreTrigger:(UITableView*)tableView
{
    NSLog(@"load more");
    [self userQuery];
}

-(void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSLog(@"cell click %ld",indexPath.row );
}

#pragma mark - UI Event

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
    [models removeAllObjects];
    [self userQuery ];
}

- (IBAction)addClick:(id)sender {
    [tableBindHelper refreshCompleted];
}






@end

