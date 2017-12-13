//
//  TextInputView.m
//  KHDataBindingDemo
//
//  Created by GevinChen on 2017/3/16.
//  Copyright © 2017年 GevinChen. All rights reserved.
//

#import "TextInputView.h"

@implementation TextInputView



/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

+ (TextInputView*)create
{
    UINib *nib = [UINib nibWithNibName:@"TextInputView" bundle:nil];
    NSArray *views = [nib instantiateWithOwner:nil options:nil];
    return views[0];
}

@end
