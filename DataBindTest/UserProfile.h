//
//  UserProfile.h
//  DataBindTest
//
//  Created by GevinChen on 2015/10/4.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import "CKHTableViewCell.h"

@interface ImageSet : NSObject

@property (nonatomic) NSString *bigger;
@property (nonatomic) NSString *epic;
@property (nonatomic) NSString *mini;
@property (nonatomic) NSString *normal;

@end

@interface UserProfile : CKHCellModel

@property (nonatomic) ImageSet *image_urls;
@property (nonatomic) NSString *username;

@end
