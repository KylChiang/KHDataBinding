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


//- (void)notify:(const NSString*)event userInfo:(id)userInfo
//{
//    if (self.helper) {
//        [self.helper notify:event userInfo:userInfo];
//    }
//}

- (void)loadImageURL:(NSString*)url completed:(void(^)(UIImage*image))completed
{
    if ( url == nil || url.length == 0 ) {
        NSLog(@"table view cell download image error, url is empty, index %ld", [self.model index].row );
        return;
    }
    [self.helper loadImageURL:url target:self completed:completed];
}

- (void)tagUIControl:(nonnull UIControl*)control;
{
    [self.helper tagUIControl:control cell:self];
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


