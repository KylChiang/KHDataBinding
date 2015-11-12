//
//  Results.m
//
//  Created by GevinChen  on 2015/10/9
//  Copyright (c) 2015 __MyCompanyName__. All rights reserved.
//

#import "UserModel.h"
#import "UserInfoCell.h"

@implementation Location

@end

@implementation Name

@end

@implementation Picture
@end

@implementation User

@end

@implementation UserModel

- (instancetype)initWithDict:(NSDictionary *)dic
{
    self = [super initWithDict:dic];
    self.cellClass = [UserInfoCell class];
    return self;
}

@end
