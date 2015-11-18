//
//  CKHTableViewCell.m
//  DataBindTest
//
//  Created by GevinChen on 2015/9/26.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import "KHTableViewCell.h"
#import "KHBindHelper.h"

@implementation KHCellModel

- (instancetype)initWithDict:(NSDictionary *)dic
{
    self = [super initWithDict:dic];
    self.cellHeight = 44;
    self.accessoryView = nil;
    self.accessoryType = UITableViewCellAccessoryNone;
    self.selectionType = UITableViewCellSelectionStyleNone;
    return self;
}

- (instancetype)init
{
    if (self = [super init]) {
        self.cellHeight = 44;
        self.accessoryView = nil;
        self.accessoryType = UITableViewCellAccessoryNone;
        self.selectionType = UITableViewCellSelectionStyleNone;
    }
    return self;
}

@end



@implementation KHTableCellModel


- (instancetype)init
{
    if ( self = [super init] ) {
        
        self.cellStyle = UITableViewCellStyleValue1;
        self.accessoryView = nil;
        self.accessoryType = UITableViewCellAccessoryNone;
        self.selectionType = UITableViewCellSelectionStyleGray;
    }
    return self;
}

@end


@implementation KHTableViewCell

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    // 讓分隔線填滿，不要內縮
    if ([self respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        self.preservesSuperviewLayoutMargins = NO;
    }
    
    if ( [self respondsToSelector:@selector(setLayoutMargins:)]) {
        self.layoutMargins = UIEdgeInsetsMake(0, 0, 0, 0);
    }
    
    if ( [self respondsToSelector:@selector(setSeparatorInset:)]) {
        self.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
    }

    
    return self;
}

- (void)onLoad:(KHTableCellModel*)model
{
    self.textLabel.text = model.text;
    self.detailTextLabel.text = model.detail;
    self.imageView.image = model.image;
    if (model.textFont) {
        self.textLabel.font = model.textFont;
    }
    if (model.detailFont) {
        self.detailTextLabel.font = model.detailFont;
    }
    if (model.textColor) {
        self.textLabel.textColor = model.textColor;
    }
    if (model.detailColor) {
        self.detailTextLabel.textColor = model.detailColor;
    }
    
    self.accessoryView = model.accessoryView;
    self.accessoryType = model.accessoryType;
    self.selectionStyle = model.selectionType;
}

- (void)loadImageURL:(NSString*)url completed:(void(^)(UIImage*image))completed
{
    if ( url == nil || url.length == 0 ) {
        NSLog(@"table view cell download image error, url is empty, index %ld", [self.model index].row );
        return;
    }
    [self.helper loadImageURL:url cell:self completed:completed];
}


@end



@implementation KHCollectionViewCell

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {

    }
    return self;
}


//
- (void)onLoad:(KHCellModel*)model
{
    // override by subclass
}

- (void)loadImageURL:(NSString*)url completed:(void(^)(UIImage*image))completed
{
    if ( url == nil || url.length == 0 ) {
        NSLog(@"table view cell download image error, url is empty, index %ld", [self.model index].row );
        return;
    }
    [self.helper loadImageURL:url cell:self completed:completed];
}

@end
