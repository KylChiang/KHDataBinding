//
//  APIOperation.m
//  ETicketClient
//
//  Created by GevinChen on 2015/9/25.
//  Copyright (c) 2015年 omg. All rights reserved.
//

#import "APIOperation.h"
#import "EncryptorAES.h"

@implementation APIOperation

-(instancetype)init
{
    return [self initWithDomain:nil requestSerializer:nil responseSerializer:nil];
}

-(instancetype)initWithDomain:(NSString *)domain
{
    return [self initWithDomain:domain requestSerializer:nil responseSerializer:nil];
}

-(instancetype)initWithDomain:(NSString*)domain requestSerializer:(APIDataSerializer)reqSerial responseSerializer:(APIDataUnserializer)resSerial;
{
    self = [super init];
    if ( self ) {
//        request=[[NSMutableURLRequest alloc]init];
        _contentType = @"application/x-www-form-urlencoded";
        _domain = [domain copy];
        domainURL = [[NSURL alloc] initWithString: _domain ];
        _requestSerializer = [reqSerial copy];
        _responseSerializer = [resSerial copy];
        _receiveData = [[NSMutableData alloc] init];
        _queue = [NSOperationQueue mainQueue];
    }
    return self;
    
}

-(void)setDomain:(NSString *)domain
{
    _domain = [domain copy];
    domainURL = [[NSURL alloc] initWithString: _domain ];
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
            if ( _debug ) {
                printf("api:%s\n",[api UTF8String]);
            }
        }    

        
        //  domain + api
        //-----------------------------
        NSString* finalUrl = nil;
        if ( [_apiUrl hasPrefix:@"/"]) {
            finalUrl = [NSString stringWithFormat:@"%@%@",_domain, api ];
        }
        else {
            finalUrl = [NSString stringWithFormat:@"%@/%@",_domain, api ];
        }
        
        //  建立 NSURL
        //-----------------------------
        [request setURL: [NSURL URLWithString:finalUrl] ];
        
        // request method
        //-----------------------------
        [request setHTTPMethod: _method ];
        
        if ( _debug ) {
            printf("%s %s\n", [_method UTF8String], [finalUrl UTF8String]);
        }
        
        // body 做序列化
        //-----------------------------
        id serialBody = nil;
        if( _body  ){
            serialBody = [self serialize: _body ];
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

        dispatch_async( dispatch_get_main_queue(), ^{
            //  發生錯誤
            //-----------------------------
            if ( err ) {
                _apiFailBlock( self, err );
            }
            else{
                //  連線成功
                //-----------------------------
                id responseObj = [self unserialize:data ];
                if ( responseObj == nil ) {
                    _apiResBlock( self, data );
                }
                else{
                    _apiResBlock( self, responseObj );
                }
            }
        });
    }
}

#pragma mark - Private

-(NSString*)url:(NSString*)url combineParam:(NSDictionary*)param
{
    NSMutableDictionary* _param = [param mutableCopy];
    NSArray *allKeys = [_param allKeys];
    
    //  拼接參數
    //------------------------
    allKeys = [_param allKeys];
    NSString *result = nil;
    if (allKeys.count > 0 ) {
        NSMutableString *paramStr = [[NSMutableString alloc] initWithCapacity:0];
        for ( int i=0; i<allKeys.count ; ++i ) {
            NSString *key = allKeys[i];
            [paramStr appendFormat:@"%@=%@", key , _param[key] ];
            if ( i<allKeys.count-1) {
                [paramStr appendString:@"&"];
            }
        }
        result =  [NSString stringWithString: paramStr ];
        

        // 檢查 url 是否已有 ? xx@gg
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

// 序列化
-(NSData*)serialize:(id)param
{
    if ( _requestSerializer ) {
        NSData* data = _requestSerializer( self, param );
        return data;
    }
    else{
        if( [param isKindOfClass:[NSString class]]){
            return [param dataUsingEncoding:NSUTF8StringEncoding];
        }
        if ( [param isKindOfClass:[NSData class]]) {
            return param;
        }
        else{
            NSException* exception = [NSException exceptionWithName:@"Parameter invalid" 
                                                             reason:@"parameter is not a NSString or you did not assign a serializer to parse param." userInfo:nil];
            @throw exception;
        }
    }
}

// 解序列化
-(id)unserialize:(NSData*)data
{
    // 如果有自訂的序列化程序，就執行，如果沒有就直接轉成字串
    if( _responseSerializer ) {
        id obj = _responseSerializer( self, data );
        return obj;
    }
    else{
        _result = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        if (_debug&&_result) {
            NSLog(@"receive:%@", _result );
        }
        return _result;
    }
}





@end
