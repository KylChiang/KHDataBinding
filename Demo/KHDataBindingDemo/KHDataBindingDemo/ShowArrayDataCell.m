//
//  ShowArrayDataCell.m
//  KHDataBindingDemo
//
//  Created by GevinChen on 2017/2/13.
//  Copyright © 2017年 GevinChen. All rights reserved.
//

#import "ShowArrayDataCell.h"

@implementation ShowArrayDataCell

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
    return [NSArray class];
}

- (void)onLoad:(NSArray*)model
{
    NSMutableString *string = [[NSMutableString alloc]initWithCapacity:100];
    for ( id obj in model ) {
        if ( [obj isKindOfClass:[NSString class]] ) {
            [string appendString: obj ];
            [string appendString: @"," ];
        }
    }
    
    self.labelArrayData.text = string;
}

@end
