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
#import "CollectionDemoController.h"

@implementation ViewController

- (IBAction)uiTableViewButtonClicked:(id)sender
{
    [self.navigationController pushViewController:[[TableViewDemoViewController alloc] init] animated:YES];
}

- (IBAction)uiCollectionViewButtonClicked:(id)sender
{
    [self.navigationController pushViewController:[[CollectionDemoController alloc] init] animated:YES];
}

@end
