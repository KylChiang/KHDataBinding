//
//  KHDataBinder.h
//
//  Created by GevinChen on 2015/9/26.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "KVCModel.h"
#import "KHCell.h"
#import "NSMutableArray+KHSwizzle.h"
#import "KHImageDownloader.h"

/**
  * Data binding
  * 使用上有三個角色
  * Data Model : 純粹資料物件
  * PairInfo : cell 的介接物件，可以當作是 cell 的代理人，因為 cell 是 reuse，所以一些設定資料不能放在 cell，因此會放在 PairInfo
  * UITableViewCell or UICollectionViewCell
 *
 *
 */
#define weakRef( var ) __weak typeof(var) weak_##var = var
@class KHDataBinding;

@protocol KHDataBindingDelegate

@optional
- (void)tableView:( UITableView *_Nonnull)tableView didSelectRowAtIndexPath:(NSIndexPath  *_Nonnull )indexPath;
- (void)collectionView:(UICollectionView*_Nonnull)collectionView didSelectItemAtIndexPath:( NSIndexPath  *_Nonnull)indexPath;

//- (void)onLoadCell:(id _Nonnull)cell model:(id _Nonnull)model;

- (void)bindingView:(id _Nonnull)bindingView didSelectItemAtIndexPath:(NSIndexPath *_Nonnull)indexPath;
- (void)bindingViewRefreshHead:(id _Nonnull)bindingView;
//- (void)bindingViewRefreshFoot:(id _Nonnull)bindingView;
- (void)onEndReached:(KHDataBinding  *_Nonnull)dataBinding;


@end


@interface KHDataBinding : NSObject < KHArrayObserveDelegate >
{
    //  記錄 CKHObserverArray
    NSMutableArray *_sectionArray;
    
    //  記錄 cell - model 介接物件，linker 的數量會跟 model 一樣
    NSMutableDictionary *_pairDic;
    
    //  記錄 model bind cell
    NSMutableDictionary *_cellClassDic;
    
    //  KHCellEventHandleData 的 array
    NSMutableArray *_cellUIEventHandlers;
    
    //  refresh
    UIScrollView *refreshScrollView;
    NSAttributedString *refreshTitle;
    NSAttributedString *refreshLastUpdate;
    NSInteger refreshState;

    
}
// pull down to refresh
@property (nonatomic,copy,nullable) NSString *headTitle;
@property (nonatomic,copy,nullable) NSString *footTitle __deprecated;

@property (nonnull,nonatomic,readonly) UIRefreshControl *refreshHeadControl;
@property (nonnull,nonatomic,readonly) UIRefreshControl *refreshFootControl __deprecated;
@property (nullable,nonatomic,strong) UIView *loadingIndicator;
@property (nonatomic) BOOL refreshHeadEnabled;
@property (nonatomic) BOOL refreshFootEnabled __deprecated;
@property (nonatomic) BOOL isLoading;
@property (nonatomic) BOOL isNeedAnimation;
@property (nonatomic) CGFloat onEndReachedThresHold;
@property (nonatomic) NSTimeInterval lastUpdate;

@property (nullable,nonatomic,weak) id delegate;

- (nonnull instancetype)initWithView:(UIView *_Nonnull)view delegate:(id _Nullable)delegate registerClass:(NSArray<Class> *_Nullable)cellClasses;

#pragma mark - UIRefreshControl

- (void)endRefreshing;


#pragma mark - Bind Array

//  生成一個已綁定的 array
- (nonnull NSMutableArray*)createBindArray;

//  生成一個已綁定的 array，並且把資料填入
- (nonnull NSMutableArray*)createBindArrayFromNSArray:(NSArray*_Nullable)array;

//  綁定一個 array
- (void)bindArray:(NSMutableArray*_Nonnull)array;

//  解綁定一個array
- (void)deBindArray:(NSMutableArray *_Nonnull)array;

//  取得一個已綁定的 array
- (nullable NSMutableArray*)getArray:(NSInteger)section;

