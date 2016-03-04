//
//  CKHTableViewCell.m
//  DataBindTest
//
//  Created by GevinChen on 2015/9/26.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import "KHCell.h"
#import "KHDataBinder.h"
#import <objc/runtime.h>

@implementation KHCellAdapter

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.accessoryView = nil;
        self.accessoryType = UITableViewCellAccessoryNone;
        self.selectionType = UITableViewCellSelectionStyleGray;
    }
    return self;
}

- (void)loadImageWithURL:(NSString*)urlString completed:(void(^)(UIImage*))completedHandle
{
    if ( urlString == nil || urlString.length == 0 ) {
        NSLog(@"*** image download wrong!!" );
        completedHandle(nil);
        return;
    }
    [[KHImageDownloader instance] loadImageURL:urlString adapter:self completed:completedHandle];
}

@end


@implementation UITableViewCellModel


- (instancetype)init
{
    if ( self = [super init] ) {
        self.cellStyle = UITableViewCellStyleValue1;
    }
    return self;
}

@end

@implementation UITableViewCell (KHCell)

- (void)setAdapter:(KHCellAdapter *)adapter
{
    objc_setAssociatedObject( self, @"KHCellAdapter", adapter, OBJC_ASSOCIATION_ASSIGN);
}

- (KHCellAdapter*)adapter
{
    return objc_getAssociatedObject(self, @"KHCellAdapter" );
}


- (void)onLoad:(UITableViewCellModel*)model
{
    self.
    self.textLabel.text = model.text;
    if ( model.textFont ) self.textLabel.font = model.textFont;
    if ( model.textColor ) self.textLabel.textColor = model.textColor;
    if ( model.image ) self.imageView.image = model.image;

    self.detailTextLabel.text = model.text;
    if ( model.detailFont ) self.detailTextLabel.font = model.detailFont;
    if ( model.detailColor) self.detailTextLabel.textColor = model.detailColor;
}

@end


@implementation UICollectionViewCell (KHCell)

- (void)setAdapter:(KHCellAdapter *)adapter
{
    objc_setAssociatedObject( self, @"KHCellAdapter", adapter, OBJC_ASSOCIATION_ASSIGN);
}

- (KHCellAdapter*)adapter
{
    return objc_getAssociatedObject(self, @"KHCellAdapter" );
}

- (void)onLoad:(id)model
{
    //  override by subclass
}

@end

