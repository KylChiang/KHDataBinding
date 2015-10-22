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
    
    // 處理 cell 被按到時候呼叫，會固定呼叫  tableView:didSelectedRowAtIndexPath:
    NSInvocation *invocation;
    
    //  因為有很多個 cell ，且是 reuse 的
    //  所以把每個 cell 裡的 ui control 轉為用一個 key 代替
    //  在 controller 的時候，就對那個 key 做觸發事件的指定
    
    //  記錄每個 ui tag 的 invocation，結構是 tag / NSMutableDictionary，作為 value 的 dictionary
    //  key 是 event / value 是 NSInvocation
    NSMutableDictionary *_invocationDic;
    
    //  
    NSMutableDictionary *_uiDic;
    
    
    NSArray *_titles;
}

@property (nonatomic) UITableView* tableView;

- (nonnull instancetype)initWithTableView:(nonnull UITableView*)tableView;

- (nonnull KHObservableArray*)createBindArray;

- (nonnull KHObservableArray*)createBindArrayFromNSArray:(nullable NSArray*)array;

- (void)setHeaderTitles:(nullable NSArray*)titles;

// 順便把 model 與 identifier 的 mapping 傳入
- (void)bindArray:(nonnull KHObservableArray*)array;

- (nullable KHObservableArray*)getArray:(NSInteger)section;

//-------------------------------------------------

- (void)addEventListener:(nonnull id)listener;

- (void)removeListener:(nonnull id)listener;

- (void)notify:(nonnull const NSString*)event userInfo:(nullable id)userInfo;

//-------------------------------------------------

//  設定點到 cell 後要做什麼處理
//  固定呼叫原本 UITableViewDelegate 裡的
//  - (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//  所以如果想要處理按到後的事情，請實作上面這個 method
- (void)setCellSelectedHandler:(nonnull id)target;

//-------------------------------------------------

//  記錄要監聽的 ui
- (void)tagUIControl:(nonnull UIControl*)control tag:(nonnull NSString*)tag;

//  設定當 cell 裡的 ui control 被按下發出事件時，觸發的 method
//  UI Event  SEL 跟原本的不同，要求要 :(id)sender :(id)model
- (void)addTarget:(nonnull id)target action:(nonnull SEL)action event:(UIControlEvents)event forTag:(nonnull NSString*)tag;

//
- (void)removeTarget:(nonnull id)target action:(nullable SEL)action forTag:(nonnull NSString*)tag;

//
- (void)removeTarget:(nonnull id)target forTag:(nonnull NSString*)tag;

//
- (nullable id)getTargetByAction:(nonnull SEL)action forTag:(nonnull NSString*)tag;;


@end

