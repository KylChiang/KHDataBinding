//
//  ViewController.m
//  DataBindTest
//
//  Created by GevinChen on 2015/8/30.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import "ViewController.h"
#import "MyCell.h"
#import "KHBindHelper.h"
#import "APIOperation.h"
#import "UserModel.h"
#import "UserInfoCell.h"
#import "CollectionDemoController.h"

//#import "AFNetworking.h"
//#import "MyAPISerializer.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UIButton *btnStopRefresh;
@property (weak, nonatomic) IBOutlet UIButton *btnQuery;


@end

@implementation ViewController
{
    
    KHTableBindHelper* tableBindHelper;
    
    KHObservableArray* models;
    KHObservableArray* itemList;
    
    NSOperationQueue *queue;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    queue = [[NSOperationQueue alloc] init];
    
    //  init
    tableBindHelper = [[KHTableBindHelper alloc] initWithTableView:self.tableView delegate:self];
    
    //  enable refresh header and footer
    tableBindHelper.enableRefreshHeader = YES;
    tableBindHelper.enableRefreshFooter = YES;

    //  create bind array
    models = [tableBindHelper createBindArray]; //  section 0
    itemList = [tableBindHelper createBindArray]; // section 1
    
    //  assign event handler
    [tableBindHelper setHeaderTitles: @[@"User Profile",@"Default Cell"]];
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
    
    [tableBindHelper bindModel:[UserModel class] cell:[UserInfoCell class]];
    
    [self loadTableView4];
}

-(void)loadTableView4
{
    KHTableCellModel *item1 = [[KHTableCellModel alloc] init];
    item1.text = @"Title1";
    item1.detail = @"detail1";
    KHTableCellModel *item2 = [[KHTableCellModel alloc] init];
    item2.text = @"Title2";
    item2.detail = @"detail2";
    KHTableCellModel *item3 = [[KHTableCellModel alloc] init];
    item3.text = @"Title3";
    item3.detail = @"detail3";
    KHTableCellModel *item4 = [[KHTableCellModel alloc] init];
    item4.text = @"Title4";
    item4.detail = @"detail4";
    
    [itemList addObject:item1];
    [itemList addObject:item2];
    [itemList addObject:item3];
    [itemList addObject:item4];
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
        NSArray *users = [KVCModel convertArray:results toClass:[UserModel class] keyCorrespond:nil];
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


- (IBAction)nextClick:(id)sender
{
    CollectionDemoController *vc = [CollectionDemoController new];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)btnclick:(id)sender model:(KHCellModel*)model
{
    printf("btn click %ld\n", model.index.row );
}

- (void)valueChanged:(id)sender model:(KHCellModel*)model
{
    printf("value changed %ld\n", model.index.row );
}

- (IBAction)searchClick:(id)sender {
    [models removeAllObjects];
    [self userQuery ];
}

- (IBAction)addClick:(id)sender {
//    [tableBindHelper refreshCompleted];
    [[KHImageDownloader instance] clearAllCache];
}






@end

