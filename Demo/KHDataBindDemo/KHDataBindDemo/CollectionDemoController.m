//
//  CollectionDemoController.m
//  KHDataBindDemo
//
//  Created by GevinChen on 2015/11/16.
//  Copyright © 2015年 omg. All rights reserved.
//

#import "CollectionDemoController.h"
#import "KHDataBinder.h"
#import "APIOperation.h"
#import "UserInfoColCell.h"
#import "UserModel.h"


@interface CollectionDemoController () <KHCollectionViewDelegate>

@end

@implementation CollectionDemoController
{
    //  collection view 的 data binder
    KHCollectionDataBinder *dataBinder;
    
    //  user data model array
    NSMutableArray *userList;
    
    //  api request queue
    NSOperationQueue *queue;
    
    //  user model temp array
    NSMutableArray *userTempList;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    queue = [[NSOperationQueue alloc] init];
    userTempList = [[NSMutableArray alloc] init];
    
    //  init collection view data binder
    dataBinder = [[KHCollectionDataBinder alloc] initWithCollectionView:self.collectionView delegate:self registerClass:[UserInfoColCell class],nil];
    //  bind array
    userList = [dataBinder createBindArray];
    //  config ui event handle of cell
    weakRef(dataBinder);
    weakRef(userList);
    [dataBinder addEvent:UIControlEventTouchUpInside cell:[UserInfoColCell class] propertyName:@"btn" handler:^(id sender, UserModel *model) {
        NSIndexPath *index = [weak_dataBinder indexPathOfModel:model];
        NSLog(@"click cell %ld , name:%@ %@", index.row, model.name.first, model.name.last );
        model.testNum = @( [model.testNum intValue] + 1 );
    }];
    [dataBinder addEvent:UIControlEventTouchUpInside cell:[UserInfoColCell class] propertyName:@"btnUpdate" handler:^(id sender, UserModel *model) {
        NSIndexPath *index = [weak_dataBinder indexPathOfModel:model];
        NSLog(@"update cell %ld", index.row );
    }];
    [dataBinder addEvent:UIControlEventTouchUpInside cell:[UserInfoColCell class] propertyName:@"btnRemove" handler:^(id sender, UserModel *model) {
        NSIndexPath *index = [weak_dataBinder indexPathOfModel:model];
        NSLog(@"remove cell %ld , name:%@ %@", index.row, model.name.first, model.name.last );
        [weak_userList removeObject:model];
    }];
    
    //  enable pull down to update
    dataBinder.refreshFootEnabled = YES;
    dataBinder.refreshHeadEnabled = YES;
    
    //  set string that will display when pull down
    dataBinder.lastUpdate = [[NSDate date] timeIntervalSince1970];
//    MyLayout *layout = [[MyLayout alloc] init];
//    dataBinder.layout = layout;
    
    //  config cell dynamic size
    //  set layout estimatedItemSize to enable cell dynamic size
    //  custom cell should also override preferredLayoutAttributesFittingAttributes:
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    layout.estimatedItemSize = CGSizeMake(100, 100);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

}


#pragma mark - Collection

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
//    NSLog(@"click %ld", indexPath.row );
}

- (void)collectionViewRefreshHead:(nonnull UICollectionView *)collectionView
{
    [self queryClick:nil];
}


- (void)refreshEnd
{

    
}
#pragma mark - UI Event

- (IBAction)backClick:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

//- (void)cellbtnClick:(id)sender model:(UserModel*)model
//{
//    NSIndexPath *index = [dataBinder indexPathOfModel:model];
//    NSLog(@"click cell %ld , name:%@ %@", index.row, model.name.first, model.name.last );
//    model.testNum = @( [model.testNum intValue] + 1 );
//}

//- (void)cellbtnUpdate:(id)sender model:(UserModel*)model
//{
//    NSIndexPath *index = [dataBinder indexPathOfModel:model];
//    NSLog(@"update cell %ld", index.row );
//}

//- (void)cellbtnRemove:(id)sender model:(UserModel*)model
//{
//    NSIndexPath *index = [dataBinder indexPathOfModel:model];
//    NSLog(@"remove cell %ld , name:%@ %@", index.row, model.name.first, model.name.last );
//    [userList removeObject:model];
//}


- (IBAction)queryClick:(id)sender
{
    //  使用自訂的 http connection handle
    //--------------------------------------------------
    NSDictionary* param = @{@"results": @7 };
    APIOperation *api = [[APIOperation alloc] init];
    api.debug = YES;
    [api GET:@"http://api.randomuser.me/" param:param body:nil response:^(APIOperation *api, id responseObject) {
        NSArray *results = responseObject[@"results"];
        NSArray *users = [KVCModel convertArray:results toClass:[UserModel class] keyCorrespond:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            for ( int i=0; i<users.count; i++) {
                UserModel *model = users[i];
                if ( i<5) {
                    [userList addObject: model ];
                }
                else{
                    [userTempList addObject:model];
                }
            }
        });
        [dataBinder endRefreshing];
    } fail:^(APIOperation *api, NSError *error) {
        NSLog(@"error !");
        [dataBinder endRefreshing];
    }];
    [queue addOperation: api ];
}

- (IBAction)stopRefreshClick:(id)sender
{
    [dataBinder endRefreshing];
}

- (IBAction)insertClick:(id)sender 
{
    if ( userTempList.count == 0 ) {
        NSLog(@"no temp data");
        return;
    }
    int idx = arc4random() % userTempList.count;
    UserModel *umodel = userTempList[idx];
    [userTempList removeObject:umodel];
    
    int insert_idx = arc4random() % userList.count;
    [userList insertObject:umodel atIndex: insert_idx ];

}

- (IBAction)removeLastClick:(id)sender 
{
    UserModel *umodel = [userList lastObject];
    [userTempList insertObject:umodel atIndex:0];
    [userList removeLastObject];
}

- (IBAction)replaceClick:(id)sender 
{
    if ( userTempList.count == 0 ) {
        NSLog(@"no temp data");
        return;
    }
    int idx = arc4random() % userTempList.count;
    UserModel *umodel = userTempList[idx];
    [userTempList removeObject:umodel];
    
    int replace_idx = arc4random() % userList.count;
    UserModel *rmodel = userList[replace_idx];
    [userList replaceObjectAtIndex:replace_idx withObject:umodel ];
    [userTempList insertObject:rmodel atIndex:0];

}

@end
