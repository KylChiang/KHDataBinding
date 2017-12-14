//
//  NonReuseHeaderView.h
//  KHDataBindingDemo
//
//  Created by GevinChen on 2017/3/12.
//  Copyright © 2017年 GevinChen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NonReuseHeaderView : UIView

@property (weak, nonatomic) IBOutlet UIButton *btn;

+(NonReuseHeaderView*)create;
@end
