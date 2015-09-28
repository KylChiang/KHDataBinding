//
//  TableViewBindHelper.m
//  DataBindTest
//
//  Created by GevinChen on 2015/9/26.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import "TableViewBindHelper.h"


@implementation CKHObserverMutableArray

-(instancetype)init
{
    if (self  = [super init]) {
        _backArray = [NSMutableArray new];
    }
    return self;
}

#pragma mark - Public 


#pragma mark - Override

// override
- (void) addObject:(id)anObject
{
    if ( _delegate && [_delegate respondsToSelector:@selector(arrayAdd:newObject:index:)] ) {
        [_delegate arrayAdd:self newObject:anObject index:[NSIndexPath indexPathForRow:_backArray.count-1 inSection:_section]];
    }
    [_backArray addObject:anObject];
}

- (void) removeObject:(id)anObject
{
    for ( int i=0; i<self.count; i++) {
        id obj = [self objectAtIndex: i ];
        if ( anObject == obj ) {
            if ( _delegate && [_delegate respondsToSelector:@selector(arrayRemove:removeObject:index:)] ) {
                [_delegate arrayRemove:self removeObject:anObject index:[NSIndexPath indexPathForRow:i inSection:_section]];
            }
            break;
        }
    }
    [_backArray removeObject:anObject];
}

- (void)removeLastObject
{
    if ( _delegate && [_delegate respondsToSelector:@selector(arrayRemove:removeObject:index:)] ) {
        id lastObj = [_backArray lastObject];
        [_delegate arrayRemove:self removeObject:lastObj index:[NSIndexPath indexPathForRow:_backArray.count-1 inSection:_section]];
    }
    [_backArray removeLastObject];
}

- (void)removeObjectAtIndex:(NSUInteger)index
{
    if ( _delegate && [_delegate respondsToSelector:@selector(arrayRemove:removeObject:index:)] ) {
        id obj = [_backArray objectAtIndex:index];
        [_delegate arrayRemove:self removeObject:obj index:[NSIndexPath indexPathForRow:index inSection:_section]];
    }
    
    [_backArray removeObjectAtIndex:index];
}

- (void)insertObject:(id)anObject atIndex:(NSUInteger)index
{
    
    if ( _delegate && [_delegate respondsToSelector:@selector(arrayInsert:insertObject:index:)] ) {
        [_delegate arrayInsert:self insertObject:anObject index:[NSIndexPath indexPathForRow:index inSection:_section]];
    }
    
    [_backArray insertObject:anObject atIndex:index];
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject
{
    if ( _delegate && [_delegate respondsToSelector:@selector(replaceObjectAtIndex:withObject:)] ) {
        id oldObj = [_backArray objectAtIndex:index];
        [_delegate arrayReplace:self newObject:anObject replacedObject:oldObj index:[NSIndexPath indexPathForRow:index inSection:_section]];
    }
    [_backArray replaceObjectAtIndex:index withObject:anObject];
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

@implementation TableViewBindHelper

- (instancetype)init
{
    self = [super init];
    if (self) {
        _originArray = [[NSMutableArray alloc] initWithCapacity: 10 ];
        _cellStateDatas = [[NSMutableArray alloc] initWithCapacity: 10 ];
        _nibs = [[NSMutableArray alloc] initWithCapacity: 10 ];
        _listeners =[[NSMutableArray alloc] initWithCapacity: 5 ];
        _identifierMap = [[NSMutableDictionary alloc] initWithCapacity:10];
        _configMap = [[NSMutableDictionary alloc] initWithCapacity:10];
    }
    return self;
}


- (void)setTableView:(UITableView *)tableView
{
    _tableView = tableView;
    _tableView.delegate = self;
    _tableView.dataSource = self;
}

- (void)registerNib:(NSString*)nibName
{
    UINib *nib = [UINib nibWithNibName: nibName bundle:nil];
    if ( nib ) {
        [_nibs addObject: nib ];
    }
    else{
        NSException* exception = [NSException exceptionWithName:@"Xib file not found." reason:[NSString stringWithFormat:@"UINib is nil with %@", nibName ] userInfo:nil];
        @throw exception;
    }
}

// 指定 model class 對映什麼 identifier
- (void)setIdentifier:(NSString*)identifier mappingModel:(Class)modelClass
{
    [self setIdentifier:identifier mappingModel:modelClass cellConfig:nil];
}

- (void)setIdentifier:(NSString*)identifier mappingModel:(Class)modelClass cellConfig:(CellConfigBlock)configBlock
{
    NSString *modelName = NSStringFromClass(modelClass);
    [_identifierMap setObject:identifier forKey:modelName];
    
    if (configBlock) {
        [_configMap setObject:configBlock forKey:modelName];
    }
}

- (void)bindArray:(CKHObserverMutableArray*)array
{
    NSMutableArray *sectionArray = [[NSMutableArray alloc] initWithCapacity: 10 ];
    [_cellStateDatas addObject: sectionArray ];

    array.delegate = self;
    array.section = _originArray.count;
    [_originArray addObject: array ];
    for ( int i=0; i<array.count; i++) {
        [self arrayAdd:array newObject:array[i] index:[NSIndexPath indexPathForRow:i inSection:array.section]];
    }
}

// 新增
-(void)arrayAdd:(CKHObserverMutableArray*)array newObject:(id)object index:(NSIndexPath*)index
{
    // create 一個新的 cell state data
    NSMutableDictionary *cellData = [self createCellStateData:object];
    
    // 放到 array 裡
    NSMutableArray *sectionArray = _cellStateDatas[index.section];
    [sectionArray addObject: cellData ];
    
    // 更新 table view
    [_tableView insertRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationRight];
}

// 刪除
-(void)arrayRemove:(CKHObserverMutableArray*)array removeObject:(id)object index:(NSIndexPath*)index
{
    NSLog(@"section:%ld , row:%ld", index.section, index.row );
    // 刪除 cell state data
    NSMutableArray *sectionArray = _cellStateDatas[index.section];
    [sectionArray removeObjectAtIndex: index.row ];
    [_tableView deleteRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationLeft];
}

// 插入
-(void)arrayInsert:(CKHObserverMutableArray*)array insertObject:(id)object index:(NSIndexPath*)index
{
    // create 一個新的 cell state data
    NSMutableDictionary *cellData = [self createCellStateData:object];
    
    // 放到 array 裡
    NSMutableArray *sectionArray = _cellStateDatas[index.section];
    [sectionArray insertObject:cellData atIndex:index.row ];
    
    // 更新 table view
    [_tableView insertRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationMiddle];
}

// 取代
-(void)arrayReplace:(CKHObserverMutableArray*)array newObject:(id)newObj replacedObject:(id)oldObj index:(NSIndexPath*)index
{
    // create 一個新的 cell state data
    NSMutableDictionary *cellData = [self createCellStateData:newObj];
    
    // 放到 array 裡
    NSMutableArray *sectionArray = _cellStateDatas[index.section];
    [sectionArray insertObject:cellData atIndex:index.row ];
    
    // 更新 table view
    [_tableView reloadRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationFade];
}

// create 一個新的 cell state data
- (NSMutableDictionary*)createCellStateData:(id)model
{
    NSMutableDictionary *cellData = [[NSMutableDictionary alloc] initWithCapacity: 5 ];
    cellData[kCellModel] = model;
    NSString *modelName = NSStringFromClass([model class]);
    cellData[kCellIdentifier] = _identifierMap[modelName];
    
    CellConfigBlock configBlock = _configMap[modelName];
    if( configBlock ) cellData[kCellConfigBlock] = configBlock;
    
    return cellData;
}

#pragma mark - Private

- (CKHTableViewCell*)createCell:(NSString*)identifier
{
    CKHTableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier: identifier ];
    // 若取不到 cell ，在 ios 7 好像會發生例外，在ios8 就直接取回nil
    if (cell==nil) {
        for ( int i=0 ; i<_nibs.count; i++ ) {
            UINib *nib = _nibs[i];
            NSArray *viewArr = [nib instantiateWithOwner:nil options:nil];
            for ( int j=0; j<viewArr.count; j++ ) {
                CKHTableViewCell*_cell = viewArr[j];
                if ( [_cell.reuseIdentifier isEqualToString:identifier]) {
                    cell = _cell;
                    break;
                }
            }
            if ( cell ) {
                break;
            }
        }
    }
    
    return cell;
}

#pragma mark - Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSMutableArray *sectionArray = _cellStateDatas[ section ];
    return sectionArray.count;
}

// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *sectionArray = _cellStateDatas[indexPath.section];
    NSMutableDictionary *cellData = sectionArray[indexPath.row];
    
    // 記錄 index
    cellData[kCellIndex] = indexPath;
    // 取出 identifier，建立 cell
    NSString* identifier = cellData[kCellIdentifier];
    CKHTableViewCell* cell = [self createCell:identifier];
    // 記錄 cell 的高
    cellData[kCellHeight] = @(cell.frame.size.height);
    
    //
    cell.helper = self;
    cell.cellData = cellData;
    
    // 取出 model，待會要傳入載入資料的 method 裡
    id model = cellData[kCellModel];
    
    // 預設的載入資料
    [cell loadModel:model stateData:cellData ];
    
    // 自訂config
    CellConfigBlock cellConfig = cellData[kCellConfigBlock];
    if ( cellConfig ) {
        cellConfig( cell, indexPath, model, cellData );
    }
    
    return cell;
}

// Default is 1 if not implemented
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _cellStateDatas.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray* array = _cellStateDatas[indexPath.section];
    NSMutableDictionary* cellData = array[indexPath.row];
    NSNumber* height = cellData[kCellHeight];
    if ( height ) {
        return [height floatValue];
    }
    return 44;
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
//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
//{
//
//}

//- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
//{
//
//}

// return list of section titles to display in section index view (e.g. "ABCD...Z#")
//- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
//{
//
//}

#pragma mark - Public

- (void)refresh:(id)model
{
    for ( int i=0; i<_cellStateDatas.count; i++) {
        NSMutableArray *sectionArray = _cellStateDatas[i];
        for ( int j=0; j<sectionArray.count ; j++ ) {
            NSMutableDictionary *cellData = sectionArray[j];
            id _model = cellData[kCellModel];
            if ( _model == model ) {
                NSIndexPath* index = cellData[kCellIndex];
                [_tableView reloadRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationMiddle];
                break;
            }
        }
    }
}

- (void)refreshAll
{
    [_tableView reloadData];
}

- (void)addEventListener:(id)listener
{
    if ( ![_listeners containsObject: listener ]) {
        [_listeners addObject: listener ];
    }
}

- (void)removeListener:(id)listener
{
    [_listeners removeObject: listener ];
}

- (void)notify:(const NSString*)event userInfo:(id)userInfo
{
    for ( int i=0; i<_listeners.count; i++ ) {
        id<HelperEventDelegate> listener = _listeners[i];
        if ( [listener respondsToSelector:@selector(tableViewEvent:userInfo:)]) {
            [listener tableViewEvent:event userInfo:userInfo];
        }
    }
}




@end
