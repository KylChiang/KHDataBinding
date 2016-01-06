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
@interface KHCellEventHandleData : NSObject

@property (nonatomic) Class cellClass;
@property (nonatomic) NSString *propertyName;
@property (nonatomic) UIControlEvents event;
@property (nonatomic) NSInvocation *invo;
//@property (nonatomic) SEL action;

- (void)eventHandle:(id)sender;

@end

@implementation KHCellEventHandleData

- (void)eventHandle:(id)sender
{
    
}

@end


@implementation KHDataBinder

- (instancetype)init
{
    self = [super init];
    if (self) {
        _sectionArray = [[NSMutableArray alloc] initWithCapacity: 10 ];
        _modelBindMap = [[NSMutableDictionary alloc] initWithCapacity: 5 ];
        _cellCreateDic= [[NSMutableDictionary alloc] initWithCapacity: 5 ];
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

- (void)defineCell:(nonnull Class)cellClass create:(id(^)(id model))createBlock load:(void(^)(id cell, id model))loadBlock
{
    if ( [cellClass isSubclassOfClass:[KHTableViewCell class]] || [cellClass isSubclassOfClass:[KHCollectionViewCell class]] ) {
        // Gevin note: ios 9.0 你可以直接 assign nil 進去不會有問題，但是在9.0之前，會發生 exception
        NSString *cellName = NSStringFromClass(cellClass);
        if( createBlock ) _cellCreateDic[cellName] = createBlock;
        if( loadBlock ) _cellLoadDic[cellName] = loadBlock;
    }
    else{
        NSException *exception = [NSException exceptionWithName:@"class invalid" reason:@"specify class is not subclass of a KHTableViewCell or a KHCollectionViewCell" userInfo:nil];
        @throw exception;
    }
}

- (nullable NSString*)getBindCellName:(NSString*)modelName
{
    return _modelBindMap[modelName];
}


#pragma mark - Setter

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

- (void)saveEventHandle:(KHCellEventHandleData*)eventHandle
{
    if ( !_cellUIEventHandles ) {
        _cellUIEventHandles = [[NSMutableArray alloc] initWithCapacity: 10 ];
    }
    
    [_cellUIEventHandles addObject: eventHandle ];
}

- (KHCellEventHandleData*)getEventHandle:(Class)cellClass property:(NSString*)propertyName event:(UIControlEvents)event
{
    for ( KHCellEventHandleData *handleData in _cellUIEventHandles) {
        if ( [handleData.cellClass isSubclassOfClass:cellClass] && 
             [handleData.propertyName isEqualToString:propertyName] &&
             handleData.event == event ) {
            return handleData;
        }
    }
    return nil;
}


//  檢查 cell 有沒有跟 _cellUIEventHandles 記錄的 KHCellEventHandleData.propertyName 同名的 ui
//  有的話，就監聽那個 ui 的事件
- (void)listenUIControlOfCell:(nonnull id)cell
{
    //  以 cell class name 取出 array ，檢查所有的 KHCellEventHandleDatas 
    NSString *cellName = NSStringFromClass([cell class]);
    
    for ( int i=0; i<_cellUIEventHandles.count; i++ ) {
        //  取出事件資料，記錄說我要監聽哪個cell 的哪個 ui 的哪個事件
        KHCellEventHandleData *handleData = _cellUIEventHandles[i];
        
        //  檢查 cell 是否為我們指定要監聽事件的 cell
        if ( [cell isKindOfClass: handleData.cellClass ] ) {
            @try {
                //  若是我們要監聽的 cell ，從 cell 取出要監聽的 ui
                id uicontrol = [cell valueForKey: handleData.propertyName ];
                //  看這個 ui 先前是否已經有設定過監聽事件，若有的話 oldtarget 會有值，若沒有，就設定
                id oldtarget = [uicontrol targetForAction:handleData.action withSender:nil];
                if (!oldtarget) {
                    [uicontrol addTarget:self action:handleData.action forControlEvents:handleData.event ];
                }
            }
            @catch (NSException *exception) {
                NSLog(@"%@ does not exist in %@", handleData.propertyName, cellName );
                @throw exception;
            }
        }
    }
}

//  UIControl 
- (void)eventTouchUpInside:(id)ui
{
    [self eventCall:UIControlEventTouchUpInside ui:ui];
}

- (void)eventValueChanged:(id)ui
{
    [self eventCall:UIControlEventValueChanged ui:ui];
}

//  監聽的 ui control 發出事件
- (void)eventCall:(UIControlEvents)event ui:(UIControl*)ui
{
//    KHCell *cell = nil;
    id<KHCell> cell = nil;
    
    // 找出 ui control 的 parent cell
    UIView *view = ui;
    while (!cell) {
        if ( view.superview == nil ) {
            break;
        }
        if ( [view.superview conformsToProtocol:@protocol(KHCell)]) {
            cell = (id<KHCell>)view.superview;
        }
        else{
            view = view.superview;
        }
    }
    
    // Gevin note:
    //  handleData 記錄 controller 指定要監聽哪個ui 所觸發的哪個事件，然後會執行哪個 method
    //  所以當事件發生後，就要比對，ui , event , 有沒有符合，有的話就執行指定的 method
    //  確認這個 ui 是哪個 property
    for ( int i=0; i<_cellUIEventHandles.count; i++) {
        KHCellEventHandleData *handleData = _cellUIEventHandles[i];
        if ( [cell isKindOfClass: handleData.cellClass ] ) {
            id uicontrol = [(NSObject*)cell valueForKey: handleData.propertyName ];
            if ( uicontrol == ui && event == handleData.event ) {
//                @try {
                id model = cell.model;
                UIControl *control = ui;
                [handleData.invo setArgument:&control atIndex:2];
                [handleData.invo setArgument:&model atIndex:3];
                [handleData.invo invoke];
//                }
//                @catch (NSException *exception) {
//                    continue;
//                }
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
    
    //  存入 array
    KHCellEventHandleData *eventHandleData = [KHCellEventHandleData new];
    eventHandleData.cellClass = cellClass;
    eventHandleData.propertyName = pname;
    eventHandleData.event = event;
    eventHandleData.invo = eventInvocation;
    [self saveEventHandle: eventHandleData ];
}

//
- (void)removeTarget:(nonnull id)target action:(nullable SEL)action cell:(nonnull Class)cellClass propertyName:(NSString*)pName
{
    if ( _cellUIEventHandles == nil ) {
        return;
    }
    for ( int i=0; i<_cellUIEventHandles.count; i++ ) {
        KHCellEventHandleData *eventHandleData = _cellUIEventHandles[i];
        if ( [cellClass isSubclassOfClass: eventHandleData.cellClass ] && 
            [eventHandleData.propertyName isEqualToString:pName] && 
            eventHandleData.invo.target == target && 
            eventHandleData.invo.selector == action ) {
            [_cellUIEventHandles removeObjectAtIndex:i];
            break;
        }
    }
}

//
- (void)removeTarget:(nonnull id)target cell:(nonnull Class)cellClass propertyName:(nonnull NSString*)pName;
{
    if ( _cellUIEventHandles == nil ) {
        return;
    }
    int i = 0;
    while ( _cellUIEventHandles.count > i ) {
        KHCellEventHandleData *eventHandleData = _cellUIEventHandles[i];
        if ( [cellClass isSubclassOfClass: eventHandleData.cellClass ] && 
            [eventHandleData.propertyName isEqualToString:pName] && 
            eventHandleData.invo.target == target ) {
            [_cellUIEventHandles removeObjectAtIndex:i];
        }
        else{
            i++;
        }
    }
}

//
- (nullable id)getTargetByAction:(nonnull SEL)action cell:(nonnull Class)cellClass propertyName:(nonnull NSString*)pName;
{
    if ( _cellUIEventHandles == nil ) {
        return nil;
    }
    int i = 0;
    while ( _cellUIEventHandles.count > i ) {
        KHCellEventHandleData *eventHandleData = _cellUIEventHandles[i];
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




#pragma mark - Image Download

- (void)loadImageURL:(nonnull NSString*)urlString cell:(id)cell completed:(nonnull void (^)(UIImage *))completed
{
    [[KHImageDownloader instance] loadImageURL:urlString cell:cell completed:completed];
}




#pragma mark - Array Observe


//  插入
-(void)arrayInsert:(NSMutableArray*)array insertObject:(id)object index:(NSIndexPath*)index
{
    
}

//  插入 多項
-(void)arrayInsert:(nonnull NSMutableArray *)array insertObjects:(nonnull NSArray *)objects indexes:(nonnull NSIndexSet *)indexSet
{
    
}

//  刪除
-(void)arrayRemove:(NSMutableArray*)array removeObject:(id)object index:(NSIndexPath*)index
{

}

//  刪除全部
-(void)arrayRemoveAll:(NSMutableArray *)array indexs:(NSArray *)indexs
{

}

//  取代
-(void)arrayReplace:(NSMutableArray*)array newObject:(id)newObj replacedObject:(id)oldObj index:(NSIndexPath*)index
{

}

//  更新
-(void)arrayUpdate:(NSMutableArray*)array update:(id)object index:(NSIndexPath*)index
{

}

-(void)arrayUpdateAll:(NSMutableArray *)array
{

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
    
    _headerHeight = 10;
    _footerHeight = 0;
    
    // 預設 KHTableCellModel 配 KHTableViewCell
    [self bindModel:[KHTableCellModel class] cell:[KHTableViewCell class]];
    // KHTableViewCell 不使用 nib，使用預設的 UITableViewCell，所以自訂建立方式
    [self defineCell:[KHTableViewCell class] create:^id(KHTableCellModel *model) {
        KHTableViewCell *cell = [[KHTableViewCell alloc] initWithStyle:model.cellStyle reuseIdentifier:@"UITableViewCell" ];
        return cell;
    } load:nil];
}

#pragma mark - Public


- (void)setHeaderTitles:(nullable NSArray*)titles
{
    _titles = [titles copy];
}

#pragma mark - Property Setter

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
        NSException *exception = [NSException exceptionWithName:@"Invalid table data" reason:[NSString stringWithFormat:@"section %ld is not exist", indexPath.section] userInfo:nil];
        @throw exception;
    }
    
    KHCellModel *model = modelArray[indexPath.row];
    
    if ( model == nil ) {
        NSException *exception = [NSException exceptionWithName:@"Invalid model data" reason:@"model is nil" userInfo:nil];
        @throw exception;
    }
    // 記錄 index
    model.index = indexPath;
    
    // class name 當作 identifier
    NSString *modelName = NSStringFromClass( [model class] );
    NSString *cellName = [self getBindCellName: modelName ];
    if ( cellName == nil ) {
        NSException *exception = [NSException exceptionWithName:@"Bind invalid" reason:[NSString stringWithFormat:@"there is no cell bind with model %@",modelName] userInfo:nil];
        @throw exception;
    }
    KHTableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier: cellName ];
    // 若取不到 cell ，在 ios 7 好像會發生例外，在ios8 就直接取回nil
    if (cell==nil) {
        //  若 model 有設定 create block，就使用 model 的
        id(^createBlock)(id) = _cellCreateDic[cellName];
        if ( createBlock ) {
            cell = createBlock(model);
        }
        else{
            //  使用預設的方式，透過 model mapping cell ，再取 cell name 相同的 nib 來生成 cell
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
    cell.helper = self;
    cell.model = model;
    
    //  記錄 cell 的高，0 代表我未把這個cell height 初始，若是指定動態高 UITableViewAutomaticDimension，值為 -1
    if( model.cellHeight == 0 ) model.cellHeight = cell.frame.size.height;
    else if( model.cellHeight == UITableViewAutomaticDimension && model.estimatedCellHeight == 44 ) model.estimatedCellHeight = cell.frame.size.height;
    
    //  把 model 載入 cell
    [cell onLoad:model];
    void(^loadBlock)(id cell, id model) = _cellLoadDic[cellName];
    if ( loadBlock ) {
        loadBlock( cell, model );
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
    KHCellModel *model = array[indexPath.row];
    float height = model.cellHeight;
//    NSLog(@" %ld cell height %f", indexPath.row,height );
    if ( height == 0 ) {
        return 44;
    }
    return height;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
//    NSLog(@" %ld estimated cell height 44", indexPath.row );
    NSMutableArray* array = _sectionArray[indexPath.section];
    KHCellModel *model = array[indexPath.row];
    return model.estimatedCellHeight;
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
//    if (_hasInit){
        [_tableView insertRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationBottom];
//    }
}

//  插入 多項
-(void)arrayInsert:(nonnull NSMutableArray *)array insertObjects:(nonnull NSArray *)objects indexes:(nonnull NSArray *)indexes
{
//    if (_hasInit){
        [_tableView insertRowsAtIndexPaths:indexes withRowAnimation:UITableViewRowAnimationBottom];
//    }    
}

//  刪除
-(void)arrayRemove:(NSMutableArray*)array removeObject:(id)object index:(NSIndexPath*)index
{
    if (_hasInit) {
        [_tableView deleteRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationTop];
    }
}

//  刪除全部
-(void)arrayRemoveAll:(NSMutableArray *)array indexs:(NSArray *)indexs
{
    if(_hasInit){
        [_tableView deleteRowsAtIndexPaths:indexs withRowAnimation:UITableViewRowAnimationTop];
    }
}

//  取代
-(void)arrayReplace:(NSMutableArray*)array newObject:(id)newObj replacedObject:(id)oldObj index:(NSIndexPath*)index
{
    if (_hasInit){
        [_tableView reloadRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationFade];
    }
}

//  更新
-(void)arrayUpdate:(NSMutableArray*)array update:(id)object index:(NSIndexPath*)index
{
    if (_hasInit){
        [_tableView reloadRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationFade];
    }
}

-(void)arrayUpdateAll:(NSMutableArray *)array
{
    if (_hasInit){
        [_tableView reloadSections:[NSIndexSet indexSetWithIndex:array.section] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}




@end







#pragma mark - KHCollectionDataBinder
#pragma mark -


@implementation KHCollectionDataBinder

- (instancetype)init
{
    self = [super init];
    
    _hasInit = NO;

    return self;
}

#pragma mark - Public

- (UICollectionViewLayout*)layout
{
    return _collectionView.collectionViewLayout;
}

#pragma mark - Property Setter

- (void)setCollectionView:(UICollectionView *)collectionView
{
    _collectionView = collectionView;
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
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
    //    printf("config cell %ld \n", indexPath.row );
    NSMutableArray *modelArray = _sectionArray[indexPath.section];
    
    if ( modelArray == nil ) {
        NSException *exception = [NSException exceptionWithName:@"Invalid table data" reason:[NSString stringWithFormat:@"section %ld is not exist", indexPath.section] userInfo:nil];
        @throw exception;
    }
    
    KHCellModel *model = modelArray[indexPath.row];
    
    if ( model == nil ) {
        NSException *exception = [NSException exceptionWithName:@"Invalid model data" reason:@"model is nil" userInfo:nil];
        @throw exception;
    }
    // 記錄 index
    model.index = indexPath;
    
    // class name 當作 identifier
    NSString *modelName = NSStringFromClass([model class]);
    NSString *cellName = [self getBindCellName: NSStringFromClass([model class]) ];
    
    KHCollectionViewCell *cell = nil;
    @try {
        cell = [_collectionView dequeueReusableCellWithReuseIdentifier:cellName forIndexPath:indexPath ];
    }
    @catch (NSException *exception) {
        
        //  若有設定 create block，就使用設定的
        id(^createBlock)(id) = _cellCreateDic[modelName];
        if ( createBlock ) {
            cell = createBlock(model);
        }
        else{
            // 這邊只會執行一次，之後就會有一個 prototype cell 一直複製
            UINib *nib = [UINib nibWithNibName:cellName bundle:[NSBundle mainBundle]];
            [_collectionView registerNib:nib forCellWithReuseIdentifier:cellName];
            cell = [_collectionView dequeueReusableCellWithReuseIdentifier:cellName forIndexPath:indexPath ];
            
            NSArray *arr = [nib instantiateWithOwner:nil options:nil];
            KHCollectionViewCell *_cell = arr[0];
            UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout*)_collectionView.collectionViewLayout;
            layout.itemSize = _cell.frame.size;
            
//            NSLog(@"cell size %@, layout size %@", NSStringFromCGSize(cell.frame.size), NSStringFromCGSize(layout.itemSize) );
        }
    }
    
    //  設定 touch event handle
    [self listenUIControlOfCell:cell];
    
    //  assign reference
    cell.helper = self;
    cell.model = model;
    
    //  把 model 載入 cell
    [cell onLoad:model];
    void(^loadBlock)(id cell, id model) = _cellLoadDic[modelName];
    if ( loadBlock ) {
        loadBlock( cell, model );
    }
    
    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    _hasInit = YES;
    return _sectionArray.count;
}

#pragma mark - UICollectionViewFlowLayout

//- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath;
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
//    if ( _hasInit ) {
        [_collectionView insertItemsAtIndexPaths:@[index]];
//    }
}

//  插入 多項
-(void)arrayInsert:(nonnull NSMutableArray *)array insertObjects:(nonnull NSArray *)objects indexes:(nonnull NSArray *)indexes
{
//    if (_hasInit){
        [_collectionView insertItemsAtIndexPaths:indexes];
//    }    
}

//  刪除
-(void)arrayRemove:(NSMutableArray*)array removeObject:(id)object index:(NSIndexPath*)index
{
    if ( _hasInit ) {
        [_collectionView deleteItemsAtIndexPaths:@[index]];
    }
}

//  刪除全部
-(void)arrayRemoveAll:(NSMutableArray *)array indexs:(NSArray *)indexs
{
    if ( _hasInit ) {
        [_collectionView deleteItemsAtIndexPaths:indexs];
    }
}

//  取代
-(void)arrayReplace:(NSMutableArray*)array newObject:(id)newObj replacedObject:(id)oldObj index:(NSIndexPath*)index
{
    if ( _hasInit ) {
        [_collectionView reloadItemsAtIndexPaths:@[index]];
    }
}

//  更新
-(void)arrayUpdate:(NSMutableArray*)array update:(id)object index:(NSIndexPath*)index
{
    if ( _hasInit ) {
        [_collectionView reloadItemsAtIndexPaths:@[index]];
    }
}

-(void)arrayUpdateAll:(NSMutableArray *)array
{
    if ( _hasInit ) {
        [_collectionView reloadSections:[NSIndexSet indexSetWithIndex:array.section]];
    }
}



@end

