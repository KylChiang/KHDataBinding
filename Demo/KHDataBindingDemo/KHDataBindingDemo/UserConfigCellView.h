//
//  UserConfigCellView.h
//  KHDataBindingDemo
//
//  Created by GevinChen on 2017/3/16.
//  Copyright © 2017年 GevinChen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UserConfigCellView : UIView

@property (weak, nonatomic) IBOutlet UITextField *textName;
@property (weak, nonatomic) IBOutlet UITextField *textAge;
@property (weak, nonatomic) IBOutlet UITextField *textGender;
@property (weak, nonatomic) IBOutlet UISwitch *swBreakfast;


+(UserConfigCellView*)create;

@end
