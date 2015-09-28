//
//  UserCell.m
//  DataBindTest
//
//  Created by GevinChen on 2015/9/27.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import "UserCell.h"
#import "UserData.h"

const NSString *CellEventJoin = @"UserCellJoinButtonClick";

@implementation UserCell

- (void)awakeFromNib
{
    [self.sexSw addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.joinBtn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)valueChanged:(UISwitch*)sender
{
    UserData* user = (UserData*)self.cellData[kCellModel];
    user.male = sender.on;
    NSLog(@"male:%d", user.male );
    self.sexLabel.text = user.male ? @"男" : @"女";
}

-(void)loadModel:(id)model stateData:(NSMutableDictionary*)tempData
{
    UserData* user = model;
    self.nameText.text = user.name;
    self.ageText.text = [user.age stringValue];
    self.moneyText.text = [user.money stringValue];
    self.addressText.text = user.address;
    self.mobileText.text = user.mobile;
    self.sexSw.on = user.male;
    self.sexLabel.text = user.male ? @"男" : @"女";
    self.introText.text = user.userDescription;
    self.joinStateLabel.text = user.hasJoin ? @"已參加" : @"未參加";
    if( user.hasJoin ){
        self.joinBtn.hidden = YES;
    }
}

-(void)btnClick:(UIButton*)btn
{
    [self.helper notify:CellEventJoin userInfo: self.cellData[kCellModel] ];
}


@end
