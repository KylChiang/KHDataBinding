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
        
    }
    return self;
}

// 宣告 ui property 的物件
-(void)setTarget:(id)target
{
    _target = target;
}

// 資料物件
-(void)setModel:(id)model
{
    NSArray* keys = [_bindHandleDic allKeys];
    for ( NSString* key in keys ) {
        [_model removeObserver:self forKeyPath: key ];
    }
    _model = model;
    
    for ( NSString* key in keys ) {
       [_model addObserver:self forKeyPath:key options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nil ];
    }
}

// 綁定
-(void)bindData:(NSString*)keypath ui:(NSString*)uiKeyPath handle:(void(^)(id uiObject,id data))bindHandle
{
    [_bindPropertyNameDic setObject:uiKeyPath forKey:keypath];
    if (bindHandle) {
        [_bindHandleDic setObject:bindHandle forKey:keypath];
    }
    [_model addObserver:self forKeyPath:keypath options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nil ];

}

// 觸發事件
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    
    // 看有沒有自訂的填入行為
    void(^bindHandle)(id uiObject,id data) = _bindHandleDic[keyPath];
    if (bindHandle) {
        NSString* uikeypath = _bindPropertyNameDic[ keyPath ];
        if ( uikeypath ) {
            bindHandle( [_target valueForKey: uikeypath ], change[ NSKeyValueChangeNewKey ] );
        }
    }
    else{
        NSString* uikeypath = _bindPropertyNameDic[ keyPath ];
        if ( uikeypath == nil ) return;
        // 預設的填入行為
        id ui = [_target valueForKey: uikeypath ];
        id value = change[ NSKeyValueChangeNewKey ];
        if ( [ui isKindOfClass:[UILabel class]] ) {
            UILabel *label = ui;
            if ( [value isKindOfClass:[NSString class]] ) {
                label.text = value;
            }
            else if( [value isKindOfClass:[NSNumber class] ]){
                label.text = [value stringValue];
            }
        }
        else if ( [ui isKindOfClass:[UITextField class]] && [value isKindOfClass:[NSString class]] ) {
            UITextField* textfield = ui;
            if ( [value isKindOfClass:[NSString class]] ) {
                textfield.text = value;
            }
            else if( [value isKindOfClass:[NSNumber class] ]){
                textfield.text = [value stringValue];
            }

        }
        else if ( [ui isKindOfClass:[UITextView class]] && [value isKindOfClass:[NSString class]] ) {
            UITextView* textview = ui;
            if ( [value isKindOfClass:[NSString class]] ) {
                textview.text = value;
            }
            else if( [value isKindOfClass:[NSNumber class] ]){
                textview.text = [value stringValue];
            }
        }
        else if ( [ui isKindOfClass:[UIButton class]]) {
            
        }
        else if ( [ui isKindOfClass:[UIImageView class]]) {
            
        }
        else if ( [ui isKindOfClass:[UISwitch class]]) {
            
        }
    }
    
}


@end
