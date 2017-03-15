//
//  ViewController.m
//  DataBindTest
//
//  Created by GevinChen on 2015/8/30.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import "TableViewDemoController.h"

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

//#import "AFNetworking.h"
//#import "MyAPISerializer.h"

@interface TableViewDemoController () <KHTableViewDelegate,UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet KHTableView *tableView;


@end

@implementation TableViewDemoController
{
    
    //  user model array
    NSMutableArray<UserModel*> *userList;
    NSMutableArray<UserModel*> *tempUserList;
    
    //  other section array
    NSMutableArray *itemList;
    NSMutableArray *itemList2;
    
    //  operation queue for api call
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
    tempUserList = [[NSMutableArray alloc] initWithCapacity:10];
}

- (void)dealloc
{
    NSLog(@"TableViewDemoController....dealloc");
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    //  first important thing, assign delegate
    self.tableView.kh_delegate = self;
    
    //  config model/cell mapping 
    [self.tableView setMappingModel:[UserModel class] cell:[UserInfoCell class]];
    [self.tableView setMappingModel:[NSArray class] cell:[ShowArrayDataCell class]];
    //  if you has one model type that need to display by two cell type
    [self.tableView setMappingModel:[NSDictionary class] block:^Class _Nullable(NSDictionary * _Nonnull model, NSIndexPath  *_Nonnull index) {
        if ( [model[@"dataType"] intValue] == 0 ) {
            return [ShowDictDataCell class];
        }
        else if([model[@"dataType"] intValue] == 1 ){
            return [ShowDictData2Cell class];
        }
        return NULL; // will throw an exception
    }];
    
    //  this line has default setting inside of KHTableView, you would not to do it again.
//    [self.tableView setMappingModel:[UITableViewCellModel class] cell:[UITableViewCell class]];

    //  create an empty section array, if you add an UserModel model into userList, it will display an UserInfoColCell in tableView
    userList = [self.tableView createSection];
    itemList = [self.tableView createSection];
    itemList2= [self.tableView createSection];
    
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
    
    
    
    //  set section 0 header / footer
    [self.tableView setHeader:@"User List Header" atIndex:0];
    [self.tableView setFooter:@"User List Footer" atIndex:0];
    
    //  set section 1 header / footer
    MyTableHeaderView *headerView = [MyTableHeaderView create];
    [headerView.button addTarget:self action:@selector(btnHeaderClicked:) forControlEvents:UIControlEventTouchUpInside];
    [headerView.button setTitle:@"header button" forState:UIControlStateNormal];
    headerView.button.layer.cornerRadius = 5;
    headerView.button.layer.borderColor = [UIColor colorWithRed:0.5 green:0.5 blue:1 alpha:1].CGColor;
    headerView.button.layer.borderWidth = 1.0f;
    [self.tableView setHeader:headerView atIndex:1];
    
    MyTableHeaderView *footerView = [MyTableHeaderView create];
    [footerView.button addTarget:self action:@selector(btnFooterClicked:) forControlEvents:UIControlEventTouchUpInside];
    [footerView.button setTitle:@"footer button" forState:UIControlStateNormal];
    footerView.button.layer.cornerRadius = 5;
    footerView.button.layer.borderColor = [UIColor colorWithRed:0.5 green:0.5 blue:1 alpha:1].CGColor;
    footerView.button.layer.borderWidth = 1.0f;
    [self.tableView setFooter:footerView atIndex:1];

    //  set section 2 header / footer
    [self.tableView setHeader:@"Third Section Header" atIndex:2];
    [self.tableView setFooter:@"Third Section Footer" atIndex:2];
    
    //  another way to set header / footer
    //---------------------------------------------------------
    // [self.tableView setHeaderArray: @[@"User List Header",headerView, @"Third Section Header"]];
    // [self.tableView setFooterArray: @[@"User List Footer",footerView, @"Third Section Footer"]];

    //  query model from api
    [self fetchUsers];

    //  load list cell
    [self loadSection1];
    [self loadSection2];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.tableView removeAllTarget];
}


#pragma mark - Private

-(void)loadSection1
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

- (void)loadSection2
{
    //  use primitive data struct to be a model, and you can see how it parsed in ShowArrayDataCell onLoad
    NSArray *item1 = @[@"hi", @"A", @"B", @"C", @"D", @"E", @"F",];
    NSMutableDictionary *item2 = [@{@"dataType":@0,
                                    @"title":@"Demo Dictionary",
                                    @"name":@"item6",
                                    @"comment":@"bla bla bla ..."} mutableCopy];
    
    NSMutableDictionary *item3 = [@{@"dataType":@1,
                                    @"data1":@"Test String",
                                    @"data2":@(123),
                                    @"data3":[NSDate date]}mutableCopy];

    [itemList2 addObject:item1];
    [itemList2 addObject:item2];
    [itemList2 addObject:item3];
}


#pragma mark - API

- (void)fetchUsers
{
    //  @todo:之後改用 AFNetworking 3.0
    //  使用自訂的 http connection handle
    //--------------------------------------------------
    NSDictionary *param = @{@"results": @20 };
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
        NSLog(@"error !");
    }];
    [apiQueue addOperation: api ];
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


#pragma mark - UITextField

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    UserModel *model = [self.tableView getModelByUIControl:textField];
    model.testText = textField.text;
    return YES;
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
    UserModel *newModel = tempUserList[0];
    [tempUserList removeObjectAtIndex:0];
    NSMutableArray *sectionArray = [self.tableView getSection:index.section];
    [sectionArray replaceObjectAtIndex:index.row withObject:newModel];
    [tempUserList addObject:model];
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


#pragma mark - Button Event (Header/Footer)

//  header button clicked
- (void)btnHeaderClicked:(id)sender
{
    NSInteger section = [self.tableView headerSectionByUIControl:sender];
    NSLog(@"section %ld header button clicked", (long)section );
}

//  footer button clicked
- (void)btnFooterClicked:(id)sender
{
    NSInteger section = [self.tableView footerSectionByUIControl:sender];
    NSLog(@"section %ld footer button clicked", (long)section );
}

#pragma mark - Button Event 

- (IBAction)dismissVIewCOntroller:(id)sender
{
    [self.tableView removeAllTarget];
    
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


//  insert random clicked
- (IBAction)btn2Clicked:(id)sender 
{
    if ( tempUserList.count == 0 ) {
        NSLog(@"no temp data");
        return;
    }
    int idx = arc4random() % tempUserList.count;
    UserModel *model = tempUserList[idx];
    [tempUserList removeObject:model];
    if (userList.count == 0) {
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

