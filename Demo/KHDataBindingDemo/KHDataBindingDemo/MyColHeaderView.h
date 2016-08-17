//
//  MyColHeaderView.h
//  KHDataBindDemo
//
//  Created by GevinChen on 2016/8/16.
//  Copyright © 2016年 omg. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KHDataBinding.h"

@interface MyColHeaderView : UICollectionReusableView

@property (weak, nonatomic) IBOutlet UILabel *labelTitle;

@end

@interface MyColHeaderViewModel : NSObject

@property (nonatomic) NSString *title;

@end