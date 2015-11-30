//
//  UserInfoCell.m
//  DataBindTest
//
//  Created by GevinChen on 2015/10/9.
//  Copyright © 2015年 GevinChen. All rights reserved.
//

#import "UserInfoCell.h"

@implementation UserInfoCell
{
    NSLayoutConstraint *aspectRatioImage;
}
- (void)awakeFromNib 
{
    
//    CGRect rect = [UIScreen mainScreen].bounds;
//    self.frame = (CGRect){0,0, rect.size.width, rect.size.width - self.constraintImgTrillingSpace.constant - 8 };
}


- (void)onLoad:(UserModel*)model
{
    NSLog(@"%s, %ld, cell frame %@, img frame %@", __PRETTY_FUNCTION__, self.model.index.row, NSStringFromCGSize( self.frame.size ), NSStringFromCGSize( self.imgUserPic.frame.size ) );
    self.lbName.text = [NSString stringWithFormat:@"%@ %@", model.user.name.first,model.user.name.last];
    self.lbGender.text = model.user.gender;
    self.lbPhone.text = model.user.phone;
    [self loadImageURL:model.user.picture.medium completed:^(UIImage *image) {
        self.imgUserPic.image = image;
    }];
}


@end
