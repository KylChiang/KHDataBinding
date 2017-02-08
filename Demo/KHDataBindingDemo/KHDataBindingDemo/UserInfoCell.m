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
    [super awakeFromNib];
}

+(Class)mappingModelClass
{
    return [UserModel class];
}

- (void)onLoad:(UserModel*)model
{

    self.lbName.text = [NSString stringWithFormat:@"%@ %@", model.name.first,model.name.last];
    self.lbGender.text = model.gender;
    self.lbPhone.text = model.phone;
    if (model.testNum == nil ) {
        model.testNum = @0;
    }
    self.lbTest.text = [model.testNum stringValue];
    self.imgUserPic.image = nil;
    [self.pairInfo loadImageURL:model.picture.medium imageView:self.imgUserPic placeHolder:nil brokenImage:nil animation:YES];
    
    NSIndexPath *index = [self.pairInfo indexPath];
    self.lbNumber.text = [NSString stringWithFormat:@"%ld", (long)index.row ];
}


@end
