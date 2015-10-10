//  EncryptorAES.H
//  testAllPay
//
//  Created by 盧丸子 on 12/9/11.
//  Copyright (c) 2012年 盧丸子. All rights reserved.
//
#import <CommonCrypto/CommonCryptor.h>
#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
enum 
{
     base64=64,  //base64
     base16=16,  //hex
};
typedef uint32_t byteTypeDirection;


@interface EncryptorAES : NSObject 

+(NSString *) AES128EncryptWithKey:(NSString *)key iv:(NSString *)iv stringCode:(NSString *)stringCode urlencode:(BOOL)encode byteType:(byteTypeDirection)_byteType;
+(NSString *) AES128DecryptWithKey:(NSString *)key iv:(NSString *)iv stringCode:(NSString *)stringCode urldecode:(BOOL)decode byteType:(byteTypeDirection)_byteType;

+(NSData *) AES128EncryptWithKey:(NSString *)key iv:(NSString *)iv data:(NSData *)data;
+(NSData *) AES128DecryptWithKey:(NSString *)key iv:(NSString *)iv data:(NSData *)data;

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
