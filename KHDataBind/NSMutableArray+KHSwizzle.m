//
//  NSArray+KHSwizzle.m
//  KHDataBindDemo
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
        [self kh_swizzleMethod:@selector(addObject:) withNewMethod:@selector(kh_addObject:)];
        [self kh_swizzleMethod:@selector(addObjectsFromArray:) withNewMethod:@selector(kh_addObjectsFromArray:)];
        [self kh_swizzleMethod:@selector(removeObject:) withNewMethod:@selector(kh_removeObject:)];
        [self kh_swizzleMethod:@selector(removeLastObject) withNewMethod:@selector(kh_removeLastObject)];
        [self kh_swizzleMethod:@selector(removeObjectAtIndex:) withNewMethod:@selector(kh_removeObjectAtIndex:)];
        [self kh_swizzleMethod:@selector(removeAllObjects) withNewMethod:@selector(kh_removeAllObjects)];
        [self kh_swizzleMethod:@selector(insertObject:atIndex:) withNewMethod:@selector(kh_insertObject:atIndex:)];
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


- (void)kh_addObject:(id)object
{
    [self kh_addObject:object]; // call original addObject: method
    if ( self.kh_delegate && [(NSObject*)self.kh_delegate respondsToSelector:@selector(arrayAdd:newObject:index:)] ) {
        [self.kh_delegate arrayAdd:self newObject:object index:[NSIndexPath indexPathForRow:self.count-1 inSection:self.section]];
    }
}

- (void)kh_addObjectsFromArray:(NSArray*)otherArray
{
    if ( otherArray == nil || otherArray.count == 0 ) {
        return;
    }
    [self kh_addObjectsFromArray:otherArray];
    if ( self.kh_delegate && [(NSObject*)self.kh_delegate respondsToSelector:@selector(arrayAdd:newObjects:indexs:)] ) {
        NSMutableArray *indexs = [NSMutableArray array];
        for ( int i=0; i<otherArray.count; i++) {
            NSIndexPath *index = [NSIndexPath indexPathForRow:self.count-otherArray.count+i inSection:self.section];
            [indexs addObject:index];
        }
        [self.kh_delegate arrayAdd:self newObjects:otherArray indexs:indexs];
    }

}

- (void)kh_removeObject:(id)anObject
{
//    if (self.count == 0 ) {
//        return;
//    }
    
    int idx = -1;
    for ( int i=0; i<self.count; i++) {
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
    
    [self kh_removeObject:anObject ];
    if ( self.kh_delegate && [(NSObject*)self.kh_delegate respondsToSelector:@selector(arrayRemove:removeObject:index:)] ) {
        [self.kh_delegate arrayRemove:self removeObject:anObject index:[NSIndexPath indexPathForRow:idx inSection:self.section]];
    }

}

- (void)kh_removeLastObject
{
    if (self.count == 0 ) {
        return;
    }
    id lastObj = [self lastObject];
    [self kh_removeLastObject];
    if ( self.kh_delegate && [(NSObject*)self.kh_delegate respondsToSelector:@selector(arrayRemove:removeObject:index:)] ) {
        [self.kh_delegate arrayRemove:self removeObject:lastObj index:[NSIndexPath indexPathForRow:self.count-1 inSection:self.section]];
    }
}

- (void)kh_removeObjectAtIndex:(NSUInteger)index
{
    id obj = [self objectAtIndex:index];
    [self kh_removeObjectAtIndex:index];
    if ( self.kh_delegate && [(NSObject*)self.kh_delegate respondsToSelector:@selector(arrayRemove:removeObject:index:)] ) {
        [self.kh_delegate arrayRemove:self removeObject:obj index:[NSIndexPath indexPathForRow:index inSection:self.section]];
    }

}

- (void)kh_removeAllObjects
{
    if (self.count == 0 ) {
        return;
    }
    NSInteger cnt = self.count;
    [self kh_removeAllObjects];
    if ( self.kh_delegate && [(NSObject*)self.kh_delegate respondsToSelector:@selector(arrayRemoveAll:indexs:)] ) {
        NSMutableArray *indexArr = [[NSMutableArray alloc] init];
        for ( int i=0; i<cnt ; i++ ) {
            NSIndexPath *idx = [NSIndexPath indexPathForRow:i inSection:self.section ];
            [indexArr addObject: idx ];
        }
        [self.kh_delegate arrayRemoveAll:self indexs:indexArr];
    }
}

- (void)kh_insertObject:(id)anObject atIndex:(NSUInteger)index
{
    
    [self kh_insertObject:anObject atIndex:index];
    if ( self.kh_delegate && [(NSObject*)self.kh_delegate respondsToSelector:@selector(arrayInsert:insertObject:index:)] ) {
        [self.kh_delegate arrayInsert:self insertObject:anObject index:[NSIndexPath indexPathForRow:index inSection:self.section]];
    }
}

- (void)kh_replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject
{
    [self kh_replaceObjectAtIndex:index withObject:anObject];
    if ( self.kh_delegate && [(NSObject*)self.kh_delegate respondsToSelector:@selector(replaceObjectAtIndex:withObject:)] ) {
        id oldObj = [self objectAtIndex:index];
        [self.kh_delegate arrayReplace:self newObject:anObject replacedObject:oldObj index:[NSIndexPath indexPathForRow:index inSection:self.section]];
    }
}

//- (id)kh_objectAtIndex:(NSUInteger)index
//{
//    
//}
//
//- (id)kh_objectAtIndexedSubscript:(NSUInteger)idx
//{
//    
//}


@end
