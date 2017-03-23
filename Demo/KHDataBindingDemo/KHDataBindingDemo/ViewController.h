//
//  ViewController.h
//  DataBindTest
//
//  Created by GevinChen on 2015/8/30.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KHDataBinding.h"



@interface ViewController : UIViewController <KHTableViewDelegate>
@property (weak, nonatomic) IBOutlet KHTableView *tableView;


@end

