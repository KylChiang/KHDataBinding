//
//  CKHTableViewCell.h
//  DataBindTest
//
//  Created by GevinChen on 2015/9/26.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import <UIKit/UIKit.h>
@class TableViewBindHelper;
// 內部記錄 cell 狀態資訊使用
extern NSString* const kCellIndex;
extern NSString* const kCellModel;
extern NSString* const kCellIdentifier;
extern NSString* const kCellConfigBlock;
extern NSString* const kCellBind;
extern NSString* const kCellHeight;

@interface CKHTableViewCell : UITableViewCell

@property (nonatomic) NSMutableDictionary *cellData;
@property (nonatomic) TableViewBindHelper *helper;




-(void)assignValue:(NSDictionary*)assignMap;

-(void)updateModel:(NSString*)cellKeyPath;

// tempData 是記錄 cell ui 上的狀態資料或暫存資料，任你存
-(void)loadModel:(id)model stateData:(NSMutableDictionary*)tempData;

@end
