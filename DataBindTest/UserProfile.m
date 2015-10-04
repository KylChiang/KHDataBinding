//
//  UserProfile.m
//  DataBindTest
//
//  Created by GevinChen on 2015/10/4.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import "UserProfile.h"

@implementation ImageSet


@end
@implementation UserProfile

-(instancetype)init
{
    if (self=[super init]) {
        self.nibName = @"UserProfileCell";
        self.identifier = @"userProfileCell";
    }
    return self;
}

@end
