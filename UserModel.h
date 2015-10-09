//
//  UserModel.h
//
//  Created by GevinChen  on 2015/10/9
//  Copyright (c) 2015 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Results;

@interface UserModel : NSObject <NSCoding, NSCopying>

@property (nonatomic, strong) Results *results;

+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

@end
