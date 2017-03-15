//
//  MyFooterView.m
//  KHDataBindDemo
//
//  Created by GevinChen on 2016/4/22.
//  Copyright © 2016年 omg. All rights reserved.
//

#import "MyTableHeaderView.h"

@implementation MyTableHeaderView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

+ (MyTableHeaderView*)create
{
    UINib*nib = [UINib nibWithNibName:NSStringFromClass([MyTableHeaderView class]) bundle:nil];
    NSArray*arr = [nib instantiateWithOwner:nil options:nil];
    return arr[0];
}

@end
