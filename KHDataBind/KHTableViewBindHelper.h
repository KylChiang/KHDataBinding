//
//  TableViewBindHelper.h
//  DataBindTest
//
//  Created by GevinChen on 2015/9/26.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "KVCModel.h"
#import "KHTableViewCell.h"
#import "UIControl+CellInfo.h"

@class KHObservableArray;

@protocol KHObserveArrayDelegate

// 新增
-(void)arrayAdd:( nonnull KHObservableArray*)array newObject:( nonnull id)object index:( nonnull NSIndexPath*)index;

// 新增多項
-(void)arrayAdd:( nonnull KHObservableArray*)array newObjects:( nonnull NSArray*)objects indexs:( nonnull NSArray*)indexs;

// 刪除
-(void)arrayRemove:( nonnull KHObservableArray*)array removeObject:( nonnull id)object index:( nonnull NSIndexPath*)index;

// 刪除全部
-(void)arrayRemoveAll:( nonnull KHObservableArray*)array;

// 插入
-(void)arrayInsert:( nonnull KHObservableArray*)array insertObject:( nonnull id)object index:( nonnull NSIndexPath*)index;

// 取代
-(void)arrayReplace:( nonnull KHObservableArray*)array newObject:( nonnull id)newObj replacedObject:( nonnull id)oldObj index:( nonnull NSIndexPath*)index;

// 更新
-(void)arrayUpdate:( nonnull KHObservableArray*)array update:( nonnull id)object index:( nonnull NSIndexPath*)index;

// 更新全部
-(void)arrayUpdateAll:( nonnull KHObservableArray*)array;

@end


@interface KHObservableArray : NSMutableArray
{
    NSMutableArray *_backArray;
}

@property (nonatomic) NSInteger section;
@property (nonatomic,nullable) id delegate;

-( nonnull instancetype)init;

-( nonnull instancetype)initWithArray:( nullable NSArray *)array;

-(void)update:( nonnull id )object;

-(void)updateAll;

@end


@protocol HelperEventDelegate <NSObject>

- (void)tableViewEvent:(nonnull const NSString*)event userInfo:( nullable id)userInfo;

@end

@interface KHTableViewBindHelper : NSObject <UITableViewDelegate, UITableViewDataSource, KHObserveArrayDelegate >
{
    //  記錄 CKHObserverArray
    NSMutableArray *_sectionArray;
    
    //  監聽 helper 發出事件的監聽者，主要是聽取 cell 所發出的 ui event
    NSMutableArray* _listeners;
    
    id _target;
    
    SEL _action;
    
    NSInvocation *invocation;
    
    //
    NSMutableDictionary *_eventTarget;
    
    //  
    NSMutableDictionary *_uicontrolDic;
    
}

@property (nonatomic,nonnull) UITableView* tableView;

- (nonnull KHObservableArray*)createBindArray;

- (nonnull KHObservableArray*)createBindArrayFromNSArray:(nullable NSArray*)array;

// 順便把 model 與 identifier 的 mapping 傳入
- (void)bindArray:(nonnull KHObservableArray*)array;

- (void)addEventListener:(nonnull id)listener;

- (void)removeListener:(nonnull id)listener;

- (void)notify:(nonnull const NSString*)event userInfo:(nullable id)userInfo;

//  設定點到 cell 後要做什麼處理
- (void)setCellSelectedHandle:(nonnull id)target action:(nonnull SEL)action;

//  設定當 cell 裡的 ui control 被按下發出事件時，觸發的 method
//  UI Event  SEL 跟原本的不同，要求要 :(id)sender :(id)model
- (void)addTarget:(nonnull id)target action:(nonnull SEL)action event:(UIControlEvents)event;

//
- (void)removeTarget:(nonnull id)target action:(nullable SEL)action;

//
- (void)removeTarget:(nonnull id)target;

//
- (nullable id)getTargetByAction:(nonnull SEL)action;

//  設定需要監聽的 ui control 及事件
- (void)responseUIControl:(nonnull UIControl*)control event:(UIControlEvents)event cell:(nonnull KHTableViewCell*)cell;


@end

