//
//  UserInfoColCell.h
//  KHDataBindDemo
//
//  Created by GevinChen on 2015/11/16.
//  Copyright © 2015年 omg. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KHBindHelper.h"

@interface UserInfoColCell : KHCollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *imgUserPic;
@property (weak, nonatomic) IBOutlet UILabel *lbName;
@property (weak, nonatomic) IBOutlet UIButton *btn;

@end
