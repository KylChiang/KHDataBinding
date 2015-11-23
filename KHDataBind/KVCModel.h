//
//  KVCModel.h
//  SimpleChatDemo
//
//  Created by gevin.chen on 2015/4/19.
//  Copyright (c) 2015年 gevin.chen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSData+Base64.h"

@interface KVCModel : NSObject
{
    // model property name 為 key , json dictionary key 為 value,
    NSMutableDictionary *_keyCorrespondDic;
}
 
-(id)initWithDict:(NSDictionary*)dic;

-(void)injectDict:(NSDictionary*)dic;

//  原本預設行為是，會直接找跟 json key 同名的 property 填入資料
//  如果有些 josn 的 key 你想轉成對應不太一樣的 property name，可以用的這個 function 註明
//  例如： {"address":"XXXXX"} 
//       address 想填到 object 的一個叫 myAddress 的 property 就可以呼叫
//      [object setProperty:@"myAddress" correspondKey:"address"];
-(void)setProperty:(NSString*)property correspondKey:(NSString*)jsonKey;

-(NSDictionary*)dict;
-(NSString*)jsonString;
-(NSData*)jsonData;

//  把 array 的 object 都轉成指定的 class
+(NSMutableArray*)convertArray:(NSArray*)array toClass:(Class)cls keyCorrespond:(NSDictionary*)correspondDic;

//  把 dictionary 的資料填入 object，預設會填入與 json key 同名的 property
+(void)injectDictionary:(NSDictionary*)jsonDic toObject:(id)object keyCorrespond:(NSDictionary*)correspondDic;

//  把 object 轉成 dictionary，依 property name 轉成相名的 json key
+(NSDictionary*)dictionaryWithObj:(id)object keyCorrespond:(NSDictionary*)correspondDic;

@end
