//
//  CollectionDemoController.m
//  KHDataBindDemo
//
//  Created by GevinChen on 2015/11/16.
//  Copyright © 2015年 omg. All rights reserved.
//

#import "CollectionDemoController.h"

// Models
#import "UserModel.h"


// Views
#import "UserInfoColCell.h"
#import "MyColHeaderView.h"
#import "MyColCell.h"
#import "NonReuseHeaderView.h"
#import "UserConfigCellView.h"

// Utilities
#import "APIOperation.h"
#import "KHCollectionView.h"

@interface CollectionDemoController () <KHCollectionViewDelegate,UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet KHCollectionView *collectionView;

@end

@implementation CollectionDemoController
{

    //  user data model array
    NSMutableArray *userList;
    NSMutableArray *stringList;
    NSMutableArray *nonreuseViewList;
    
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


- (void)viewDidLoad 
{
    [super viewDidLoad];
    
    //  config model/cell mapping 
    [self.collectionView setMappingModel:[UserModel class] cell:[UserInfoColCell class]];
    [self.collectionView setMappingModel:[NSString class] cell:[MyColCell class]];
    
    //  create an empty section array, if you add an UserModel model into userList, it will display an UserInfoColCell in collectionView
    userList = [self.collectionView createSection];
    stringList = [self.collectionView createSection];
    nonreuseViewList = [self.collectionView createSection];
    
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
    
    //  config model mapping with headerView class and footerView class 
    [self.collectionView setMappingModel:[NSMutableDictionary class] headerClass:[MyColHeaderView class]];
    [self.collectionView setMappingModel:[NSMutableDictionary class] footerClass:[MyColHeaderView class]];
    
    //  assign header/footer model at section, this will make section 0 display header(MyColHeaderView)/footer(MyColHeaderView)
    [self.collectionView setHeaderModel:[@{@"title":@"Header View"} mutableCopy] atIndex:0];
    [self.collectionView setFooterModel:[@{@"title":@"Footer View"} mutableCopy] atIndex:0];
    
    //  set section1 header
    NonReuseHeaderView *headerNonreuseView = [NonReuseHeaderView create];
    [headerNonreuseView.btn addTarget:self
                               action:@selector(headerBtnClicked:) 
                     forControlEvents:UIControlEventTouchUpInside];
    
    [self.collectionView setHeaderModel:headerNonreuseView atIndex:1];
    [self.collectionView setSize:(CGSize){320,76} headerModel:headerNonreuseView];
    
    //  load section 1
    [self loadSection1]; // use primitive data to be as a model
    [self loadSection2]; // non reuse view list
    
    [self fetchUsers];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.collectionView removeAllTarget];
}


#pragma mark - UI

- (void)loadSection1
{
    [stringList addObjectsFromArray:@[@"one",@"two",@"three",@"four",@"five",@"six",@"seven",@"eight",@"nine"]];
//    [stringList addObject:@"one"];
    
}

//  non reuse custom view as a model
- (void)loadSection2
{
    UserConfigCellView *view1 = [UserConfigCellView create];
    view1.textName.delegate = self;
    view1.textAge.delegate = self;
    view1.textGender.delegate = self;

    UserConfigCellView *view2 = [UserConfigCellView create];
    view2.textName.delegate = self;
    view2.textAge.delegate = self;
    view2.textGender.delegate = self;

    UserConfigCellView *view3 = [UserConfigCellView create];
    view3.textName.delegate = self;
    view3.textAge.delegate = self;
    view3.textGender.delegate = self;

    UserConfigCellView *view4 = [UserConfigCellView create];
    view4.textName.delegate = self;
    view4.textAge.delegate = self;
    view4.textGender.delegate = self;

    [nonreuseViewList addObjectsFromArray:@[view1, view2, view3, view4 ]];
}


#pragma mark - Collection

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"click %ld", (long)indexPath.row );
}

- (void)collectionView:(KHCollectionView *)collectionView newCell:(id)cell model:(id)model indexPath:(NSIndexPath *)indexPath
{
//    if ( [cell isKindOfClass:[UserInfoColCell class]]) {
//        UserInfoColCell *myCell = cell;
//        [myCell.btn addTarget:self action:@selector(cellBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
//        [myCell.btnUpdate addTarget:self action:@selector(cellBtnUpdateClicked:) forControlEvents:UIControlEventTouchUpInside];
//        [myCell.btnRemove addTarget:self action:@selector(cellBtnRemoveClicked:) forControlEvents:UIControlEventTouchUpInside];
//    }
}


