//
//  UserProfileCell.h
//  DataBindTest
//
//  Created by GevinChen on 2015/10/4.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import "CKHTableViewCell.h"
#import "UserProfile.h"
#import "CKHTask.h"

@interface UserProfileCell : CKHTableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *userImage;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@end
