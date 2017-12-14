//
//  KHCore.m
//  KHDataBindingDemo
//
//  Created by richard on 2017/12/14.
//  Copyright © 2017年 omg. All rights reserved.
//

#import "KHCore.h"

@implementation KHCore

+ (instancetype)shareCore
{
    static KHCore           *singleton;
    static dispatch_once_t  onceToken;
    
    dispatch_once(&onceToken, ^{
        singleton = [KHCore new];
        
        [singleton __setup];
    });
    
    return singleton;
}

#pragma mark - Private
- (void)__setup
{
    
}

@end
