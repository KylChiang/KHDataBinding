//
//  MyAPISerializer.m
//  DataBindTest
//
//  Created by GevinChen on 2015/10/10.
//  Copyright © 2015年 GevinChen. All rights reserved.
//

#import "MyAPISerializer.h"

@implementation MyAPISerializer


- (NSURLRequest *)requestBySerializingRequest:(NSMutableURLRequest *)request
                               withParameters:(NSDictionary *)parameters
                                        error:(NSError *__autoreleasing *)error
{
    if ( parameters ) {
        NSError *jsonError = nil;
        NSData *data = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:&jsonError];
        [request setHTTPBody: data ];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"]; // 跟 server 說，我寄過去的是什麼格式
    }
    
    return request;
}



@end


@implementation MyAPIUnSerializer



- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
    NSError *jsonError = nil;
    NSDictionary *jsonDic = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
    
    return jsonDic;
}

@end