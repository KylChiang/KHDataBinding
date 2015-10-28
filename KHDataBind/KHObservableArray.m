//
//  KHObservableArray.m
//  KHDataBindDemo
//
//  Created by GevinChen on 2015/10/27.
//  Copyright © 2015年 omg. All rights reserved.
//

#import "KHObservableArray.h"


@implementation KHObservableArray

-(instancetype)init
{
    if (self  = [super init]) {
        _backArray = [NSMutableArray new];
    }
    return self;
}

-(instancetype)initWithArray:(NSArray *)array
{
    if (self=[super init]) {
        _backArray = [[NSMutableArray alloc] initWithArray:array];
    }
    return self;
}

#pragma mark - Public

-(void)update:(id)object
{
    if ( [_backArray containsObject: object ] ) {
        for ( int i=0; i<_backArray.count ; i++ ) {
            id _obj = _backArray[i];
            if ( _obj == object ) {
                if ( _delegate && [_delegate respondsToSelector:@selector(arrayUpdate:update:index:)] ) {
                    [_delegate arrayUpdate:self update:object index:[NSIndexPath indexPathForRow:i inSection:_section]];
                }
                break;
            }
        }
    }
}

-(void)updateAll
{
    if ( _delegate && [_delegate respondsToSelector:@selector(arrayUpdateAll:)] ) {
        [_delegate arrayUpdateAll:self];
    }
}

#pragma mark - Override

// override
- (void) addObject:(id)anObject
{
    [_backArray addObject:anObject];
    if ( _delegate && [_delegate respondsToSelector:@selector(arrayAdd:newObject:index:)] ) {
        [_delegate arrayAdd:self newObject:anObject index:[NSIndexPath indexPathForRow:_backArray.count-1 inSection:_section]];
    }
}

- (void) addObjectsFromArray:(NSArray *)otherArray
{
    [_backArray addObjectsFromArray:otherArray];
    if ( _delegate && [_delegate respondsToSelector:@selector(arrayAdd:newObjects:indexs:)] ) {
        NSMutableArray *indexs = [NSMutableArray array];
        for ( int i=0; i<otherArray.count; i++) {
            NSIndexPath *index = [NSIndexPath indexPathForRow:_backArray.count-otherArray.count+i inSection:_section];
            [indexs addObject:index];
        }
        [_delegate arrayAdd:self newObjects:otherArray indexs:indexs];
    }
}


- (void) removeObject:(id)anObject
{
    if (_backArray.count == 0 ) {
        return;
    }
    
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
    
    [_backArray removeObjectAtIndex: idx ];
    if ( _delegate && [_delegate respondsToSelector:@selector(arrayRemove:removeObject:index:)] ) {
        [_delegate arrayRemove:self removeObject:anObject index:[NSIndexPath indexPathForRow:idx inSection:_section]];
    }
    
}

- (void)removeLastObject
{
    if (_backArray.count == 0 ) {
        return;
    }
    id lastObj = [_backArray lastObject];
    [_backArray removeLastObject];
    if ( _delegate && [_delegate respondsToSelector:@selector(arrayRemove:removeObject:index:)] ) {
        [_delegate arrayRemove:self removeObject:lastObj index:[NSIndexPath indexPathForRow:_backArray.count-1 inSection:_section]];
    }
}

- (void)removeObjectAtIndex:(NSUInteger)index
{
    if ( _backArray.count == 0 || _backArray.count <= index ) {
        return;
    }
    id obj = [_backArray objectAtIndex:index];
    [_backArray removeObjectAtIndex:index];
    if ( _delegate && [_delegate respondsToSelector:@selector(arrayRemove:removeObject:index:)] ) {
        [_delegate arrayRemove:self removeObject:obj index:[NSIndexPath indexPathForRow:index inSection:_section]];
    }
}

- (void)removeAllObjects
{
    if (_backArray.count == 0 ) {
        return;
    }
    NSInteger cnt = _backArray.count;
    [_backArray removeAllObjects];
    if ( _delegate && [_delegate respondsToSelector:@selector(arrayRemoveAll:indexs:)] ) {
        NSMutableArray *indexArr = [[NSMutableArray alloc] init];
        for ( int i=0; i<cnt ; i++ ) {
            NSIndexPath *idx = [NSIndexPath indexPathForRow:i inSection:_section ];
            [indexArr addObject: idx ];
        }
        [_delegate arrayRemoveAll:self indexs:indexArr];
    }
}

- (void)insertObject:(id)anObject atIndex:(NSUInteger)index
{
    if (index >= _backArray.count ) {
        index = _backArray.count;
    }
    
    [_backArray insertObject:anObject atIndex:index];
    if ( _delegate && [_delegate respondsToSelector:@selector(arrayInsert:insertObject:index:)] ) {
        [_delegate arrayInsert:self insertObject:anObject index:[NSIndexPath indexPathForRow:index inSection:_section]];
    }
    
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject
{
    [_backArray replaceObjectAtIndex:index withObject:anObject];
    if ( _delegate && [_delegate respondsToSelector:@selector(replaceObjectAtIndex:withObject:)] ) {
        id oldObj = [_backArray objectAtIndex:index];
        [_delegate arrayReplace:self newObject:anObject replacedObject:oldObj index:[NSIndexPath indexPathForRow:index inSection:_section]];
    }
}

- (NSUInteger)count
{
    return _backArray.count;
}

- (id)objectAtIndex:(NSUInteger)index
{
    return _backArray[index];
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx
{
    return _backArray[idx];
}

@end
