//
//  URLUtility.h
//  DataBindTest
//
//  Created by GevinChen on 2015/10/10.
//  Copyright © 2015年 GevinChen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Base64Utility : NSObject

+(NSString*)urlEncoded:(NSString*)str;
+(NSString*)urlDecoded :(NSString*)str;
+(NSString *)base64Encode:(NSString *)plainString;
+(NSString *)base64Decode:(NSString *)base64String;
+(NSString*)stringFromByte:(Byte)byteVal;
+(NSString*)hexStringFromData:(NSData*)data;
+(NSData *)dataFromHexString:(NSString *)string;
+(NSString*)md5:(NSString*)string;

@end