//  取得有幾個 section (array)
- (NSInteger)sectionCount;

//  override by subclass，把 cell 註冊至 tableView 或 collectionView
- (void)registerCell:(NSString *_Nonnull)cellName;

//  設定對映
- (void)setMappingModel:(Class _Nonnull)modelClass :(Class _Nonnull)cellClass;

//  設定對映，使用 block 處理
- (void)setMappingModel:(Class _Nonnull)modelClass block:( Class _Nullable(^ _Nonnull)(id _Nonnull model, NSIndexPath *_Nonnull index))mappingBlock;

//  用  model 來找對應的 cell class
- (nullable NSString*)getMappingCellNameWith:(nonnull id)model index:(NSIndexPath *_Nullable)index;

//  取得某個 model 的配對物件
- (nullable KHPairInfo*)getPairInfo:(nonnull id)model;

//  透過 model 取得 cell
- (nullable id)getCellByModel:(id _Nonnull)model;

//  透過 cell 取得 data model
- (nullable id)getModelWithCell:(id _Nonnull)cell;

//  取得某 model 的 index
- (nullable NSIndexPath*)indexPathOfModel:(id _Nonnull)model;

//  取得某 cell 的 index
- (nullable NSIndexPath*)indexPathOfCell:(id _Nonnull)cell;

//  更新 model
- (void)updateModel:(id _Nonnull)model;

//  重載 // override by subclass
- (void)reloadData;

//  監聽 model 的資料變動，即時更新 cell
- (void)enabledObserve:(BOOL)enable model:(id _Nonnull)model;



#pragma mark - UIControl Handle

//  設定當 cell 裡的 ui control 被按下發出事件時，觸發的 method
//  UI Event  SEL 跟原本的不同，要求要 :(id)sender :(id)model
- (void)addEvent:(UIControlEvents)event cell:(Class _Nonnull)cellClass propertyName:(NSString *_Nonnull)pname handler:(void(^_Nonnull)(id _Nonnull sender, id _Nonnull model))eventHandleBlock;

//
- (void)removeEvent:(UIControlEvents)event cell:(Class _Nonnull)cellClass propertyName:(NSString *_Nonnull)pName;

@end

@interface KHTableDataBinding : KHDataBinding <UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate>
{
    /*
     是否已執行第一次的reload，主要用來辨別是否執行單一cell 的 udpate animation，因為未 reload 前 tableView 沒有資料，執行 animation 會 exception 
     */
    BOOL _firstReload;
    
    NSMutableArray *_headerTitles;

    NSMutableArray *_headerViews;
    
    NSMutableArray *_footerTitles;
    
    NSMutableArray *_footerViews;
    
}

@property (nullable,nonatomic) UITableView *tableView;

//  header
@property (nullable,nonatomic) UIColor *headerBgColor;
@property (nullable,nonatomic) UIColor *headerTextColor;
@property (nullable,nonatomic) UIFont  *headerFont;
@property (nonatomic) float    headerHeight;

//  footer
@property (nullable,nonatomic) UIColor *footerBgColor;
@property (nullable,nonatomic) UIColor *footerTextColor;
@property (nullable,nonatomic) UIFont  *footerFont;
@property (nonatomic) float    footerHeight;


//- (nonnull instancetype)initWithTableView:(nonnull UITableView*)tableView delegate:(nullable id)delegate registerClass:(nullable NSArray<Class>*)cellClasses;

//  table view cell height
- (float)getCellHeightWithModel:(id _Nonnull)model;
- (void)setCellHeight:(float)cellHeight model:(id _Nonnull)model;
- (void)setCellHeight:(float)cellHeight models:(NSArray *_Nonnull)models;

- (void)setDefaultCellHeight:(CGFloat)cellHeight forModelClass:(Class _Nonnull)modalClass;

//  設定 header title
- (void)setHeaderTitle:(NSString  *_Nonnull)headerTitle atSection:(NSUInteger)section;

