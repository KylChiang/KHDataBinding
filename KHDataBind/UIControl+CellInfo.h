//
//  UIButton+CellInfo.h
//  Pipimy
//
//  Created by GevinChen on 2015/1/5.
//  Copyright (c) 2015年 omg. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "KHTableViewCell.h"

@interface UIControl ( CellInfo )

// 當 uicontrol 放在 tableview cell 裡時，當觸發 click 事件時，多加這個資訊用以辨認是哪個 cell 所觸發
//@property (nonatomic) NSIndexPath *index;
@property (nonatomic,weak) KHTableViewCell *cell;

@end
