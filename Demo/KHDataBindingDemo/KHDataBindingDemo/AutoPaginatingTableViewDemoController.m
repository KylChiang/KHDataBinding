//
//  AutoPaginatingTableViewDemoController.m
//  KHDataBindingDemo
//
//  Created by Calvin Huang on 09/02/2017.
//  Copyright © 2017 CpasLock Studio. All rights reserved.
//

#import "AutoPaginatingTableViewDemoController.h"

// Models
#import "UserModel.h"

// Views
#import "UserInfoCell.h"
#import "MyTableHeaderView.h"
#import "ShowArrayDataCell.h"
#import "ShowDictDataCell.h"
#import "ShowDictData2Cell.h"

// Utilities
#import "APIOperation.h"
#import "KHTableView.h"

@interface AutoPaginatingTableViewDemoController () <KHTableViewDelegate,UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet KHTableView *tableView;

@end

@implementation AutoPaginatingTableViewDemoController
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

- (void)dealloc
{
    NSLog(@"AutoPaginatingTableViewDemoController....dealloc");
}

#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    [self.tableView setMappingModel:[UserModel class] cell:[UserInfoCell class]];

    self.tableView.kh_delegate = self;

    self.tableView.enabledPulldownRefresh = YES;
    
    self.tableView.enabledLoadingMore = YES;
    
    // Invoke onEndReached above the end.
    self.tableView.onEndReachedThresHold = 100;
    
    //  create an empty section array, if you add an UserModel model into userList, it will display an UserInfoColCell in collectionView
    userList = [self.tableView createSection];

    // set event handle  
    [self.tableView addTarget:self
                       action:@selector(cellBtnReplaceClicked:)
             forControlEvents:UIControlEventTouchUpInside
                       onCell:[UserInfoCell class]
                 propertyName:@"btnReplace"];
    
    [self.tableView addTarget:self
                       action:@selector(cellBtnRemoveClicked:)
             forControlEvents:UIControlEventTouchUpInside
                       onCell:[UserInfoCell class]
                 propertyName:@"btnRemove"];
    
    [self.tableView addTarget:self
                       action:@selector(cellSwitchValueChanged:)
             forControlEvents:UIControlEventValueChanged
                       onCell:[UserInfoCell class]
                 propertyName:@"sw"];
    
    [self fetchUsers];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.tableView removeAllTarget];
}


#pragma mark - Button Event (Cell)

// cell remove button clicked
- (void)cellBtnRemoveClicked:(id)sender
{
    UserModel *model = [self.tableView getModelByUIControl:sender];
    NSIndexPath *index = [self.tableView indexPathForModel:model];
    printf("btn click %ld\n", (long)index.row );
    [userList removeObject:model];
}


//  cell replace button clicked
- (void)cellBtnReplaceClicked:(id)sender
{
    UserModel *model = [self.tableView getModelByUIControl:sender];
    NSIndexPath *index = [self.tableView indexPathForModel:model];
    NSLog(@"cell %ld replace button clicked", (long)index.row );
//    UserModel *newModel = tempUserList[0];
//    [tempUserList removeObjectAtIndex:0];
//    NSMutableArray *sectionArray = [self.tableView getSection:index.section];
//    [sectionArray replaceObjectAtIndex:index.row withObject:newModel];
//    [tempUserList addObject:model];
    model.testNum++;
}

//  cell switch clicked
- (void)cellSwitchValueChanged:(UISwitch*)sender
{
    UserModel *model = [self.tableView getModelByUIControl:sender];
    NSIndexPath *index = [self.tableView indexPathForModel:model];
    NSLog(@"cell %ld switch changed", (long)index.row );
    //    model.swValue = sender.on;
}

#pragma mark - IBActions

- (IBAction)dismissViewContrller:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - KHTableViewDelegate

// 做 cell 初始
- (void)tableView:(KHTableView *)tableView newCell:(id _Nonnull)cell model:(id _Nonnull)model indexPath:(NSIndexPath * _Nonnull)indexPath
{
    if ( [cell isKindOfClass:[UserInfoCell class]] ) {
        UserInfoCell *myCell = cell;
        myCell.textField.delegate = self;
    }
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSLog(@"cell click %ld",(long)indexPath.row );
}

//  pull down refresh
- (void)tableViewOnPulldown:(KHTableView *)tableView refreshControl:(UIRefreshControl *)refreshControl
{
    [userList removeAllObjects];
    currentPage = 0;
    [self fetchUsers];
}

//  loading more
- (void)tableViewOnEndReached:(KHTableView *)tableView
{
    currentPage += 1;
    NSLog(@"🏁 Run: %ld times", currentPage);
    [self fetchUsers];
}


#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    UserModel *model = [self.tableView getModelByUIControl:textField];
    model.testText = textField.text;
    return YES;
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
        
        [w_self.tableView endRefreshing];
    } fail:^(APIOperation *api, NSError *error) {
        NSLog(@"error !");
        [w_self.tableView endRefreshing];
    }];
    [apiQueue addOperation: api ];
}




#pragma mark - Button Event 

- (IBAction)dismissVIewCOntroller:(id)sender
{
    [self.tableView removeAllTarget];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
