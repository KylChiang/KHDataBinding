//
//  NSArray+KHSwizzle.m
//
//  Created by GevinChen on 2015/12/10.
//  Copyright © 2015年 omg. All rights reserved.
//

#import "NSMutableArray+KHSwizzle.h"
#import <objc/runtime.h>
#import <objc/message.h>


@implementation NSMutableArray (KHSwizzle)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self kh_swizzleMethod:@selector(addObjectsFromArray:) withNewMethod:@selector(kh_addObjectsFromArray:)];
        [self kh_swizzleMethod:@selector(removeObjectAtIndex:) withNewMethod:@selector(kh_removeObjectAtIndex:)];
        [self kh_swizzleMethod:@selector(removeAllObjects) withNewMethod:@selector(kh_removeAllObjects)];
        [self kh_swizzleMethod:@selector(insertObject:atIndex:) withNewMethod:@selector(kh_insertObject:atIndex:)];
        [self kh_swizzleMethod:@selector(insertObjects:atIndexes:) withNewMethod:@selector(kh_insertObjects:atIndexes:)];
        [self kh_swizzleMethod:@selector(replaceObjectAtIndex:withObject:) withNewMethod:@selector(kh_replaceObjectAtIndex:withObject:)];
    });
}

+ (void)kh_swizzleMethod:(SEL)originalSelector withNewMethod:(SEL)swizzledSelector {
    
        //  Gevin note : 使用 NSMutableArray 必須直接指定使用 __NSArrayM 為 class name
        //               原因好像是說 NSMutableArray 它是一個 class cluster，它的實體會隱
        //               藏 class type，實際的 class type 就叫 __NSArrayM
        Class class = NSClassFromString(@"__NSArrayM");  //[self class];
        // When swizzling a class method, use the following:
        // Class class = object_getClass((id)self);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        BOOL didAddMethod =
        class_addMethod(class,
                        originalSelector,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod));
        
        if (didAddMethod) {
            class_replaceMethod(class,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
}


- (void)setKh_delegate:(id)kh_delegate
{
    objc_setAssociatedObject(self, @"kh_delegate", kh_delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC );
}

-(id)kh_delegate
{
    id delegate = objc_getAssociatedObject(self, @"kh_delegate");
    return delegate;
}

-(void)setSection:(NSInteger)section
{
    objc_setAssociatedObject(self, @"kh_section", @(section), OBJC_ASSOCIATION_RETAIN_NONATOMIC );
}

-(NSInteger)section
{
    NSNumber *sectionNum = objc_getAssociatedObject(self, @"kh_section");
    if (sectionNum) {
        NSInteger _sect = [sectionNum integerValue];
        return _sect;
    }
    return 0;
}


-(void)setIsInsertMulti:(BOOL)isInsertMulti
{
    objc_setAssociatedObject(self, @"kh_isInsertMulti", @(isInsertMulti), OBJC_ASSOCIATION_RETAIN_NONATOMIC );
}

-(BOOL)isInsertMulti
{
    NSNumber *insertMulti = objc_getAssociatedObject(self, @"kh_isInsertMulti" );
    if ( insertMulti ) {
        return [insertMulti boolValue];
    }
    return NO;
}


- (void)kh_addObjectsFromArray:(NSArray*)otherArray
{
    if ( self.kh_delegate == nil ) {
        [self kh_addObjectsFromArray:otherArray];
    }
    else{
        
        if ( otherArray == nil || otherArray.count == 0 ) {
            return;
        }
        self.isInsertMulti = YES;
        [self kh_addObjectsFromArray:otherArray];
        
        if ( [(NSObject*)self.kh_delegate respondsToSelector:@selector(arrayInsertSome:insertObjects:indexes:)] ) {
            NSMutableArray *indexs = [NSMutableArray array];
            for ( NSInteger i=0; i<otherArray.count; i++) {
                NSIndexPath *index = [NSIndexPath indexPathForRow:self.count-otherArray.count+i inSection:self.section];
                [indexs addObject:index];
            }
            [self.kh_delegate arrayInsertSome:self insertObjects:otherArray indexes:indexs];
        }
        self.isInsertMulti = NO;
    }
}

- (void)kh_insertObject:(id)anObject atIndex:(NSUInteger)index
{
    if ( self.kh_delegate == nil ) {
        [self kh_insertObject:anObject atIndex:index];
    }
    else{
        [self kh_insertObject:anObject atIndex:index];
        
        //  呼叫 addObjectsFromArray，最後會呼叫到這裡，這樣就會變成呼叫多次 delegate 的 arrayInsert:insertObject:
        //  多加 self.isInsertMulti 這個屬性做判斷，如果是 addObjectsFromArray 就不呼叫 arrayInsert:insertObject:
        if ( self.isInsertMulti == NO ) {
            if ( [(NSObject*)self.kh_delegate respondsToSelector:@selector(arrayInsert:insertObject:index:)] ) {
                [self.kh_delegate arrayInsert:self insertObject:anObject index:[NSIndexPath indexPathForRow:index inSection:self.section]];
            }
        }
    }
}

- (void)kh_insertObjects:(NSArray *)objects atIndexes:(NSIndexSet *)indexes
{
    if ( self.kh_delegate == nil ) {
        [self kh_insertObjects:objects atIndexes:indexes];
    }
    else{
        [self kh_insertObjects:objects atIndexes:indexes];
        if ( [(NSObject*)self.kh_delegate respondsToSelector:@selector(arrayInsertSome:insertObjects:indexes:)] ) {
            
            NSMutableArray *indexArray = [[NSMutableArray alloc] init];
            [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
                [indexArray addObject:[NSIndexPath indexPathForRow:idx inSection:self.section]];
            }];
            [self.kh_delegate arrayInsertSome:self insertObjects:objects indexes:indexArray];
        }
    }
}

