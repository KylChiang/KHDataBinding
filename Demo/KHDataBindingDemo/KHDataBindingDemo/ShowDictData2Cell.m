//
//  ShowDictData2Cell.m
//  KHDataBindingDemo
//
//  Created by GevinChen on 2017/2/13.
//  Copyright © 2017年 GevinChen. All rights reserved.
//

#import "ShowDictData2Cell.h"

@implementation ShowDictData2Cell
{
    NSDateFormatter *fmt;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    fmt = [[NSDateFormatter alloc] init];
    [fmt setDateFormat:@"yyyy-MM-dd HH;mm:ss"];
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
    self.labelData1.text = model[@"data1"];
    self.labelData2.text = [model[@"data2"] stringValue];
    NSDate *date = model[@"data3"];
    self.labelData3.text = [fmt stringFromDate: date ];

}

@end
