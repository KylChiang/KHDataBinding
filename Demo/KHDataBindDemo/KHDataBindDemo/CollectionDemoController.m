//
//  CollectionDemoController.m
//  KHDataBindDemo
//
//  Created by GevinChen on 2015/11/16.
//  Copyright © 2015年 omg. All rights reserved.
//

#import "CollectionDemoController.h"
#import "KHBindHelper.h"
#import "APIOperation.h"
#import "UserInfoColCell.h"
#import "UserModel.h"

@interface CollectionDemoController () <KHCollectionBindHelperDelegate>

@end

@implementation CollectionDemoController
{
    KHCollectionBindHelper *bindHelper;
    KHObservableArray *userList;
    
    NSOperationQueue *queue;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    queue = [[NSOperationQueue alloc] init];
    
    bindHelper = [[KHCollectionBindHelper alloc] init];
    bindHelper.collectionView = self.collectionView;
    bindHelper.delegate = self;
    [bindHelper bindModel:[UserModel class] cell:[UserInfoColCell class]];
    [bindHelper addTarget:self action:@selector(cellbtnClick:model:) event:UIControlEventTouchUpInside cell:[UserInfoColCell class] propertyName:@"btn"];
    userList = [bindHelper createBindArray];
    bindHelper.enableRefreshFooter = YES;
    bindHelper.enableRefreshHeader = YES;

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
    NSLog(@"click %ld", indexPath.row );
}

- (void)collectionViewRefresh:(UICollectionView *)collectionView
{
    NSLog(@"collection view reload");
    [self performSelector:@selector(refreshEnd) withObject:nil afterDelay:1.5];
}

- (void)collectionViewLoadMore:(UICollectionView *)collectionView
{
    NSLog(@"collection view load more");
    [self performSelector:@selector(refreshEnd) withObject:nil afterDelay:1.5];
}

- (void)refreshEnd
{
    [bindHelper refreshCompleted];
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
    NSDictionary* param = @{@"results": @10 };
    APIOperation *api = [[APIOperation alloc] init];
    api.debug = YES;
    [api GET:@"http://api.randomuser.me/" param:param body:nil response:^(APIOperation *api, id responseObject) {
        NSArray *results = responseObject[@"results"];
        NSArray *users = [KVCModel convertArray:results toClass:[UserModel class] keyCorrespond:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            [userList addObjectsFromArray: users ];
        });
        [bindHelper refreshCompleted];
    } fail:^(APIOperation *api, NSError *error) {
        NSLog(@"error !");
        [bindHelper refreshCompleted];
    }];
    [queue addOperation: api ];
}

@end
