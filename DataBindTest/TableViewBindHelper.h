//
//  TableViewBindHelper.h
//  DataBindTest
//
//  Created by GevinChen on 2015/9/26.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CKHTableViewCell.h"

//  原本第一個參數 cell 的型別是 CKHTableViewCell，改用 id 是因為
//  之後如果有自訂的 cell，你在寫 block 內容時，可以直接把 id 型別改成你
//  自訂的型別，這樣就不用在 block 內做一次轉型
typedef void(^CellConfigBlock)(id cell, NSIndexPath* index, id model, NSMutableDictionary* cellData );

@interface CKHObserverMutableArray : NSMutableArray
{
    NSMutableArray *_backArray;
}

@property (nonatomic) NSInteger section;
@property (nonatomic) id delegate;

-(instancetype)init;

@end

@protocol CKHObserverMutableArrayDelegate

// 新增
-(void)arrayAdd:(CKHObserverMutableArray*)array newObject:(id)object index:(NSIndexPath*)index;

// 刪除
-(void)arrayRemove:(CKHObserverMutableArray*)array removeObject:(id)object index:(NSIndexPath*)index;

// 插入
-(void)arrayInsert:(CKHObserverMutableArray*)array insertObject:(id)object index:(NSIndexPath*)index;

// 取代
-(void)arrayReplace:(CKHObserverMutableArray*)array newObject:(id)newObj replacedObject:(id)oldObj index:(NSIndexPath*)index;

@end


@protocol HelperEventDelegate <NSObject>

- (void)tableViewEvent:(const NSString*)event userInfo:(id)userInfo;

@end

@interface TableViewBindHelper : NSObject <UITableViewDelegate, UITableViewDataSource, CKHObserverMutableArrayDelegate >
{
    //
    NSMutableArray* _originArray;
    
    //    NSMutableArray* _identifiers;
    
    // 記錄 model 與 identifier 的對映
    NSMutableDictionary* _identifierMap;
    
    // 記錄 model 與 cell config block 的對映
    NSMutableDictionary* _configMap;
    
    // 記錄每個 cell 的狀態，因為 cell 是 reuse 的
    NSMutableArray* _cellStateDatas;
    
    // 記錄會用到的 nib instance，用來尋找 cell
    NSMutableArray* _nibs;
    
    // 監聽 helper 發出事件的監聽者，主要是聽取 cell 所發出的 ui event
    NSMutableArray* _listeners;
    
    // 記錄什麼 model 要用什麼 identifier 來找 cell
//    NSMutableDictionary* _modelDataMap;
    
}

@property (nonatomic) UITableView* tableView;

// 記錄 nib，之後指定的 identifier 會從這裡面去找
- (void)registerNib:(NSString*)nibName;

// 指定 model class 對映什麼 identifier
- (void)setIdentifier:(NSString*)identifier mappingModel:(Class)modelClass;

- (void)setIdentifier:(NSString*)identifier mappingModel:(Class)modelClass cellConfig:(CellConfigBlock)configBlock;

- (void)bindArray:(CKHObserverMutableArray*)array;

- (void)refresh:(id)model;

- (void)refreshAll;

- (void)addEventListener:(id)listener;

- (void)removeListener:(id)listener;

- (void)notify:(const NSString*)event userInfo:(id)userInfo;

@end
