//
//  KHPairInfo.h
//
//  Created by GevinChen on 2015/9/26.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KVCModel.h"

@class KHCollectionView;
@class KHTableView;
@class KHDataBinding;

NS_ASSUME_NONNULL_BEGIN
/**
  * data model 與 cell 的配對資訊
  * 因為 cell 會 reuse，所以用這個來記說目前 model 對映哪個 cell instance
  * model 與 KHPairInfo 設定之後就固定，不會再變動，cell 會一直變，每當 reuse 就會重新設定 cell  
 *
  * 之後，當 model 有資料變動，才知道要更新哪一個 cell instance
 */
extern NSString *const kCellSize;
extern NSString *const kCellHeight;

@interface KHPairInfo : NSObject
{
    //  用來標記說下個 run loop 要執行更新
    BOOL needUpdate;
    BOOL hasUpdated;
    
    //  記錄額外的資料，有一些可能不會在 model 上的資料
    //  例如 cell 的 ui 顯示狀態
    NSMutableDictionary *_userInfo;
}

@property (nonatomic,assign,nullable) KHDataBinding *binder;
@property (nonatomic,assign,nullable) KHCollectionView *collectionView;
@property (nonatomic,assign,nullable) KHTableView *tableView;
@property (nonatomic,readonly,nullable) id cell;
@property (nonatomic,strong,nullable) id model;
@property (nonatomic,readonly,nullable) NSIndexPath *indexPath;
@property (nonatomic) CGSize cellSize;
@property (nonatomic) BOOL enabledObserveModel;
@property (nonatomic) NSString *pairCellName;

- (void)loadModelToCell;

/**
 記錄額外的資料，有一些可能不會在 model 上的資料
 例如 cell 的 ui 顯示狀態

 @param key 資料的 key
 @param valueObj 資料本體
 */
- (void)setUserInfo:(id)key value:(id)valueObj;


/**
 取得先前記錄的資料

 @param key 資料的key
 @return 資料本身
 */
- (id)getUserInfo:(id)key;

//  建立 KVO，讓 model 屬性變動後，立即更新到 cell
- (void)observeModel;
- (void)deObserveModel;

//  從網路下載圖片，下載完後，呼叫 callback
- (void)loadImageURL:(nonnull NSString*)urlString completed:(nullable void(^)( UIImage*image, NSError*error))completedHandle;

//  從網路下載圖片，下載完後，直接把圖片填入到傳入的 imageView 裡
- (void)loadImageURL:(nonnull NSString*)urlString 
           imageView:(nullable UIImageView*)imageView
         placeHolder:(nullable UIImage*)placeHolderImage 
         brokenImage:(nullable UIImage*)brokenImage
           animation:(BOOL)animated;

//  從網路下載圖片，下載完後，直接把圖片填入到傳入的 imageView 裡
- (void)loadImageURL:(nonnull NSString*)urlString
           imageView:(nullable UIImageView*)imageView
         placeHolder:(nullable UIImage*)placeHolderImage
         brokenImage:(nullable UIImage*)brokenImage
           animation:(BOOL)animated
           completed:(nullable void(^)( UIImageView*imageView, UIImage*image, NSError*error))completedHandle;

//  更新 model 不做更新，用在 cell 裡執行修改 model，因為 model 修改後會自動觸發更新，所以當你修改不想要做更新時，可執行此 method
- (void)modifyModelNoNotify:(void(^)(id _Nonnull model))modifyBlock;


@end



/**
  * 用來控制預設的 UITableViewCell 顯示內容
 *
 */
@interface UITableViewCellModel : NSObject

@property (nonatomic,nullable) NSString *text;
@property (nonatomic,nullable) NSString *detail;
@property (nonatomic,nullable) UIImage *image;
@property (nonatomic,nullable) UIFont *textFont;
@property (nonatomic,nullable) UIFont *detailFont;
@property (nonatomic,nullable) UIColor *textColor;
@property (nonatomic,nullable) UIColor *detailColor;
@property (nonatomic) UITableViewCellStyle cellStyle;
@property (nonatomic) UITableViewCellAccessoryType accessoryType;
@property (nonatomic,nullable) UIView *accessoryView;
@property (nonatomic) UITableViewCellSelectionStyle selectionType;
@property (nonatomic,nullable) UIColor *backgroundColor;
@property (nonatomic,nullable) UIView *backgroundView;
@property (nonatomic) UIEdgeInsets separatorInset;
@property (nonatomic) UIEdgeInsets layoutMargins;
@property (nonatomic) BOOL preservesSuperviewLayoutMargins;

@end


@interface UITableViewCell (KHCell)

