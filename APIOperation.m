//
//  APIOperation.m
//  ETicketClient
//
//  Created by GevinChen on 2015/9/25.
//  Copyright (c) 2015年 omg. All rights reserved.
//

#import "APIOperation.h"
#import "EncryptorAES.h"


@implementation BlockDataSerializer

- (instancetype)initWithSerialize:(APIDataSerializer)serializeBlock unserialize:(APIDataUnserializer)unserilizeBlock
{
    self = [super init];
    if (self) {
        _serialize = [serializeBlock copy];
        _unserialize = [unserilizeBlock copy];
    }
    return self;
}

- (NSData*)serialize:(APIOperation*)api data:(id)value
{
    if ( _serialize ) {
        NSData *data = _serialize( api, value );
        return data;
    }
    return nil;
}

- (id)unSerialize:(APIOperation*)api data:(NSData*)data
{
    if ( _unserialize ) {
        id value = _unserialize( api, data );
        return value;
    }
    return nil;
}


@end


@implementation SelectorDataSerializer

-(instancetype)initWithTarget:(id)target serialize:(SEL)serialize unserialize:(SEL)unserialize
{
    self = [super init];
    if (self) {
        _target = target;
        _serialize = serialize;
        _unserialize = unserialize;
        
        if ( serialize != NULL ) {
            NSMethodSignature* signature1 = [_target methodSignatureForSelector:_serialize];
            _serializeInvoke = [NSInvocation invocationWithMethodSignature:signature1];
            [_serializeInvoke setTarget:_target];
            [_serializeInvoke setSelector:_serialize];
        }

        if ( unserialize != NULL ) {
            NSMethodSignature* signature2 = [_target methodSignatureForSelector:_unserialize];
            _unserializeInvoke = [NSInvocation invocationWithMethodSignature:signature2];
            [_unserializeInvoke setTarget:_target];
            [_unserializeInvoke setSelector:_unserialize];
        }
    }
    return self;
}

- (NSData*)serialize:(APIOperation*)api data:(id)value
{
    if (_serializeInvoke) {
        [_serializeInvoke setArgument:&api atIndex:2];
        [_serializeInvoke setArgument:&value atIndex:3];
        [_serializeInvoke invoke];
        
        NSData *data = nil;
        [_serializeInvoke getReturnValue: &data ];
        return data;
    }
    return nil;
}

- (id)unSerialize:(APIOperation*)api data:(NSData*)data
{
    if (_unserializeInvoke ) {
        [_unserializeInvoke setArgument:&api atIndex:2];
        [_unserializeInvoke setArgument:&data atIndex:3];
        [_unserializeInvoke invoke];
        
        id value = nil;
        [_unserializeInvoke getReturnValue: &value ];
        return value;
    }
    return nil;
}


@end


@implementation APIJSONSerializer


- (NSData*)serialize:(APIOperation*)api data:(id)value
{
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:value options:0 error:&error];
    
    if ( error ) {
        printf("json serialize error, code:%ld ,domain:%s \n", error.code, [error.domain UTF8String] );
    }
    return data;
}

- (id)unSerialize:(APIOperation*)api data:(NSData*)data
{
    NSError *error = nil;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    
    if ( error ) {
        printf("json unserialize error, code:%ld ,domain:%s \n", error.code, [error.domain UTF8String] );
    }
    return dic;
}


@end


//----------------------------------------------------



@implementation APIOperation

-(instancetype)init
{
    APIJSONSerializer *jsonSerializer = [APIJSONSerializer new];
    return [self initWithSerializer:jsonSerializer unserializer:jsonSerializer];
}

-(instancetype)initWithSerializer:(id)serializer unserializer:(id)unserializer
{
    self = [super init];
    if ( self ) {
//        request=[[NSMutableURLRequest alloc]init];
        _contentType = @"application/x-www-form-urlencoded";
        _serializer = serializer;
        _unserializer = unserializer;
        _receiveData = [[NSMutableData alloc] init];
        _queue = [NSOperationQueue mainQueue];
    }
    return self;
    
}

-(void)GET:(NSString*)api
     param:(NSDictionary*)param
      body:(id)body
  response:(APIOperationResponse)responseHandle
      fail:(APIOperationError)failHandle
{
    _method = @"GET";
    
    _apiUrl = api;
    
    _param = param;
    
    _body = body;
    
    _apiResBlock = responseHandle;
    
    _apiFailBlock = failHandle;
}

-(void)POST:(NSString*)api
      param:(NSDictionary*)param
       body:(id)body
   response:(APIOperationResponse)responseHandle
       fail:(APIOperationError)failHandle
{
    _method = @"POST";
    
    _apiUrl = api;
    
    _param = param;
    
    _body = body;
    
    _apiResBlock = responseHandle;
    
    _apiFailBlock = failHandle;
}

-(void)PUT:(NSString*)api
     param:(NSDictionary*)param
      body:(id)body
  response:(APIOperationResponse)responseHandle
      fail:(APIOperationError)failHandle
{
    _method = @"PUT";
    
    _apiUrl = api;
    
    _param = param;
    
    _body = body;
    
    _apiResBlock = responseHandle;
    
    _apiFailBlock = failHandle;
}

-(void)DEL:(NSString*)api
     param:(NSDictionary*)param
      body:(id)body
  response:(APIOperationResponse)responseHandle
      fail:(APIOperationError)failHandle
{
    _method = @"DELETE";
    
    _apiUrl = api;
    
    _param = param;
    
    _body = body;
    
    _apiResBlock = responseHandle;
    
    _apiFailBlock = failHandle;
}

