//
//  Results.h
//
//  Created by GevinChen  on 2015/10/9
//  Copyright (c) 2015 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KHCell.h"

@interface Location : NSObject

@property (nonatomic, strong) NSString *state;
@property (nonatomic, strong) NSString *street;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) NSString *zip;


@end


@interface Name : NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *first;
@property (nonatomic, strong) NSString *last;


@end


@interface Picture : NSObject

@property (nonatomic, strong) NSString *large;
@property (nonatomic, strong) NSString *thumbnail;
@property (nonatomic, strong) NSString *medium;

@end


@interface Login : NSObject

@property (nonatomic) NSString *username;
@property (nonatomic) NSString *password;
@property (nonatomic) NSString *salt;
@property (nonatomic) NSString *md5;
@property (nonatomic) NSString *sha1;
@property (nonatomic) NSString *sha256;

@end

@interface Identifier : NSObject
@property (nonatomic) NSString *name;
@property (nonatomic) NSString *value;
@end


@interface UserModel : NSObject

@property (nonatomic) NSString *gender;
@property (nonatomic) NSString *email;
@property (nonatomic) NSNumber *registered;
@property (nonatomic) NSNumber *dob;
@property (nonatomic) NSString *phone;
@property (nonatomic) NSString *cell;
@property (nonatomic) NSString *nat;

@property (nonatomic) Name *name;
@property (nonatomic) Location *location;
@property (nonatomic) Picture *picture;
@property (nonatomic) Login *login;
@property (nonatomic) Identifier *ID;

//  for cell display
@property (nonatomic) NSInteger testNum;
@property (nonatomic) BOOL swValue;
@property (nonatomic) NSString *testText;

@end

