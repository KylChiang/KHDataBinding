//
//  AutoExpandHeightDemoController.m
//  KHDataBindingDemo
//
//  Created by GevinChen on 2017/3/6.
//  Copyright © 2017年 omg. All rights reserved.
//

#import "CollectionViewAutoExpandHeightDemoController.h"

// Models
#import "UserModel.h"

// Views
#import "UserInfoColCell.h"
#import "MyColHeaderView.h"

// Utilities
#import "APIOperation.h"
#import "KHCollectionView.h"


@interface CollectionViewAutoExpandHeightDemoController () <KHCollectionViewDelegate>


@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet KHCollectionView *collectionView;



@end

@implementation CollectionViewAutoExpandHeightDemoController
{
    //  user data model array
    NSMutableArray *userList;
    NSMutableArray *tempUserList;
    
    //  api request queue
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
    tempUserList = [[NSMutableArray alloc] init];
}

#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.collectionView.autoExpandHeight = YES;
    
    //  config model/cell mapping 
    [self.collectionView setMappingModel:[UserModel class] cell:[UserInfoColCell class]];
    
    //  create an empty section array, if you add an UserModel model into userList, it will display an UserInfoColCell in collectionView
    userList = [self.collectionView createSection];
    
    // set event handle
    [self.collectionView addTarget:self
                            action:@selector(cellBtnClicked:)
                  forControlEvents:UIControlEventTouchUpInside
                            onCell:[UserInfoColCell class]
                      propertyName:@"btn"];
    
    [self.collectionView addTarget:self
                            action:@selector(cellBtnUpdateClicked:)
                  forControlEvents:UIControlEventTouchUpInside
                            onCell:[UserInfoColCell class]
                      propertyName:@"btnUpdate"];
    
    [self.collectionView addTarget:self
                            action:@selector(cellBtnRemoveClicked:)
                  forControlEvents:UIControlEventTouchUpInside
                            onCell:[UserInfoColCell class]
                      propertyName:@"btnRemove"];
    
    //  config model mapping with header and footer 
    [self.collectionView setMappingModel:[NSMutableDictionary class] headerClass:[MyColHeaderView class]];
    [self.collectionView setMappingModel:[NSMutableDictionary class] footerClass:[MyColHeaderView class]];
    
    //  assign header/footer model at section, this will make section 0 display header(MyColHeaderView)/footer(MyColHeaderView)
    [self.collectionView setHeaderModel:[@{@"title":@"Header View"} mutableCopy] atIndex:0];
    [self.collectionView setFooterModel:[@{@"title":@"Footer View"} mutableCopy] atIndex:0];
    
    [self fetchUsers];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.collectionView removeAllTarget];
}

#pragma mark - UIButton Clicked

//  test button on cell
- (void)cellBtnClicked:(id)sender
{
    UserModel *model = [self.collectionView modelForUI:sender];
    NSIndexPath *index = [self.collectionView indexPathForModel:model];
    NSLog(@"%ld test clicked, name:%@ %@", (long)index.row, model.name.first, model.name.last );
    model.testNum += 1;
}

//  update button on cell
- (void)cellBtnUpdateClicked:(id)sender
{
    UserModel *model = [self.collectionView modelForUI:sender];
    NSIndexPath *index = [self.collectionView indexPathForModel:model];
    NSLog(@"%ld update clicked", (long)index.row );
}

//  remove button on cell
- (void)cellBtnRemoveClicked:(id)sender
{
    UserModel *model = [self.collectionView modelForUI:sender];
    NSIndexPath *index = [self.collectionView indexPathForModel:model];
    NSLog(@"%ld remove clicked, name:%@ %@", (long)index.row, model.name.first, model.name.last );
    [tempUserList addObject:model];
    [userList removeObject:model];
}

- (IBAction)dismissViewContrller:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)btnAddOneClicked:(id)sender 
{
    if ( tempUserList.count > 0 ) {
        [userList addObject: tempUserList[0] ];
        [tempUserList removeObjectAtIndex:0];
    }
}


#pragma mark - API

- (void)fetchUsers
{
    //  @todo:之後改用 AFNetworking 3.0
    //  使用自訂的 http connection handle
    //--------------------------------------------------
    NSDictionary *param = @{@"results": @10 };
    APIOperation *api = [[APIOperation alloc] init];
    api.debug = YES;
//    __weak typeof(self) w_self = self;
    [api GET:@"http://api.randomuser.me/" param:param body:nil response:^(APIOperation *api, id responseObject) {
        NSArray *results = responseObject[@"results"];
        NSArray *users = [KVCModel convertArray:results toClass:[UserModel class] keyCorrespond:nil];
        // 
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
