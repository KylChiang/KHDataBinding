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
#import "MyFooterView.h"
#import "MyDemoCellTableViewCell.h"

// Utilities
#import "APIOperation.h"
#import "KHDataBinding.h"

@interface AutoPaginatingCollectionViewDemoViewController () <KHDataBindingDelegate>

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;

@property (nonatomic, strong) KHDataBinding *dataBinding;

@property (nonatomic, strong) NSMutableArray<UserModel *> *userInfos;

@property (nonatomic, strong) NSOperationQueue *apiOperationQueue;

@property (nonatomic, assign) NSInteger currentPage;

@end

@implementation AutoPaginatingCollectionViewDemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
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

@end
