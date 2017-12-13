//
//  NSArray+KHSwizzle.m
//
//  Created by GevinChen on 2015/12/10.
//  Copyright © 2015年 GevinChen. All rights reserved.
//

#import "NSMutableArray+KHSwizzle.h"
#import <objc/runtime.h>
#import <objc/message.h>


@implementation NSMutableArray (KHSwizzle)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //  Gevin note : 使用 NSMutableArray 必須直接指定使用 __NSArrayM 為 class name
        //               原因好像是說 NSMutableArray 它是一個 class cluster，它的實體會隱
        //               藏 class type，實際的 class type 就叫 __NSArrayM
        Class class = NSClassFromString(@"__NSArrayM");  //[self class];
        // When swizzling a class method, use the following:
        // Class class = object_getClass((id)self);
        [self kh_swizzleMethod:@selector(addObjectsFromArray:) withNewMethod:@selector(kh_addObjectsFromArray:) class:class];
        [self kh_swizzleMethod:@selector(removeObjectAtIndex:) withNewMethod:@selector(kh_removeObjectAtIndex:) class:class];
        [self kh_swizzleMethod:@selector(removeObjectsInArray:) withNewMethod:@selector(kh_removeObjectsInArray:) class:class];
        [self kh_swizzleMethod:@selector(removeAllObjects) withNewMethod:@selector(kh_removeAllObjects) class:class];
        [self kh_swizzleMethod:@selector(insertObject:atIndex:) withNewMethod:@selector(kh_insertObject:atIndex:) class:class];
        [self kh_swizzleMethod:@selector(insertObjects:atIndexes:) withNewMethod:@selector(kh_insertObjects:atIndexes:) class:class];
        [self kh_swizzleMethod:@selector(replaceObjectAtIndex:withObject:) withNewMethod:@selector(kh_replaceObjectAtIndex:withObject:) class:class];
    });
}

