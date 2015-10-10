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
#import "CKHTableViewCell.h"

@interface CKHObserveableArray : NSMutableArray
{
    NSMutableArray *_backArray;
}

@property (nonatomic) NSInteger section;
@property (nonatomic) id delegate;

-(instancetype)init;

-(instancetype)initWithArray:(NSArray *)array;

-(void)update:(id)object;

@end

@protocol CKHObserverMutableArrayDelegate

// 新增
-(void)arrayAdd:(CKHObserveableArray*)array newObject:(id)object index:(NSIndexPath*)index;

// 新增多項
-(void)arrayAdd:(CKHObserveableArray*)array newObjects:(NSArray*)objects indexs:(NSArray*)indexs;

// 刪除
-(void)arrayRemove:(CKHObserveableArray*)array removeObject:(id)object index:(NSIndexPath*)index;

// 刪除全部
-(void)arrayRemoveAll:(CKHObserveableArray*)array;

// 插入
-(void)arrayInsert:(CKHObserveableArray*)array insertObject:(id)object index:(NSIndexPath*)index;

// 取代
-(void)arrayReplace:(CKHObserveableArray*)array newObject:(id)newObj replacedObject:(id)oldObj index:(NSIndexPath*)index;

// 更新
-(void)arrayUpdate:(CKHObserveableArray*)array update:(id)object index:(NSIndexPath*)index;

@end


@protocol HelperEventDelegate <NSObject>

- (void)tableViewEvent:(const NSString*)event userInfo:(id)userInfo;

@end

@interface TableViewBindHelper : NSObject <UITableViewDelegate, UITableViewDataSource, CKHObserverMutableArrayDelegate >
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
- (void)bindArray:(CKHObserveableArray*)array;

- (void)reloadData:(CKHCellModel*)model;

- (void)reloadAll;

- (void)addEventListener:(id)listener;

- (void)removeListener:(id)listener;

- (void)notify:(const NSString*)event userInfo:(id)userInfo;

//  設定點到 cell 後要做什麼處理
- (void)setCellSelectedHandle:(id)target action:(SEL)action;

@end
