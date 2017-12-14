//
//  ShowDictDataCell.m
//  KHDataBindingDemo
//
//  Created by GevinChen on 2017/2/13.
//  Copyright © 2017年 GevinChen. All rights reserved.
//

#import "ShowDictDataCell.h"

@implementation ShowDictDataCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

+ (Class)mappingModelClass
{
    return [NSDictionary class];
}

- (void)onLoad:(NSDictionary*)model
{
    self.labelTitle.text = model[@"title"];
    self.labelName.text = model[@"name"];
    self.labelComment.text = model[@"comment"];
}


@end
