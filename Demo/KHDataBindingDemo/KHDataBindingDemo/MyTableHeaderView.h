//
//  MyFooterView.h
//  KHDataBindDemo
//
//  Created by GevinChen on 2016/4/22.
//  Copyright © 2016年 GevinChen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MyTableHeaderView : UIView
@property (weak, nonatomic) IBOutlet UIButton *button;

+ (MyTableHeaderView*)create;
@end
