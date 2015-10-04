//
//  CKHTableViewCell.m
//  DataBindTest
//
//  Created by GevinChen on 2015/9/26.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import "CKHTableViewCell.h"
#import "TableViewBindHelper.h"

@implementation CKHCellModel

-(instancetype)init
{
    if (self = [super init]) {
        _storage = [[NSMutableDictionary alloc] initWithCapacity:5];
    }
    return self;
}

@end


@implementation CKHTableViewCell

- (void)awakeFromNib
{
//    self.translatesAutoresizingMaskIntoConstraints = NO;
}


- (void)onInit:(CKHCellModel*)model
{
    // override by subclass
}

//
- (void)onLoad:(CKHCellModel*)model
{
    // override by subclass
}

- (void)notify:(const NSString*)event userInfo:(id)userInfo
{
    if (self.helper) {
        [self.helper notify:event userInfo:userInfo];
    }
}

@end


@implementation UITableCellModel

- (instancetype)init
{
    if ( self = [super init] ) {
        
        self.identifier = @"defaultCell";
        self.cellStyle = UITableViewCellStyleValue1;
        self.accessoryView = nil;
        self.accessoryType = UITableViewCellAccessoryNone;
        self.selectionType = UITableViewCellSelectionStyleGray;
        
        self.onCreateBlock = ^( UITableCellModel *model ){
            DefaultCell *cell = [[DefaultCell alloc] initWithStyle:model.cellStyle reuseIdentifier:model.identifier ];
            return cell;
        };
    }
    return self;
}

@end


@implementation DefaultCell

- (void)onInit:(UITableCellModel*)model
{
    
}

- (void)onLoad:(UITableCellModel*)model
{
    self.textLabel.text = model.text;
    self.detailTextLabel.text = model.detail;
    self.imageView.image = model.image;
    
    self.accessoryView = model.accessoryView;
    self.accessoryType = model.accessoryType;
    self.selectionStyle = model.selectionType;
}


@end


