//
//  TableViewBindHelper.m
//  DataBindTest
//
//  Created by GevinChen on 2015/9/26.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import "KHDataBinder.h"
#import <objc/runtime.h>
#import <CCBottomRefreshControl/UIScrollView+BottomRefreshControl.h>


//  記錄有指定哪些 cell 的 ui 需要被監聽
@interface KHCellEventHandler : NSObject

@property (nonatomic,assign) KHDataBinder *binder;
@property (nonatomic) Class cellClass;
@property (nonatomic) NSString *propertyName;
@property (nonatomic) UIControlEvents event;
@property (nonatomic) NSInvocation *invo;
//@property (nonatomic) SEL action;

- (void)eventHandle:(id)ui;

@end

@implementation KHCellEventHandler

- (void)eventHandle:(id)ui
{
    id cell = nil;
    
    // 找出 ui control 的 parent cell
    UIView *view = ui;
    while (!cell) {
        if ( view.superview == nil ) {
            break;
        }
        if ( [view.superview isKindOfClass: [UITableViewCell class] ] || [view.superview isKindOfClass:[UICollectionViewCell class]]) {
            cell = view.superview;
        }
        else{
            view = view.superview;
        }
    }
    
    //  取出 cell 對映的 model
    id model = [self.binder getDataModelWithCell: cell];
    //  執行事件處理 method
    UIControl *control = ui;
    [self.invo setArgument:&control atIndex:2];
    [self.invo setArgument:&model atIndex:3];
    [self.invo invoke];
}

@end


@implementation KHDataBinder

- (instancetype)init
{
    self = [super init];
    if (self) {
        _sectionArray = [[NSMutableArray alloc] initWithCapacity: 10 ];
        _proxyDic   = [[NSMutableDictionary alloc] initWithCapacity: 5 ];
        _modelBindMap = [[NSMutableDictionary alloc] initWithCapacity: 5 ];
//        _cellCreateDic= [[NSMutableDictionary alloc] initWithCapacity: 5 ];
        _cellLoadDic= [[NSMutableDictionary alloc] initWithCapacity: 5 ];
        
        //  init UIRefreshControl
        _refreshHeadControl = [[UIRefreshControl alloc] init];
        _refreshHeadControl.backgroundColor = [UIColor whiteColor];
        _refreshHeadControl.tintColor = [UIColor lightGrayColor]; // spinner color
        [_refreshHeadControl addTarget:self
                                action:@selector(refreshHead:)
                      forControlEvents:UIControlEventValueChanged];
        NSDictionary *attributeDic = @{NSForegroundColorAttributeName:[UIColor lightGrayColor],
                                       NSFontAttributeName:[UIFont boldSystemFontOfSize:14]};
        refreshTitle1 = [[NSAttributedString alloc] initWithString:@"Pull down to reload!" attributes:attributeDic];
        //    refreshTitle2 = [[NSAttributedString alloc] initWithString:@"Last Update:2015-12-12 10:10:34" attributes:attributeDic];
        _refreshHeadControl.attributedTitle = refreshTitle1;//[[NSAttributedString alloc] initWithString:@"Pull down to reload!" attributes:attributeDic];
        refreshState = 1;
        
        _refreshFootControl = [[UIRefreshControl alloc] init];
        _refreshFootControl.backgroundColor = [UIColor whiteColor];
        _refreshFootControl.tintColor = [UIColor lightGrayColor]; // spinner color
        [_refreshFootControl addTarget:self
                                action:@selector(refreshFoot:)
                      forControlEvents:UIControlEventValueChanged];
        _refreshFootControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull up to load more!" attributes:attributeDic];

    }
    return self;
}




#pragma mark - Bind Array (Public)


- (nonnull NSMutableArray*)createBindArray
{
    return [self createBindArrayFromNSArray:nil ];
}

- (nonnull NSMutableArray*)createBindArrayFromNSArray:(nullable NSArray*)array
{
    NSMutableArray *bindArray = nil;
    if (array) {
        bindArray = [[NSMutableArray alloc] initWithArray:array];
    }
    else{
        bindArray = [[NSMutableArray alloc] init];
    }
    [self bindArray:bindArray];
    return bindArray;
}

- (void)bindArray:(nonnull NSMutableArray*)array
{
    array.kh_delegate = self;
    array.section = _sectionArray.count;
    [_sectionArray addObject: array ];
}

- (void)deBindArray:(nonnull NSMutableArray*)array
{
    array.kh_delegate = nil;
    array.section = 0;
    [_sectionArray removeObject: array ];
}

- (nullable NSMutableArray*)getArray:(NSInteger)section
{
    return _sectionArray[section];
}

- (NSInteger)arrayCount
{
    return _sectionArray.count;
}