//  設定 header view
- (void)setHeaderView:(UIView *_Nonnull)view atSection:(NSUInteger)section;
- (void)setHeaderTitles:(NSArray *_Nonnull)titles;
- (void)setHeaderViews:(NSArray *_Nonnull)views;

//  設定 footer title
- (void)setFooterTitle:(NSString  *_Nonnull)footerTitle atSection:(NSUInteger)section;

//  設定 footer view
- (void)setFooterView:( UIView *_Nonnull)view atSection:(NSUInteger)section;
- (void)setFooterTitles:(NSArray *_Nonnull)titles;
- (void)setFooterViews:(NSArray *_Nonnull)views;

//  透過某個 responder UI，取得 cell
- (nullable UITableViewCell*)getCellOf:(UIView *_Nonnull)responderUI;

//  透過某個 responder UI，取得 model  
- (nullable id)getModelOf:(UIView *_Nonnull)responderUI;

/*
 Gevin note :
 原本打算讓 table view binder 可以設定預設的 cell height accessoryType 之類的屬性值
 但是想到說，一個 table 裡可能會有兩種以上的 cell ，所以預設值其實不實用
 
 另外想到一點就是，最原本用 delegate 來定義 cell 的寫法，其實應該也是在那個 delegate 裡去設定
 dequeue 的 cell 的屬性值
 相對於我的寫法，就是把那一段移到 onload 裡
 但是 cell height 的問題比較大，因為 cell height 會在 onload 之前先執行
 
 */

@end



@interface KHCollectionDataBinding : KHDataBinding <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate>
{

    /*
     是否已執行第一次的reload，主要用來辨別是否執行單一cell 的 udpate animation，因為未 reload 前 tableView 沒有資料，執行 animation 會 exception
     */
    BOOL _firstReload;
    
    NSMutableArray *_headerModelList;
    
    NSMutableArray *_footerModelList;
    
    //  key: mapping model class name / value: reusableView class
    NSMutableDictionary *_reusableViewDic;
    
    //  key: reusableView class name / value: size Value
    NSMutableDictionary *_reusableViewSizeDic;
    
    UICollectionViewCell *_prototype_cell;
}

@property (nonnull,nonatomic) UICollectionView *collectionView;
@property (nullable,nonatomic) UICollectionViewFlowLayout *layout;

//- (nonnull instancetype)initWithCollectionView:(nonnull UICollectionView*)collectionView delegate:(nullable id)delegate registerClass:(nullable NSArray<Class>*)cellClasses;

- (CGSize)getCellSizeWithModel:(id _Nonnull)model;
- (void)setCellSize:(CGSize)cellSize model:(id _Nonnull)model;
- (void)setCellSize:(CGSize)cellSize models:(NSArray *_Nonnull)models;

- (void)setDefaultCellSize:(CGSize)cellSize forModelClass:(Class _Nonnull)modelClass;

- (void)registerReusableView:(Class _Nonnull)reusableViewClass;
- (void)registerReusableView:(Class _Nonnull)reusableViewClass size:(CGSize)size;
- (void)setReusableView:(Class _Nonnull)reusableViewClass size:(CGSize)size;
- (CGSize)getReusableViewSize:(Class _Nonnull)reusableViewClass;

- (void)setHeaderModel:(id _Nonnull)headerModel atIndex:(NSInteger)sectionIndex;
- (void)setHeaderModels:(NSArray *_Nonnull)headerModels;

- (void)setFooterModel:(id _Nonnull)headerModel atIndex:(NSInteger)sectionIndex;
- (void)setFooterModels:(NSArray *_Nonnull)headerModels;

//  透過某個 responder UI，取得 cell
- (nullable UICollectionViewCell*)getCellOf:(UIView *_Nonnull)responderUI;

//  透過某個 responder UI，取得 model  
- (nullable id)getModelOf:(UIView *_Nonnull)responderUI;

@end

