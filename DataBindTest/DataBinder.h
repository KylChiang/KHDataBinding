//
//  DataBinder.h
//  DataBindTest
//
//  Created by GevinChen on 2015/8/30.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface DataBinder : NSObject
{
    id _model;
    
    id _target;
    
    // 皆以 model 的 property name 為 key
    NSMutableDictionary* _bindHandleDic;
    NSMutableDictionary* _bindPropertyNameDic;
}

// 宣告 ui property 的物件
-(void)setTarget:(id)target;

// 資料物件
-(void)setModel:(id)model;

// 綁定
-(void)bindData:(NSString*)keypath ui:(NSString*)uiKeyPath handle:(void(^)(id uiObject,id data))bindHandle;

-(void)deBind;


@end