- (void)bindModel:(nonnull Class)modelClass cell:(nonnull Class)cellClass
{
    NSString *modelName = NSStringFromClass(modelClass);
    NSString *cellName = NSStringFromClass(cellClass);
    _modelBindMap[modelName] = cellName;
}

- (nullable NSString*)getBindCellName:(NSString*)modelName
{
    return _modelBindMap[modelName];
}

//  取得某個 model 的 cell 介接物件
- (nullable KHCellProxy*)cellProxyWithModel:(id)model
{
    NSValue *myKey = [NSValue valueWithNonretainedObject:model];
    return _proxyDic[myKey];
}

//  懂過 cell 取得 data model
- (nullable id)getDataModelWithCell:(nonnull id)cell
{
    for ( NSValue *myKey in _proxyDic ) {
        KHCellProxy *cellProxy = _proxyDic[myKey];
        if ( cellProxy.cell == cell ) {
            return cellProxy.model;
        }
    }
    return nil;
}

//  取得某 model 的 index
- (nullable NSIndexPath*)indexPathOfModel:(nonnull id)model_
{
    for ( int i=0 ; i<_sectionArray.count ; i++ ) {
        NSArray *arr = _sectionArray[i];
        for ( int j=0 ; j<arr.count ; j++ ) {
            id model = arr[j];
            if ( model == model_ ) {
                NSIndexPath *index = [NSIndexPath indexPathForRow:j inSection:i];
                return index;
            }
        }
    }
    return nil;
}

//  取得某 cell 的 index
- (nullable NSIndexPath*)indexPathOfCell:(nonnull id)cell
{
    id model = [self getDataModelWithCell: cell ];
    if( model ){
        NSIndexPath *index = [self indexPathOfModel:model];
        return index;
    }

    return nil;
}

#pragma mark - Setter

- (void)setHeadTitle:(NSString *)headTitle
{
    _headTitle = headTitle;
    if (_refreshHeadControl) {
        NSDictionary *attributeDic = @{NSForegroundColorAttributeName:[UIColor lightGrayColor],
                                       NSFontAttributeName:[UIFont boldSystemFontOfSize:14]};
        refreshTitle1 = [[NSAttributedString alloc] initWithString:_headTitle attributes:attributeDic];
        _refreshHeadControl.attributedTitle = refreshTitle1;
    }
}

- (void)setFootTitle:(NSString *)footTitle
{
    _footTitle = footTitle;
    if (_refreshFootControl) {
        NSDictionary *attributeDic = @{NSForegroundColorAttributeName:[UIColor lightGrayColor],
                                       NSFontAttributeName:[UIFont boldSystemFontOfSize:14]};
        refreshTitle1 = [[NSAttributedString alloc] initWithString:_footTitle attributes:attributeDic];
        _refreshFootControl.attributedTitle = refreshTitle1;
    }
}

- (void)setRefreshHeadEnabled:(BOOL)refreshHeadEnabled
{
    _refreshHeadEnabled = refreshHeadEnabled;
    if (_refreshHeadEnabled) {
        if ( _refreshHeadControl ) {
            if (refreshScrollView) [refreshScrollView addSubview: _refreshHeadControl ];
        }
    }
    else{
        if ( _refreshHeadControl ) {
            if (refreshScrollView) [_refreshHeadControl removeFromSuperview];
        }
    }
}

- (void)setRefreshFootEnabled:(BOOL)refreshFootEnabled
{
    _refreshFootEnabled = refreshFootEnabled;
    if ( _refreshFootEnabled ) {
        if (_refreshFootControl ) {
            if (refreshScrollView) refreshScrollView.bottomRefreshControl = _refreshFootControl;
        }
    }
    else{
        if (refreshScrollView) refreshScrollView.bottomRefreshControl = nil;
    }
}

- (void)setLastUpdate:(NSTimeInterval)lastUpdate
{
    _lastUpdate = lastUpdate;
    if ( _lastUpdate > 0 ) {
        NSDate *date = [[NSDate alloc] initWithTimeIntervalSince1970:_lastUpdate ];
        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        [fmt setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT: 8 * 3600 ]];
        [fmt setDateFormat: @"yyyy-MM-dd HH:mm:ss" ];
        NSString *dateString = [fmt stringFromDate: date ];
        NSString *updateString = [NSString stringWithFormat:@"Last Update:%@",dateString];
        NSDictionary *attributeDic = @{NSForegroundColorAttributeName:[UIColor lightGrayColor],
                                       NSFontAttributeName:[UIFont boldSystemFontOfSize:14]};
        refreshTitle2 = [[NSAttributedString alloc] initWithString:updateString attributes:attributeDic];
        
    }
}

#pragma mark - UIRefreshControl

