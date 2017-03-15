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

- (void)awakeFromNib
{
    // Initialization code
    [super awakeFromNib];
    
    [self.sw addTarget:self action:@selector(switchClicked:) forControlEvents:UIControlEventValueChanged];
}

+(Class)mappingModelClass
{
    return [UserModel class];
}

//  for dynamic height
- (UICollectionViewLayoutAttributes *)preferredLayoutAttributesFittingAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes
{
    [self setNeedsLayout];
    [self layoutIfNeeded];
    CGSize size = [self.contentView systemLayoutSizeFittingSize: layoutAttributes.size ];
    CGRect oldFrame = layoutAttributes.frame;
    //  若要動態寬的話，就把 ceilf 的對象，改為 width
    CGRect newFrame = (CGRect){ oldFrame.origin, oldFrame.size.width, ceilf( size.height ) };
    layoutAttributes.frame = newFrame;
    return layoutAttributes;
}

- (void)onLoad:(UserModel*)model
{
    self.sw.on = model.swValue;
    self.labelNum.text = [NSString stringWithFormat:@"%ld",(long)model.testNum];
    self.lbName.text = [NSString stringWithFormat:@"%@ %@", model.name.first,model.name.last];
    [self.pairInfo loadImageURL:model.picture.medium imageView:self.imgUserPic placeHolder:nil brokenImage:nil animation:YES];
}


- (void)switchClicked:(UISwitch*)sw
{
    // cell 內修改 model 值，可用此 method，因為 model 修改會觸發 cell onLoad，有時只是想修改不想觸發更新
    [self.pairInfo modifyModelNoAnimate:^(UserModel *_Nonnull model) {
        model.swValue = sw.on;
    }];
}


@end
