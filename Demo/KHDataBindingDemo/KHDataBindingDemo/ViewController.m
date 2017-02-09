//
//  ViewController.m
//  DataBindTest
//
//  Created by GevinChen on 2015/8/30.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import "ViewController.h"

// ViewControllers
#import "TableViewDemoViewController.h"
#import "AutoPaginatingTableViewDemoViewController.h"
#import "CollectionDemoController.h"
#import "AutoPaginatingCollectionViewDemoViewController.h"

@implementation ViewController

- (IBAction)basicTableViewPresentButtonClicked:(id)sender
{
    [self.navigationController pushViewController:[[TableViewDemoViewController alloc] init] animated:YES];
}

- (IBAction)tableViewAutoPaginatingPresentButtonClicked:(id)sender
{
    [self.navigationController pushViewController:[[AutoPaginatingTableViewDemoViewController alloc] init] animated:YES];
}

- (IBAction)collectionViewAutoPaginatingPresentButtonClicked:(id)sender
{
    [self.navigationController pushViewController:[[AutoPaginatingCollectionViewDemoViewController alloc] init] animated:YES];
}

- (IBAction)basicCollectionViewPredenrButtonClicked:(id)sender
{
    [self.navigationController pushViewController:[[CollectionDemoController alloc] init] animated:YES];
}

@end