- (void)setRefreshScrollView:(UIScrollView*)scrollView
{
    refreshScrollView = scrollView;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    //  若沒有啟用，或是有啟用但正在更新，就不做這個檢查
    if( !self.refreshHeadEnabled || _refreshHeadControl.refreshing ) return;
    if ( refreshTitle2 && scrollView.contentOffset.y < -80 ) {
        if ( refreshState == 1 ) {
            refreshState = 2;
            _refreshHeadControl.attributedTitle = refreshTitle2;
        }
    }
    else if( scrollView.contentOffset.y > -80 ){
        if ( refreshState == 2 ) {
            refreshState = 1;
            _refreshHeadControl.attributedTitle = refreshTitle1;
        }
    }
}

- (void)refreshHead:(id)sender
{
    //  override by subclass
}

- (void)refreshFoot:(id)sender
{
    //  override by subclass
}


- (void)endRefreshing
{
    if (_refreshHeadControl.refreshing) {
        [_refreshHeadControl endRefreshing];
    }
    if (_refreshFootControl.refreshing) {
        [_refreshFootControl endRefreshing];
    }
}




#pragma mark - UIControl Handle (Private)

- (void)saveEventHandle:(KHCellEventHandler*)eventHandle
{
    if ( !_cellUIEventHandlers ) {
        _cellUIEventHandlers = [[NSMutableArray alloc] initWithCapacity: 10 ];
    }
    
    [_cellUIEventHandlers addObject: eventHandle ];
}

- (KHCellEventHandler*)getEventHandle:(Class)cellClass property:(NSString*)propertyName event:(UIControlEvents)event
{
    for ( KHCellEventHandler *handleData in _cellUIEventHandlers) {
        if ( [handleData.cellClass isSubclassOfClass:cellClass] && 
             [handleData.propertyName isEqualToString:propertyName] &&
             handleData.event == event ) {
            return handleData;
        }
    }
    return nil;
}


//  檢查 cell 有沒有跟 _cellUIEventHandlers 記錄的 KHCellEventHandler.propertyName 同名的 ui
//  有的話，就監聽那個 ui 的事件
- (void)listenUIControlOfCell:(nonnull id)cell
{
    NSInteger cnt = _cellUIEventHandlers.count;
    for ( int i=0; i<cnt; i++ ) {
        //  取出事件資料，記錄說我要監聽哪個cell 的哪個 ui 的哪個事件
        KHCellEventHandler *eventHandler = _cellUIEventHandlers[i];
        
        if ( [cell isKindOfClass: eventHandler.cellClass ] ) {
            @try {
                //  若是我們要監聽的 cell ，從 cell 取出要監聽的 ui
                id uicontrol = [cell valueForKey: eventHandler.propertyName ];
                //  看這個 ui 先前是否已經有設定過監聽事件，若有的話 oldtarget 會有值，若沒有，就設定
                id oldtarget = [uicontrol targetForAction:@selector(eventHandle:) withSender:nil];
                if (!oldtarget) {
                    [uicontrol addTarget:eventHandler action:@selector(eventHandle:) forControlEvents:eventHandler.event ];
                }
            }
            @catch (NSException *exception) {
                NSLog(@"%@ does not exist in %@", eventHandler.propertyName, NSStringFromClass(eventHandler.cellClass) );
                @throw exception;
            }
        }
    }
}




#pragma mark - UIControl Handle (Public)


//  UI Event
- (void)addTarget:(nonnull id)target action:(nonnull SEL)action event:(UIControlEvents)event cell:(nonnull Class)cellClass propertyName:(nonnull NSString*)pname
{
    NSMethodSignature* signature1 = [target methodSignatureForSelector:action];
    NSInvocation *eventInvocation = [NSInvocation invocationWithMethodSignature:signature1];
    [eventInvocation setTarget:target];
    [eventInvocation setSelector:action];
    
    //  建立事件處理物件
    KHCellEventHandler *eventHandleData = [KHCellEventHandler new];
    eventHandleData.binder = self;
    eventHandleData.cellClass = cellClass;
    eventHandleData.propertyName = pname;
    eventHandleData.event = event;
    eventHandleData.invo = eventInvocation;
    
    //  存入 array
    [self saveEventHandle: eventHandleData ];
    
}

//
- (void)removeTarget:(nonnull id)target action:(nullable SEL)action cell:(nonnull Class)cellClass propertyName:(NSString*)pName
{
    if ( _cellUIEventHandlers == nil ) {
        return;
    }
    for ( int i=0; i<_cellUIEventHandlers.count; i++ ) {
        KHCellEventHandler *eventHandleData = _cellUIEventHandlers[i];
        if ( [cellClass isSubclassOfClass: eventHandleData.cellClass ] && 
            [eventHandleData.propertyName isEqualToString:pName] && 
            eventHandleData.invo.target == target && 
            eventHandleData.invo.selector == action ) {
            [_cellUIEventHandlers removeObjectAtIndex:i];
            break;
        }
    }
}

