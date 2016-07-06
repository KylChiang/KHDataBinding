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
    self.labelNum.text = [model.testNum stringValue];
    self.lbName.text = [NSString stringWithFormat:@"%@ %@", model.name.first,model.name.last];
    [self.linker loadImageURL:model.picture.medium imageView:self.imgUserPic placeHolder:nil brokenImage:nil animation:YES];

}

@end