@property (nonatomic) BOOL kh_hasConfig; //用來標記是否是新建立的 
@property (nonatomic,assign,nullable) KHPairInfo *pairInfo;

//  取得這個 cell 對映哪個 model
+ (nonnull Class)mappingModelClass;

//  目前配對的 model
- (nullable id)model;

- (nullable NSIndexPath*)indexPath;

//  由子類別實作，執行把 model 的資料填入 cell
- (void)onLoad:(nullable id)model;

//  從網路下載圖片，下載完後，呼叫 callback
- (void)loadImageURL:(nonnull NSString*)urlString completed:(nullable void(^)( UIImage*,  NSError*))completedHandle;

//  從網路下載圖片，下載完後，直接把圖片填入到傳入的 imageView 裡
- (void)loadImageURL:(nonnull NSString*)urlString 
           imageView:(nullable UIImageView*)imageView
         placeHolder:(nullable UIImage*)placeHolderImage 
         brokenImage:(nullable UIImage*)brokenImage
           animation:(BOOL)animated;

//  從網路下載圖片，下載完後，直接把圖片填入到傳入的 imageView 裡
- (void)loadImageURL:(nonnull NSString*)urlString
           imageView:(nullable UIImageView*)imageView
         placeHolder:(nullable UIImage*)placeHolderImage
         brokenImage:(nullable UIImage*)brokenImage
           animation:(BOOL)animated
           completed:(nullable void(^)( UIImageView*imageView, UIImage*image, NSError*error))completedHandle;

//  更新 model 不做更新，用在 cell 裡執行修改 model，因為 model 修改後會自動觸發更新，所以當你修改不想要做更新時，可執行此 method
- (void)modifyModelNoNotify:(void(^)(id _Nonnull model))modifyBlock;


@end

/**
  * 沒有實際用處，只是為了符合 cell mapping 的規則
  * 因為 UICollectionViewCell 通常使用上都要繼承一個自訂內容 layout
  * 並不像 UITableViewCell，不會直接使用 UICollectionViewCell
 *
 */
@interface UICollectionViewCellModel : NSObject

@end

@interface UICollectionReusableView (KHCell)

@property (nonatomic) BOOL kh_hasConfig; //用來標記是否是新建立的 
@property (nonatomic,assign,nullable) KHPairInfo *pairInfo;

//  取得這個 cell 對映哪個 model
+ (nonnull Class)mappingModelClass;

//  目前配對的 model
- (nullable id)model;

- (nullable NSIndexPath*)indexPath;

//  由子類別實作，執行把 model 的資料填入 cell
- (void)onLoad:(id _Nonnull)model;

//  從網路下載圖片，下載完後，呼叫 callback
- (void)loadImageURL:(nonnull NSString*)urlString completed:(nullable void(^)( UIImage*,  NSError*))completedHandle;

//  從網路下載圖片，下載完後，直接把圖片填入到傳入的 imageView 裡
- (void)loadImageURL:(nonnull NSString*)urlString 
           imageView:(nullable UIImageView*)imageView
         placeHolder:(nullable UIImage*)placeHolderImage 
         brokenImage:(nullable UIImage*)brokenImage
           animation:(BOOL)animated;

//  從網路下載圖片，下載完後，直接把圖片填入到傳入的 imageView 裡
- (void)loadImageURL:(nonnull NSString*)urlString
           imageView:(nullable UIImageView*)imageView
         placeHolder:(nullable UIImage*)placeHolderImage
         brokenImage:(nullable UIImage*)brokenImage
           animation:(BOOL)animated
           completed:(nullable void(^)( UIImageView*imageView, UIImage*image, NSError*error))completedHandle;

//  更新 model 不做更新，用在 cell 裡執行修改 model，因為 model 修改後會自動觸發更新，所以當你修改不想要做更新時，可執行此 method
- (void)modifyModelNoNotify:(void(^)(id _Nonnull model))modifyBlock;

@end


typedef enum{
    CellAnimation_Insert=0,
    CellAnimation_Remove,
    CellAnimation_Reload,
}CellAnimationType;



@interface KHEventHandleData : NSObject

@property (nonatomic,weak,nullable) id target;
@property (nonatomic,nullable) SEL action;
@property (nonatomic) UIControlEvents event;
@property (nonatomic,nullable) Class cellClass;
@property (nonatomic,copy,nullable) NSString *propertyName;
@property (nonatomic) NSMutableArray *cellViews;

- (void)addEventTargetForCellView:(UIView*)cellView;

- (void)removeEventTargetFromAllCellViews;

@end



NS_ASSUME_NONNULL_END
