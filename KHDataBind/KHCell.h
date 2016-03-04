//
//  CKHTableViewCell.h
//  DataBindTest
//
//  Created by GevinChen on 2015/9/26.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KVCModel.h"

@class KHDataBinder;


/**
 *  data model 與 cell 的介接資料物件
 *  可以把 adapter 當作 cell 的替代
 */

@interface KHCellAdapter : NSObject

@property (nonatomic,assign) id cell;
@property (nonatomic,strong) id model;

//  只有 for table view cell
//@property (nonatomic,strong) NSIndexPath *index; // 因為更新不是全部都更新，有的cell沒更新，導致 index 仍為舊值的問題，所以就不記錄index 了
@property (nonatomic) float cellHeight;
@property (nonatomic) UITableViewCellAccessoryType accessoryType;
@property (nonatomic) UIView *accessoryView;
@property (nonatomic) UITableViewCellSelectionStyle selectionType;
@property (nonatomic) UIColor *backgroundColor;

//  for collection view cell
@property (nonatomic) CGSize cellSize;

- (void)loadImageWithURL:(NSString*)urlString completed:(void(^)(UIImage*))completedHandle;

@end


/*
 Gevin note:
    因為有 UITableViewCell , UICollectionViewCell，然後我想要讓它們共有一個 root，所以
    最上層我用 protocol 的方式，來強迫定義介面，然後再各自繼承，有自己的 sub class
 */

//@protocol KHCell <NSObject>
//
//@property (nonatomic,assign) KHCellAdapter *adapter;
//
//- (void)onLoad:(id)model;
//
//@end


/**
 *  用來控制預設的 UITableViewCell 顯示內容
 *  註：不會有 UICollectionViewCell 的 model，因為 UICollectionViewCell 通常使用上都要繼承一個自訂內容 layout
 *
 */
@interface UITableViewCellModel : NSObject

@property (nonatomic) NSString *text;
@property (nonatomic) NSString *detail;
@property (nonatomic) UIImage *image;
@property (nonatomic) UIFont *textFont;
@property (nonatomic) UIFont *detailFont;
@property (nonatomic) UIColor *textColor;
@property (nonatomic) UIColor *detailColor;
@property (nonatomic) UITableViewCellStyle cellStyle;

@end


@interface UITableViewCell (KHCell)

@property (nonatomic,assign) KHCellAdapter *adapter;

- (void)onLoad:(id)model;

@end

@interface UICollectionViewCell (KHCell)

@property (nonatomic,assign) KHCellAdapter *adapter;

- (void)onLoad:(id)model;

@end