#pragma mark - API

- (void)fetchUsers
{
    //  @todo:之後改用 AFNetworking 3.0
    //  使用自訂的 http connection handle
    //--------------------------------------------------
    NSDictionary *param = @{@"results": @30 };
    APIOperation *api = [[APIOperation alloc] init];
    api.debug = YES;
//    __weak typeof(self) w_self = self;
    [api GET:@"http://api.randomuser.me/" param:param body:nil response:^(APIOperation *api, id responseObject) {
        NSArray *results = responseObject[@"results"];
        NSArray *users = [KVCModel convertArray:results toClass:[UserModel class] keyCorrespond:nil];
        for ( int i=0; i<users.count; i++) {
            UserModel *model = users[i];
            model.testNum = 0;
        }        
        [tempUserList addObjectsFromArray: users ];
    } fail:^(APIOperation *api, NSError *error) {
        NSLog(@"api error !");
    }];
    [apiQueue addOperation: api ];
}

#pragma mark - UITextField

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
//    UserModel *model = [self.collectionView getModelByUIControl:textField];
//    model.testText = textField.text;
    return YES;
}



#pragma mark - Button Event (Cell)

- (void)headerBtnClicked:(id)sender
{
    NSLog(@"header clicked");
}

//  test button on cell
- (void)cellBtnClicked:(id)sender
{
    UserModel *model = [self.collectionView getModelByUIControl:sender];
    NSIndexPath *index = [self.collectionView indexPathForModel:model];
    NSLog(@"%ld test clicked, name:%@ %@", (long)index.row, model.name.first, model.name.last );
    model.testNum += 1;
}

//  update button on cell
- (void)cellBtnUpdateClicked:(id)sender
{
    UserModel *model = [self.collectionView getModelByUIControl:sender];
    NSIndexPath *index = [self.collectionView indexPathForModel:model];
    NSLog(@"%ld update clicked", (long)index.row );
}

//  remove button on cell
- (void)cellBtnRemoveClicked:(id)sender
{
    UserModel *model = [self.collectionView getModelByUIControl:sender];
    NSIndexPath *index = [self.collectionView indexPathForModel:model];
    NSLog(@"%ld remove clicked, name:%@ %@", (long)index.row, model.name.first, model.name.last );
    [tempUserList addObject:model];
    [userList removeObject:model];
}

#pragma mark - Button Event 

// back
- (IBAction)dismissVIewController:(id)sender
{
    [self.collectionView removeAllTarget];
    [self dismissViewControllerAnimated:YES completion:nil];
}


//  load clicked
- (IBAction)btn1Clicked:(id)sender
{
    if ( tempUserList.count == 0 ) {
        NSLog(@"no temp data");
        return;
    }
    NSInteger cnt = tempUserList.count > 10 ? 10 : tempUserList.count;
    // load 10 model
    for ( int i=0; i<cnt; i++ ) {
        [userList addObject: tempUserList[i] ];
    }
    [tempUserList removeObjectsInRange:(NSRange){0,cnt}];
}

// insert random clicked
- (IBAction)btn2Clicked:(id)sender 
{
    if ( tempUserList.count == 0 ) {
        NSLog(@"no temp data");
        return;
    }
    int idx = arc4random() % tempUserList.count;
    UserModel *model = tempUserList[idx];
    [tempUserList removeObject:model];
    if (userList.count == 0){
        [userList addObject:model];
    }
    else{
        int insert_idx = arc4random() % userList.count;
        [userList insertObject:model atIndex: insert_idx ];
    }
}

//  remove random clicked
- (IBAction)btn3Clicked:(id)sender
{
    if (userList.count == 0){
        return;
    }
    int remove_idx = arc4random() % userList.count;
    UserModel *model = userList[remove_idx];
    [userList removeObjectAtIndex:remove_idx];
    [tempUserList addObject:model];
}

//  replace random clicked
- (IBAction)btn4Clicked:(id)sender 
{
    if (userList.count == 0){
        return;
    }
    if ( tempUserList.count == 0 ) {
        NSLog(@"no temp data");
        return;
    }
    int replace_idx = arc4random() % userList.count;
    UserModel *model = userList[replace_idx];
    UserModel *newModel = tempUserList[0];
    [tempUserList removeObject:newModel];
    [userList replaceObjectAtIndex:replace_idx withObject:newModel];
    [tempUserList addObject:model];
}

@end
