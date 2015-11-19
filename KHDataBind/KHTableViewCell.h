//
//  CKHTableViewCell.h
//  DataBindTest
//
//  Created by GevinChen on 2015/9/26.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KVCModel.h"

@class KHBindHelper;

@interface KHCellModel : KVCModel

@property (nonatomic) float cellHeight;
@property (nonatomic) NSIndexPath *index;
@property (nonatomic) UITableViewCellAccessoryType accessoryType;
@property (nonatomic) UIView *accessoryView;
@property (nonatomic) UITableViewCellSelectionStyle selectionType;

@end

/*
 Gevin note:
    因為有 UITableViewCell , UICollectionViewCell，然後我想要讓它們共有一個 root，所以
    最上層我用 protocol 的方式，來強迫定義介面，然後再各自繼承，有自己的 sub class
 */

@protocol KHCell <NSObject>

@property (nonatomic) id model;
@property (nonatomic) KHBindHelper *helper;

- (void)onLoad:(id)model;

@end

@interface KHTableCellModel : KHCellModel

@property (nonatomic) NSString *text;
@property (nonatomic) NSString *detail;
@property (nonatomic) UIImage *image;
@property (nonatomic) UIFont *textFont;
@property (nonatomic) UIFont *detailFont;
@property (nonatomic) UIColor *textColor;
@property (nonatomic) UIColor *detailColor;
@property (nonatomic) UITableViewCellStyle cellStyle;
@property (nonatomic) UIColor *backgroundColor;

@end

@interface KHTableViewCell : UITableViewCell <KHCell>
@property (nonatomic) id model;
@property (nonatomic) KHBindHelper *helper;

// 載入圖片
- (void)loadImageURL:(NSString*)url completed:(void(^)(UIImage*image))completed;

@end


@interface KHCollectionViewCell : UICollectionViewCell <KHCell>

@property (nonatomic) id model;
@property (nonatomic) KHBindHelper *helper;

// 載入圖片
- (void)loadImageURL:(NSString*)url completed:(void(^)(UIImage*image))completed;

@end



