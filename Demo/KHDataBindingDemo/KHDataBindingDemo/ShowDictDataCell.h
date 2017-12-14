//
//  ShowDictDataCell.h
//  KHDataBindingDemo
//
//  Created by GevinChen on 2017/2/13.
//  Copyright © 2017年 GevinChen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KHCell.h"

@interface ShowDictDataCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *labelTitle;
@property (weak, nonatomic) IBOutlet UILabel *labelName;
@property (weak, nonatomic) IBOutlet UILabel *labelComment;

@end
