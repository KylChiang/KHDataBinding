//
//  ViewController.m
//  DataBindTest
//
//  Created by GevinChen on 2015/8/30.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import "ViewController.h"
#import "DataBinder.h"
#import "UserData.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *ageLabel;
@property (weak, nonatomic) IBOutlet UILabel *moneyLabel;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UILabel *mobileLabel;

@end

@implementation ViewController
{
    DataBinder* binder;
    
    UserData* user;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    user = [UserData new];
    user.name = @"shit";
    user.age = @18;
    user.money = @10000;
    user.address = @"you motherfucker , asshole. ";
    user.mobile = @"0988776655";
    
    binder = [DataBinder new];
    [binder setTarget: self ];
    [binder setModel: user ];
    [binder bindData:@"name" ui:@"nameLabel" handle:^(UILabel* uiObject, NSString* data) {
        uiObject.text = [NSString stringWithFormat:@"我叫%@", data ];
    }];
    [binder bindData:@"age" ui:@"ageLabel" handle:^(UILabel* uiObject, NSNumber* data) {
        uiObject.text = [data stringValue];
    }];
    [binder bindData:@"money" ui:@"moneyLabel" handle:nil];
    [binder bindData:@"address" ui:@"addressLabel" handle:nil];
    [binder bindData:@"mobile" ui:@"mobileLabel" handle:nil];
    
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    
}

- (IBAction)btn1Clk:(id)sender {
    user.name = @"hello";
}


- (IBAction)btn2clk:(id)sender {
    user.age = @25;
}

- (IBAction)btn3clk:(id)sender {
}

- (IBAction)btn4clk:(id)sender {
}



@end