//
- (void)removeTarget:(nonnull id)target cell:(nonnull Class)cellClass propertyName:(nonnull NSString*)pName;
{
    if ( _cellUIEventHandlers == nil ) {
        return;
    }
    int i = 0;
    while ( _cellUIEventHandlers.count > i ) {
        KHCellEventHandler *eventHandleData = _cellUIEventHandlers[i];
        if ( [cellClass isSubclassOfClass: eventHandleData.cellClass ] && 
            [eventHandleData.propertyName isEqualToString:pName] && 
            eventHandleData.invo.target == target ) {
            [_cellUIEventHandlers removeObjectAtIndex:i];
        }
        else{
            i++;
        }
    }
}

//
- (nullable id)getTargetByAction:(nonnull SEL)action cell:(nonnull Class)cellClass propertyName:(nonnull NSString*)pName;
{
    if ( _cellUIEventHandlers == nil ) {
        return nil;
    }
    int i = 0;
    while ( _cellUIEventHandlers.count > i ) {
        KHCellEventHandler *eventHandleData = _cellUIEventHandlers[i];
        if ( [cellClass isSubclassOfClass: eventHandleData.cellClass ] && 
            [eventHandleData.propertyName isEqualToString:pName] && 
            eventHandleData.invo.selector == action ) {
            return eventHandleData.invo.target;
        }
        else{
            i++;
        }
    }
    
    return nil;
}




//#pragma mark - Image Download
//
//- (void)loadImageURL:(nonnull NSString*)urlString cell:(id)cell completed:(nonnull void (^)(UIImage *))completed
//{
//    [[KHImageDownloader instance] loadImageURL:urlString cell:cell completed:completed];
//}




#pragma mark - Array Observe


//  插入
-(void)arrayInsert:(NSMutableArray*)array insertObject:(id)object index:(NSIndexPath*)index
{
    KHCellProxy *cellProxy = [[KHCellProxy alloc] init];
    cellProxy.dataBinder = self;
    cellProxy.model = object;
    NSValue *myKey = [NSValue valueWithNonretainedObject:object];
    _proxyDic[myKey] = cellProxy;
    
}

//  插入 多項
-(void)arrayInsertSome:(nonnull NSMutableArray *)array insertObjects:(nonnull NSArray *)objects indexes:(nonnull NSIndexSet *)indexSet
{
    for ( id model in objects ) {
        KHCellProxy *cellProxy = [[KHCellProxy alloc] init];
        cellProxy.dataBinder = self;
        cellProxy.model = model;
        NSValue *myKey = [NSValue valueWithNonretainedObject:model];
        _proxyDic[myKey] = cellProxy;
    }
}

//  刪除
-(void)arrayRemove:(NSMutableArray*)array removeObject:(id)object index:(NSIndexPath*)index
{
    NSValue *myKey = [NSValue valueWithNonretainedObject:object];
    KHCellProxy *cellProxy = _proxyDic[myKey];
    cellProxy.model = nil;
    [_proxyDic removeObjectForKey:myKey];
}

//  刪除多項
-(void)arrayRemoveSome:(NSMutableArray *)array removeObjects:(NSArray *)objects indexs:(NSArray *)indexs
{
    for ( id model in objects ) {
        NSValue *myKey = [NSValue valueWithNonretainedObject:model];
        KHCellProxy *cellProxy = _proxyDic[myKey];
        cellProxy.model = nil;
        [_proxyDic removeObjectForKey:myKey];
    }
}

//  取代
-(void)arrayReplace:(NSMutableArray*)array newObject:(id)newObj replacedObject:(id)oldObj index:(NSIndexPath*)index
{
    NSValue *oldKey = [NSValue valueWithNonretainedObject:oldObj];
    KHCellProxy *cellProxy = _proxyDic[oldKey];
    [_proxyDic removeObjectForKey:oldKey];
    cellProxy.model = newObj;
    NSValue *newKey = [NSValue valueWithNonretainedObject:newObj];
    _proxyDic[newKey] = cellProxy;
}

//  更新
//-(void)arrayUpdate:(NSMutableArray*)array update:(id)object index:(NSIndexPath*)index
//{
//    
//}
//
//-(void)arrayUpdateAll:(NSMutableArray *)array
//{
//
//}

@end




#pragma mark - KHTableDataBinder
#pragma mark - 


@implementation KHTableDataBinder

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initImpl];
    }
    return self;
}

- (instancetype)initWithTableView:(UITableView*)tableView
{
    return [self initWithTableView:tableView delegate:nil];
}

