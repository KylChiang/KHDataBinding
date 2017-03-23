//
//  ViewController.m
//  DataBindTest
//
//  Created by GevinChen on 2015/8/30.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import "ViewController.h"

// ViewControllers
#import "TableViewDemoController.h"
#import "TableViewNonReuseViewController.h"
#import "TableViewHeaderFooterDemoController.h"
#import "AutoPaginatingTableViewDemoController.h"
#import "TableViewAutoExpandHeightDemoController.h"

#import "CollectionDemoController.h"
#import "CollectionViewNonReuseViewDemoController.h"
#import "CollectionViewHeaderFooterDemoController.h"
#import "AutoPaginatingCollectionViewDemoViewController.h"
#import "CollectionViewAutoExpandHeightDemoController.h"

@implementation ViewController
{
    NSMutableDictionary *controllerDic;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    controllerDic = [[NSMutableDictionary alloc] initWithCapacity:10];
    
    self.tableView.kh_delegate = self;
    NSMutableArray *tableViewDemoItemList = [self.tableView createSection];
    NSMutableArray *collectionViewDemoItemList = [self.tableView createSection];
    
    NSArray *tableDemoTitles = @[@"TableView Classical Demo",
                                 @"TableView Non Reuse View Demo",
                                 @"TableView Header / Footer Demo",
                                 @"TableView Auto Paginating Demo",
                                 @"TableView Auto Expand Height", ];
    NSArray *tableDemoVCs = @[[TableViewDemoController new],
                              [TableViewNonReuseViewController new],
                              [TableViewHeaderFooterDemoController new],
                              [AutoPaginatingTableViewDemoController new],
                              [TableViewAutoExpandHeightDemoController new]
                              ];
    float colorValue = 0.6f;
    for ( int i=0; i<tableDemoTitles.count; i++) {
        UITableViewCellModel *model = [UITableViewCellModel new];
        model.text = tableDemoTitles[i];
        model.textFont = [UIFont systemFontOfSize:13.0f];
        model.textColor = [UIColor whiteColor];
        model.backgroundColor = [UIColor colorWithRed:colorValue green:colorValue blue:1.0f alpha:1.0f];
        colorValue = colorValue - 0.05f;
        [tableViewDemoItemList addObject:model];
        controllerDic[model.text] = tableDemoVCs[i];
    }
    
    NSArray *collectionDemoTitles = @[@"CollectionView Basic Demo",
                                      @"CollectionView Non Reuse View Demo",
                                      @"CollectionView Header / Footer Demo",
                                      @"CollectionView Auto Paginating Demo",
                                      @"CollectionView Auto Expand Height", ];
    NSArray *collectionDemoVCs = @[[CollectionDemoController new],
                                   [CollectionViewNonReuseViewDemoController new],
                                   [CollectionViewHeaderFooterDemoController new],
                                   [AutoPaginatingCollectionViewDemoViewController new],
                                   [CollectionViewAutoExpandHeightDemoController new]
                                   ];
    colorValue = 0.6f;
    for ( int i=0; i<collectionDemoTitles.count; i++) {
        UITableViewCellModel *model = [UITableViewCellModel new];
        model.text = collectionDemoTitles[i];
        model.textFont = [UIFont systemFontOfSize:13.0f];
        model.textColor = [UIColor whiteColor];
        model.backgroundColor = [UIColor colorWithRed:0.8f green:0.45f blue:colorValue alpha:1.0f];
        colorValue = colorValue - 0.05f;
        [collectionViewDemoItemList addObject:model];
        controllerDic[model.text] = collectionDemoVCs[i];
    }
    
    [self.tableView setHeaderModels:@[@"KHTableView Demo", @"KHCollectionView Demo"]];
    
}

- (void)tableView:(KHTableView *)tableView newCell:(UITableViewCell*)cell model:(id)model indexPath:(NSIndexPath *)indexPath
{
    cell.textLabel.shadowOffset = CGSizeMake(0, 0.5);
    cell.textLabel.shadowColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.7];
    
}

- (void)tableView:(KHTableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCellModel *model = [tableView modelForIndexPath:indexPath];
    UIViewController *vc = controllerDic[model.text];
    if ( vc != nil && vc != [NSNull null] ) {
        [self presentViewController:vc animated:YES completion:nil];
    }
    
}


@end
