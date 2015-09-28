//
//  DataBinder.m
//  DataBindTest
//
//  Created by GevinChen on 2015/8/30.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import "DataBinder.h"

@implementation DataBinder

- (instancetype)init
{
    self = [super init];
    if (self) {
        _bindHandleDic = [NSMutableDictionary dictionary];
        _bindPropertyNameDic = [NSMutableDictionary dictionary];
        _contextDic = [NSMutableDictionary dictionary];
    }
    return self;
}

-(instancetype)initWithTarget:(id)target model:(id)model
{
    self = [super init];
    if (self) {
        
        self.target = target;
        self.model = model;
        _bindHandleDic = [NSMutableDictionary dictionary];
        _bindPropertyNameDic = [NSMutableDictionary dictionary];
        _contextDic = [NSMutableDictionary dictionary];
    }
    return self;
}

// 宣告 ui property 的物件
-(void)setTarget:(id)target
{
    _target = target;
    
    if ( _model ) {
        // trigger update manually
        [self deBind];
        [self binding];
    }
}

// 資料物件
-(void)setModel:(id)model
{
    [self deBind];
    
    _model = model;
    
    [self binding];
}

// 綁定
-(void)bindModelKeyPath:(NSString*)keypath uiKeyPath:(NSString*)uiKeyPath handle:(id(^)(id data))bindHandle
{
    [_bindPropertyNameDic setObject:uiKeyPath forKey:keypath];
    if (bindHandle) {
        [_bindHandleDic setObject:bindHandle forKey:keypath];
    }
    [_model addObserver:self forKeyPath:keypath options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:&_contextDic ];
}

// 移除監聽
- (void)deBind
{
    NSArray* keys = [_bindPropertyNameDic allKeys];
    for ( NSString* key in keys ) {
        [_model removeObserver:self forKeyPath: key ];
    }
}

// 監聽
- (void)binding
{
    NSArray* keys = [_bindPropertyNameDic allKeys];
    for ( NSString* key in keys ) {
        [_model addObserver:self forKeyPath:key options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nil ];
    }
}

// 觸發事件
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ( object == _model ) {
        // 看有沒有自訂的填入行為
        id(^bindHandle)(id data) = _bindHandleDic[keyPath];
        NSString* uikeypath = _bindPropertyNameDic[ keyPath ];
        NSString* uikeypath1 = _contextDic[keyPath];
        
        // 若 _contextDic 有相同的值，就表示是從 ui 所觸發的更新，這時候就不用再把值回傳給 ui 了
        if ( uikeypath1 != nil && [uikeypath isEqualToString:uikeypath1] ) {
            [_contextDic removeObjectForKey:keyPath];
            return;
        }

        if (bindHandle) {
            if ( uikeypath ) {
                NSLog(@"model %@ assign %@ to target %@", keyPath, bindHandle( change[ NSKeyValueChangeNewKey ] ), uikeypath );
                [_target setValue: bindHandle( change[ NSKeyValueChangeNewKey ] ) forKeyPath: uikeypath ];
            }
        }
        else{
            NSLog(@"model %@ assign %@ to target %@", keyPath, change[ NSKeyValueChangeNewKey ], uikeypath );
            [_target setValue: change[ NSKeyValueChangeNewKey ] forKeyPath: uikeypath ];
        }
    }
}

-(void)updateModelKeyPath:(NSString*)keypath value:(id)value
{
    NSString* uikeypath = _bindPropertyNameDic[ keypath ];
    // 記錄哪個 ui property 做更新
    [_contextDic setObject:uikeypath forKey:keypath];
//    // 更新 model
//    id value = [_target valueForKey:uikeypath];
    [_model setValue:value forKey:keypath];
}

@end
