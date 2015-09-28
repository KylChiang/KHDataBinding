//
//  MyCell.m
//  DataBindTest
//
//  Created by GevinChen on 2015/9/26.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import "MyCell.h"

const NSString *ButtonCellButtonClickEvent = @"ButtonCellButtonClickEvent";
const NSString *MyCellSwitchChanged = @"MyCellSwitchChanged";

@implementation LabelCell

- (void)setText:(NSString *)text
{
    if ( [text isKindOfClass:[NSString class]]) {
        _text = text;
    }
    else if( [text isKindOfClass:[NSValue class]]){
        _text = [text valueForKey:@"stringValue"];
    }
    
    self.infoLabel.text = _text;
}

- (void)setTitle:(NSString *)title
{
    _title = title;
    self.titleLabel.text = title;
}

@end

@implementation SwitchCell

- (void)awakeFromNib {
    [self.isOnSw addTarget:self action:@selector(changedValue:) forControlEvents:UIControlEventValueChanged];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setTitle:(NSString*)title
{
    _title = title;
    self.titleLabel.text = title;
}

- (void)setOn:(BOOL)on
{
    _on = on;
    self.isOnSw.on = on;
}

- (void)changedValue:(id)sender
{
    [self.helper notify:MyCellSwitchChanged userInfo:self.isOnSw];
}

@end

@implementation TextFieldCell 

- (void)awakeFromNib {
    self.textField.delegate = self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)setText:(NSString *)text
{
    if ( [text isKindOfClass:[NSString class]]) {
        _text = text;
    }
    else if( [text isKindOfClass:[NSValue class]]){
        _text = [text valueForKey:@"stringValue"];
    }
    
    self.textField.text = _text;
}

- (void)setTitle:(NSString *)title
{
    _title = title;
    self.titleLabel.text = title;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    _text = textField.text;
    [self updateModel:@"text"];
    [textField resignFirstResponder];
    return YES;
}


@end


@implementation ButtonCell

- (void)awakeFromNib {
    [self.btn addTarget:self action:@selector(btnclick:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (void)setTitle:(NSString *)title
{
    _title = title;
    self.titleLabel.text = title;
}

- (void)setBtnTitle:(NSString *)btnTitle
{
    _btnTitle = btnTitle;
    [self.btn setTitle:btnTitle forState:UIControlStateNormal];
}

- (void)btnclick:(id)sender
{
    [self.helper notify:ButtonCellButtonClickEvent userInfo:self.cellData[kCellIndex]];
}


@end


@implementation TextViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

@end



@implementation SlideCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

@end



