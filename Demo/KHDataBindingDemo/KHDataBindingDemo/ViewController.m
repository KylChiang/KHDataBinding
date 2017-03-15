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
#import "AutoPaginatingTableViewDemoController.h"
#import "CollectionDemoController.h"
#import "AutoPaginatingCollectionViewDemoViewController.h"
#import "CollectionViewAutoExpandHeightDemoController.h"

@implementation ViewController

- (IBAction)basicTableViewPresentButtonClicked:(id)sender
{
    [self presentViewController:[[TableViewDemoController alloc] init] animated:YES completion:nil];
}

- (IBAction)tableViewAutoPaginatingPresentButtonClicked:(id)sender
{
    [self presentViewController:[[AutoPaginatingTableViewDemoController alloc] init] animated:YES completion:nil];
}

- (IBAction)collectionViewAutoPaginatingPresentButtonClicked:(id)sender
{
    [self presentViewController:[[AutoPaginatingCollectionViewDemoViewController alloc] init] animated:YES completion:nil];
}

- (IBAction)basicCollectionViewPredenrButtonClicked:(id)sender
{
    [self presentViewController:[[CollectionDemoController alloc] init] animated:YES completion:nil];
}
- (IBAction)collectionViewAutoExpandHeightClicked:(id)sender 
{
    
    [self presentViewController:[[CollectionViewAutoExpandHeightDemoController alloc] init] animated:YES completion:nil];
}

@end
