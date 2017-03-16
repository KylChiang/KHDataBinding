//
//  UserConfigCellView.m
//  KHDataBindingDemo
//
//  Created by GevinChen on 2017/3/16.
//  Copyright © 2017年 omg. All rights reserved.
//

#import "UserConfigCellView.h"

@implementation UserConfigCellView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

+(UserConfigCellView*)create
{
    UINib *nib = [UINib nibWithNibName:@"UserConfigCellView" bundle:nil];
    NSArray *views = [nib instantiateWithOwner:nil
                                       options:nil];
    return views[0];
}

@end