-(void)requestMethod:(NSString*)method 
                 api:(NSString*)api
               param:(NSDictionary*)param
                body:(id)body
            response:(APIOperationResponse)responseHandle
                fail:(APIOperationError)failHandle;
{
    
    _method = method;
    
    _apiUrl = api;
    
    _param = param;
    
    _body = body;
    
    _apiResBlock = responseHandle;
    
    _apiFailBlock = failHandle;
    
}

- (void)main
{
    @autoreleasepool {
        
        NSMutableURLRequest* request=[[NSMutableURLRequest alloc]init];
        
        // api + param
        //-----------------------------
        NSString* api = _apiUrl;
        if ( _param ) {
            api = [self url:api combineParam:_param ];
        }
        
        //  建立 NSURL
        //-----------------------------
        [request setURL: [NSURL URLWithString:api] ];
        
        // request method
        //-----------------------------
        [request setHTTPMethod: _method ];
        
        if ( _debug ) {
            printf("%s %s\n", [_method UTF8String], [api UTF8String]);
        }
        
        // body 做序列化
        //-----------------------------
        id serialBody = nil;
        if( _body  ){
            if ( _serializer ) {
                serialBody = [_serializer serialize:self data:_body];
            }
            else{
                if( [_body isKindOfClass:[NSString class]]){
                    serialBody = [(NSString*)_body dataUsingEncoding:NSUTF8StringEncoding];
                }
                if ( [_body isKindOfClass:[NSData class]]) {
                    serialBody = _body;
                }
                else{
                    NSException* exception = [NSException exceptionWithName:@"Parameter invalid"
                                                                     reason:@"parameter is not a NSString or you did not assign a serializer to parse param." userInfo:nil];
                    @throw exception;
                }
            }
            
            if ( serialBody ) {
                [request setHTTPBody: serialBody ];
            }
        }
        
        // 設定 request header
        //-----------------------------
        if (self.acceptType) {
            [request setValue:self.acceptType forHTTPHeaderField:@"Accept"];  // 跟 server 說，client 預期可以收到什麼格式
        }
        if ( self.contentType ) {
            [request setValue:self.contentType forHTTPHeaderField:@"Content-Type"]; // 跟 server 說，我寄過去的是什麼格式
        }
        if ( _debug ) {
            printf("Accept:%s\n",[self.acceptType UTF8String]);
            printf("Content-Type:%s\n",[self.contentType UTF8String]);
        }
        
        //  設定一些 request 的設定
        //------------------------------
        [request setTimeoutInterval: 15 ];
        [request setHTTPShouldHandleCookies:NO];
        
        // 發送請求
        //-----------------------------
        NSURLResponse *res = nil;
        NSError *err = nil;
        
        //  送出後取得資料
        //-----------------------------
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&res error:&err];
        
        //  檢查此次連線的狀態
        //-----------------------------
        if ( res ) {
            //連線建立成功
            //取得狀態
            _statusCode = (int)[(NSHTTPURLResponse *)res statusCode];
            printf("%s statusCode:%d\n", [_title UTF8String], _statusCode );
        }

        //  發生錯誤
        //-----------------------------
        if ( err ) {
            _apiFailBlock( self, err );
        }
        else{
            //  連線成功
            //-----------------------------
            
            //  解序列化
            id responseObj = nil;
            //  如果有自訂的序列化程序，就執行，如果沒有就直接轉成字串
            if( _unserializer ) {
                responseObj = [_unserializer unSerialize:self data:data];
            }
            else{
                responseObj = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
                if (_debug&&responseObj) {
                    NSLog(@"receive:%@", responseObj );
                }
            }
            
            //  若都無法解序列化，就直接把收到的 data 送去
            if ( responseObj == nil ) {
                _apiResBlock( self, data );
            }
            else{
                _apiResBlock( self, responseObj );
            }
        }
    }
}

#pragma mark - Private

-(NSString*)url:(NSString*)url combineParam:(NSDictionary*)param
{
    NSMutableDictionary* paramDic = [param mutableCopy];
    NSArray *allKeys = [paramDic allKeys];
    
    //  拼接參數
    //------------------------
    allKeys = [paramDic allKeys];
    NSString *result = nil;
    if (allKeys.count > 0 ) {
        NSMutableString *paramStr = [[NSMutableString alloc] initWithCapacity:0];
        for ( int i=0; i<allKeys.count ; ++i ) {
            NSString *key = allKeys[i];
            [paramStr appendFormat:@"%@=%@", key , paramDic[key] ];
            if ( i<allKeys.count-1) {
                [paramStr appendString:@"&"];
            }
        }
        result =  [NSString stringWithString: paramStr ];
        

        // 檢查 url 是否已有 ?
        //  ex: http://www.xxx.com/api/query? or http://www.xxx.com/api/query
        //------------------------
        NSRange range = [url rangeOfString:@"?"];
        
        // 沒有 ?
        if ( range.location == NSNotFound ) {
            // 做 url encode 並加上 ? 與 url 合併
            result = [EncryptorAES urlEncoded: result];
            url = [NSString stringWithFormat:@"%@?%@", url, result ];
        }
        // 有 ?
        else{
            // ? 在最後一個字，表示沒有參數
            if ( range.location == url.length - range.length ) {
                result = [EncryptorAES urlEncoded: result];
                url = [NSString stringWithFormat:@"%@%@", url, result ];
            }
            // ? 不在最後一個字，表示有既有參數
            else{
                // 先把原本的參數拆開
                NSArray* urlComp = [url componentsSeparatedByString:@"?"];
                
                // 合併新的參數跟原本的參數，然後做 url encode
                NSString* newURIString = [NSString stringWithFormat:@"%@&%@", urlComp[1], result ];
                newURIString = [EncryptorAES urlEncoded: newURIString];
                
                // 合併成新的網址
                url = [NSString stringWithFormat:@"%@?%@", urlComp[0], newURIString ];
            }
        }
    }
    
    return url;
}


@end
