//
//  TableViewBindHelper.m
//  DataBindTest
//
//  Created by GevinChen on 2015/9/26.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import "KHTableViewBindHelper.h"


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
    [_backArray removeLastObject];
    if ( _delegate && [_delegate respondsToSelector:@selector(arrayRemove:removeObject:index:)] ) {
        id lastObj = [_backArray lastObject];
        [_delegate arrayRemove:self removeObject:lastObj index:[NSIndexPath indexPathForRow:_backArray.count-1 inSection:_section]];
    }
}

- (void)removeObjectAtIndex:(NSUInteger)index
{
    if ( _backArray.count == 0 || _backArray.count <= index ) {
        return;
    }
    [_backArray removeObjectAtIndex:index];
    if ( _delegate && [_delegate respondsToSelector:@selector(arrayRemove:removeObject:index:)] ) {
        id obj = [_backArray objectAtIndex:index];
        [_delegate arrayRemove:self removeObject:obj index:[NSIndexPath indexPathForRow:index inSection:_section]];
    }
}

- (void)removeAllObjects
{
    if (_backArray.count == 0 ) {
        return;
    }
    [_backArray removeAllObjects];
    if ( _delegate && [_delegate respondsToSelector:@selector(arrayRemoveAll:)] ) {
        [_delegate arrayRemoveAll:self];
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

@implementation KHTableViewBindHelper

- (instancetype)init
{
    self = [super init];
    if (self) {
        _sectionArray = [[NSMutableArray alloc] initWithCapacity: 10 ];
        _listeners =[[NSMutableArray alloc] initWithCapacity: 5 ];
    }
    return self;
}

- (instancetype)initWithTableView:(UITableView*)tableView
{
    self = [super init];
    if (self) {
        _sectionArray = [[NSMutableArray alloc] initWithCapacity: 10 ];
        _listeners =[[NSMutableArray alloc] initWithCapacity: 5 ];
        self.tableView = tableView;
    }
    return self;
}

#pragma mark - Property

- (void)setTableView:(UITableView *)tableView
{
    _tableView = tableView;
    _tableView.delegate = self;
    _tableView.dataSource = self;
}

#pragma mark - Public


- (nonnull KHObservableArray*)createBindArray
{
    return [self createBindArrayFromNSArray:nil ];
}

- (nonnull KHObservableArray*)createBindArrayFromNSArray:(nullable NSArray*)array
{
    KHObservableArray *bindArray = nil;
    if (array) {
        bindArray = [[KHObservableArray alloc] initWithArray:array];
    }
    else{
        bindArray = [[KHObservableArray alloc] init];
    }
    [self bindArray:bindArray];
    return bindArray;
}

- (void)setHeaderTitles:(nullable NSArray*)titles
{
    _titles = [titles copy];
}


- (void)bindArray:(nonnull KHObservableArray*)array
{
    array.delegate = self;
    array.section = _sectionArray.count;
    [_sectionArray addObject: array ];
}

- (nullable KHObservableArray*)getArray:(NSInteger)section
{
    return _sectionArray[section];
}

- (void)addEventListener:(nonnull id)listener
{
    if ( ![_listeners containsObject: listener ]) {
        [_listeners addObject: listener ];
    }
}

- (void)removeListener:(nonnull id)listener
{
    [_listeners removeObject: listener ];
}

- (void)notify:(nonnull const NSString*)event userInfo:(nullable id)userInfo
{
    for ( int i=0; i<_listeners.count; i++ ) {
        id<HelperEventDelegate> listener = _listeners[i];
        if ( [listener respondsToSelector:@selector(tableViewEvent:userInfo:)]) {
            [listener tableViewEvent:event userInfo:userInfo];
        }
    }
}

//  設定點到 cell 後要做什麼處理
- (void)setCellSelectedHandler:(nonnull id)target
{
    _target = target;
    _action = @selector(tableView:didSelectRowAtIndexPath:);
    
    NSMethodSignature* signature1 = [_target methodSignatureForSelector:_action];
    invocation = [NSInvocation invocationWithMethodSignature:signature1];
    [invocation setTarget:_target];
    [invocation setSelector:_action];
}

//  設定需要監聽的 ui control 及事件
- (void)tagUIControl:(nonnull UIControl*)control tag:(nonnull NSString*)tag
{
    if (_uiDic==nil) {
        _uiDic = [[NSMutableDictionary alloc] initWithCapacity:5];
    }
    
    NSMutableArray *uiArr = _uiDic[tag];
    
    if ( uiArr == nil ) {
        uiArr = [[NSMutableArray alloc ] init];
        [_uiDic setObject:uiArr forKey:tag];
    }
    
    [uiArr addObject:control];
    
    //
    [control addTarget:self action:@selector(controlEventTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    
    [control addTarget:self action:@selector(controlEventValueChanged:) forControlEvents:UIControlEventValueChanged];
    
}

//  UI Event
- (void)addTarget:(nonnull id)target action:(nonnull SEL)action event:(UIControlEvents)event forTag:(nonnull NSString*)tag
{
    NSMethodSignature* signature1 = [target methodSignatureForSelector:action];
    NSInvocation *eventInvocation = [NSInvocation invocationWithMethodSignature:signature1];
    [eventInvocation setTarget:target];
    [eventInvocation setSelector:action];
    
    if ( _invocationDic == nil ) {
        _invocationDic = [[NSMutableDictionary alloc] initWithCapacity: 5 ];
    }
    
    NSMutableDictionary *eventDic = [_invocationDic objectForKey: tag ];
    if ( eventDic == nil ) {
        eventDic = [NSMutableDictionary new];
        [_invocationDic setObject:eventDic forKey:tag];
    }
    
    NSString *eventKey = [NSString stringWithFormat:@"%ld", event ];
    [eventDic setObject: eventInvocation forKey:eventKey ];
    
}

//
- (void)removeTarget:(nonnull id)target action:(nullable SEL)action forTag:(NSString*)tag
{
    NSMutableDictionary *_eventDic = _invocationDic[tag];
    if ( _eventDic ) {
        NSArray *allkeys = [_eventDic allKeys];
        for ( NSString *key in allkeys ) {
            NSInvocation *invo = _eventDic[key];
            if (invo.target == target && invo.selector == action ) {
                [_eventDic removeObjectForKey:key];
                break;
            }
        }
    }
}

//
- (void)removeTarget:(nonnull id)target forTag:(NSString*)tag
{
    NSMutableDictionary *_eventDic = _invocationDic[tag];
    if ( _eventDic ) {
        NSArray *allkeys = [_eventDic allKeys];
        for ( NSString *key in allkeys ) {
            NSInvocation *invo = _eventDic[key];
            if (invo.target == target ) {
                [_eventDic removeObjectForKey:key];
            }
        }
    }
}

//
- (nullable id)getTargetByAction:(nonnull SEL)action forTag:(NSString*)tag
{
    NSMutableDictionary *_eventDic = _invocationDic[tag];
    if ( _eventDic ) {
        NSArray *allkeys = [_eventDic allKeys];
        for ( NSString *key in allkeys ) {
            NSInvocation *invo = _eventDic[key];
            if (invo.selector == action ) {
                return invo.target;
            }
        }
    }
    return nil;
}


#pragma mark - Private

//  監聽的 ui control 發出事件
- (void)eventCall:(UIControlEvents)event ui:(UIControl*)ui
{
    NSString *tag = nil;
    KHTableViewCell *cell = nil;

    // 找出自己的 parent cell
    UIView *view = ui;
    while (!cell) {
        if ( view.superview == nil ) {
            break;
        }
        if ( [view.superview isKindOfClass:[KHTableViewCell class]]) {
            cell = view.superview;
        }
        else{
            view = view.superview;
        }
    }
    
    NSString *eventString = [NSString stringWithFormat:@"%ld", event ];
    
    //  先找出 ui 的 tag
    NSArray *allkeys = [_uiDic allKeys];
    for ( NSString *key in allkeys ) {
        NSMutableArray *uiArr = _uiDic[ key ];
        for ( int i=0; i<uiArr.count; i++ ) {
            id _ui = uiArr[i];
            if ( _ui == ui ) {
                tag = key;
                break;
            }
        }
        if ( tag ) {
            break;
        }
    }
    
    //
    NSDictionary *eventDic = [_invocationDic objectForKey:tag];
    
    if ( eventDic == nil ) return;
    
    NSInvocation *invo = eventDic[eventString];
    id model = cell.model;
    [invo setArgument:&ui    atIndex:2];
    [invo setArgument:&model atIndex:3];
    [invo invoke];
    
}

- (void)controlEventTouchUpInside:(id)ui
{
    [self eventCall:UIControlEventTouchUpInside ui:ui];
}

- (void)controlEventValueChanged:(id)ui
{
    [self eventCall:UIControlEventValueChanged ui:ui];
}


#pragma mark - Array Observe

// 新增
-(void)arrayAdd:(KHObservableArray*)array newObject:(id)object index:(NSIndexPath*)index
{
//    NSLog(@"add section:%ld , row:%ld", index.section, index.row );
    // 更新 table view
    [_tableView insertRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationBottom];
//    [_tableView reloadSections:[NSIndexSet indexSetWithIndex:index.section] withRowAnimation:UITableViewRowAnimationBottom];
}

-(void)arrayAdd:(KHObservableArray *)array newObjects:(NSArray *)objects indexs:(NSArray *)indexs
{
    [_tableView insertRowsAtIndexPaths:indexs withRowAnimation:UITableViewRowAnimationBottom];
}

// 刪除
-(void)arrayRemove:(KHObservableArray*)array removeObject:(id)object index:(NSIndexPath*)index
{
    //    NSLog(@"remove section:%ld , row:%ld", index.section, index.row );
    // 刪除 cell state data
    [_tableView deleteRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationTop];
}

// 刪除全部
-(void)arrayRemoveAll:(KHObservableArray *)array
{
    //    NSLog(@"remove all section:%ld", array.section );
    [_tableView deleteSections:[NSIndexSet indexSetWithIndex:array.section] withRowAnimation:UITableViewRowAnimationTop];
}

// 插入
-(void)arrayInsert:(KHObservableArray*)array insertObject:(id)object index:(NSIndexPath*)index
{
//    NSLog(@"insert section:%ld , row:%ld", index.section, index.row );
    // 更新 table view
    [_tableView insertRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationBottom];
}

// 取代
-(void)arrayReplace:(KHObservableArray*)array newObject:(id)newObj replacedObject:(id)oldObj index:(NSIndexPath*)index
{
//    NSLog(@"replace section:%ld , row:%ld", index.section, index.row );

    // 更新 table view
    [_tableView reloadRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationMiddle];
}

// 更新
-(void)arrayUpdate:(KHObservableArray*)array update:(id)object index:(NSIndexPath*)index
{
//    NSLog(@"update section:%ld , row:%ld", index.section, index.row );

    [_tableView reloadRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationMiddle];
}

-(void)arrayUpdateAll:(KHObservableArray *)array
{
    [_tableView reloadSections:[NSIndexSet indexSetWithIndex:array.section] withRowAnimation:UITableViewRowAnimationAutomatic];
}


#pragma mark - Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    KHObservableArray *models = _sectionArray[section];
//    NSLog(@"number of row:%ld", models.count );
    return models.count;
}

// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *modelArray = _sectionArray[indexPath.section];
    KHCellModel *model = modelArray[indexPath.row];
    
    // 記錄 index
    model.index = indexPath;
    
    // 取出 identifier，建立 cell
    NSString* identifier = model.identifier;
    
    KHTableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier: identifier ];
    // 若取不到 cell ，在 ios 7 好像會發生例外，在ios8 就直接取回nil
    if (cell==nil) {
        //  若 model 有設定 create block，就使用 model 的
        if ( model.onCreateBlock ) {
            cell = model.onCreateBlock( model );
        }
        else{
            //  helper 預設的方式
            if ( model.nibName == nil ) {
                NSException* exception = [NSException exceptionWithName:@"Cell nib name is nil." reason:@"Cell nib name is nil." userInfo:nil];
                @throw exception;
            }
            UINib *nib = [UINib nibWithNibName: model.nibName bundle:nil];
            if ( nib ) {
                NSArray *viewArr = [nib instantiateWithOwner:nil options:nil];
                for ( int j=0; j<viewArr.count; j++ ) {
                    KHTableViewCell*_cell = viewArr[j];
                    if ( [_cell.reuseIdentifier isEqualToString:identifier]) {
                        cell = _cell;
                        break;
                    }
                }
            }
            else{
                NSException* exception = [NSException exceptionWithName:@"Xib file not found." reason:[NSString stringWithFormat:@"UINib is nil with %@", model.nibName ] userInfo:nil];
                @throw exception;
            }
        }
        
        //  assign reference
        cell.helper = self;
        cell.model = model;
        
        //  初始 cell
        if ( model.onInitBlock ){
             model.onInitBlock( cell, model );
        }
        else{
            [cell onInit:model];
        }
    }
    else{
        //  assign reference
        cell.helper = self;
        cell.model = model;
    }
    
    //  記錄 cell 的高
    model.cellHeight = cell.frame.size.height;
    
    //  把 model 載入 cell
    if ( model.onLoadBlock ) {
        model.onLoadBlock( cell, model );
    }
    else {
        [cell onLoad:model];
    }
    
    return cell;
}

// Default is 1 if not implemented
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _sectionArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    KHObservableArray* array = _sectionArray[indexPath.section];
    KHCellModel *model = array[indexPath.row];
    float height = model.cellHeight;
    if ( height == 0 ) {
//        printf("%ld height 44\n", indexPath.row);
        return 44;
    }
//    printf("%ld height %f\n", indexPath.row, height);
    return height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [invocation setArgument:&tableView atIndex:2];
    [invocation setArgument:&indexPath atIndex:3];
    [invocation invoke];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}


//- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
//{
//    
//}

//- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
//{
//    
//}

// fixed font style. use custom view (UILabel) if you want something different
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ( section < _sectionArray.count && section < _titles.count ) {
        return _titles[ section ];
    }
    return nil;
}

//- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
//{
//
//}

// return list of section titles to display in section index view (e.g. "ABCD...Z#")
//- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
//{
//
//}


@end
