//
//  MyCell.h
//  DataBindTest
//
//  Created by GevinChen on 2015/9/26.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TableViewBindHelper.h"

@interface LabelCell : CKHTableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;

@property (nonatomic,readwrite) NSString* title;
@property (nonatomic,readwrite) NSString* text;

@end


extern const NSString *MyCellSwitchChanged;
@interface SwitchCell : CKHTableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UISwitch *isOnSw;

@property (nonatomic,readwrite) NSString* title;
@property (nonatomic,readwrite) BOOL on;

@end


@interface TextFieldCell : CKHTableViewCell <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (nonatomic,readwrite) NSString* title;
@property (nonatomic,readwrite) NSString* text;

@end


extern const NSString *ButtonCellButtonClickEvent;
@interface ButtonCell : CKHTableViewCell
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *btn;

@property (nonatomic) NSString* title;
@property (nonatomic) NSString* btnTitle;

@end


@interface TextViewCell : CKHTableViewCell
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end



@interface SlideCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UISlider *slide;

@end



