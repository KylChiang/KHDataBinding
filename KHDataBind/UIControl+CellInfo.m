//
//  UIButton+CellInfo.m
//  Pipimy
//
//  Created by GevinChen on 2015/1/5.
//  Copyright (c) 2015年 omg. All rights reserved.
//

#import "UIControl+CellInfo.h"
#import <objc/runtime.h>

@implementation UIControl ( CellInfo )
/*
@dynamic index;

-(void)setIndex:(NSIndexPath *)index
{
    objc_setAssociatedObject( self, @"kIndexPath", index, OBJC_ASSOCIATION_RETAIN);
}

-(NSIndexPath*)index
{
    return objc_getAssociatedObject(self, @"kIndexPath" );
}
*/

@dynamic cell;

-(void)setCell:(KHTableViewCell *)cell
{
    objc_setAssociatedObject( self, @"khCell", cell, OBJC_ASSOCIATION_ASSIGN );
}

-(KHTableViewCell*)cell
{
    return objc_getAssociatedObject(self, @"khCell");
}

@end
