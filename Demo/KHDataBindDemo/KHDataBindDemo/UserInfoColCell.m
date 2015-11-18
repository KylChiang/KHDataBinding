//
//  UserInfoColCell.m
//  KHDataBindDemo
//
//  Created by GevinChen on 2015/11/16.
//  Copyright © 2015年 omg. All rights reserved.
//

#import "UserInfoColCell.h"
#import "UserModel.h"

@implementation UserInfoColCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)onLoad:(UserModel*)model
{
    self.lbName.text = [NSString stringWithFormat:@"%@ %@", model.user.name.first,model.user.name.last];
    [self loadImageURL:model.user.picture.thumbnail completed:^(UIImage *image) {
        self.imgUserPic.image = image;
    }];

}

@end
