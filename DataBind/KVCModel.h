//
//  KVCModel.h
//  SimpleChatDemo
//
//  Created by gevin.chen on 2015/4/19.
//  Copyright (c) 2015年 gevin.chen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KVCModel : NSObject
{
    // model property name 為 key , json dictionary key 為 value,
    NSMutableDictionary *_mapping;
}

-(id)initWithDict:(NSDictionary*)dic;

-(void)injectDict:(NSDictionary*)dic;

-(void)addMapping:(NSString*)jsonKey propertyName:(NSString*)pName;

-(NSDictionary*)dict;
-(NSString*)jsonString;
-(NSData*)jsonData;

+(NSMutableArray*)convertArray:(NSArray*)array toClass:(Class)cls;

@end
