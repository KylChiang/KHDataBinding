//
//  KHDataBinder.m
//
//  Created by GevinChen on 2015/9/26.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import "KHDataBinder.h"
#import <objc/runtime.h>
#import <CCBottomRefreshControl/UIScrollView+BottomRefreshControl.h>

//  KHCellEventHandler 主要負責處理 cell 裡 UI 事件觸發後的處理
//  它類似橋接，會記錄是哪個 cell class 裡的哪個 property，觸發的什麼事件後，要用哪個 method 來處理
//  
//  使用方式
//  在 controller 呼叫 data binder 的
//  - (void)addTarget:(nonnull id)target action:(nonnull SEL)action event:(UIControlEvents)event cell:(nonnull Class)cellClass propertyName:(nonnull NSString*)pname;
//  
//  它會建立一個 KHCellEventHandler 的 instance
//  上面就是在跟 data binder 登記，你想要處理哪種 cell class 裡的哪個 ui 觸發的事件，然後用什麼 method 來處理
//  那 method 的格式要符合能接收兩個參數
//  例如： -(void)buttonClick:(id)sender model:(id)model，第一個會傳 ui，第二個會傳對應的 model
//  
//  假設我有一個 MsgCell 裡面有兩個 button
//  cell.btnRead
//  cell.btnDel
//  
//  在 controller 呼叫就會是
//  [dataBinder addEvent:UIControlEventTouchUpInside cell:[MsgCell class] propertyName:@"btnRead" handler:^(id sender, id model ){ ... }];
//  [dataBinder addEvent:UIControlEventTouchUpInside cell:[MsgCell class] propertyName:@"btnDel" handler:^(id sender, id model ){ ... }];
//  
//  使用上這樣就行了，之後就實作 method 裡要做什麼處理
//
//
//  背後的運作方式
//  當每次呼叫 UITableViewDataSource 的
//  - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
//  載入一個 cell 的時候，就把 cell 丟進 [dataBinder listenUIControlOfCell:cell] 來檢查
//  看 class 與 property 是否相符
//  相符的話，就設定 ui 事件觸發後，執行 KHCellEventHandler 的 eventHandle:
//  然後在 KHCellEventHandler 的 eventHandle 裡，會再執行先前設定的 method
//  
//  觸發的流程：
//  user touch button ==> button trigger event ==> run [KHCellEventHandler eventHandle:] ==> run controller method
//  

//  記錄有指定哪些 cell 的 ui 需要被監聽
@interface KHCellEventHandler : NSObject

@property (nonatomic,assign) KHDataBinder *binder;
@property (nonatomic) Class cellClass;
@property (nonatomic) NSMutableArray *listenedCells;
@property (nonatomic) NSString *propertyName;
@property (nonatomic) UIControlEvents event;
@property (nonatomic,copy) void(^eventHandleBlock)(id sender, id model);

- (void)eventHandle:(id)ui;

@end

@implementation KHCellEventHandler

- (instancetype)init
{
    
    self = [super init];
    
    _listenedCells = [[NSMutableArray alloc] initWithCapacity:20];
    
    return self;
}

//  檢查 cell 有沒有跟 _cellUIEventHandlers 記錄的 KHCellEventHandler.propertyName 同名的 ui
//  有的話，就監聽那個 ui 的事件
- (void)listenUIControlOfCell:(nonnull id)cell
{
    if ( [_listenedCells containsObject: cell ] ) {
        return;
    }
        
    if ( [cell isKindOfClass: self.cellClass ] ) {
        @try {
            //  若是我們要監聽的 cell ，從 cell 取出要監聽的 ui
            UIControl *uicontrol = [cell valueForKey: self.propertyName ];
            //  看這個 ui 先前是否已經有設定過監聽事件，若有的話 eventHandler 就會有值 
            id eventHandler = [uicontrol targetForAction:@selector(eventHandle:) withSender:nil];
            if (!eventHandler) {
                [uicontrol addTarget:self action:@selector(eventHandle:) forControlEvents:self.event ];
            }
        }
        @catch (NSException *exception) {
            NSLog(@"%@ does not exist in %@", self.propertyName, NSStringFromClass(self.cellClass) );
            @throw exception;
        }
    }
}

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
    if ( self.eventHandleBlock ) {
        self.eventHandleBlock( ui, model );
    }
}

@end


@implementation KHDataBinder

