//
//  URLUtility.m
//  DataBindTest
//
//  Created by GevinChen on 2015/10/10.
//  Copyright © 2015年 GevinChen. All rights reserved.
//

#import "Base64Utility.h"
#import <CommonCrypto/CommonDigest.h>

@implementation Base64Utility

+(NSString*)urlEncoded:(NSString*)str {
    
    NSString *escapedString =CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                       (CFStringRef)str,
                                                                                       NULL,
                                                                                       CFSTR("!$'()*+,-./:;?@_~%#[]"),
                                                                                       kCFStringEncodingUTF8));
    
    
    return escapedString;
    
}

+(NSString*)urlDecoded :(NSString*)str {
    
    NSString *cleanUrlString =  [str stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return cleanUrlString;
    
}

+(NSString *)base64Encode:(NSString *)plainString
{
    NSData *plainData = [plainString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64String = [plainData base64EncodedStringWithOptions:0];
    return base64String;
}

+ (NSString *)base64Decode:(NSString *)base64String
{
    
    NSData *plainTextData = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
    NSString *plainText = [[NSString alloc] initWithData:plainTextData encoding:NSUTF8StringEncoding];
#if !__has_feature(objc_arc)
    [plainText autorelease];
#endif
    return plainText;
}

+(NSString*)stringFromByte:(Byte)byteVal
{
    NSMutableString *str=[NSMutableString string];
    
    //取高四位
    Byte byte1 = byteVal>>4;
    //取低四位
    Byte byte2=byteVal & 0xf;
    //拼接16进制字符串
    [str appendFormat:@"%x",byte1];
    [str appendFormat:@"%x",byte2];
    return str;
}

+(NSString*)hexStringFromData:(NSData*)data
{
    NSMutableString *str=[NSMutableString string];
    Byte *byte= (Byte*)[data bytes];
    for(int i=0;i<[data length];i++){
        //byte+i为指针
        [str appendString:[self stringFromByte:*(byte+i)]];
    }
    return str;
}


+(NSData *)dataFromHexString:(NSString *)string {
    string = [string lowercaseString];
    NSMutableData *data= [NSMutableData new];
#if !__has_feature(objc_arc)
    [data autorelease];
#endif
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i = 0;
    long length = string.length;
    while (i < length-1) {
        char c = [string characterAtIndex:i++];
        if (c < '0' || (c > '9' && c < 'a') || c > 'f')
            continue;
        byte_chars[0] = c;
        byte_chars[1] = [string characterAtIndex:i++];
        whole_byte = strtol(byte_chars, NULL, 16);
        [data appendBytes:&whole_byte length:1];
        
    }
    
    return data;
}

+(NSString*)md5:(NSString*)string{
    const char *cStr = [string UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, strlen(cStr), result );
    return [NSString
            stringWithFormat: @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1],
            result[2], result[3],
            result[4], result[5],
            result[6], result[7],
            result[8], result[9],
            result[10], result[11],
            result[12], result[13],
            result[14], result[15]
            ];
    
}

@end
