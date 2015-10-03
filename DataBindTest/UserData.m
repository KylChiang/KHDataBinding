//
//  UserData.m
//  DataBindTest
//
//  Created by GevinChen on 2015/8/30.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import "UserData.h"

@implementation UserData

-(instancetype)init
{
    self = [super init];
    if ( self ) {
        self.nibName = @"UserCell";
        self.identifier = @"userCell";
    }
    return self;
}

@end
