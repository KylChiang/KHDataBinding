//
//  ViewController.m
//  DataBindTest
//
//  Created by GevinChen on 2015/8/30.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import "ViewController.h"
//#import "MyCell.h"
#import "KHDataBinding.h"
#import "APIOperation.h"
#import "UserModel.h"
#import "UserInfoCell.h"
#import "CollectionDemoController.h"
#import <CoreData/CoreData.h>
#import "MyFooterView.h"
#import "MyDemoCellTableViewCell.h"


//#import "AFNetworking.h"
//#import "MyAPISerializer.h"

/*
 1. 建立你的 custom data model，不需要繼承特定類別
 2. 建立你的 custom cell，繼承 UITableViewCell or UICollectionViewCell，並且要同時建立nib，載入時會去尋找與class同名的 nib file
 3. custom cell 要實作一個 onLoad:(id)model method，裡面做的事就是把 data model 的資料填入 cell 的 ui
 4. 在 controller 宣告，並且生成一個 dataBinder 或是 CollectionDataBinder，把 tableView 或是 collectionView 傳入
 5. 把 array 與 data binder 做綁定
 6. 對 binder 設定 哪個 data model 要餵哪個 cell
 7. 把 model 的實體加入 array
 8. done!
 
 */

@interface ViewController () <KHDataBindingDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UIButton *btnStopRefresh;
@property (weak, nonatomic) IBOutlet UIButton *btnQuery;

//@property (nonatomic) NSManagedObjectContext *managedObjectContext;
//@property (nonatomic) NSManagedObjectModel *managedObjectModel;
//@property (nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end

@implementation ViewController
{
    //  data binder
    KHTableDataBinding* dataBinder;
    
    //  user model array
    NSMutableArray<UserModel*> *userList;
    
    //  UITableViewCellModel array
    NSMutableArray<UITableViewCellModel*> *itemList;
    
    //  operation queue for api call
    NSOperationQueue *apiQueue;
    
    NSMutableArray *tempUserModelList;
}



- (void)viewDidLoad {
    [super viewDidLoad];
    
    apiQueue = [[NSOperationQueue alloc] init];
    tempUserModelList = [[NSMutableArray alloc] initWithCapacity:10];
    
    //  init
    dataBinder = [[KHTableDataBinding alloc] initWithView:self.tableView delegate:self registerClass:@[[UserInfoCell class],[MyDemoCellTableViewCell class]]];

    //  enable refresh header and footer
    dataBinder.refreshHeadEnabled = YES;
    dataBinder.refreshFootEnabled = YES;
    dataBinder.headTitle = @"Pull Down To Refresh";

    //  header title
    [dataBinder setHeaderTitles: @[@"User Profile",@"Default Cell"]];
    
    //  footer title
//    [dataBinder setFooterTitles: @[@"footer title1", @"footer title1", @"footer title3"]];
    
    //  footer view
//    UINib* nib = [UINib nibWithNibName:@"MyFooterView" bundle:nil];
//    NSArray* arr = [nib instantiateWithOwner:nil options:nil];
//    MyFooterView *mfv = arr[0];
//    [dataBinder setFooterView:mfv atSection:1];
    
    //  create bind array
    userList = [dataBinder createBindArray]; //  section 0
    
    itemList = [dataBinder createBindArray]; // section 1
    // KHTableDataBinding define that UITableViewCellModel mapping with UITableViewCell as default, you don't need to bind again.
    
    weakRef( dataBinder );
    weakRef( userList );
    //  config button of cell event handle
    [dataBinder addEvent:UIControlEventTouchUpInside
                    cell:[UserInfoCell class]
            propertyName:@"btn"
                 handler:^(id sender, id model) {
                     NSIndexPath *index = [weak_dataBinder indexPathOfModel:model];
                     printf("btn click %ld\n", (long)index.row );
                     [weak_userList removeObject:model];
                  }];
    [dataBinder addEvent:UIControlEventTouchUpInside
                    cell:[UserInfoCell class]
            propertyName:@"btnUpdate"
                 handler:^(id sender, id model) {
                     NSIndexPath *index = [weak_dataBinder indexPathOfModel:model];
                     printf("btn update click %ld\n", (long)index.row );
                     UserModel *umodel = model;
                     umodel.testNum = @( [umodel.testNum intValue] + 1 );
                 }];
    [dataBinder addEvent:UIControlEventValueChanged
                    cell:[UserInfoCell class]
            propertyName:@"sw"
                 handler:^(id sender, id model) {
                     NSIndexPath *index = [weak_dataBinder indexPathOfModel:model];
                     //    KHPairInfo *cellProxy = [dataBinder cellProxyWithModel:model];
                     printf("value changed %ld\n", (long)index.row );
                 }];
    
    //  set string when pull down
    dataBinder.lastUpdate = [[NSDate date] timeIntervalSince1970];
    
    //  load list cell
    [self loadTableView4];
}

