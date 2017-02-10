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
#import "KHDataBinding.h"

@interface AutoPaginatingCollectionViewDemoViewController () <KHDataBindingDelegate>

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;

@property (nonatomic, strong) KHCollectionDataBinding *dataBinding;

@property (nonatomic, strong) NSMutableArray<UserModel *> *userInfos;

@property (nonatomic, strong) NSOperationQueue *apiOperationQueue;

@property (nonatomic, assign) NSInteger currentPage;

@end

@implementation AutoPaginatingCollectionViewDemoViewController

#pragma mark - Initializers
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self initiailizeDefaultProperties];
    }
    
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self initiailizeDefaultProperties];
    }
    
    return self;
}

- (void)initiailizeDefaultProperties
{
    _apiOperationQueue = [[NSOperationQueue alloc] init];
    _currentPage = 0;
}

#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.dataBinding = [[KHCollectionDataBinding alloc] initWithView:self.collectionView
                                                            delegate:self
                                                       registerClass:@[ [UserInfoColCell class] ]];
    
    self.dataBinding.refreshHeadEnabled = YES;
    self.dataBinding.isLoading = YES;
    
    // Invoke onEndReached above the end.
    self.dataBinding.onEndReachedThresHold = 100;
    
    self.userInfos = [self.dataBinding createBindArray];
    
    typeof(self) __weak weakself = self;
    
    // Add HeaderModel & FooterModel, if Model exists, update model.
    [self.dataBinding setHeaderModel:[@{ @"title":@"Header View" } mutableCopy] atIndex:0];
    [self.dataBinding setFooterModel:[@{ @"title":@"Footer View" } mutableCopy] atIndex:0];
    
    //  config button of cell event handle
    [self.dataBinding addEvent:UIControlEventTouchUpInside
                          cell:[UserInfoCell class]
                  propertyName:@"btn"
                       handler:^(id sender, id model) {
                           [weakself.userInfos removeObject:model];
                       }];
    [self.dataBinding addEvent:UIControlEventTouchUpInside
                          cell:[UserInfoCell class]
                  propertyName:@"btnUpdate"
                       handler:^(id sender, UserModel *model) {
                           model.testNum = @([model.testNum integerValue] + 1);
                       }];
    [self.dataBinding addEvent:UIControlEventValueChanged
                          cell:[UserInfoCell class]
                  propertyName:@"btnRemove"
                       handler:^(id sender, id model) {
                           NSIndexPath *indexPath = [weakself.dataBinding indexPathOfCell:model];
                           NSLog(@"Value changed at indexPath: %@-%@", @(indexPath.section), @(indexPath.row));
                       }];
    
    //  config cell dynamic size
    //  set layout estimatedItemSize to enable cell dynamic size
    //  custom cell should also override preferredLayoutAttributesFittingAttributes:
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    layout.estimatedItemSize = CGSizeMake(100, 100);
    
    [self fetchUsers];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IBActions
- (IBAction)dismissViewContrller:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - KHDataBindingDelegate
- (void)onEndReached:(KHDataBinding *)dataBinding
{
    self.currentPage += 1;
    
    NSLog(@"🏁 Run: %@ times", @(self.currentPage));
    
    [self fetchUsers];
}

#pragma mark - Private Methods
- (void)fetchUsers
{
    typeof(self) __weak weakself = self;
    
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
            
            weakself.dataBinding.isNeedAnimation = NO;
            
            [weakself.userInfos addObjectsFromArray:users];
            
            weakself.dataBinding.isNeedAnimation = YES;
        });
        [weakself.dataBinding endRefreshing];
    } fail:^(APIOperation *api, NSError *error) {
        NSLog(@"error !");
        [weakself.dataBinding endRefreshing];
    }];
    
    [self.apiOperationQueue addOperation: api];
}

@end
