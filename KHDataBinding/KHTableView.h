//
//  KHTableView.h
//  KHDataBindingDemo
//
//  Created by GevinChen on 2017/3/7.
//  Copyright © 2017年 omg. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KHCell.h"
#import "NSMutableArray+KHSwizzle.h"

@protocol KHTableViewDelegate <NSObject,UIScrollViewDelegate>

@optional

- (void)tableView:(KHTableView*_Nonnull)tableView didSelectRowAtIndexPath:(NSIndexPath  *_Nonnull )indexPath;

- (void)tableView:(KHTableView *_Nonnull)tableView willDisplayCell:(nonnull UITableViewCell *)cell forRowAtIndexPath:(nonnull NSIndexPath *)indexPath;


//  reuse cell 的時候，同 - (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
- (void)tableView:(KHTableView*_Nonnull)tableView newCell:(UITableViewCell* _Nonnull)cell model:(id _Nonnull)model indexPath:(NSIndexPath  *_Nonnull )indexPath;

//  下拉更新觸發
- (void)tableViewOnPulldown:(KHTableView*_Nonnull)tableView refreshControl:(UIRefreshControl *_Nonnull)refreshControl;

//  至底
- (void)tableViewOnEndReached:(KHTableView*_Nonnull)tableView;

@end

//-----------------------------------------------

@interface KHTableViewLoadingFooter : UITableViewHeaderFooterView

@property (nonatomic, strong) UIView * _Nullable indicatorView;

@end

//-----------------------------------------------

@interface UITableContainerCell : UITableViewCell

@property (nonatomic, strong) UIView * _Nullable nonReuseCustomView;

@end

//-----------------------------------------------

@interface KHTableView : UITableView <UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, KHArrayObserveDelegate>
{
    //  記錄全部的 section array
    NSMutableArray *_sections;
    
    //  記錄 model bind cell
    NSMutableDictionary *_cellClassDic;
    
    //  記錄 cell 預設的 size
    NSMutableDictionary *_cellDefaultSizeDic;
    
    //  記錄 cell - model 介接物件，linker 的數量會跟 model 一樣
    NSMutableDictionary *_pairDic;
    
    //
    NSMutableDictionary *_headerModelDic;
    NSMutableDictionary *_footerModelDic;
    
//    NSMutableDictionary *_headerViewDic;
//    NSMutableDictionary *_footerViewDic;
    
    //  key: reusableView class name / value: size Value
    //  key: section NSNumber / value: size NSValue
    NSMutableDictionary *_headerViewSizeDic;
    NSMutableDictionary *_footerViewSizeDic;
    
    //  執行動畫的 queue，它裡面固定是三個 mutable array，分別記錄欲執行 insert, remove, reload 動畫的 index
    //  最後會在 setNeedsRunAnimation 裡一次執行，以提高效率
    NSMutableArray *_item_animationQueue;
    NSMutableArray *_section_animationQueue;
    
    //  是否完成第一次載入
    BOOL _firstReload;
    
    //  需要執行 reload
    BOOL _needReload;
    
    //  是否第一次完成載入 header footer
    BOOL _firstLoadHeaderFooter;
    
    //  標記需要執行動畫
    __block BOOL needUpdate;
    
    //  記錄監聽了哪些種類的 cell 上的 ui 的事件，
    NSMutableArray<KHEventHandleData*> *_eventDatas;
    
    //  媽逼，ios 10 突然加了這個屬性，早不加晚不加的，所以會跟我原本寫的衝突
    UIRefreshControl *_refreshControl;

    //  refresh
    NSAttributedString *_refreshTitle;
    
    //  是否正在執行 OnEndReached 的 callback
    BOOL _hasCalledOnEndReached;
    
    //  constraint height for auto adjust height, for auto expand height
    NSLayoutConstraint *constraintHeight;
    
    //  constraint height is exist, for auto expand height
    BOOL isExist;
}

//  下拉更新啟用
@property (nonatomic) BOOL enabledPulldownRefresh;
@property (nonnull,nonatomic,strong) NSAttributedString *refreshTitle;

//  拉至底，自動載入
@property (nonatomic) BOOL enabledLoadingMore;
@property (nonatomic) CGFloat onEndReachedThresHold;
@property (nullable,nonatomic,strong) UIView *loadingIndicator;   
@property (nonatomic) BOOL isNeedAnimation;
@property (nullable,nonatomic,weak) id<KHTableViewDelegate> kh_delegate;
@property (nonatomic) BOOL autoExpandHeight; // 自動調整高，以顯示全部cell

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

@property (nonatomic) NSString * _Nullable viewName;

#pragma mark - Refresh