- (instancetype)init
{
    self = [super init];
    if (self) {
        _sectionArray = [[NSMutableArray alloc] initWithCapacity: 10 ];
        _linkerDic   = [[NSMutableDictionary alloc] initWithCapacity: 5 ];
        _cellClassDic = [[NSMutableDictionary alloc] initWithCapacity: 5 ];
        
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



#pragma mark - Model Cell Linker

- (KHModelCellLinker*)createLinker
{
    KHModelCellLinker *cellLinker = [[KHModelCellLinker alloc] init];
    return cellLinker;
}

- (void) addLinker:(id)object
{
    KHModelCellLinker *cellLinker = [self createLinker];
    cellLinker.binder = self;
    cellLinker.model = object;
    NSValue *myKey = [NSValue valueWithNonretainedObject:object];
    _linkerDic[myKey] = cellLinker;
}

- (void) removeLinker:(id)object
{
    NSValue *myKey = [NSValue valueWithNonretainedObject:object];
    KHModelCellLinker *cellLinker = _linkerDic[myKey];
    cellLinker.model = nil;
    [_linkerDic removeObjectForKey:myKey];
}

- (void) replaceLinkerOld:(id)oldObject new:(id)newObject
{
    NSValue *oldKey = [NSValue valueWithNonretainedObject:oldObject];
    KHModelCellLinker *cellLinker = _linkerDic[oldKey];
    [_linkerDic removeObjectForKey:oldKey];
    cellLinker.model = newObject;
    NSValue *newKey = [NSValue valueWithNonretainedObject:newObject];
    _linkerDic[newKey] = cellLinker;
}

//  取得某個 model 的 cell 介接物件
- (nullable KHModelCellLinker*)getLinkerViaModel:(id)model
{
    NSValue *myKey = [NSValue valueWithNonretainedObject:model];
    return _linkerDic[myKey];
}

//  連結 model 與 cell
- (void)linkModel:(id)model cell:(id)cell
{
    //  取出 model 的 linker
    KHModelCellLinker *cellLinker = [self getLinkerViaModel: model ];
    
    //  斷開先前有 reference 到這個 cell 的 linker  
    for ( NSValue *mykey in _linkerDic ) {
        KHModelCellLinker *linker = _linkerDic[mykey];
        if (linker.cell == cell ) {
            linker.cell = nil;
            break;
        }
    }
    //  cell reference linker
    [cell setValue:cellLinker forKey:@"linker"];
    //  linker reference cell
    cellLinker.cell = cell;
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
    //  若 array 裡有資料，那就要建立 proxy
    for ( id object in array ) {
        [self addLinker: object ];
    }
}

- (void)deBindArray:(nonnull NSMutableArray*)array
{
    array.kh_delegate = nil;
    array.section = 0;
    [_sectionArray removeObject: array ];
    //  移除 proxy
    for ( id object in array ) {
        [self removeLinker: object ];
    }
}

- (nullable NSMutableArray*)getArray:(NSInteger)section
{
    return _sectionArray[section];
}

- (NSInteger)sectionCount
{
    return _sectionArray.count;
}

- (void)registerCell:(nonnull Class)cellClass
{
    //  不知道為什麼，呼叫 instancesRespondToSelector 檢查不到mappingModelClass的存在
//    if ([cellClass instancesRespondToSelector:@selector(mappingModelClass)]) {
        Class modelClass2 = [cellClass mappingModelClass];
        NSString *modelName = NSStringFromClass(modelClass2);
        NSString *cellName = NSStringFromClass(cellClass);
        _cellClassDic[modelName] = cellName;
//    }
}

//  用  model class 來找對應的 cell class
- (nullable NSString*)getCellName:(nonnull Class)modelClass
{
    NSString *modelName = NSStringFromClass(modelClass);
    NSString *cellName = _cellClassDic[modelName];
    return cellName;
}

//  透過 model 取得 cell
- (nullable id)getCellByModel:(nonnull id)model
{
    // override by subclass
    return nil;
}

//  透過 cell 取得 data model
- (nullable id)getDataModelWithCell:(nonnull id)cell
{
    for ( NSValue *myKey in _linkerDic ) {
        KHModelCellLinker *cellLinker = _linkerDic[myKey];
        if ( cellLinker.cell == cell ) {
            return cellLinker.model;
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


//  更新 model
- (void)updateModel:(id)model
{
    NSIndexPath *index = [self indexPathOfModel: model ];
    [self arrayUpdate:_sectionArray[index.section] update:model index:index];
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
        
        [eventHandler listenUIControlOfCell: cell ];
    }
}




#pragma mark - UIControl Handle (Public)


//  UI Event
- (void)addEvent:(UIControlEvents)event cell:(nonnull Class)cellClass propertyName:(nonnull NSString*)pname handler:(void(^)(id, id ))eventHandleBlock
{
    
    //  建立事件處理物件
    KHCellEventHandler *eventHandleData = [KHCellEventHandler new];
    eventHandleData.binder = self;
    eventHandleData.cellClass = cellClass;
    eventHandleData.propertyName = pname;
    eventHandleData.event = event;
    eventHandleData.eventHandleBlock = eventHandleBlock;
    
    //  存入 array
    [self saveEventHandle: eventHandleData ];
    
}

//
- (void)removeEvent:(UIControlEvents)event cell:(nonnull Class)cellClass propertyName:(nonnull NSString*)pName
{
    if ( _cellUIEventHandlers == nil ) {
        return;
    }
    for ( int i=0; i<_cellUIEventHandlers.count; i++ ) {
        KHCellEventHandler *eventHandleData = _cellUIEventHandlers[i];
        if ( [cellClass isSubclassOfClass: eventHandleData.cellClass ] && 
            [eventHandleData.propertyName isEqualToString:pName] && 
            eventHandleData.event == event ) {
            [_cellUIEventHandlers removeObjectAtIndex:i];
            break;
        }
    }
}


#pragma mark - Array Observe


//  插入
-(void)arrayInsert:(NSMutableArray*)array insertObject:(id)object index:(NSIndexPath*)index
{
    [self addLinker:object];
}

//  插入 多項
-(void)arrayInsertSome:(nonnull NSMutableArray *)array insertObjects:(nonnull NSArray *)objects indexes:(nonnull NSIndexSet *)indexSet
{
    for ( id model in objects ) {
        [self addLinker:model];
    }
}

//  刪除
-(void)arrayRemove:(NSMutableArray*)array removeObject:(id)object index:(NSIndexPath*)index
{
    [self removeLinker:object];
}

//  刪除多項
-(void)arrayRemoveSome:(NSMutableArray *)array removeObjects:(NSArray *)objects indexs:(NSArray *)indexs
{
    for ( id model in objects ) {
        [self removeLinker:model];
    }
}

//  取代
-(void)arrayReplace:(NSMutableArray*)array newObject:(id)newObj replacedObject:(id)oldObj index:(NSIndexPath*)index
{
    [self replaceLinkerOld:oldObj new:newObj];
}

//  更新
- (void)arrayUpdate:(NSMutableArray *)array update:(id)object index:(NSIndexPath *)index
{
    //  override by subclass
}

//  更新全部
- (void)arrayUpdateAll:(NSMutableArray *)array
{
    // override by subclass
}

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
        
    }
    return self;
}

- (void)initImpl
{
    _cellHeightKeyword = @"cellHeight";
    _headerHeight = -1;
    _footerHeight = -1;
    
    _headerTitles= [[NSMutableArray alloc] init];
    _headerViews = [[NSMutableArray alloc] init];
    _footerTitles= [[NSMutableArray alloc] init];
    _footerViews = [[NSMutableArray alloc] init];

    // 預設 UITableViewCellModel 配 UITableViewCell
    [super registerCell:[UITableViewCell class]];
}




#pragma mark - Override

- (void)bindArray:(NSMutableArray *)array
{
    [super bindArray:array];
    
    //  先填 null
    for ( int i=0; i<self.sectionCount; i++) {
        if ( i == _headerTitles.count ) {
            [_headerTitles addObject:[NSNull null]];
        }
        if ( i == _headerViews.count ) {
            [_headerViews addObject:[NSNull null]];
        }
        if ( i == _footerTitles.count ) {
            [_footerTitles addObject:[NSNull null]];
        }
        if ( i == _footerViews.count ) {
            [_footerViews addObject:[NSNull null]];
        }
    }
    if ( array.count > 0 ) {
        [self.tableView reloadData];
    }
}

-(void)registerCell:(Class)cellClass
{
    [super registerCell:cellClass];
    
    NSString *cellName = NSStringFromClass(cellClass);
    UINib *nib = [UINib nibWithNibName:cellName bundle:[NSBundle mainBundle]];
    [_tableView registerNib:nib forCellReuseIdentifier:cellName];
}

#pragma mark - Private




#pragma mark - Public

- (float)getCellHeightWithModel:(nonnull id)model
{
    KHModelCellLinker *proxy = [self getLinkerViaModel:model];
    float cellHeight = [proxy.data[_cellHeightKeyword] floatValue];
    return cellHeight;
}


- (void)setCellHeight:(float)cellHeight model:(nonnull id)model
{
    KHModelCellLinker *proxy = [self getLinkerViaModel:model];
    proxy.data[_cellHeightKeyword] = @(cellHeight);
}

//  設定 header title
- (void)setHeaderTitle:(nonnull NSString *)headerTitle atSection:(NSUInteger)section
{
    if ( section < _headerTitles.count ) {
        [_headerTitles replaceObjectAtIndex:section withObject:headerTitle ];
        dispatch_async( dispatch_get_main_queue(), ^{
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:UITableViewRowAnimationAutomatic];
        });
    }
    else{
        int titleCnt = _headerTitles.count;
        for ( int i=titleCnt; i<section+1; i++) {
            if ( i==section) {
                [_headerTitles addObject:headerTitle];
            }
            else{
                [_headerTitles addObject:[NSNull null]];
            }
        }
    }
}

//  設定 header view
- (void)setHeaderView:(nonnull UIView*)view atSection:(NSUInteger)section
{
    //  直接指定 index 放資料，如果中間有 index 沒資料就先塞 null
    if ( section < _sectionArray.count ) {
        [_headerViews replaceObjectAtIndex:section withObject:view ];
        dispatch_async( dispatch_get_main_queue(), ^{
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:UITableViewRowAnimationAutomatic];
        });
    }
    else{
        int viewCnt = _headerViews.count;
        for ( int i=viewCnt; i<section; i++) {
            if ( i==section-1) {
                [_headerViews addObject:view];
            }
            else{
                [_headerViews addObject:[NSNull null]];
            }
        }
    }
}

