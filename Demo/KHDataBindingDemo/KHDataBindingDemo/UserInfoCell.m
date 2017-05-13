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
    
    self.btnRemove.layer.cornerRadius = 5;
    self.btnRemove.layer.borderColor = [UIColor colorWithRed:0.5 green:0.5 blue:1 alpha:1].CGColor;
    self.btnRemove.layer.borderWidth = 1.0f;
    
    self.btnReplace.layer.cornerRadius = 5;
    self.btnReplace.layer.borderColor = [UIColor colorWithRed:0.5 green:0.5 blue:1 alpha:1].CGColor;
    self.btnReplace.layer.borderWidth = 1.0f;
    
    [self.sw addTarget:self action:@selector(swValueChanged:) forControlEvents:UIControlEventValueChanged];
}

+(Class)mappingModelClass
{
    return [UserModel class];
}

- (void)onLoad:(UserModel*)model
{
    self.labelName.text = [NSString stringWithFormat:@"%@ %@", model.name.first,model.name.last];
    self.labelGender.text = model.gender;
    self.labelPhone.text = model.phone;
    self.imgUserPic.image = nil;
    [self loadImageURL:model.picture.medium imageView:self.imgUserPic placeHolder:nil brokenImage:nil animation:YES];
    self.labelTextDisplay.text = model.testText;
    self.textField.text = model.testText;
    self.sw.on = model.swValue;
}

- (void)swValueChanged:(UISwitch*)sender
{
    //  if you want to change model property value, you should use method 'modifyModelNoAnimate' better
    //  because modify model value will trigger cell reload and call onLoad
    //  
    //  modify model directly, it will make this issue.
    //  click sw -> sw.on changed -> trigger swValueChanged: -> modify model -> KVO -> onLoad -> set sw.on value again 
    [self.pairInfo modifyModelNoNotify:^(UserModel *_Nonnull model) {
        model.swValue = sender.on;
    }];
}

@end
