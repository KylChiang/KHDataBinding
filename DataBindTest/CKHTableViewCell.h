//
//  CKHTableViewCell.h
//  DataBindTest
//
//  Created by GevinChen on 2015/9/26.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import <UIKit/UIKit.h>
@class TableViewBindHelper;

typedef id(^CellCreateBlock)( id model );
typedef void(^CellConfigBlock)(id cell, id model );

@interface CKHCellModel : NSObject

@property (nonatomic) NSString *identifier;
@property (nonatomic) NSString *nibName;
@property (nonatomic) float cellHeight;
@property (nonatomic) NSIndexPath *index;
@property (nonatomic) NSMutableDictionary *storage; // 暫存一些 cell 產生的資料如下載的圖片，或是變換的狀態之類的

// create block 預設是使用 helper 內定的流程，若有特別例外的做法，就實做這個 block
@property (nonatomic,copy) CellCreateBlock onCreateBlock;

// init , load  預設是執行 cell 實作的 onInit , onLoad，若有設定 block 就會執行 block
@property (nonatomic,copy) CellConfigBlock onInitBlock;
@property (nonatomic,copy) CellConfigBlock onLoadBlock;

@end

@interface CKHTableViewCell : UITableViewCell

@property (nonatomic) id model;
@property (nonatomic) TableViewBindHelper *helper;

- (void)notify:(const NSString*)event userInfo:(id)userInfo;

// 只在 create 之後執行，只執行一次
- (void)onInit:(id)model;

// 每次 reuse 使用都執行
- (void)onLoad:(id)model;

@end



@interface UITableCellModel : CKHCellModel

@property (nonatomic) NSString *text;
@property (nonatomic) NSString *detail;
@property (nonatomic) UIImage *image;
@property (nonatomic) UITableViewCellStyle cellStyle;
@property (nonatomic) UITableViewCellAccessoryType accessoryType;
@property (nonatomic) UIView *accessoryView;
@property (nonatomic) UITableViewCellSelectionStyle selectionType;

@end

@interface DefaultCell : CKHTableViewCell

@end