- (nonnull instancetype)initWithTableView:(nonnull UITableView*)tableView delegate:(id)delegate
{
    self = [super init];
    if (self) {
        
        [self initImpl];
        self.tableView = tableView;
        self.delegate = delegate;
        
//        _cellHeight = 44;
//        _cellAccessoryType = UITableViewCellAccessoryNone;
//        _cellAccessoryView = nil;
//        _cellSelectionType = UITableViewCellSelectionStyleNone;
//        _cellBackgroundColor = [UIColor whiteColor];
        
    }
    return self;
}

- (void)initImpl
{
    _headerHeight = 10;
    _footerHeight = 0;
    
    // 預設 UITableViewCellModel 配 UITableViewCell
    [self bindModel:[UITableViewCellModel class] cell:[UITableViewCell class]];
}




#pragma mark - Override

- (void)bindArray:(NSMutableArray *)array
{
    [super bindArray:array];
    if ( array.count > 0 ) {
        [self.tableView reloadData];
    }
}

- (void)bindModel:(Class)modelClass cell:(Class)cellClass
{
    [super bindModel:modelClass cell:cellClass];
    
//    NSString *modelName = NSStringFromClass(modelClass);
    NSString *cellName = NSStringFromClass(cellClass);
    UINib *nib = [UINib nibWithNibName:cellName bundle:[NSBundle mainBundle]];
    [_tableView registerNib:nib forCellReuseIdentifier:cellName];
}

#pragma mark - Private

- (void)configAdapter:(KHCellProxy*)cellProxy
{
    
}


#pragma mark - Public

- (void)setHeaderTitles:(nullable NSArray*)titles
{
    _titles = [titles copy];
}




#pragma mark - Setter

- (void)setTableView:(UITableView *)tableView
{
    _tableView = tableView;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self setRefreshScrollView:_tableView];
}




#pragma mark - UIRefresh

- (void)refreshHead:(id)sender
{
    if ( self.refreshHeadEnabled && _delegate && [_delegate respondsToSelector:@selector(tableViewRefreshHead:)]) {
        [_delegate tableViewRefreshHead:_tableView];
    }
}

- (void)refreshFoot:(id)sender
{
    if ( self.refreshFootEnabled && _delegate && [_delegate respondsToSelector:@selector(tableViewRefreshFoot:)] ) {
        [_delegate tableViewRefreshFoot:_tableView];
    }
}




#pragma mark - Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSMutableArray *models = _sectionArray[section];
//    NSLog(@"section %ld row count %ld", section, models.count);
    return models.count;
}

// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    _hasInit = YES;
//    printf("config cell %ld \n", indexPath.row );
    
    NSMutableArray *modelArray = _sectionArray[indexPath.section];
    
    if ( modelArray == nil ) {
        NSException *exception = [NSException exceptionWithName:@"Invalid table data" reason:[NSString stringWithFormat:@"section %i is not exist", indexPath.section] userInfo:nil];
        @throw exception;
    }
    
    id model = modelArray[indexPath.row];
    
    KHCellProxy *cellProxy = [self cellProxyWithModel: model ];
    
    if ( model == nil ) {
        NSException *exception = [NSException exceptionWithName:@"Invalid model data" reason:@"model is nil" userInfo:nil];
        @throw exception;
    }
    // 記錄 index
//    cellProxy.index = indexPath;
    
    // class name 當作 identifier
    NSString *modelName = NSStringFromClass( [model class] );
    //  取出 model name 對映的 cell name
    NSString *cellName = [self getBindCellName: modelName ];
    if ( [model isKindOfClass:[UITableViewCellModel class]] || [cellName isEqualToString:@"UITableViewCell"] ) {
        UITableViewCellModel *cellModel = model;
        switch (cellModel.cellStyle) {
            case UITableViewCellStyleDefault:
                cellName = @"UITableViewCellStyleDefault";
                break;
            case UITableViewCellStyleSubtitle:
                cellName = @"UITableViewCellStyleSubtitle";
                break;
            case UITableViewCellStyleValue1:
                cellName = @"UITableViewCellStyleValue1";
                break;
            case UITableViewCellStyleValue2:
                cellName = @"UITableViewCellStyleValue2";
                break;
        }
    }
    else if ( cellName == nil ) {
        NSException *exception = [NSException exceptionWithName:@"Bind invalid" reason:[NSString stringWithFormat:@"there is no cell bind with model %@",modelName] userInfo:nil];
        @throw exception;
    }
    
    UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier: cellName ];
    // 若取不到 cell ，在 ios 7 好像會發生例外，在ios8 就直接取回nil
    if (cell==nil) {
        if ( [model isKindOfClass:[UITableViewCellModel class]] ) {
            UITableViewCellModel *cellModel = model;
            cell = [[UITableViewCell alloc] initWithStyle:cellModel.cellStyle reuseIdentifier:cellName];
        }
        else{
            //  預設建立 cell 都是繼承一個自訂的 cell，並且配一個同 cell name 的 nib
            UINib *nib = [UINib nibWithNibName:cellName bundle:[NSBundle mainBundle]];
            if (!nib) {
                NSException* exception = [NSException exceptionWithName:@"Xib file not found." reason:[NSString stringWithFormat:@"UINib file %@ is nil", cellName ] userInfo:nil];
                @throw exception;
            }
            else{
                [_tableView registerNib:nib forCellReuseIdentifier:cellName];
                cell = [_tableView dequeueReusableCellWithIdentifier: cellName ];
            }
        }
    }
    
    //  設定 touch event handle
    [self listenUIControlOfCell:cell];
    
    //  assign reference
    cellProxy.cell = cell;
    cell.cellProxy = cellProxy;
    
    //  記錄 cell 的高，0 代表我未把這個cell height 初始，若是指定動態高 UITableViewAutomaticDimension，值為 -1
    if( cellProxy.cellHeight == 0 ){
        cellProxy.cellHeight = cell.frame.size.height;
    }
    
    //  把 model 載入 cell
    if ( [cell respondsToSelector:@selector(onLoad:)]) {
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
    NSMutableArray* array = _sectionArray[indexPath.section];
    id model = array[indexPath.row];
    KHCellProxy *cellProxy = [self cellProxyWithModel: model ];
    
    if( cellProxy.cellHeight == 0 ){
        NSString *cellName = [self getBindCellName: NSStringFromClass([model class])];
        UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier: cellName ];
        cellProxy.cellHeight = cell.frame.size.height;
    }
    
    float height = cellProxy.cellHeight;