- (void)kh_removeObjectAtIndex:(NSUInteger)index
{
    if ( self.kh_delegate == nil ) {
        [self kh_removeObjectAtIndex:index];
    }
    else{
        id obj = [self objectAtIndex:index];
        [self kh_removeObjectAtIndex:index];
        if ( [(NSObject*)self.kh_delegate respondsToSelector:@selector(arrayRemove:removeObject:index:)] ) {
            [self.kh_delegate arrayRemove:self removeObject:obj index:[NSIndexPath indexPathForRow:index inSection:self.section]];
        }
    }
}

- (void)kh_removeAllObjects
{
    if ( self.kh_delegate == nil ) {
        [self kh_removeAllObjects];
    }
    else{
        if (self.count == 0 ) {
            return;
        }
        NSInteger cnt = self.count;
        if ( [(NSObject*)self.kh_delegate respondsToSelector:@selector(arrayRemoveSome:removeObjects:indexs:)] ) {
            NSArray *removeObjects = [self copy];
            [self kh_removeAllObjects];
            NSMutableArray *indexArr = [[NSMutableArray alloc] init];
            for ( NSInteger i=0; i<cnt ; i++ ) {
                NSIndexPath *idx = [NSIndexPath indexPathForRow:i inSection:self.section ];
                [indexArr addObject: idx ];
            }
            [self.kh_delegate arrayRemoveSome:self removeObjects:removeObjects indexs:indexArr];
        }
        else{
            [self kh_removeAllObjects];
        }
    }
}


//- (void)kh_removeObjectsInArray:(NSArray *)otherArray
//{
//    if ( self.kh_delegate == nil ) {
//        [self kh_removeObjectsInArray:otherArray];
//    }
//    else{
//        if ( self.count == 0 || otherArray.count == 0 ) {
//            return;
//        }
//        
//        NSInteger cnt = self.count;
//        NSMutableArray *indexArr = [[NSMutableArray alloc] init];
//        NSMutableArray *d_otherArray = [otherArray mutableCopy];
//        NSMutableArray *d_otherArray2 = [NSMutableArray new];
//        for ( int i=0; i<cnt ; i++ ) {
//            int j = 0;
//            while ( j < d_otherArray.count ) {
//                id object1 = d_otherArray[j];
//                id object2 = self[i];
//                if ( object1 == object2 ) {
//                    NSIndexPath *idx = [NSIndexPath indexPathForRow:i inSection:self.section ];
//                    [indexArr addObject: idx ];
//                    [d_otherArray removeObjectAtIndex: j ];
//                    [d_otherArray2 addObject:object1];
//                }
//                else{
//                    j++;
//                }
//            }
//        }
//        [self kh_removeObjectsInArray:otherArray];
//        if ( d_otherArray2.count > 0 && [(NSObject*)self.kh_delegate respondsToSelector:@selector(arrayRemoveSome:removeObjects:indexs:)] ) {
//            [self.kh_delegate arrayRemoveSome:self removeObjects:d_otherArray2 indexs:indexArr];
//        }
//    }
//}


- (void)kh_replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject
{
    if ( self.kh_delegate == nil ) {
        [self kh_replaceObjectAtIndex:index withObject:anObject];
    }
    else{
        id oldObj = [self objectAtIndex:index];
        [self kh_replaceObjectAtIndex:index withObject:anObject];
        if ( [(NSObject*)self.kh_delegate respondsToSelector:@selector(arrayReplace:newObject:replacedObject:index:)] ) {

            [self.kh_delegate arrayReplace:self newObject:anObject replacedObject:oldObj index:[NSIndexPath indexPathForRow:index inSection:self.section]];
        }
    }
}

- (void)update:(nonnull id)anObject
{
    NSInteger idx = -1;
    for ( NSInteger i=0; i<self.count; i++) {
        id obj = [self objectAtIndex: i ];
        if ( anObject == obj ) {
            idx = i;
            break;
        }
    }
    
    // 沒找到
    if ( idx == -1 ) {
        return;
    }
    
    if ( self.kh_delegate && [(NSObject*)self.kh_delegate respondsToSelector:@selector(arrayUpdate:update:index:)] ) {
        [self.kh_delegate arrayUpdate:self update:anObject index:[NSIndexPath indexPathForRow:idx inSection:self.section]];
    }
}

- (void)updateAll
{
    if ( self.kh_delegate && [(NSObject*)self.kh_delegate respondsToSelector:@selector(arrayUpdateAll:)] ) {
        [self.kh_delegate arrayUpdateAll:self];
    }
    
}



@end
