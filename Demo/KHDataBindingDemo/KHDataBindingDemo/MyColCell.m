//
//  MyColCell.m
//  KHDataBindingDemo
//
//  Created by GevinChen on 2017/3/12.
//  Copyright © 2017年 omg. All rights reserved.
//

#import "MyColCell.h"

@implementation MyColCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)onLoad:(NSString*)model
{
    
    self.labelTitle.text = model;
}

@end