//    NSLog(@" %ld cell height %f", indexPath.row,height );
    if ( height == 0 ) {
        return 44;
    }
    return height;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
//    NSLog(@" %ld estimated cell height 44", indexPath.row );
//    NSMutableArray* array = _sectionArray[indexPath.section];
//    KHCellModel *model = array[indexPath.row];
//    return model.estimatedCellHeight;
    return 44; //   for UITableViewAutomaticDimension
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( _delegate && [_delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)] ) {
        [_delegate tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return _footerHeight;
}

// fixed font style. use custom view (UILabel) if you want something different
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ( section < _sectionArray.count && section < _titles.count ) {
        return _titles[ section ];
    }
    return nil;
}

/**
 *  回傳每個 section 的header高
 */
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ( _titles.count > 0 && _titles[section] != [NSNull null] ) {
        //        printf("section header height:%f\n", self.sectionHeaderHeight );
        return self.headerHeight + 21;
    }
    return 0;
}

/**
 * 顯示 headerView 之前，可以在這裡對 headerView 做一些顯示上的調整，例如改變字色或是背景色
 */
- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section{
    UITableViewHeaderFooterView* thfv = (UITableViewHeaderFooterView*)view;
    if( _headerBgColor ) thfv.contentView.backgroundColor = _headerBgColor;
    if( _headerTextColor ) thfv.textLabel.textColor = _headerTextColor;
    if(_headerFont) thfv.textLabel.font = _headerFont;
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView* thfv = (UITableViewHeaderFooterView*)view;
    if( _footerBgColor ) thfv.contentView.backgroundColor = _footerBgColor;
    if( _footerTextColor ) thfv.textLabel.textColor = _footerTextColor;
    if( _footerFont ) thfv.textLabel.font = _footerFont;
}




#pragma mark - Array Observe

//  插入
-(void)arrayInsert:(NSMutableArray*)array insertObject:(id)object index:(NSIndexPath*)index
{
    [super arrayInsert:array insertObject:object index:index];
    
    if (_hasInit){
        [_tableView insertRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationBottom];
    }
    else{
        [_tableView reloadData];
    }
}

//  插入 多項
-(void)arrayInsertSome:(NSMutableArray *)array insertObjects:(NSArray *)objects indexes:(NSArray *)indexes
{
    [super arrayInsertSome:array insertObjects:objects indexes:indexes ];
    
    if (_hasInit){
        [_tableView insertRowsAtIndexPaths:indexes withRowAnimation:UITableViewRowAnimationBottom];
    }
    else{
        [_tableView reloadData];
    }
}

//  刪除
-(void)arrayRemove:(NSMutableArray*)array removeObject:(id)object index:(NSIndexPath*)index
{
    [super arrayRemove:array removeObject:object index:index];
    
    if (_hasInit) {
        [_tableView deleteRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationTop];
    }
}

//  刪除全部
-(void)arrayRemoveSome:(NSMutableArray *)array removeObjects:(NSArray *)objects indexs:(NSArray *)indexs
{
    [super arrayRemoveSome:array removeObjects:objects indexs:indexs ];
    
    if(_hasInit){
        [_tableView deleteRowsAtIndexPaths:indexs withRowAnimation:UITableViewRowAnimationTop];
    }
}