-(void)loadTableView4
{
    UITableViewCellModel *item1 = [[UITableViewCellModel alloc] init];
    item1.text = @"Title1";
    item1.detail = @"detail1";
    item1.cellStyle = UITableViewCellStyleDefault;
    UITableViewCellModel *item2 = [[UITableViewCellModel alloc] init];
    item2.text = @"Title2";
    item2.detail = @"detail2";
    item2.cellStyle = UITableViewCellStyleValue1;
    UITableViewCellModel *item3 = [[UITableViewCellModel alloc] init];
    item3.text = @"Title3";
    item3.detail = @"detail3";
    item3.cellStyle = UITableViewCellStyleValue2;
    UITableViewCellModel *item4 = [[UITableViewCellModel alloc] init];
    item4.text = @"Title4";
    item4.detail = @"detail4";
    item4.cellStyle = UITableViewCellStyleSubtitle;
    
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
    //  random user icon
    //  http://api.randomuser.me/?results=10

    //  使用自訂的 http connection handle
    //--------------------------------------------------
    NSDictionary* param = @{@"results": @10 };
    APIOperation *api = [[APIOperation alloc] init];
    api.debug = YES;
    [api GET:@"http://api.randomuser.me/" param:param body:nil response:^(APIOperation *api, id responseObject) {
        NSArray *results = responseObject[@"results"];
        NSArray *users = [KVCModel convertArray:results toClass:[UserModel class] keyCorrespond:@{@"ID":@"id"}];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSMutableArray *_array = [[NSMutableArray alloc] init];
            for ( int i=0 ; i<users.count ; i++ ) {
                UserModel *model = users[i];
                
                //  前半加入 table view，後半先保留起來，用來測試 insert
                if ( i < 5 ) {
                    [_array addObject:model];
                }
                else{
                    [tempUserModelList addObject:model];
                }
            }
            [userList addObjectsFromArray:_array ];
        });
        [dataBinder endRefreshing];
    } fail:^(APIOperation *api, NSError *error) {
        NSLog(@"error !");
        [dataBinder endRefreshing];
    }];
    [apiQueue addOperation: api ];
    
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
//            NSMutableArray *_array = [[NSMutableArray alloc] init];
//            for ( int i=0 ; i<users.count ; i++ ) {
//                UserModel *model = users[i];
//                
//                //  前半加入 table view，後半先保留起來，用來測試 insert
//                if ( i < ( users.count / 2 ) ) {
//                    [_array addObject:model];
//                }
//                else{
//                    [tempUserModelList addObject:model];
//                }
//            }
//            [userList addObjectsFromArray:_array ];
//        });
//        [dataBinder endRefreshing];
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
//            NSMutableArray *_array = [[NSMutableArray alloc] init];
//            for ( int i=0 ; i<users.count ; i++ ) {
//                UserModel *model = users[i];
//                
//                //  前半加入 table view，後半先保留起來，用來測試 insert
//                if ( i < ( users.count / 2 ) ) {
//                    [_array addObject:model];
//                }
//                else{
//                    [tempUserModelList addObject:model];
//                }
//            }
//            [userList addObjectsFromArray:_array ];
//        });
//        [dataBinder endRefreshing];
//    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//        NSLog(@"error!!");
//    }];
//    [apiQueue addOperation: operation ];
    
}



#pragma mark - UI


#pragma mark - Table Bind Event

- (void)tableViewRefreshHead:(nonnull UITableView *)tableView
{
    NSLog(@"refresh");
}

- (void)tableViewRefreshFoot:(nonnull UITableView *)tableView
{
    NSLog(@"load more");
}

-(void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSLog(@"cell click %ld",(long)indexPath.row );
}

#pragma mark - UI Event


- (IBAction)nextClick:(id)sender
{
    CollectionDemoController *vc = [CollectionDemoController new];
    [self presentViewController:vc animated:YES completion:nil];
}

//- (void)btnclick:(id)sender model:(id)model
//{
//    NSIndexPath *index = [dataBinder indexPathOfModel:model];
//    printf("btn click %i\n", index.row );
//    [userList removeObject:model];
//}

//- (void)btnUpdateclick:(id)sender model:(id)model
//{
//    NSIndexPath *index = [dataBinder indexPathOfModel:model];
//    printf("btn update click %ld\n", index.row );
//    UserModel *umodel = model;
//    umodel.testNum = @( [umodel.testNum intValue] + 1 );
//}

//- (void)valueChanged:(id)sender model:(id)model
//{
//    NSIndexPath *index = [dataBinder indexPathOfModel:model];
////    KHPairInfo *cellProxy = [dataBinder cellProxyWithModel:model];
//    printf("value changed %ld\n", index.row );
//}

