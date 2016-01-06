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
    KHCollectionDataBinder *dataBinder;
    NSMutableArray *userList;
    
    NSOperationQueue *queue;
    
    NSMutableArray *tempArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    queue = [[NSOperationQueue alloc] init];
    tempArray = [[NSMutableArray alloc] init];
    
    dataBinder = [[KHCollectionDataBinder alloc] init];
    dataBinder.collectionView = self.collectionView;
    dataBinder.delegate = self;
    [dataBinder bindModel:[UserModel class] cell:[UserInfoColCell class]];
    [dataBinder addTarget:self action:@selector(cellbtnClick:model:) event:UIControlEventTouchUpInside cell:[UserInfoColCell class] propertyName:@"btn"];
    userList = [dataBinder createBindArray];
    dataBinder.refreshFootEnabled = YES;
    dataBinder.refreshHeadEnabled = YES;
    dataBinder.lastUpdate = [[NSDate date] timeIntervalSince1970];
    
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
//    NSLog(@"collection view reload");
    [self performSelector:@selector(refreshEnd) withObject:nil afterDelay:1.5];
}

- (void)collectionViewRefreshFoot:(nonnull UICollectionView *)collectionView
{
//    NSLog(@"collection view load more");
    [self performSelector:@selector(refreshEnd) withObject:nil afterDelay:1.5];
}

- (void)refreshEnd
{
    [dataBinder endRefreshing];
    
}
#pragma mark - UI Event

- (IBAction)backClick:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cellbtnClick:(id)sender model:(UserModel*)model
{
    NSLog(@"cell %ld click, name:%@ %@", model.index.row, model.user.name.first, model.user.name.last );
}

- (IBAction)queryClick:(id)sender
{
    //  使用自訂的 http connection handle
    //--------------------------------------------------
    NSDictionary* param = @{@"results": @15 };
    APIOperation *api = [[APIOperation alloc] init];
    api.debug = YES;
    [api GET:@"http://api.randomuser.me/" param:param body:nil response:^(APIOperation *api, id responseObject) {
        NSArray *results = responseObject[@"results"];
        NSArray *users = [KVCModel convertArray:results toClass:[UserModel class] keyCorrespond:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            for ( int i=0; i<users.count; i++) {
                UserModel *model = users[i];
                if ( i<10) {
                    [userList addObject: model ];
                }
                else{
                    [tempArray addObject:model];
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
    if ( tempArray.count == 0 ) {
        NSLog(@"no temp data");
        return;
    }
    int idx = arc4random() % tempArray.count;
    UserModel *umodel = tempArray[idx];
    [tempArray removeObject:umodel];
    
    int insert_idx = arc4random() % userList.count;
    [userList insertObject:umodel atIndex: insert_idx ];

}

- (IBAction)removeLastClick:(id)sender 
{
    UserModel *umodel = [userList lastObject];
    [tempArray insertObject:umodel atIndex:0];
    [userList removeLastObject];

}

- (IBAction)replaceClick:(id)sender 
{
    if ( tempArray.count == 0 ) {
        NSLog(@"no temp data");
        return;
    }
    int idx = arc4random() % tempArray.count;
    UserModel *umodel = tempArray[idx];
    [tempArray removeObject:umodel];
    
    int replace_idx = arc4random() % userList.count;
    UserModel *rmodel = userList[replace_idx];
    [userList replaceObjectAtIndex:replace_idx withObject:umodel ];
    [tempArray insertObject:rmodel atIndex:0];

}

@end
