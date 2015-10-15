//
//  URLUtility.h
//  DataBindTest
//
//  Created by GevinChen on 2015/10/10.
//  Copyright © 2015年 GevinChen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSData+Base64.h"

@interface Base64Utility : NSObject

+(NSString*)urlEncoded:(NSString*)str;
+(NSString*)urlDecoded :(NSString*)str;
+(NSString *)base64Decode:(NSString *)base64String;
+(NSData*)base64DecodeToData:(NSString*)base64String;
+(NSString*)base64forData:(NSData*)theData;
+(NSString*)stringFromByte:(Byte)byteVal;
+(NSString*)hexStringFromData:(NSData*)data;
+(NSData *)dataFromHexString:(NSString *)string;
+(NSString*)md5:(NSString*)string;

@end