- (void)endRefreshing;

- (UIRefreshControl* _Nonnull)refreshControl;

#pragma mark - Bind Array

- (NSMutableArray *_Nonnull)createSection;

- (NSMutableArray *_Nullable)getSection:(NSInteger)section;

- (void)addSection:(NSMutableArray *_Nonnull)array;

- (void)removeSection:(NSMutableArray *_Nonnull)array;

- (void)removeSectionAt:(NSInteger)section;

- (NSUInteger)sectionCount;


#pragma mark - Data Model

- (NSIndexPath *_Nullable)indexPathForModel:(id _Nonnull)model;

- (UITableViewCell *_Nullable)cellForModel:(id _Nonnull)model;

- (id _Nullable)modelForCell:(UITableViewCell *_Nonnull)cell;

- (id _Nullable)modelForIndexPath:(NSIndexPath*_Nonnull)indexPath;

#pragma mark - Lookup back

//  透過某個 responder UI，取得 cell
- (nullable UITableViewCell*)cellForUI:(UIControl *_Nonnull)uiControl;

//  透過某個 responder UI，取得 model
- (nullable id)modelForUI:(UIControl *_Nonnull)uiControl;

#pragma mark - Config Model Cell Mapping

//  設定對映
- (void)setMappingModel:(Class _Nonnull)modelClass cell:(Class _Nonnull)cellClass;

//  設定對映，使用 block 處理
- (void)setMappingModel:(Class _Nonnull)modelClass block:(Class _Nullable(^ _Nonnull)(id _Nonnull model, NSIndexPath *_Nonnull index))mappingBlock;

//  取得對映的 cell name
- (NSString *_Nullable)getMappingCellFor:(id _Nonnull)model index:(NSIndexPath *_Nullable)index;

#pragma mark - Cell Size

- (CGSize)getCellSizeFor:(id _Nonnull)model;

- (void)setCellSize:(CGSize)cellSize model:(id _Nonnull)model;

- (void)setCellSize:(CGSize)cellSize models:(NSArray *_Nonnull)models;

- (void)setCellDefaultSize:(CGSize)cellSize class:(Class _Nonnull)cellClass;

- (CGSize)getCellDefaultSizeFor:(Class _Nonnull)cellClass;

#pragma mark - Header / Footer

// 直接給予 header array , models 預設接受 NSString or UIView
- (void)setHeaderModels:(NSArray *_Nonnull)models;

- (void)setFooterModels:(NSArray *_Nonnull)models;

// model 必須是 UIView 或是 NSString
- (void)setHeaderModel:(id _Nonnull)model at:(NSInteger)section;

- (void)setFooterModel:(id _Nonnull)model at:(NSInteger)section;

- (id _Nullable)modelForHeaderAt:(NSInteger)section;

- (id _Nullable)modelForFooterAt:(NSInteger)section;

// model 必須是 UIView 或是 NSString，回傳 -1 表示找不到
- (NSInteger)sectionForHeaderModel:(id _Nonnull)model;

- (NSInteger)sectionForFooterModel:(id _Nonnull)model;

- (NSInteger)sectionForHeaderUI:(id _Nonnull)ui;

- (NSInteger)sectionForFooterUI:(id _Nonnull)ui;

#pragma mark - Header / Footer Height

- (void)setHeightForHeader:(CGFloat)height at:(NSInteger)section;

- (void)setHeightForFooter:(CGFloat)height at:(NSInteger)section;

- (CGFloat)heightForHeaderAt:(NSInteger)section;

- (CGFloat)heightForFooterAt:(NSInteger)section;


#pragma mark - UI Event Handle

// 指定要監聽某個 cell 上的某個 ui，這邊要注意，你要監聽的 UIResponder 一定要設定為一個 property，那到時觸發事件後，你想要知道是屬於哪個 cell 或哪個 model，再另外反查
- (void)addTarget:(nullable id)target action:(nonnull SEL)action forControlEvents:(UIControlEvents)event onCell:(nonnull Class)cellClass propertyName:(nonnull NSString*)property;
- (void)addTarget:(nullable id)target action:(nonnull SEL)action forControlEvents:(UIControlEvents)event onCell:(nonnull Class)cellClass propertyNames:(nonnull NSArray<NSString*>*)properties;

- (void)removeTarget:(nullable id)target action:(nonnull SEL)action forControlEvents:(UIControlEvents)event onCell:(nonnull Class)cellClass propertyName:(nonnull NSString*)property;
- (void)removeTarget:(nullable id)target action:(nonnull SEL)action forControlEvents:(UIControlEvents)event onCell:(nonnull Class)cellClass;

- (void)removeAllTarget;


@end