- (void)setHeaderTitles:(NSArray*)titles
{
    for ( int i=0; i<titles.count; i++) {
        NSString *title = titles[i];
        [self setHeaderTitle:title atSection:i];
    }
}

- (void)setHeaderViews:(NSArray*)views
{
    for ( int i=0; i<views.count; i++) {
        UIView *view = views[i];
        [self setHeaderView:view atSection:i];
    }
}

//  設定 footer title
- (void)setFooterTitle:(nonnull NSString *)footerTitle atSection:(NSUInteger)section
{
    if ( section < _footerTitles.count ) {
        [_footerTitles replaceObjectAtIndex:section withObject:footerTitle ];
        dispatch_async( dispatch_get_main_queue(), ^{
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:UITableViewRowAnimationAutomatic];
        });
    }
    else{
        int titleCnt = _footerTitles.count;
        for ( int i=titleCnt; i<section+1; i++) {
            if ( i==section) {
                [_footerTitles addObject:footerTitle];
            }
            else{
                [_footerTitles addObject:[NSNull null]];
            }
        }
    }
}

//  設定 footer view
- (void)setFooterView:(nonnull UIView*)view atSection:(NSUInteger)section
{
    //  直接指定 index 放資料，如果中間有 index 沒資料就先塞 null
    if ( section < _footerViews.count ) {
        [_footerViews replaceObjectAtIndex:section withObject:view ];
        dispatch_async( dispatch_get_main_queue(), ^{
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:UITableViewRowAnimationAutomatic];
        });
    }
    else{
        int viewCnt = _footerViews.count;
        for ( int i=viewCnt; i<section+1; i++) {
            if ( i==section) {
                [_footerViews addObject:view];
            }
            else{
                [_footerViews addObject:[NSNull null]];
            }
        }
    }
}