- (IBAction)searchClick:(id)sender 
{
    [userList removeAllObjects];
    [self userQuery ];
}

- (IBAction)addClick:(id)sender 
{
//    [dataBinder endRefreshing];
//    [userList removeObjectAtIndex:2];
    
//    UITableViewCellModel *item = itemList[1];
//    item.text = @"test";
//    item.detail = @"fuck you";
//    NSLog(@">>  modify end");
}


- (IBAction)insertClick:(id)sender 
{
    if ( tempUserModelList.count == 0 ) {
        NSLog(@"no temp data");
        return;
    }
    int idx = arc4random() % tempUserModelList.count;
    UserModel *umodel = tempUserModelList[idx];
    [tempUserModelList removeObject:umodel];
    
    int insert_idx = arc4random() % userList.count;
    [userList insertObject:umodel atIndex: insert_idx ];
    
}


- (IBAction)removeLastClick:(id)sender 
{
    UserModel *umodel = [userList lastObject];
    [tempUserModelList insertObject:umodel atIndex:0];
    [userList removeLastObject];
}


- (IBAction)replaceClick:(id)sender 
{
    if ( tempUserModelList.count == 0 ) {
        NSLog(@"no temp data");
        return;
    }
    int idx = arc4random() % tempUserModelList.count;
    UserModel *umodel = tempUserModelList[idx];
    [tempUserModelList removeObject:umodel];
    
    int replace_idx = arc4random() % userList.count;
    UserModel *rmodel = userList[replace_idx];
    [userList replaceObjectAtIndex:replace_idx withObject:umodel ];
    [tempUserModelList insertObject:rmodel atIndex:0];
}

//- (void)setupManagedObjectContext
//{
//    //讀取資料模型來生成被管理的物件Managedobject
//    
//    //  初始操作資料庫的物件，類似設定 table scheme
//    NSURL *modelURL = [[NSBundle mainBundle]URLForResource:@"UserDataModel" withExtension:@"momd"];
//    self.managedObjectModel = [[NSManagedObjectModel alloc]initWithContentsOfURL:modelURL];
//    
//    //  Managed Object Context參與對數據對象進行各種操作的全過程，並監測資料對象的變化，以提供對undo/redo的支持及更新綁定到資料的UI。
//    self.managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
//    self.managedObjectContext.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
//    
//    //  指定資料庫實體檔案的位址
//    NSError* error;
//    NSURL *documentFolderPath = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentationDirectory inDomains:NSUserDomainMask] lastObject];
//    NSURL *sqlURL = [documentFolderPath URLByAppendingPathComponent:@"user.sqlite"];
//    [self.managedObjectContext.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
//                                                                       configuration:nil
//                                                                                 URL:sqlURL
//                                                                             options:nil
//                                                                               error:&error];
//    if (error) {
//        NSLog(@"error: %@", error);
//    }
//    self.managedObjectContext.undoManager = [[NSUndoManager alloc] init];
//}

//  新增
//- (void)addData
//{
//    //  新增一個 row
//    UserModel *model = (UserModel*)[NSEntityDescription insertNewObjectForEntityForName:@"UserModel" inManagedObjectContext:self.managedObjectContext];
//    
//    // 填入資料
//    // Gevin note: 這裡應該就是，透過 dictionary 的 key 來填資料
//    // Gevin note: 或許，新增很多個，但可以不存？
//    // Gevin note: 如果有多個 managed context？
//    //  ....
//    
//    [userList addObject:model];
//    
//    // 儲存
//    NSError *error = nil;
//    if ( ![self.managedObjectContext save:&error] ) {
//        NSLog(@"儲存發生錯誤");
//    }
//}

//  清除
//- (void)removeData
//{
//    //  刪除資料 
//    for ( int i=0; i<userList.count; i++) {
//        UserModel *model = userList[i];
//        [self.managedObjectContext deleteObject:model];
//    }
//    
//    [userList removeAllObjects];
//    
//    //  儲存
//    NSError *error = nil;
//    if ( [self.managedObjectContext save:&error]) {
//        NSLog(@"刪除發生錯誤");
//    }
//}

//  取出資料
//- (void)loadData
//{
//    NSFetchRequest *request = [[NSFetchRequest alloc] init];
//    NSEntityDescription *entity = [NSEntityDescription entityForName:@"UserModel" inManagedObjectContext:self.managedObjectContext];
//    
//    [request setEntity:entity];
//    NSError *error = nil;
//    NSMutableArray *array = [[self.managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
//}

//  更新
//- (void)updateData
//{
//    //   取出要更新的 model
//    UserModel *model = userList[0];
//    
//    //  修改資料
//    //  ....
//    
//    //  儲存
//    NSError *error = nil;
//    if ([self.managedObjectContext save:&error]) {
//        NSLog(@"更新資料發生錯誤");
//    }
//}



@end

