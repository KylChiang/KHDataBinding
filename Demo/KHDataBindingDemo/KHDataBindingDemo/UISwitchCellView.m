//
//  UISwitchCellView.m
//  KHDataBindingDemo
//
//  Created by GevinChen on 2017/3/16.
//  Copyright © 2017年 omg. All rights reserved.
//

#import "UISwitchCellView.h"

@implementation UISwitchCellView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

+ (UISwitchCellView*)create
{
    UINib *nib = [UINib nibWithNibName:@"UISwitchCellView" bundle:nil];
    NSArray *views = [nib instantiateWithOwner:nil options:nil];
    return views[0];
}



@end
