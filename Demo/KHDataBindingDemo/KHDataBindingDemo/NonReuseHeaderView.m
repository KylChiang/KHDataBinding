//
//  NonReuseHeaderView.m
//  KHDataBindingDemo
//
//  Created by GevinChen on 2017/3/12.
//  Copyright © 2017年 GevinChen. All rights reserved.
//

#import "NonReuseHeaderView.h"

@implementation NonReuseHeaderView

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    self.btn.layer.cornerRadius = 5;
    self.btn.layer.borderWidth = 1;
    self.btn.layer.borderColor = [UIColor colorWithRed:0.5 green:0.5 blue:1 alpha:1].CGColor;
    
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
+(NonReuseHeaderView*)create
{
    UINib *nib = [UINib nibWithNibName:@"NonReuseHeaderView" bundle:nil];
    NSArray *views = [nib instantiateWithOwner:nil options:nil];
    return views[0];
}

@end
