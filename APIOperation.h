//
//  APIOperation.h
//  ETicketClient
//
//  Created by GevinChen on 2015/9/25.
//  Copyright (c) 2015年 omg. All rights reserved.
//

#import <Foundation/Foundation.h>

@class APIOperation;
// api response block
typedef void(^APIOperationResponse)(APIOperation* api, id responseObject );
typedef void(^APIOperationError)(APIOperation* api, NSError* error );

// serialize block
typedef NSData* (^APIDataSerializer)(APIOperation* api,id requestObj );
typedef id (^APIDataUnserializer)(APIOperation* api,NSData*data);

@interface APIOperation : NSOperation
{
    NSURL *domainURL;
    
    NSURLConnection *conn;
    
//    NSMutableURLRequest *request;
    
    NSDictionary* _param;
    
    NSData* _body;
    
    NSMutableData* _receiveData;
    
    NSOperationQueue* _queue;
    
    APIOperationResponse _apiResBlock;
    APIOperationError    _apiFailBlock;
}

@property (nonatomic) NSString* title; // 此次連線的名稱，可不填
@property (nonatomic) NSString* acceptType; //
@property (nonatomic) NSString* contentType; // 參考 http://www.freeformatter.com/mime-types-list.html or http://tool.oschina.net/commons
@property (nonatomic) NSString* domain; // domain
@property (nonatomic) NSString* apiUrl;    // api 網址，不含domain
@property (nonatomic) NSString* method; // GET or POST , PUT , DELETE
@property (nonatomic) NSDictionary* param;
@property (nonatomic) NSData* body;
@property (nonatomic) NSOperationQueue* queue;
@property (nonatomic,copy) APIDataSerializer requestSerializer; // 序列化函式指標
@property (nonatomic,copy) APIDataUnserializer responseSerializer; // 解序列化函式指標
@property (nonatomic,readonly) NSString* result;    // 收到的結果
@property (nonatomic) int statusCode;   // api 回應狀態碼
@property (nonatomic) BOOL debug;


-(instancetype)initWithDomain:(NSString*)domain;
-(instancetype)initWithDomain:(NSString*)domain requestSerializer:(APIDataSerializer)reqSerial responseSerializer:(APIDataUnserializer)resSerial;

-(void)requestMethod:(NSString*)method 
                 api:(NSString*)api
               param:(NSDictionary*)param
                body:(id)body
            response:(APIOperationResponse)responseHandle
                fail:(APIOperationError)failHandle;

@end
