//
//  UserInfoCell.h
//  DataBindTest
//
//  Created by GevinChen on 2015/10/9.
//  Copyright © 2015年 GevinChen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KHBindHelper.h"
#import "UserModel.h"

@interface UserInfoCell : KHTableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imgUserPic;
@property (weak, nonatomic) IBOutlet UILabel *lbName;
@property (weak, nonatomic) IBOutlet UILabel *lbGender;
@property (weak, nonatomic) IBOutlet UILabel *lbPhone;
@property (weak, nonatomic) IBOutlet UIButton *btn;
@property (weak, nonatomic) IBOutlet UISwitch *sw;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintImgTrillingSpace;




@end
