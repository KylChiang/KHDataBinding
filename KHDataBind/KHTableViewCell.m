//
//  CKHTableViewCell.m
//  DataBindTest
//
//  Created by GevinChen on 2015/9/26.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import "KHTableViewCell.h"
#import "KHTableViewBindHelper.h"

@implementation KHCellModel

- (instancetype)initWithDict:(NSDictionary *)dic
{
    [self initModel];
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
        [self initModel];
        self.cellHeight = 44;
        self.accessoryView = nil;
        self.accessoryType = UITableViewCellAccessoryNone;
        self.selectionType = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)initModel
{
    // override by subclass , init property    
}

- (void)setData:(id)data forKey:(NSString*)key
{
    if (!_storage) {
        _storage = [[NSMutableDictionary alloc] initWithCapacity: 3 ];
    }
    [_storage setObject:data forKey:key ];
}

- (id)getDataForKey:(NSString*)key
{
    if (_storage) {
        return [_storage objectForKey:key];
    }
    return nil;
}

- (void)removeDataForKey:(NSString*)key
{
    if (_storage ) {
        [_storage removeObjectForKey:key];
    }
}

@end


@implementation KHCell

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
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
    }
    return self;
}

+ (NSString*)xibName
{
    //  override by subclass
    return nil;
}

- (void)onInit:(KHCellModel*)model
{
    // override by subclass
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
    [self.helper loadImageURL:url target:self completed:completed];
}


@end


@implementation KHTableCellModel

- (instancetype)init
{
    if ( self = [super init] ) {
        
//        self.identifier = @"defaultCell";
        self.cellStyle = UITableViewCellStyleValue1;
        self.accessoryView = nil;
        self.accessoryType = UITableViewCellAccessoryNone;
        self.selectionType = UITableViewCellSelectionStyleGray;
        self.cellClass = [KHTableViewCell class];
        self.onCreateBlock = ^( KHTableCellModel *model ){
            KHTableViewCell *cell = [[KHTableViewCell alloc] initWithStyle:model.cellStyle reuseIdentifier:@"UITableViewCell" ];
            return cell;
        };
    }
    return self;
}

@end


@implementation KHTableViewCell

- (void)onInit:(KHTableCellModel*)model
{
    
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


@end