- (void)setFooterTitles:(NSArray*)titles
{
    for ( int i=0; i<titles.count; i++) {
        NSString *title = titles[i];
        [self setFooterTitle:title atSection:i];
    }
}

- (void)setFooterViews:(NSArray*)views
{
    for ( int i=0; i<views.count; i++) {
        UIView *view = views[i];
        [self setFooterView:view atSection:i];
    }
}

#pragma mark - Setter

- (void)setTableView:(UITableView *)tableView
{
    _tableView = tableView;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self setRefreshScrollView:_tableView];
}


- (void)setHeaderFont:(UIFont *)headerFont
{
    _headerFont = headerFont;
    
    float fontHeight = [_headerFont pointSize];
    if ( fontHeight + 15 > _headerHeight ) {
        _headerHeight = fontHeight + 15;
    }
}

- (void)setFooterFont:(UIFont *)footerFont
{
    _footerFont = footerFont;
    
    float fontHeight = [_footerFont pointSize];
    if ( fontHeight + 15 > _footerHeight ) {
        _footerHeight = fontHeight + 15;
    }
}



#pragma mark - Override

//  透過 model 取得 cell
- (nullable id)getCellByModel:(nonnull id)model
{
    NSIndexPath *index = [self indexPathOfModel: model ];
    UITableViewCell *cell = [_tableView cellForRowAtIndexPath: index ];
    return cell;
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
        NSException *exception = [NSException exceptionWithName:@"Invalid table data" reason:[NSString stringWithFormat:@"section %ld is not exist", indexPath.section] userInfo:nil];
        @throw exception;
    }
    
    //  取出 model array 裡，當下 index 指到的 model
    id model = modelArray[indexPath.row];
    
    // class name 當作 identifier
    NSString *modelName = NSStringFromClass( [model class] );
    //  取出 model name 對映的 cell class
    NSString *cellName = [self getCellName: [model class] ];
    
    if ( !cellName ) {
        NSException *exception = [NSException exceptionWithName:@"Bind invalid" reason:[NSString stringWithFormat:@"there is no cell mapping with model '%@'",modelName] userInfo:nil];
        @throw exception;
    }
    
    UITableViewCell *cell = nil;
    if ( [model isKindOfClass:[UITableViewCellModel class]] ) {
        UITableViewCellModel *cellModel = model;
        
        NSString *identifier = nil;
        switch (cellModel.cellStyle) {
            case UITableViewCellStyleDefault:
                identifier = @"UITableViewCellStyleDefault";
                break;
            case UITableViewCellStyleSubtitle:
                identifier = @"UITableViewCellStyleSubtitle";
                break;
            case UITableViewCellStyleValue1:
                identifier = @"UITableViewCellStyleValue1";
                break;
            case UITableViewCellStyleValue2:
                identifier = @"UITableViewCellStyleValue2";
                break;
        }
        // 若取不到 cell ，在 ios 7 好像會發生例外，在ios8 就直接取回nil
        cell = [_tableView dequeueReusableCellWithIdentifier: identifier ];
        if ( !cell ){
            cell = [[UITableViewCell alloc] initWithStyle:cellModel.cellStyle reuseIdentifier: identifier ];
        }
    }
    else {
        // 若取不到 cell ，在 ios 7 好像會發生例外，在ios8 就直接取回nil
        cell = [_tableView dequeueReusableCellWithIdentifier: cellName ];
        if (!cell) {
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
    
    //  設定 touch event handle，若 binder 為 nil 表示為新生成的，這個只要執行一次就行
    [self listenUIControlOfCell:cell];

    //  model 與 cell 連結
    [self linkModel:model cell:cell];
    
    //  記錄 cell 的高，0 代表我未把這個cell height 初始，若是指定動態高 UITableViewAutomaticDimension，值為 -1
    KHModelCellLinker *linker = [self getLinkerViaModel:model];
    NSNumber *cellHeightValue = linker.data[_cellHeightKeyword];
    if( cellHeightValue == nil ){
        linker.data[_cellHeightKeyword] = @(cell.frame.size.height);
    }
    
    //  把 model 載入 cell
    [cell onLoad:model];
    
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
    KHModelCellLinker *cellLinker = [self getLinkerViaModel: model ];
    NSNumber *cellHeight = cellLinker.data[_cellHeightKeyword];
    if( cellHeight == nil ){
        NSString *cellName = [self getCellName: [model class] ];
        UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier: cellName ];
        cellLinker.data[_cellHeightKeyword] = @(cell.frame.size.height);
    }
    
    float height = [cellHeight floatValue];
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


/**
 *  回傳每個 section 的header高
 */
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    // 如果有 view 就用 view 的高
    id obj = _headerViews[ section ];
    if ( obj != [NSNull null]) {
        UIView *headerView = obj;
        return headerView.frame.size.height;
    }
    
    // 沒有 view 就看有沒有 title，有 title 就用 header height + 21
    id titleobj = _headerTitles[section];
    if( titleobj != [NSNull null] ){
        return _headerHeight;
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    // 如果有 view 就用 view 的高
    id obj = _footerViews[ section ];
    if ( obj != [NSNull null]) {
        UIView *footerView = obj;
        return footerView.frame.size.height;
    }
    
    // 沒有 view 就看有沒有 title，有 title 就用 header height + 21
    id titleobj = _footerTitles[section];
    if( titleobj != [NSNull null] ){
        return _footerHeight;
    }
    
    return 0;
}

// fixed font style. use custom view (UILabel) if you want something different
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    id titleobj = _headerTitles[section];
    return titleobj == [NSNull null] ? nil : titleobj;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = _headerViews[section];
    return view == [NSNull null] ? nil : view ;
}

