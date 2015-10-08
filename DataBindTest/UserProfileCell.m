//
//  UserProfileCell.m
//  DataBindTest
//
//  Created by GevinChen on 2015/10/4.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import "UserProfileCell.h"

@implementation UserProfileCell


- (void)onInit:(UserProfile*)model
{
    
}

- (void)onLoad:(UserProfile*)model
{
//    printf("cell %ld height%f\n", model.index.row, model.cellHeight );
    self.nameLabel.text = model.username;

    UIImage *image = model.storage[@"image"];
    if ( image != nil && image != [NSNull null] ) {
        self.userImage.image = image;
    }
    else if( image == nil ){
        //
        printf("download start %ld %s\n", model.index.row, [model.image_urls.normal UTF8String] );
        model.storage[@"image"] = [NSNull null];
        
        CKHTask *task = [[CKHTask alloc] initWith:^BOOL(CKHTask *task) {
            NSData *data = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:model.image_urls.normal]];
            UIImage *image = [[UIImage alloc] initWithData: data ];
            printf("download completed %s\n", [model.image_urls.normal UTF8String] );
            model.storage[@"image"] = image;
            if ( self.model == model ) {
                self.userImage.image = image;
            }
            return NO;
        }, nil ];
//        printf("download start %s\n", [model.image_urls.normal UTF8String] );
        [task start];
    }
    
}

@end
