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
    [self presentViewController:[[TableViewDemoViewController alloc] init] animated:YES completion:nil];
}

- (IBAction)tableViewAutoPaginatingPresentButtonClicked:(id)sender
{
    [self presentViewController:[[AutoPaginatingTableViewDemoViewController alloc] init] animated:YES completion:nil];
}

- (IBAction)collectionViewAutoPaginatingPresentButtonClicked:(id)sender
{
    [self presentViewController:[[AutoPaginatingCollectionViewDemoViewController alloc] init] animated:YES completion:nil];
}

- (IBAction)basicCollectionViewPredenrButtonClicked:(id)sender
{
    [self presentViewController:[[CollectionDemoController alloc] init] animated:YES completion:nil];
}

@end
