//
//  MyCell.h
//  DataBindTest
//
//  Created by GevinChen on 2015/9/26.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KHTableViewBindHelper.h"

@interface LabelCell : KHAbstractCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;

@end

@interface SwitchCell : KHAbstractCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UISwitch *sw;

@end

@interface TextFieldCell : KHAbstractCell <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;


@end


@interface ButtonCell : KHAbstractCell
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *btn;


@end

@interface TextViewCell : KHAbstractCell
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end


@interface SlideCell : KHAbstractCell
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UISlider *slide;

@end



