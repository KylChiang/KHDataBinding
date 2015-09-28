//
//  CKHTableViewCell.m
//  DataBindTest
//
//  Created by GevinChen on 2015/9/26.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import "CKHTableViewCell.h"

NSString* const kCellIndex = @"kCellIndex";
NSString* const kCellModel = @"kCellModel";
NSString* const kCellIdentifier = @"kCellIdentifier";
NSString* const kCellConfigBlock = @"kCellConfigBlock";
NSString* const kCellBind = @"kCellBind";
NSString* const kCellHeight = @"kCellHeight";

@implementation CKHTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)assignValue:(NSDictionary*)assignMap
{
    id model = self.cellData[kCellModel];
//    NSArray* uikeypaths = [assignMap allKeys];
    for ( NSString* keypath in assignMap ){
        NSString* modelPath = assignMap[keypath];
        
        NSArray* cellPaths = [keypath componentsSeparatedByString:@"."];
        id target = self;
        for ( int j=0; j<cellPaths.count-1; j++) {
            // 若沒有這個 property 就跳過
            target = [target valueForKey:cellPaths[j]];
            if ( j == cellPaths.count-2) break;
        }
        
        NSArray* modelPaths = [modelPath componentsSeparatedByString:@"."];
        id target2 = model;
        for ( int j=0; j<modelPaths.count-1; j++) {
            target2 = [target2 valueForKey:modelPaths[j] ];
            if ( j == modelPaths.count - 2 ) break;
        }
        
        // 若 model 沒有這個 property，就把 path 當作值填入
        id value = nil;
        if ( [target2 respondsToSelector:NSSelectorFromString([modelPaths lastObject])]){
            value = [target2 valueForKey: [modelPaths lastObject] ];
        }
        else {
            value = [modelPaths lastObject];
        }
            
        [target setValue:value forKey:[cellPaths lastObject] ];
        
    }
}

// 把 cell ui 的值，填入 model
-(void)updateModel:(NSString*)cellKeyPath
{
    NSObject *model = self.cellData[kCellModel];
    NSDictionary* assignMap = self.cellData[kCellBind];
    for ( NSString* keypath in assignMap ){
        if ( [keypath isEqualToString: cellKeyPath ] ) {
            NSString *modelPath = assignMap[keypath];
            if ( [model respondsToSelector:NSSelectorFromString( modelPath ) ]) {
                [model setValue: [self valueForKey:keypath] forKey:modelPath];
            }
            break;
        }
    }
}


-(void)loadModel:(id)model stateData:(NSMutableDictionary*)tempData
{
    
}

@end
