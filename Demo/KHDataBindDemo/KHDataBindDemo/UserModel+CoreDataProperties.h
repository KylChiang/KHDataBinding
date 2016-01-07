//
//  UserModel+CoreDataProperties.h
//  KHDataBindDemo
//
//  Created by GevinChen on 2016/1/7.
//  Copyright © 2016年 omg. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "UserModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface UserModel (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *testNum;
@property (nullable, nonatomic, retain) NSManagedObject *user;

@end

NS_ASSUME_NONNULL_END
