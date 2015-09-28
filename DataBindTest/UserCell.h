//
//  UserCell.h
//  DataBindTest
//
//  Created by GevinChen on 2015/9/27.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import "TableViewBindHelper.h"

extern const NSString* CellEventJoin;

@interface UserCell : CKHTableViewCell

@property (weak, nonatomic) IBOutlet UITextField *nameText;
@property (weak, nonatomic) IBOutlet UITextField *ageText;
@property (weak, nonatomic) IBOutlet UITextField *moneyText;
@property (weak, nonatomic) IBOutlet UITextField *mobileText;
@property (weak, nonatomic) IBOutlet UITextField *addressText;
@property (weak, nonatomic) IBOutlet UILabel *sexLabel;
@property (weak, nonatomic) IBOutlet UISwitch *sexSw;
@property (weak, nonatomic) IBOutlet UITextView *introText;
@property (weak, nonatomic) IBOutlet UIButton *joinBtn;
@property (weak, nonatomic) IBOutlet UILabel *joinStateLabel;


@end
