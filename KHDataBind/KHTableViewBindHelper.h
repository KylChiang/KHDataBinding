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

@interface KHObservableArray : NSMutableArray
{
    NSMutableArray *_backArray;
}

@property (nonatomic) NSInteger section;
@property (nonatomic) id delegate;

-(instancetype)init;

-(instancetype)initWithArray:(NSArray *)array;

-(void)update:(id)object;

@end

@protocol KHObserveArrayDelegate

// 新增
-(void)arrayAdd:(KHObservableArray*)array newObject:(id)object index:(NSIndexPath*)index;

// 新增多項
-(void)arrayAdd:(KHObservableArray*)array newObjects:(NSArray*)objects indexs:(NSArray*)indexs;

// 刪除
-(void)arrayRemove:(KHObservableArray*)array removeObject:(id)object index:(NSIndexPath*)index;

// 刪除全部
-(void)arrayRemoveAll:(KHObservableArray*)array;

// 插入
-(void)arrayInsert:(KHObservableArray*)array insertObject:(id)object index:(NSIndexPath*)index;

// 取代
-(void)arrayReplace:(KHObservableArray*)array newObject:(id)newObj replacedObject:(id)oldObj index:(NSIndexPath*)index;

// 更新
-(void)arrayUpdate:(KHObservableArray*)array update:(id)object index:(NSIndexPath*)index;

@end


@protocol HelperEventDelegate <NSObject>

- (void)tableViewEvent:(const NSString*)event userInfo:(id)userInfo;

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
    
}

@property (nonatomic) UITableView* tableView;

// 順便把 model 與 identifier 的 mapping 傳入
- (void)bindArray:(KHObservableArray*)array;

- (void)reloadData:(KHCellModel*)model;

- (void)reloadAll;

- (void)addEventListener:(id)listener;

- (void)removeListener:(id)listener;

- (void)notify:(const NSString*)event userInfo:(id)userInfo;

//  設定點到 cell 後要做什麼處理
- (void)setCellSelectedHandle:(id)target action:(SEL)action;

@end
