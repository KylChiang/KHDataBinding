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

@implementation KHCellProxy

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.accessoryView = nil;
        self.accessoryType = UITableViewCellAccessoryNone;
        self.selectionType = UITableViewCellSelectionStyleNone;
//        self.cellHeight = 44;
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

- (NSIndexPath*)indexPathOfModel
{
    return [self.dataBinder indexPathOfModel: self.model ];
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

- (void)setCellProxy:(KHCellProxy *)cellProxy
{
    objc_setAssociatedObject( self, @"KHCellProxy", cellProxy, OBJC_ASSOCIATION_ASSIGN);
}

- (KHCellProxy*)cellProxy
{
    return objc_getAssociatedObject(self, @"KHCellProxy" );
}


- (void)onLoad:(UITableViewCellModel*)model
{
//    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.textLabel.text = model.text;
    if ( model.textFont ) self.textLabel.font = model.textFont;
    if ( model.textColor ) self.textLabel.textColor = model.textColor;
    if ( model.image ) self.imageView.image = model.image;

    self.detailTextLabel.text = model.detail;
    if ( model.detailFont ) self.detailTextLabel.font = model.detailFont;
    if ( model.detailColor) self.detailTextLabel.textColor = model.detailColor;
}

@end


@implementation UICollectionViewCell (KHCell)

- (void)setCellProxy:(KHCellProxy *)cellProxy
{
    objc_setAssociatedObject( self, @"KHCellProxy", cellProxy, OBJC_ASSOCIATION_ASSIGN);
}

- (KHCellProxy*)cellProxy
{
    return objc_getAssociatedObject(self, @"KHCellProxy" );
}

- (void)onLoad:(id)model
{
    //  override by subclass
}

@end

