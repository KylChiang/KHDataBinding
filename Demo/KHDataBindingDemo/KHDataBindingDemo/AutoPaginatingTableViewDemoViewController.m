//
//  AutoPaginatingTableViewDemoViewController.m
//  KHDataBindingDemo
//
//  Created by Calvin Huang on 09/02/2017.
//  Copyright © 2017 CpasLock Studio. All rights reserved.
//

#import "AutoPaginatingTableViewDemoViewController.h"



@interface AutoPaginatingTableViewDemoViewController ()

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@end

@implementation AutoPaginatingTableViewDemoViewController

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
