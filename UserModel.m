//
//  UserModel.m
//
//  Created by GevinChen  on 2015/10/9
//  Copyright (c) 2015 __MyCompanyName__. All rights reserved.
//

#import "UserModel.h"
#import "Results.h"


NSString *const kUserModelResults = @"results";


@interface UserModel ()

- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict;

@end

@implementation UserModel

@synthesize results = _results;


+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict
{
    return [[self alloc] initWithDictionary:dict];
}

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    
    // This check serves to make sure that a non-NSDictionary object
    // passed into the model class doesn't break the parsing.
    if(self && [dict isKindOfClass:[NSDictionary class]]) {
            self.results = [Results modelObjectWithDictionary:[dict objectForKey:kUserModelResults]];

    }
    
    return self;
    
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    [mutableDict setValue:[self.results dictionaryRepresentation] forKey:kUserModelResults];

    return [NSDictionary dictionaryWithDictionary:mutableDict];
}

- (NSString *)description 
{
    return [NSString stringWithFormat:@"%@", [self dictionaryRepresentation]];
}

#pragma mark - Helper Method
- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict
{
    id object = [dict objectForKey:aKey];
    return [object isEqual:[NSNull null]] ? nil : object;
}


#pragma mark - NSCoding Methods

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];

    self.results = [aDecoder decodeObjectForKey:kUserModelResults];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{

    [aCoder encodeObject:_results forKey:kUserModelResults];
}

- (id)copyWithZone:(NSZone *)zone
{
    UserModel *copy = [[UserModel alloc] init];
    
    if (copy) {

        copy.results = [self.results copyWithZone:zone];
    }
    
    return copy;
}


@end
