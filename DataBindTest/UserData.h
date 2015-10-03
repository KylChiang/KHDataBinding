//
//  UserData.h
//  DataBindTest
//
//  Created by GevinChen on 2015/8/30.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CKHTableViewCell.h"

@interface UserData : CKHCellModel

@property (nonatomic) NSNumber *uid;
@property (nonatomic) NSString *name;
@property (nonatomic) NSNumber *age;
@property (nonatomic) NSString *address;
@property (nonatomic) NSNumber *money;
@property (nonatomic) NSString *mobile;
@property (nonatomic) BOOL male;
@property (nonatomic) NSString *userDescription;
@property (nonatomic) BOOL hasJoin;

@end
