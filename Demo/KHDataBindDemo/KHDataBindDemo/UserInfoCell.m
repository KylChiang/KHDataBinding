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
    
}


- (void)onLoad:(UserModel*)model
{
//    NSLog(@"%s, %ld, cell frame %@, img frame %@", __PRETTY_FUNCTION__, self.model.index.row, NSStringFromCGSize( self.frame.size ), NSStringFromCGSize( self.imgUserPic.frame.size ) );
    self.lbName.text = [NSString stringWithFormat:@"%@ %@", model.user.name.first,model.user.name.last];
    self.lbGender.text = model.user.gender;
    self.lbPhone.text = model.user.phone;
    if (model.testNum == nil ) {
        model.testNum = @0;
    }
    self.lbTest.text = [model.testNum stringValue];
    self.imgUserPic.image = nil;
    [self loadImageURL:model.user.picture.medium completed:^(UIImage *image) {
        self.imgUserPic.image = image;
    }];
}


@end
