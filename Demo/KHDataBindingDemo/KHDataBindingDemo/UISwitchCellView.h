//
//  UISwitchCellView.h
//  KHDataBindingDemo
//
//  Created by GevinChen on 2017/3/16.
//  Copyright © 2017年 omg. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UISwitchCellView : UIView
@property (weak, nonatomic) IBOutlet UISwitch *sw;
@property (weak, nonatomic) IBOutlet UILabel *labelTitle;
@property (weak, nonatomic) IBOutlet UILabel *labelDescription;

+ (UISwitchCellView*)create;

@end
