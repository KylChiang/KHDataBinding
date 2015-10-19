//
//  UserInfoCell.m
//  DataBindTest
//
//  Created by GevinChen on 2015/10/9.
//  Copyright © 2015年 GevinChen. All rights reserved.
//

#import "UserInfoCell.h"

@implementation UserInfoCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)onInit:(id)model
{
    //
    [self.helper responseUIControl:self.sw  event:UIControlEventValueChanged cell:self];
    //
    [self.helper responseUIControl:self.btn event:UIControlEventTouchUpInside cell:self];
}

- (void)onLoad:(UserModel*)model
{
    self.nameLabel.text = [NSString stringWithFormat:@"%@ %@", model.user.name.first,model.user.name.last];
    self.genderLabel.text = model.user.gender;
    self.phoneLabel.text = model.user.phone;
    
    
}


@end
