//
//  Results.m
//
//  Created by GevinChen  on 2015/10/9
//  Copyright (c) 2015 __MyCompanyName__. All rights reserved.
//

#import "UserModel.h"


@implementation Location

@end

@implementation Name

@end

@implementation Picture
@end

@implementation User

@end

@implementation UserModel

-(instancetype)initWithDict:(NSDictionary *)dic
{
    if (self=[super initWithDict:dic]) {
        self.nibName = @"UserInfoCell";
        self.identifier = @"userCell";
    }
    return self;
}

-(instancetype)init
{
    if (self=[super init]) {
        self.nibName = @"UserInfoCell";
        self.identifier = @"userCell";
    }
    return self;
}


@end
