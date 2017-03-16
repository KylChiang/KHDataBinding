//
//  TextInputView.h
//  KHDataBindingDemo
//
//  Created by GevinChen on 2017/3/16.
//  Copyright © 2017年 omg. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TextInputView : UIView

@property (weak, nonatomic) IBOutlet UILabel *labelTitle;
@property (weak, nonatomic) IBOutlet UITextField *textField;


+ (TextInputView*)create;

@end
