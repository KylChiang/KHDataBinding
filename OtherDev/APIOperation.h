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
typedef void(^APIOperationResponse)(APIOperation *api, id responseObject );
typedef void(^APIOperationError)(APIOperation *api, NSError *error );


@protocol APIDataSerializeDelegate

@optional
// override by subclass
- (NSData*)serialize:(APIOperation*)api data:(id)value;

// override by subclass
- (id)unSerialize:(APIOperation*)api data:(NSData*)data;

@end


// serialize block
typedef NSData *(^APIDataSerializer)(APIOperation *api,id requestObj );
typedef id (^APIDataUnserializer)(APIOperation *api,NSData*data);

@interface BlockDataSerializer : NSObject <APIDataSerializeDelegate>
{
    APIDataSerializer _serialize;
    APIDataUnserializer _unserialize;
}

- (instancetype)initWithSerialize:(APIDataSerializer)serializeBlock unserialize:(APIDataUnserializer)unserilizeBlock;

@end

@interface SelectorDataSerializer : NSObject <APIDataSerializeDelegate>
{
    
    id _target;
    
    SEL _serialize;
    
    SEL _unserialize;
    
    NSInvocation *_serializeInvoke;
    
    NSInvocation *_unserializeInvoke;
    
}

- (instancetype)initWithTarget:(id)target serialize:(SEL)serialize unserialize:(SEL)unserialize;

@end

@interface APIJSONSerializer : NSObject <APIDataSerializeDelegate>

@end



@interface APIOperation : NSOperation
{
    
    NSURLConnection *conn;
    
//    NSMutableURLRequest *request;
    
    NSDictionary *_param;
    
    NSData *_body;
    
    NSMutableData *_receiveData;
    
    NSOperationQueue *_queue;
    
    APIOperationResponse _apiResBlock;
    APIOperationError    _apiFailBlock;
}

@property (nonatomic) NSString *title; // 此次連線的名稱，可不填
@property (nonatomic) NSString *acceptType; //
@property (nonatomic) NSString *contentType; // 參考 http://www.freeformatter.com/mime-types-list.html or http://tool.oschina.net/commons
@property (nonatomic) NSString *apiUrl; // api 網址，不含domain
@property (nonatomic) NSString *method; // GET or POST , PUT , DELETE
@property (nonatomic) NSDictionary *param;
@property (nonatomic) NSData *body;
@property (nonatomic) NSOperationQueue *queue;
@property (nonatomic) id<APIDataSerializeDelegate> serializer; // 序列化物件
@property (nonatomic) id<APIDataSerializeDelegate> unserializer; // 解序列化函式指標
@property (nonatomic,readonly) NSString *result;    // 收到的結果
@property (nonatomic) int statusCode;   // api 回應狀態碼
@property (nonatomic) BOOL debug;


-(instancetype)initWithSerializer:(id)serializer unserializer:(id)unserializer;

-(void)GET:(NSString*)api
     param:(NSDictionary*)param
      body:(id)body
  response:(APIOperationResponse)responseHandle
      fail:(APIOperationError)failHandle;

-(void)POST:(NSString*)api
      param:(NSDictionary*)param
       body:(id)body
   response:(APIOperationResponse)responseHandle
       fail:(APIOperationError)failHandle;

-(void)PUT:(NSString*)api
     param:(NSDictionary*)param
      body:(id)body
  response:(APIOperationResponse)responseHandle
      fail:(APIOperationError)failHandle;

-(void)DEL:(NSString*)api
     param:(NSDictionary*)param
      body:(id)body
  response:(APIOperationResponse)responseHandle
      fail:(APIOperationError)failHandle;

-(void)requestMethod:(NSString*)method
                 api:(NSString*)api
               param:(NSDictionary*)param
                body:(id)body
            response:(APIOperationResponse)responseHandle
                fail:(APIOperationError)failHandle;

@end
