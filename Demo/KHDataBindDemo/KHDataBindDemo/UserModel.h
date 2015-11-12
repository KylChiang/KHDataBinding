//
//  Results.h
//
//  Created by GevinChen  on 2015/10/9
//  Copyright (c) 2015 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KHTableViewCell.h"
#import "UserInfoCell.h"

@interface Location : KVCModel

@property (nonatomic, strong) NSString *state;
@property (nonatomic, strong) NSString *street;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) NSString *zip;


@end


@interface Name : KVCModel

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *first;
@property (nonatomic, strong) NSString *last;


@end


@interface Picture : KVCModel

@property (nonatomic, strong) NSString *large;
@property (nonatomic, strong) NSString *thumbnail;
@property (nonatomic, strong) NSString *medium;

@end


@interface User : KVCModel

@property (nonatomic, strong) NSString *sha256;
@property (nonatomic, strong) NSString *cell;
@property (nonatomic, strong) NSString *phone;
@property (nonatomic, strong) NSString *nationality;
@property (nonatomic, strong) NSString *version;
@property (nonatomic, strong) NSString *dob;
@property (nonatomic, strong) NSString *registered;
@property (nonatomic, strong) Picture *picture;
@property (nonatomic, strong) NSString *sha1;
@property (nonatomic, strong) NSString *dNI;
@property (nonatomic, strong) Location *location;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *salt;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *md5;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) Name *name;
@property (nonatomic, strong) NSString *gender;

@end


@interface UserModel : KHCellModel

//@property (nonatomic, strong) NSString *seed;
@property (nonatomic, strong) User *user;

@end