//  取代
-(void)arrayReplace:(NSMutableArray*)array newObject:(id)newObj replacedObject:(id)oldObj index:(NSIndexPath*)index
{
    [super arrayReplace:array newObject:newObj replacedObject:oldObj index:index];
    
    if (_hasInit){
        [_tableView reloadRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationFade];
    }
}

//  更新
//-(void)arrayUpdate:(NSMutableArray*)array update:(id)object index:(NSIndexPath*)index
//{
//    [super arrayUpdate:array update:object index:index];
//    
//    if (_hasInit){
//        // Gevin note:
//        //  使用動畫，在全部 table cell 的呈現上，會有些奇怪的行為發生，雖然不會造成運作問題
//        //  但是會一直發生，覺得很煩，所以乾脆直接呼叫 cell ui reload 的 method
////        [_tableView reloadRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationNone];
//        
//        UITableViewCell *cell = [_tableView cellForRowAtIndexPath: index ];
//        id model = cell.cellProxy.model;
//        [cell onLoad: model];
//    }
//}
//
//-(void)arrayUpdateAll:(NSMutableArray *)array
//{
//    [super arrayUpdateAll:array];
//    
//    if (_hasInit){
//        [_tableView reloadSections:[NSIndexSet indexSetWithIndex:array.section] withRowAnimation:UITableViewRowAnimationAutomatic];
//    }
//}


@end






#pragma mark - KHCollectionDataBinder
#pragma mark -


@implementation KHCollectionDataBinder
{
    UICollectionViewCell *_prototype_cell;
}

- (instancetype)init
{
    self = [super init];
    
    _hasInit = NO;

    return self;
}




#pragma mark - Override

- (void)bindArray:(NSMutableArray *)array
{
    [super bindArray:array];
    if ( array.count > 0 ) {
        [self.collectionView reloadData];
    }
}




#pragma mark - Public

- (void)setLayout:(UICollectionViewLayout *)layout
{
    _layout = layout;
    _collectionView.collectionViewLayout = layout;
}

//- (UICollectionViewLayout*)layout
//{
//    
//    return ;
//}


#pragma mark - Property Setter

- (void)setCollectionView:(UICollectionView *)collectionView
{
    _collectionView = collectionView;
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    _layout = _collectionView.collectionViewLayout;
    
    [self setRefreshScrollView:_collectionView];
    
    // Configure layout
//    self.flowLayout = [[UICollectionViewFlowLayout alloc] init];
//    [self.flowLayout setItemSize:CGSizeMake(191, 160)];
//    [self.flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
//    self.flowLayout.minimumInteritemSpacing = 0.0f;
//    [self.collectionView setCollectionViewLayout:self.flowLayout];
//    self.collectionView.bounces = YES;
//    [self.collectionView setShowsHorizontalScrollIndicator:NO];
//    [self.collectionView setShowsVerticalScrollIndicator:NO];

}




#pragma mark - Data Source

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSArray *array = _sectionArray[section];
    return array.count;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    _hasInit = YES;
    NSLog(@"DataBinder >> %i cell config", indexPath.row );
    NSMutableArray *modelArray = _sectionArray[indexPath.section];
    
    if ( modelArray == nil ) {
        NSException *exception = [NSException exceptionWithName:@"Invalid table data" reason:[NSString stringWithFormat:@"section %ld is not exist", indexPath.section] userInfo:nil];
        @throw exception;
    }
    
    id model = modelArray[indexPath.row];
    
    KHCellProxy *cellProxy = [self cellProxyWithModel: model ];
    
    if ( model == nil ) {
        NSException *exception = [NSException exceptionWithName:@"Invalid model data" reason:@"model is nil" userInfo:nil];
        @throw exception;
    }
    
    // class name 當作 identifier
    NSString *modelName = NSStringFromClass([model class]);
    NSString *cellName = [self getBindCellName: NSStringFromClass([model class]) ];
    
    UICollectionViewCell *cell = nil;
    @try {
        cell = [_collectionView dequeueReusableCellWithReuseIdentifier:cellName forIndexPath:indexPath ];
    }
    @catch (NSException *exception) {
        
        // 這邊只會執行一次，之後就會有一個 prototype cell 一直複製
        UINib *nib = [UINib nibWithNibName:cellName bundle:[NSBundle mainBundle]];
        [_collectionView registerNib:nib forCellWithReuseIdentifier:cellName];
        cell = [_collectionView dequeueReusableCellWithReuseIdentifier:cellName forIndexPath:indexPath ];
        
//        NSArray *arr = [nib instantiateWithOwner:nil options:nil];
//        UICollectionViewCell *_cell = arr[0];
//        UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout*)_collectionView.collectionViewLayout;
//        layout.itemSize = _cell.frame.size;
//        
//        NSLog(@"cell size %@, layout size %@", NSStringFromCGSize(cell.frame.size), NSStringFromCGSize(layout.itemSize) );
    }
    
    //  設定 touch event handle
    [self listenUIControlOfCell:cell];
    
    //  記錄 size
    cellProxy.cellSize = cell.frame.size;
    
    //  assign reference
    cellProxy.cell = cell;
    cell.cellProxy = cellProxy;
    
    //  把 model 載入 cell
    [cell onLoad:model];
    
    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    _hasInit = YES;
    return _sectionArray.count;
}




