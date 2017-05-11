//
//  KHCollectionView.h
//  KHDataBindingDemo
//
//  Created by GevinChen on 2017/3/2.
//  Copyright © 2017年 omg. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KHCell.h"
#import "NSMutableArray+KHSwizzle.h"


@protocol KHCollectionViewDelegate <NSObject,UIScrollViewDelegate>

@optional
- (void)collectionView:(KHCollectionView*_Nonnull)collectionView didSelectItemAtIndexPath:( NSIndexPath  *_Nonnull)indexPath;

//  cell 建立的時候
- (void)collectionView:(KHCollectionView *_Nonnull)collectionView newCell:(UICollectionViewCell* _Nonnull)cell model:(id _Nonnull)model indexPath:(NSIndexPath  *_Nonnull )indexPath;

//  reuse header footer 建立的時候
- (void)collectionView:(KHCollectionView *_Nonnull)collectionView newHeader:(UICollectionReusableView* _Nonnull)header model:(id _Nonnull)model indexPath:(NSIndexPath  *_Nonnull )indexPath;
- (void)collectionView:(KHCollectionView *_Nonnull)collectionView newFooter:(UICollectionReusableView* _Nonnull)header model:(id _Nonnull)model indexPath:(NSIndexPath  *_Nonnull )indexPath;


//  下拉更新觸發
- (void)collectionViewOnPulldown:(KHCollectionView*_Nonnull)collectionView refreshControl:(UIRefreshControl *_Nonnull)refreshControl;

//  至底
- (void)collectionViewOnEndReached:(KHCollectionView*_Nonnull)collectionView;

@end

//-------------------------------------------

@interface KHCollectionViewLoadingFooter : UICollectionReusableView

@property (nonatomic, strong) UIView * _Nullable indicatorView;

@end

//-------------------------------------------

@interface KHContainerReusableView : UICollectionReusableView

@property (nonatomic, strong) UIView * _Nullable contentView; 

@end


//-------------------------------------------


@interface UICollectionContainerCell : UICollectionViewCell

@property (nonatomic, strong) UIView * _Nullable nonReuseCustomView;

@end


//-------------------------------------------

@interface KHCollectionView : UICollectionView <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate, KHArrayObserveDelegate>
{
    //  記錄全部的 section array
    NSMutableArray *_sections;
    
    //  記錄 model bind cell
    NSMutableDictionary *_cellClassDic;
    
    //  記錄 cell 預設的 size
    NSMutableDictionary *_cellDefaultSizeDic;
    
    //  記錄 cell - model 介接物件，linker 的數量會跟 model 一樣
    NSMutableDictionary *_pairDic;
    
    //  記錄監聽了哪些種類的 cell 上的 ui 的事件，
    NSMutableArray<KHEventHandleData*> *_eventDatas;

    //  key: NSValue of section array pointer / value: model
    NSMutableDictionary *_headerModelDic;
    NSMutableDictionary *_footerModelDic;

    //  key: mapping model class name / value: reusableView class
    NSMutableDictionary *_reusableViewDic;
    
    //  key: reusableView class name / value: size Value
    NSMutableDictionary *_reusableViewSizeDic;
    
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
    
    //  是否顯示 loading more 的 indicator
    BOOL _showLoadingMore;
    
    //  標記需要執行動畫
    __block BOOL needUpdate;
    
    //  用來計算 cell 的初始 size，因為取得 size 的 delegate 會比 cellForItem 先執行
    UICollectionViewCell *_prototype_cell;
    
    //  媽逼，ios 10 突然加了這個屬性，早不加晚不加的，所以會跟我原本寫的衝突
    UIRefreshControl *_refreshControl;

    //  refresh
    NSAttributedString *_refreshTitle;
    
    //  是否正在執行 OnEndReached 的 callback
//    BOOL _hasCalledOnEndReached;
    
    //  constraint height for auto adjust height
    NSLayoutConstraint *constraintHeight;
    
    //  constraint height is exist
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
@property (nullable,nonatomic,weak) id<KHCollectionViewDelegate> kh_delegate;
@property (nonatomic) BOOL autoExpandHeight; // 自動調整高，以顯示全部cell
@property (nonatomic) NSString * _Nullable viewName;
@property (nonatomic) BOOL debug;

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

- (UICollectionViewCell *_Nullable)cellForModel:(id _Nonnull)model;

- (id _Nullable)modelForCell:(UICollectionViewCell *_Nonnull)cell;

- (id _Nullable)modelForIndexPath:(NSIndexPath*_Nonnull)indexPath;

#pragma mark - Lookup back

//  透過某個 responder UI，取得 cell
- (nullable UICollectionViewCell*)cellForUI:(UIControl *_Nonnull)uiControl;

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

- (void)setDefaultSize:(CGSize)cellSize forCellClass:(Class _Nonnull)cellClass;

- (CGSize)getDefaultSizeForCellClass:(Class _Nonnull)cellClass;

#pragma mark - Config Model Header/Footer Mapping

- (void)setMappingModel:(Class _Nonnull)modelClass reusableViewClass:(Class _Nonnull)reusableViewClass;

//  取得對映的 header / footer name
- (NSString *_Nullable)getReusableViewNameFor:(id _Nonnull)model;

- (void)setHeaderModel:(id _Nonnull)model atIndex:(NSInteger)sectionIndex;
- (void)setHeaderModels:(NSArray *_Nonnull)models;

- (void)setFooterModel:(id _Nonnull)model atIndex:(NSInteger)sectionIndex;
- (void)setFooterModels:(NSArray *_Nonnull)models;

- (id _Nullable)headerModelAt:(NSInteger)section;
- (id _Nullable)footerModelAt:(NSInteger)section;

- (UICollectionReusableView* _Nullable)headerViewAt:(NSInteger)section;
- (UICollectionReusableView* _Nullable)footerViewAt:(NSInteger)section;

// 使用上，應該會直覺 header 就會對應一開始設定給它的 section
// 例如有三個 section 都有 header，當刪除 section 1 的時候，會連同 header 1 也刪除
// 會只剩下 section 0 , header 0, section 2 , header 2

#pragma mark Get Header Footer Sectoin

- (NSInteger)sectionForHeaderFooterModel:(id _Nonnull)model;

- (NSInteger)sectionForHeaderFooterUI:(UIView* _Nonnull)ui;

#pragma mark - Header/Footer Size

- (void)setHeaderFooterSize:(CGSize)size model:(id _Nonnull)model;

- (CGSize)getHeaderFooterSizeModel:(id _Nonnull)model;

#pragma mark - UI Event Handle

// 指定要監聽某個 cell 上的某個 ui，這邊要注意，你要監聽的 UIResponder 一定要設定為一個 property，那到時觸發事件後，你想要知道是屬於哪個 cell 或哪個 model，再另外反查
- (void)addTarget:(nullable id)target action:(nonnull SEL)action forControlEvents:(UIControlEvents)event onCell:(nonnull Class)cellClass propertyName:(nonnull NSString*)property;
- (void)addTarget:(nullable id)target action:(nonnull SEL)action forControlEvents:(UIControlEvents)event onCell:(nonnull Class)cellClass propertyNames:(nonnull NSArray<NSString*>*)properties;

- (void)removeTarget:(nullable id)target action:(nonnull SEL)action forControlEvents:(UIControlEvents)event onCell:(nonnull Class)cellClass propertyName:(nonnull NSString*)property;
- (void)removeTarget:(nullable id)target action:(nonnull SEL)action forControlEvents:(UIControlEvents)event onCell:(nonnull Class)cellClass;

- (void)removeAllTarget;

@end