+ (void)kh_swizzleMethod:(SEL)originalSelector withNewMethod:(SEL)swizzledSelector class:(Class)class
{

    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    BOOL didAddMethod = class_addMethod(class,
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

const void *kh_delegate_key;

- (void)setKh_delegate:(id)kh_delegate
{
    objc_setAssociatedObject(self, &kh_delegate_key, kh_delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC );
}

-(id)kh_delegate
{
    id delegate = objc_getAssociatedObject(self, &kh_delegate_key);
    return delegate;
}

const void *kh_section_key;

-(void)setKh_section:(NSInteger)kh_section
{
    objc_setAssociatedObject(self, &kh_section_key, @(kh_section), OBJC_ASSOCIATION_RETAIN_NONATOMIC );
}

-(NSInteger)kh_section
{
    NSNumber *sectionNum = objc_getAssociatedObject(self, &kh_section_key);
    if (sectionNum) {
        NSInteger _sect = [sectionNum integerValue];
        return _sect;
    }
    return 0;
}

const void *addObjectsFlag_key;

-(void)setAddObjectsFlag:(BOOL)addObjectsFlag
{
    objc_setAssociatedObject(self, &addObjectsFlag_key, @(addObjectsFlag), OBJC_ASSOCIATION_RETAIN_NONATOMIC );
}

-(BOOL)addObjectsFlag
{
    NSNumber *flag = objc_getAssociatedObject(self, &addObjectsFlag_key);
    if (flag) {
        BOOL value = [flag boolValue];
        return value;
    }
    return NO;
}


const void *removeObjectsFlag_key;

-(void)setRemoveObjectsFlag:(BOOL)removeObjectsFlag
{
    objc_setAssociatedObject(self, &removeObjectsFlag_key, @(removeObjectsFlag), OBJC_ASSOCIATION_RETAIN_NONATOMIC );
}

-(BOOL)removeObjectsFlag
{
    NSNumber *flag = objc_getAssociatedObject(self, &removeObjectsFlag_key);
    if (flag) {
        BOOL value = [flag boolValue];
        return value;
    }
    return NO;
}




#pragma mark - swizzle

- (void)kh_addObjectsFromArray:(NSArray*)otherArray
{
    if ( self.kh_delegate == nil ) {
        [self kh_addObjectsFromArray:otherArray];
    }
    else{
        if ( otherArray && otherArray.count > 0 ) {
            NSInteger original_cnt = self.count;
            //  有些版本的 os，addObjectsFromArray 會執行 insertObject，有的不會
            self.addObjectsFlag = YES;
            [self kh_addObjectsFromArray:otherArray];
            self.addObjectsFlag = NO;
            if ( [(NSObject*)self.kh_delegate respondsToSelector:@selector(insertObjects:indexs:inArray:)] ) {
                NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSetWithIndexesInRange:(NSRange){original_cnt,otherArray.count}];
                [self.kh_delegate insertObjects:otherArray indexs:indexSet inArray:self];
            }            
        }
        else{
            [self kh_addObjectsFromArray:otherArray];
        }
    }
}

- (void)kh_insertObject:(id)anObject atIndex:(NSUInteger)index
{
    if ( self.kh_delegate == nil ) {
        [self kh_insertObject:anObject atIndex:index]; // 執行舊的 method
    }
    else{
        [self kh_insertObject:anObject atIndex:index];
        //  呼叫 addObjectsFromArray，最後會呼叫到這裡
        if (self.addObjectsFlag) return;
        if ( [(NSObject*)self.kh_delegate respondsToSelector:@selector(insertObject:index:inArray:)] ) {
            [self.kh_delegate insertObject:anObject index:index inArray:self];
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
        if ( [(NSObject*)self.kh_delegate respondsToSelector:@selector(insertObjects:indexs:inArray:)] ) {
            [self.kh_delegate insertObjects:objects indexs:indexes inArray:self];
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
        
        //  呼叫 removeObjectsInArray: 也會觸發這裡，所以加個 flag 擋住
        if( self.removeObjectsFlag ) return;
        if ( [(NSObject*)self.kh_delegate respondsToSelector:@selector(removeObject:index:inArray:)] ) {
            [self.kh_delegate removeObject:obj index:index inArray:self];
        }
    }
}

- (void)kh_removeObjectsInArray:(NSArray*)otherArray
{
    if ( self.kh_delegate == nil ) {
        [self kh_removeObjectsInArray:otherArray];
    }
    else{
        if (self.count == 0 ) {
            return;
        }
        if ( [(NSObject*)self.kh_delegate respondsToSelector:@selector(removeObjects:indexs:inArray:)] ) {            
            NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
            for ( id obj in otherArray ) {
                NSUInteger index = [self indexOfObject:obj];
                [indexSet addIndex:index];
            }
            self.removeObjectsFlag = YES;
            [self kh_removeObjectsInArray:otherArray];
            self.removeObjectsFlag = NO;
            [self.kh_delegate removeObjects:otherArray indexs:indexSet inArray:self];
        }
        else{
            [self kh_removeObjectsInArray:otherArray];
        }
    }
}

- (void)kh_removeAllObjects
{
    if ( self.kh_delegate == nil ) {
        [self kh_removeAllObjects];
    }
    else{
        if (self.count > 0 ) {
            if ( [(NSObject*)self.kh_delegate respondsToSelector:@selector(removeObjects:indexs:inArray:)] ) {
                NSArray *removeObjects = [self copy];
                NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSetWithIndexesInRange:(NSRange){0,removeObjects.count}];
                [self kh_removeAllObjects];
                [self.kh_delegate removeObjects:removeObjects indexs:indexSet inArray:self];
            }
            else{
                [self kh_removeAllObjects];
            }
        }
        else{
            [self kh_removeAllObjects];
        }
    }
}

- (void)kh_replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject
{
    if ( self.kh_delegate == nil ) {
        [self kh_replaceObjectAtIndex:index withObject:anObject];
    }
    else{
        id oldObj = [self objectAtIndex:index];
        [self kh_replaceObjectAtIndex:index withObject:anObject];
        if ( [(NSObject*)self.kh_delegate respondsToSelector:@selector(replacedObject:newObject:index:inArray:)] ) {
            [self.kh_delegate replacedObject:oldObj newObject:anObject index:index inArray:self];
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
    
    if ( self.kh_delegate && [(NSObject*)self.kh_delegate respondsToSelector:@selector(update:index:inArray:)] ) {
        [self.kh_delegate update:anObject index:idx inArray:self];
    }
}

//- (void)updateAll
//{
//    if ( self.kh_delegate && [(NSObject*)self.kh_delegate respondsToSelector:@selector(arrayUpdateAll:)] ) {
//        [self.kh_delegate arrayUpdateAll:self];
//    }
//    
//}



@end
