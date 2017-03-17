//
//  AutoPaginatingCollectionViewDemoViewController.m
//  KHDataBindingDemo
//
//  Created by Calvin Huang on 09/02/2017.
//  Copyright © 2017 CapsLock Studio. All rights reserved.
//

#import "AutoPaginatingCollectionViewDemoViewController.h"

// Models
#import "UserModel.h"

// Views
#import "UserInfoColCell.h"
#import "MyColHeaderView.h"

// Utilities
#import "APIOperation.h"
#import "KHCollectionView.h"

@interface AutoPaginatingCollectionViewDemoViewController () <KHCollectionViewDelegate>

@property (nonatomic, weak) IBOutlet KHCollectionView *collectionView;

@end

@implementation AutoPaginatingCollectionViewDemoViewController
{
    //  user data model array
    NSMutableArray *userList;
    
    //  api request queue
    NSOperationQueue *apiQueue;
    
    //  paginating index
    NSInteger currentPage;
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
    currentPage = 0;
}

#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    //  assign delegate
    self.collectionView.kh_delegate = self;
    
    //  enable pull down to refresh
    self.collectionView.enabledPulldownRefresh = YES;
    
    //  enable scroll to bottom to call collectionViewOnEndReached:
    self.collectionView.enabledLoadingMore = YES;
    
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
    UserModel *model = [self.collectionView modelForUIControl:sender];
    NSIndexPath *index = [self.collectionView indexPathForModel:model];
    NSLog(@"%ld test clicked, name:%@ %@", (long)index.row, model.name.first, model.name.last );
    model.testNum += 1;
}

//  update button on cell
- (void)cellBtnUpdateClicked:(id)sender
{
    UserModel *model = [self.collectionView modelForUIControl:sender];
    NSIndexPath *index = [self.collectionView indexPathForModel:model];
    NSLog(@"%ld update clicked", (long)index.row );
}

//  remove button on cell
- (void)cellBtnRemoveClicked:(id)sender
{
    UserModel *model = [self.collectionView modelForUIControl:sender];
    NSIndexPath *index = [self.collectionView indexPathForModel:model];
    NSLog(@"%ld remove clicked, name:%@ %@", (long)index.row, model.name.first, model.name.last );
    [userList removeObject:model];
}

- (IBAction)dismissViewContrller:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - KHCollectionViewDelegate

//  pull down refresh
- (void)collectionView:(KHCollectionView*_Nonnull)collectionView onPulldown:(UIRefreshControl *_Nonnull)refreshControl
{
    [userList removeAllObjects];
    currentPage = 0;
    [self fetchUsers];
}

//  loading more
- (void)collectionViewOnEndReached:(KHCollectionView *)collectionView
{
    currentPage += 1;
    [self fetchUsers];
}

#pragma mark - API

- (void)fetchUsers
{
    //  @todo:之後改用 AFNetworking 3.0
    //  使用自訂的 http connection handle
    //--------------------------------------------------
    NSDictionary *param = @{@"results": @7 };
    APIOperation *api = [[APIOperation alloc] init];
    api.debug = YES;
    __weak typeof(self) w_self = self;
    [api GET:@"http://api.randomuser.me/" param:param body:nil response:^(APIOperation *api, id responseObject) {
        NSArray *results = responseObject[@"results"];
        NSArray *users = [KVCModel convertArray:results toClass:[UserModel class] keyCorrespond:nil];
        // 
        for ( int i=0; i<users.count; i++) {
            UserModel *model = users[i];
            //  you can specify fix size, otherwise use default size from xib
            // [self.collectionView setCellSize:(CGSize){140,220} model:model];
            model.testNum = 0;
        }
        
        //  this line will make collectionView display UserInfoColCell of same count of users
        [userList addObjectsFromArray: users ];
        
        [w_self.collectionView endRefreshing];
    } fail:^(APIOperation *api, NSError *error) {
        NSLog(@"error !");
        [w_self.collectionView endRefreshing];
    }];
    [apiQueue addOperation: api ];
}

@end