#pragma mark - UICollectionViewFlowLayout

//  設定 cell size
//  每新增一個 cell，前面的每個 cell 都 size 都會重新取得
//  假設現在有四個cell，再新增一個，那個method就會呼叫五次，最後再呼叫一次 cellForItemAtIndexPath:
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *arr = [self getArray:indexPath.section];
    id model = arr[indexPath.row];
    if ( !_prototype_cell ) {
        NSString *cellName = [self getBindCellName: NSStringFromClass([model class]) ];
        UINib *nib = [UINib nibWithNibName:cellName bundle:[NSBundle mainBundle]];
        NSArray *arr = [nib instantiateWithOwner:nil options:nil];
        _prototype_cell = arr[0];
    }
    
    KHCellProxy *cellProxy = [self cellProxyWithModel: model ];
    cellProxy.cellSize = _prototype_cell.frame.size;
    NSLog(@"DataBinder >> %i cell size %@", indexPath.row, NSStringFromCGSize(_prototype_cell.frame.size));
    return cellProxy.cellSize;
}

//- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section;
//- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section;
//- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section;
//- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section;
//- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section;




#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ( _delegate && [_delegate respondsToSelector:@selector(collectionView:didSelectItemAtIndexPath:)] ) {
        [_delegate collectionView:collectionView didSelectItemAtIndexPath:indexPath];
    }
}




#pragma mark - UIRefreshControl

- (void)refreshHead:(id)sender
{
    if ( self.refreshHeadEnabled && _delegate && [_delegate respondsToSelector:@selector(collectionViewRefreshHead:)]) {
        [_delegate collectionViewRefreshHead:_collectionView];
    }
}

- (void)refreshFoot:(id)sender
{
    if ( self.refreshFootEnabled && _delegate && [_delegate respondsToSelector:@selector(collectionViewRefreshFoot:)]) {
        [_delegate collectionViewRefreshFoot:_collectionView];
    }
}




#pragma mark - Array Observe

//  插入
-(void)arrayInsert:(NSMutableArray*)array insertObject:(id)object index:(NSIndexPath*)index
{
    [super arrayInsert:array insertObject:object index:index];
    if ( _hasInit ) {
        [_collectionView insertItemsAtIndexPaths:@[index]];
    }
    else{
        [_collectionView reloadData];
    }
}

//  插入 多項
-(void)arrayInsertSome:(NSMutableArray *)array insertObjects:(NSArray *)objects indexes:(NSArray *)indexes
{
    [super arrayInsertSome:array insertObjects:objects indexes:indexes];
    if (_hasInit){
        [_collectionView insertItemsAtIndexPaths:indexes];
    }
    else{
        [_collectionView reloadData];
    }
}

//  刪除
-(void)arrayRemove:(NSMutableArray*)array removeObject:(id)object index:(NSIndexPath*)index
{
    [super arrayRemove:array removeObject:object index:index];
    if ( _hasInit ) {
        [_collectionView deleteItemsAtIndexPaths:@[index]];
    }
}

//  刪除全部
-(void)arrayRemoveSome:(NSMutableArray *)array removeObjects:(NSArray *)objects indexs:(NSArray *)indexs
{
    [super arrayRemoveSome:array removeObjects:objects indexs:indexs];
    if ( _hasInit ) {
        [_collectionView deleteItemsAtIndexPaths:indexs];
    }
}

//  取代
-(void)arrayReplace:(NSMutableArray*)array newObject:(id)newObj replacedObject:(id)oldObj index:(NSIndexPath*)index
{
    [super arrayReplace:array newObject:newObj replacedObject:oldObj index:index];
    if ( _hasInit ) {
        [_collectionView reloadItemsAtIndexPaths:@[index]];
    }
}

//  更新
//-(void)arrayUpdate:(NSMutableArray*)array update:(id)object index:(NSIndexPath*)index
//{
//    [super arrayUpdate:array update:object index:index];
//    if ( _hasInit ) {
//        [_collectionView reloadItemsAtIndexPaths:@[index]];
//    }
//}
//
//-(void)arrayUpdateAll:(NSMutableArray *)array
//{
//    [super arrayUpdateAll:array];
//    if ( _hasInit ) {
//        [_collectionView reloadSections:[NSIndexSet indexSetWithIndex:array.section]];
//    }
//}



@end


