//
//  KHModelCellLinker.h
//
//  Created by GevinChen on 2015/9/26.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KVCModel.h"

@class KHDataBinding;


/**
 *  data model 與 cell 的介接物件
 *  因為 cell 會 reuse，所以用這個來記說目前 model 對映哪個 cell instance
 *  當 model 有資料變動，才知道要更新哪一個 cell 實體
 */
extern NSString* const kCellSize;
extern NSString* const kCellHeight;

@interface KHModelCellLinker : NSObject
{
    //  用來標記說下個 run loop 要執行更新
    BOOL needUpdate;
    BOOL hasUpdated;
}

@property (nonatomic,assign,nullable) KHDataBinding *binder;
@property (nonatomic,assign) id cell;
@property (nonatomic,assign) id model;
@property (nonatomic) CGSize cellSize;

//  建立 KVO，讓 model 屬性變動後，立即更新到 cell
- (void)observeModel;
- (void)deObserveModel;

//  取得目前的 index
- (NSIndexPath*)indexPath;

//  從網路下載圖片，下載完後，呼叫 callback
- (void)loadImageURL:(nonnull NSString*)urlString completed:(nullable void(^)( UIImage*,  NSError*))completedHandle;

//  從網路下載圖片，下載完後，直接把圖片填入到傳入的 imageView 裡
- (void)loadImageURL:(nonnull NSString*)urlString imageView:(nullable UIImageView*)imageView placeHolder:(nullable UIImage*)placeHolderImage brokenImage:(nullable UIImage*)brokenImage animation:(BOOL)animated;

@end




/**
 *  用來控制預設的 UITableViewCell 顯示內容
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

//@property (nonatomic,assign) KHDataBinder *binder;
@property (nonatomic,assign,nullable) KHModelCellLinker *linker;

//  取得這個 cell 對映哪個 model
+ (nonnull Class)mappingModelClass;

//  由子類別實作，執行把 model 的資料填入 cell
- (void)onLoad:(nullable id)model;

@end

/**
 *  沒有實際用處，只是為了符合 cell mapping 的規則
 *  因為 UICollectionViewCell 通常使用上都要繼承一個自訂內容 layout
 *  並不像 UITableViewCell，不會直接使用 UICollectionViewCell
 *
 */
@interface UICollectionViewCellModel : NSObject

@end

@interface UICollectionViewCell (KHCell)

@property (nonatomic,assign) KHModelCellLinker *linker;

//  取得這個 cell 對映哪個 model
+ (nonnull Class)mappingModelClass;

//  由子類別實作，執行把 model 的資料填入 cell
- (void)onLoad:(nullable id)model;

@end

@interface UICollectionReusableView (KHCell)

//  取得這個 cell 對映哪個 model
+ (nonnull Class)mappingModelClass;

//  由子類別實作，執行把 model 的資料填入 cell
- (void)onLoad:(nullable id)model;

@end