- (NSString*)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    id titleobj = _footerTitles[section];
    return titleobj == [NSNull null] ? nil : titleobj;
}

- (UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *view = _footerViews[section];
    return view == [NSNull null] ? nil : view ;
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
- (void)arrayUpdate:(NSMutableArray *)array update:(id)object index:(NSIndexPath *)index
{
    [super arrayUpdate:array update:object index:index];
    if (_hasInit) {
        [_tableView reloadRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

//  更新全部
- (void)arrayUpdateAll:(NSMutableArray *)array
{
    [super arrayUpdateAll:array];
    [_tableView reloadData];
}

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
    _cellSizeKeyword = @"cellSize";

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


- (void)setCellSize:(CGSize)cellSize model:(id)model
{
    KHModelCellLinker *proxy = [self getLinkerViaModel:model];
    proxy.data[_cellSizeKeyword] = [NSValue valueWithCGSize:cellSize];
}


#pragma mark - Override

//  透過 model 取得 cell
- (nullable id)getCellByModel:(nonnull id)model
{
    NSIndexPath *index = [self indexPathOfModel: model ];
    UICollectionViewCell *cell = [_collectionView cellForItemAtIndexPath: index ];
    return cell;
}


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
//    NSLog(@"DataBinder >> %ld cell config", indexPath.row );
    NSMutableArray *modelArray = _sectionArray[indexPath.section];
    
    if ( modelArray == nil ) {
        NSException *exception = [NSException exceptionWithName:@"Invalid table data" reason:[NSString stringWithFormat:@"section %ld is not exist", indexPath.section] userInfo:nil];
        @throw exception;
    }
    
    id model = modelArray[indexPath.row];
    
    if ( model == nil ) {
        NSException *exception = [NSException exceptionWithName:@"Invalid model data" reason:@"model is nil" userInfo:nil];
        @throw exception;
    }
    
    // class name 當作 identifier
    NSString *cellName = [self getCellName: [model class] ];
    
    UICollectionViewCell *cell = nil;
    @try {
        cell = [_collectionView dequeueReusableCellWithReuseIdentifier:cellName forIndexPath:indexPath ];
    }
    @catch (NSException *exception) {
        // 這邊只會執行一次，之後就會有一個 prototype cell 一直複製
        UINib *nib = [UINib nibWithNibName:cellName bundle:[NSBundle mainBundle]];
        [_collectionView registerNib:nib forCellWithReuseIdentifier:cellName];
        cell = [_collectionView dequeueReusableCellWithReuseIdentifier:cellName forIndexPath:indexPath ];
    }
    
    //  設定 touch event handle，若 cellLinker 為 nil 表示為新生成的，這個只要執行一次就行
    [self listenUIControlOfCell:cell];

    KHModelCellLinker *cellLinker = [self getLinkerViaModel: model ];

    //  model 與 cell 連結
    [self linkModel:model cell:cell];
    
    //  記錄 size
    cellLinker.data[_cellSizeKeyword] = [NSValue valueWithCGSize:cell.frame.size];
    
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
    KHModelCellLinker *cellLinker = [self getLinkerViaModel: model ];
    NSValue *cellSizeValue = cellLinker.data[_cellSizeKeyword];
    
    if ( cellSizeValue == nil ) {
        NSString *cellName = [self getCellName: [model class] ];
        UINib *nib = [UINib nibWithNibName:cellName bundle:[NSBundle mainBundle]];
        NSArray *arr = [nib instantiateWithOwner:nil options:nil];
        _prototype_cell = arr[0];
        cellSizeValue = [NSValue valueWithCGSize:_prototype_cell.frame.size];
    }
    
    CGSize size = [cellSizeValue CGSizeValue];
//    NSLog(@"DataBinder >> %i cell size %@", indexPath.row, NSStringFromCGSize(_prototype_cell.frame.size));
    
    return size;
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
-(void)arrayUpdate:(NSMutableArray*)array update:(id)object index:(NSIndexPath*)index
{
    [super arrayUpdate:array update:object index:index];
    if ( _hasInit ) {
        [_collectionView reloadItemsAtIndexPaths:@[index]];
    }
}

-(void)arrayUpdateAll:(NSMutableArray *)array
{
    [super arrayUpdateAll:array];
    if ( _hasInit ) {
        [_collectionView reloadSections:[NSIndexSet indexSetWithIndex:array.section]];
    }
}



@end


