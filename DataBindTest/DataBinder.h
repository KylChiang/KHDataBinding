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
    // 皆以 model 的 property name 為 key， ui keypath 為 value
    NSMutableDictionary* _bindHandleDic;
    NSMutableDictionary* _bindPropertyNameDic;
    NSMutableDictionary* _contextDic;
}

// target 可以是 controller 或是一個 custom view，就是擁有一堆 UI property 的物件
@property (nonatomic) id target;
@property (nonatomic) id model;

-(instancetype)initWithTarget:(id)target model:(id)model;

// 綁定
-(void)bindModelKeyPath:(NSString*)keypath uiKeyPath:(NSString*)uiKeyPath handle:(id(^)(id data))bindHandle;

//
-(void)deBind;

//  指定 model 的 keypath，然後塞 value 進去
//  目前遇到一個狀況，假設有一個 UISwitch 的 property 叫 isFemale
//  那用 'isFemale.on' 塞值給 UISwitch ok，但是用 'isFemale.on'
//  來取值 [target valueForKey:@"isFemale.on"] 會 crash
//  所以改成值是外部自行取出再傳入
//  另一方面也是說，取出的值，也許要做什麼特別的處理
-(void)updateModelKeyPath:(NSString*)keypath value:(id)value;

@end
