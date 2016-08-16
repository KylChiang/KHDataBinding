//
//  MyColHeaderView.m
//  KHDataBindDemo
//
//  Created by GevinChen on 2016/8/16.
//  Copyright © 2016年 omg. All rights reserved.
//

#import "MyColHeaderView.h"

@implementation MyColHeaderViewModel


@end

@implementation MyColHeaderView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
}


+(Class)mappingModelClass
{
    return [MyColHeaderViewModel class];
}

- (void)onLoad:(MyColHeaderViewModel*)model
{
    self.labelTitle.text = model.title;
}

@end


