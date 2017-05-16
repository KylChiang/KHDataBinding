//
//  KHTableView.m
//  KHDataBindingDemo
//
//  Created by GevinChen on 2017/3/7.
//  Copyright © 2017年 omg. All rights reserved.
//




#import "KHTableView.h"

#define HEADER UICollectionElementKindSectionHeader 
#define FOOTER UICollectionElementKindSectionFooter


@implementation KHTableView

- (instancetype)initWithFrame:(CGRect)frame style:(UITableViewStyle)style
{
    self = [super initWithFrame:frame style:style];
    
    [self initImpl];
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    [self initImpl];
    
    return self;
}



- (void)dealloc
{
    self.autoExpandHeight = NO;
}

- (void)initImpl
{
    _isNeedAnimation = YES;
    _sections = [[NSMutableArray alloc] initWithCapacity: 10 ];
    _pairDic   = [[NSMutableDictionary alloc] initWithCapacity: 5 ];
    _cellClassDic = [[NSMutableDictionary alloc] initWithCapacity: 5 ];
    _cellDefaultSizeDic = [[NSMutableDictionary alloc] initWithCapacity: 5 ];
    _item_animationQueue = [[NSMutableArray alloc] initWithCapacity: 3 ];
    //  init animation queue struct
    [_item_animationQueue addObject: [[NSMutableArray alloc] initWithCapacity: 10 ] ]; // insert
    [_item_animationQueue addObject: [[NSMutableArray alloc] initWithCapacity: 10 ] ]; // remove
    [_item_animationQueue addObject: [[NSMutableArray alloc] initWithCapacity: 10 ] ]; // reload    
    
    _section_animationQueue= [[NSMutableArray alloc] initWithCapacity: 3 ];
    //  init animation queue struct
    [_section_animationQueue addObject: [NSMutableIndexSet indexSet] ]; // insert
    [_section_animationQueue addObject: [NSMutableIndexSet indexSet] ]; // remove
    [_section_animationQueue addObject: [NSMutableIndexSet indexSet] ]; // reload    

    _eventDatas = [[NSMutableArray alloc] initWithCapacity: 10 ];
    
    _headerModelDic = [[NSMutableDictionary alloc] initWithCapacity: 10 ];
    _footerModelDic = [[NSMutableDictionary alloc] initWithCapacity: 10 ];
//    _headerViewDic = [[NSMutableDictionary alloc] initWithCapacity: 5 ];
//    _footerViewDic = [[NSMutableDictionary alloc] initWithCapacity: 5 ];
    _headerViewSizeDic = [[NSMutableDictionary alloc] initWithCapacity: 5 ];
    _footerViewSizeDic = [[NSMutableDictionary alloc] initWithCapacity: 5 ];
    
    
    //  init UIRefreshControl
    _refreshControl = [[UIRefreshControl alloc] init];
    _refreshControl.backgroundColor = [UIColor clearColor];
    _refreshControl.tintColor = [UIColor lightGrayColor]; // spinner color
    [_refreshControl addTarget:self
                        action:@selector(refreshHead:)
              forControlEvents:UIControlEventValueChanged];
    NSDictionary *attributeDic = @{NSForegroundColorAttributeName:[UIColor lightGrayColor],
                                   NSFontAttributeName:[UIFont boldSystemFontOfSize:14]};
    _refreshTitle = [[NSAttributedString alloc] initWithString:@"Pull down to reload!" attributes:attributeDic];
    _refreshControl.attributedTitle = _refreshTitle;//[[NSAttributedString alloc] initWithString:@"Pull down to reload!" attributes:attributeDic];
    
    //  default model mapping
    [self setMappingModel:[UITableViewCellModel class] cell:[UITableViewCell class]];
    //  register UICollectionContainerCell for non reuse cell
    [self setMappingModel:[UIView class] cell:[UITableContainerCell class]];
    
    // register loading footer
    [self registerClass:[KHTableViewLoadingFooter class] forHeaderFooterViewReuseIdentifier:NSStringFromClass([KHTableViewLoadingFooter class])];
    
    // init loading footer indicator view
    UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    [indicatorView startAnimating];
    indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    _loadingIndicator = indicatorView;
    _loadingIndicator.hidden = YES;
    _onEndReachedThresHold = 30.0f;
    
    //  assign delegate
    self.delegate = self;
    self.dataSource = self;
}


//#pragma mark - Override
//
//- (void)reloadData
//{
//    if( !_needReload ){
//        [super reloadData];
//        _needReload = YES;
//    }
//}


#pragma mark - autoExpandHeight

// @todo: 要再找個 時間點執行 constraintHeight.constant = xxx;
- (void)setAutoExpandHeight:(BOOL)autoExpandHeight
{
    if( _autoExpandHeight == autoExpandHeight ) return;
    _autoExpandHeight = autoExpandHeight;
    if ( _autoExpandHeight ) {
        NSArray *constraints = self.constraints;
        for (int i=0; i<constraints.count; i++ ) {
            NSLayoutConstraint *constraint = constraints[i];
            if ( constraint.firstItem == self && constraint.firstAttribute == NSLayoutAttributeHeight ) {
                constraintHeight = constraint;
                isExist = YES; // 標記為，原本就有 constraint height
                break;
            }
        }
        
        //  原本的 layout 並沒有
        if ( constraintHeight == nil ) {
            isExist = NO; // 標記為是後來才加入的
            constraintHeight = [NSLayoutConstraint constraintWithItem:self 
                                                            attribute:NSLayoutAttributeHeight 
                                                            relatedBy:NSLayoutRelationEqual 
                                                               toItem:nil
                                                            attribute:0
                                                           multiplier:1
                                                             constant:self.contentSize.height];
            [self addConstraint:constraintHeight];
        }
        [self addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:NULL]; //NSKeyValueObservingOptionOld
    }
    else{
        //  如果不是原本就有 constraint height 的，就把它移除
        if ( constraintHeight && !isExist ) {
            [self removeConstraint: constraintHeight ];
        }
        constraintHeight = nil;
        [self removeObserver:self forKeyPath:@"contentSize"];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ( [keyPath isEqualToString:@"contentSize"] ) {
        constraintHeight.constant = self.contentSize.height;
    }
}


#pragma mark - Pair Info

- (KHPairInfo*)createNewPairInfo
{
    KHPairInfo *pairInfo = [[KHPairInfo alloc] init];
    return pairInfo;
}

- (KHPairInfo *) addPairInfo:(id)object
{
    //  防呆，避免加入兩次 pairInfo
    KHPairInfo *pairInfo = [self getPairInfo:object];
    if ( !pairInfo ) {
        pairInfo = [self createNewPairInfo];
        NSValue *myKey = [NSValue valueWithNonretainedObject:object];
        _pairDic[myKey] = pairInfo;
    }
//    NSString *cellName = [self getMappingCellFor:object index:nil];
//    if ( cellName == nil ){
//        pairInfo.pairCellName = cellName;
//        pairInfo.cellSize = [self getDefaultSizeForCellClass:NSClassFromString(cellName)];
//    }
    pairInfo.tableView = self;
    pairInfo.model = object;
    return pairInfo;
}

- (void) removePairInfo:(id)object
{
    NSValue *myKey = [NSValue valueWithNonretainedObject:object];
    KHPairInfo *pairInfo = _pairDic[myKey];
    pairInfo.model = nil;
    pairInfo.tableView = nil;
    pairInfo.collectionView = nil;
    [_pairDic removeObjectForKey:myKey];
}

- (void) replacePairInfo:(id)oldObject new:(id)newObject
{
    NSValue *oldKey = [NSValue valueWithNonretainedObject:oldObject];
    KHPairInfo *pairInfo = _pairDic[oldKey];
    [_pairDic removeObjectForKey:oldKey];
    pairInfo.model = newObject;
    NSValue *newKey = [NSValue valueWithNonretainedObject:newObject];
    _pairDic[newKey] = pairInfo;
}

//  取得某個 model 的 cell 介接物件
- (nullable KHPairInfo*)getPairInfo:(id _Nonnull)model
{
    NSValue *myKey = [NSValue valueWithNonretainedObject:model];
    return _pairDic[myKey];
}

////  連結 model 與 cell
//- (void)pairedModel:(id)model cell:(UITableViewCell*)cell
//{
//    //  取出 model 的 pairInfo
//    KHPairInfo *pairInfo = [self getPairInfo: model ];
//    
//    //  斷開先前的 reference
////    cell.pairInfo.cell = nil;
////    cell.pairInfo = nil;
//    //  cell reference pairInfo
//    cell.pairInfo = pairInfo;
//    //  pairInfo reference cell
////    pairInfo.cell = cell;
//}


#pragma mark - Bind Array


- (void)observeArray:(NSMutableArray *_Nonnull)array
{
    for ( NSArray *marray in _sections ) {
        if ( marray == array ) {
            return;
        }
    }
    //  Gevin note: 不知道為何，containsObject: 把兩個空 array 視為同一個
    array.kh_delegate = self;
    array.kh_section = _sections.count;
    [_sections addObject: array ];
    //  若 array 裡有資料，那就要建立 proxy
    for ( id object in array ) {
        [self addPairInfo: object ];
    }
    if( _firstReload ) {
        [self addInsertSectionAnimation:array.kh_section];
        [self runSectionAnimation];
    }
    else{
        [self reloadData];
    }
}

- (void)deObserveBindArray:(NSMutableArray *_Nonnull)array
{
    BOOL find = NO;
    for ( NSArray *marray in _sections ) {
        if ( marray == array ) {
            find = YES;
            break;
        }
    }
    if ( find ) {
        [_sections removeObject: array ];
        if( _firstReload ) {
            [self addRemoveSectionAnimation:array.kh_section];
            [self runSectionAnimation];
        }
        else{
            [self reloadData];
        }
        array.kh_delegate = nil;
        array.kh_section = 0;
        //  移除 proxy
        for ( id object in array ) {
            [self removePairInfo: object ];
        }
    }
}


- (NSMutableArray *_Nonnull)createSection
{
    NSMutableArray *bindArray = [[NSMutableArray alloc] init];
    [self observeArray:bindArray];
    return bindArray;
    
}

- (NSMutableArray *_Nullable)getSection:(NSInteger)section
{
    if ( _sections.count <= section ) {
        return nil;
    }
    
    return _sections[section];
}

- (void)addSection:(NSMutableArray *_Nonnull)array
{
    [self observeArray:array];
}

- (void)removeSection:(NSMutableArray *_Nonnull)array
{
    [self deObserveBindArray:array];
}

- (void)removeSectionAt:(NSInteger)section
{
    if ( section >= _sections.count ) {
        return;
    }
    NSMutableArray *array = _sections[section];
    [self deObserveBindArray:array];
}

- (NSUInteger)sectionCount
{
    return _sections.count;
}

#pragma mark - Data Model

- (NSIndexPath *_Nullable)indexPathForModel:(id _Nonnull)model
{
    for ( NSInteger i=0 ; i<_sections.count ; i++ ) {
        NSArray *arr = _sections[i];
        for ( NSInteger j=0 ; j<arr.count ; j++ ) {
            id compare_model = arr[j];
            if ( model == compare_model ) {
                NSIndexPath *index = [NSIndexPath indexPathForRow:j inSection:i];
                return index;
            }
        }
    }
    return nil;
}

- (UITableViewCell *_Nullable)cellForModel:(id _Nonnull)model
{
    NSIndexPath *index = [self indexPathForModel: model ];
//    UITableViewCell *cell = [self cellForItemAtIndexPath: index ];
    UITableViewCell *cell = [self cellForRowAtIndexPath:index];
    return cell;
}

- (id _Nullable)modelForCell:(UITableViewCell *_Nonnull)cell
{
    NSIndexPath* index = [self indexPathForCell:cell];
    id model = [self modelForIndexPath:index];
    return model;
//    for ( NSValue *myKey in _pairDic ) {
//        KHPairInfo *pairInfo = _pairDic[myKey];
//        if ( pairInfo.cell == cell ) {
//            return pairInfo.model;
//        }
//    }
    
}

- (id _Nullable)modelForIndexPath:(NSIndexPath*_Nonnull)indexPath
{
    if (indexPath.section >= _sections.count) {
        return nil;
    }
    
    NSArray *sectionArray = _sections[indexPath.section];
    if (indexPath.row >= sectionArray.count) {
        return nil;
    }
    
    id model = sectionArray[indexPath.row];
    
    return model;
}

#pragma mark - Lookup back

//  透過某個 responder UI，取得 cell
- (nullable UITableViewCell*)cellForUI:(UIControl *_Nonnull)uiControl
{
    if ( uiControl.superview == nil ) {
        return nil;
    }
    UITableViewCell *cell = nil;
    UIView *superView = uiControl.superview;
    while ( superView ) {
        if ( [superView isKindOfClass:[UITableViewCell class]] ) {
            cell = (UITableViewCell *)superView;
            break;
        }
        superView = superView.superview;
    }
    return cell;
}

//  透過某個 responder UI，取得 model
- (nullable id)modelForUI:(UIControl *_Nonnull)uiControl
{
    UITableViewCell *cell = [self cellForUI: uiControl ];
    if ( cell == nil ) {
        return nil;
    }
    id model = [self modelForCell: cell ];
    return model;
}


#pragma mark - Config Model Cell Mapping

//  設定對映
- (void)setMappingModel:(Class _Nonnull)modelClass cell:(Class _Nonnull)cellClass
{
    NSString *modelName;
    if ( modelClass == [NSDictionary class] || modelClass == [NSMutableDictionary class] ) {
        modelName = @"NSDictionary";
    }
    else if( modelClass == [NSArray class] || modelClass == [NSMutableArray class] ){
        modelName = @"NSArray";
    }
    else if( modelClass == [NSString class] || modelClass == [NSMutableString class] ){
        modelName = @"NSString";
    }
    else if( modelClass == [NSNumber class]){
        modelName = @"NSNumber";
    }
    else if( [modelClass isSubclassOfClass:[UIView class]] ){
        modelName = @"UIView";
    }
    else{
        modelName = NSStringFromClass(modelClass);
    }
    NSString *cellName = NSStringFromClass(cellClass);
    _cellClassDic[modelName] = cellName;
    
    if([[NSBundle mainBundle] pathForResource:cellName ofType:@"nib"] != nil) {
        UINib*nib = [UINib nibWithNibName:cellName bundle:nil];
        [self registerNib:nib forCellReuseIdentifier:cellName];
        NSArray *views = [nib instantiateWithOwner:nil options:nil];
        UIView *prototype = views[0];
        [self setDefaultSize:prototype.frame.size forCellClass:cellClass];
    }
    else {
        [self registerClass:cellClass forCellReuseIdentifier:cellName];
    }    
}

//  設定對映，使用 block 處理
- (void)setMappingModel:(Class _Nonnull)modelClass block:( Class _Nullable(^ _Nonnull)(id _Nonnull model, NSIndexPath *_Nonnull index))mappingBlock
{
    NSString *modelName;
    if ( modelClass == [NSDictionary class] || modelClass == [NSMutableDictionary class] ) {
        modelName = @"NSDictionary";
    }
    else if( modelClass == [NSArray class] || modelClass == [NSMutableArray class] ){
        modelName = @"NSArray";
    }
    else if( modelClass == [NSString class] || modelClass == [NSMutableString class] ){
        modelName = @"NSString";
    }
    else if( [modelClass isSubclassOfClass:[UIView class]] ){
        modelName = @"UIView";
    }
    else{
        modelName = NSStringFromClass(modelClass);
    }
    _cellClassDic[modelName] = [mappingBlock copy];
}

//  取得對映的 cell class
- (NSString *_Nullable)getMappingCellFor:(id _Nonnull)model index:(NSIndexPath *_Nullable)index
{
    /*
     Gevin note:
     NSString 我透過 [cellClass mappingModelClass]; 取出 class 轉成字串，會得到 NSString
     但是透過 NSString 的實體，取得 class 轉成字串，卻會是 __NSCFConstantString
     2017-02-13 : 改直接用 class 做檢查
     
     */
    NSString *modelName;
    if ( [model isKindOfClass: [NSString class] ] ) {
        modelName = @"NSString";
    }
    else if( [model isKindOfClass:[NSDictionary class]] ){
        modelName = @"NSDictionary";
    }
    else if( [model isKindOfClass:[NSArray class]] ){
        modelName = @"NSArray";
    }
    else if( [model isKindOfClass:[UIView class]]){
        modelName = @"UIView";
    }
    else{
        modelName = NSStringFromClass( [model class] );
    }
    
    id obj = _cellClassDic[modelName];
    //  _cellClassDic 記錄的 不是字串，就是 block，若兩個都沒有
    if ( [obj isKindOfClass:[NSString class]]) {
        return obj;
    }
    else if( obj != nil ){
        Class _Nullable(^mappingBlock)(id _Nonnull model, NSIndexPath *_Nonnull index) = obj;
        Class cellClass = mappingBlock( model, index );
        NSString *cellName = NSStringFromClass(cellClass);
        return cellName;
    }
    else{
        NSLog(@"KHTableView !!!! warnning !!!! Can't find any CellName mapping with this class %@", modelName );
        return nil;
    }
    //    return cellName;
}


#pragma mark - Cell Size

- (CGSize)getCellSizeFor:(id _Nonnull)model
{
    KHPairInfo *pairInfo = [self getPairInfo:model];
    return pairInfo.cellSize;
}

- (void)setCellSize:(CGSize)cellSize model:(id)model
{
    [self setCellSize:cellSize model:model animated:NO];
}

- (void)setCellSize:(CGSize)cellSize model:(id)model animated:(BOOL)animated
{
    if ( model == nil ) {
        NSLog(@"KHTableView !!! warning !!! the model pass to set cell size method is nil");
        return;
    }
    KHPairInfo *pairInfo = [self getPairInfo:model];
    if ( !pairInfo ) {
        pairInfo = [self addPairInfo:model];
    }
    pairInfo.cellSize = cellSize;
//    if ( animated && _firstReload ) {
//        NSIndexPath *index = [self indexPathForModel:model];
//        [self runReloadAnimation:index];
//    }
//    else{
//        [self reloadData];
//    }
}

- (void)setCellSize:(CGSize)cellSize models:(NSArray *_Nonnull)models
{
    for ( id model in models ) {
        [self setCellSize:cellSize model:model];
    }
}

- (void)setDefaultSize:(CGSize)cellSize forCellClass:(Class _Nonnull)cellClass
{
    NSString *cellName = NSStringFromClass(cellClass);
    NSValue *value = [NSValue valueWithCGSize:cellSize];
    _cellDefaultSizeDic[cellName] = value; 
}

- (CGSize)getDefaultSizeForCellClass:(Class _Nonnull)cellClass
{
    NSString *cellName = NSStringFromClass(cellClass);
    NSValue *value = _cellDefaultSizeDic[cellName];
    if (value) {
        return [value CGSizeValue];
    }
    return CGSizeMake(-1, -1); 
}


#pragma mark - Header / Footer

#pragma mark Set Model

- (void)setHeaderFooter:(NSString* _Nonnull)kind model:(id _Nullable)model atIndex:(NSInteger)section
{
    if ( section >= _sections.count ) {
        NSLog(@"Warring!!! the section index %d of %@ model out of bound %d.", (int)section, kind == HEADER ? @"header":@"footer", (int)_sections.count );
        return;
    }
    NSMutableArray *sectionArray = _sections[section];
    NSValue *key = [NSValue valueWithNonretainedObject:sectionArray];
    NSMutableDictionary *targetDic = nil;
    float height = 0;
    if ( kind == HEADER ) {
        targetDic = _headerModelDic;
        height = self.sectionHeaderHeight;
    }
    else if( kind == FOOTER ){
        targetDic = _footerModelDic;
        height = self.sectionFooterHeight;
    }
    else{
        return;
    }
    targetDic[key] = model;
    
    //  set height
    if ( [model isKindOfClass:[NSString class]]) {
        [self setHeight:height headerFooterKind:kind at:section];
    }
    else if( [model isKindOfClass:[UIView class]]){
        UIView *view = model;
        [self setHeight:view.frame.size.height headerFooterKind:kind at:section];
    }
}


// 直接給予 header array
- (void)setHeaderModels:(NSArray*_Nullable)models
{
    if (models) {
        for ( int i=0; i<models.count; i++) {
            id model = models[i];
            [self setHeaderModel:model at:i];
        }
    }
    else{
        int section_cnt = _sections.count;
        for ( int i=0; i<section_cnt; i++ ) {
            [self setFooterModel:nil at:i];
        }
    }
}

- (void)setFooterModels:(NSArray *_Nullable)models
{
    if (models) {
        for ( int i=0; i<models.count; i++) {
            id model = models[i];
            [self setFooterModel:model at:i];
        }
    }
    else{
        int section_cnt = _sections.count;
        for ( int i=0; i<section_cnt; i++ ) {
            [self setFooterModel:nil at:i];
        }
    }
}


- (void)setHeaderModel:(id _Nullable)model at:(NSInteger)section
{
    [self setHeaderFooter:HEADER model:model atIndex:section];
}

- (void)setFooterModel:(id _Nullable)model at:(NSInteger)section
{
    [self setHeaderFooter:FOOTER model:model atIndex:section];
}


#pragma mark Get Header Footer Model

- (id _Nullable)getHeaderFooterModel:(NSString*)kind at:(NSInteger)section
{
    if ( section >= _sections.count || section < 0 ) {
        return nil;
    }
    NSDictionary *targetDic = nil;
    if ( kind == HEADER ) {
        targetDic = _headerModelDic;
    }
    else if( kind == FOOTER ){
        targetDic = _footerModelDic;
    }
    else{
        return nil;
    }
    NSMutableArray *sectionArray = _sections[section];
    NSValue *key = [NSValue valueWithNonretainedObject:sectionArray];
    id obj = targetDic[key];
    return obj;    
}

- (id _Nullable)headerModelAt:(NSInteger)section
{
    return [self getHeaderFooterModel:HEADER at:section];
}

- (id _Nullable)footerModelAt:(NSInteger)section
{
    return [self getHeaderFooterModel:FOOTER at:section];
}

#pragma mark Get Header Footer Sectoin

- (NSInteger)sectionForHeaderFooter:(NSString* _Nonnull)kind model:(id _Nonnull)model
{
    NSDictionary *targetDic = nil;
    if ( kind == HEADER ) {
        targetDic = _headerModelDic;
    }
    else if( kind == FOOTER ){
        targetDic = _footerModelDic;
    }
    for ( int i=0; i<_sections.count; i++) {
        NSArray *array = _sections[i];
        NSValue *key = [NSValue valueWithNonretainedObject:array];
        id tmp_model = targetDic[key];
        if ( tmp_model == model ) {
            return i;
        }
    }
    return -1;
}

// headerObj 可以是 UIView 或是 NSString
- (NSInteger)sectionForHeaderModel:(id _Nonnull)model
{
    return [self sectionForHeaderFooter:HEADER model:model];
}

- (NSInteger)sectionForFooterModel:(id _Nonnull)model
{
    return [self sectionForHeaderFooter:FOOTER model:model];
}

- (NSInteger)sectionForHeaderFooter:(NSString* _Nonnull)kind UI:(UIView* _Nonnull)ui
{
    NSDictionary *targetDic = nil;
    if ( kind == HEADER ) {
        targetDic = _headerModelDic;
    }
    else if( kind == FOOTER ){
        targetDic = _footerModelDic;
    }
    for ( int i=0; i<_sections.count; i++) {
        NSArray *array = _sections[i];
        NSValue *key = [NSValue valueWithNonretainedObject:array];
        id tmp_model = targetDic[key];
        if ( [tmp_model isKindOfClass:[UIView class]] ) {
            UIView *view = (UIView *)tmp_model;
            if ( [ui isDescendantOfView:view] ) {
                return i;
            }
        }
    }
    return -1;
}


- (NSInteger)sectionForHeaderUI:(id _Nonnull)ui
{
    return [self sectionForHeaderFooter:HEADER UI:ui];
}

- (NSInteger)sectionForFooterUI:(id _Nonnull)ui
{
    return [self sectionForHeaderFooter:FOOTER UI:ui];
}


#pragma mark - Header / Footer Height

- (void)setHeight:(CGFloat)height headerFooterKind:(NSString*)kind at:(NSInteger)section
{
    if ( section >= _sections.count  || section < 0 ) {
        return;
    }
    NSArray *sectionArray = _sections[section];
    NSValue *key = [NSValue valueWithNonretainedObject:sectionArray];
    if ( kind == HEADER ) {
        _headerViewSizeDic[key] = @(height);
    }
    else if( kind == FOOTER ){
        _footerViewSizeDic[key] = @(height);
    }    
}

- (CGFloat)getHeightForHeaderfooterKind:(NSString*)kind at:(NSInteger)section
{
    if ( section >= _sections.count  || section < 0 ) {
        return -1;
    }
    NSArray *sectionArray = _sections[section];
    NSValue *key = [NSValue valueWithNonretainedObject:sectionArray];
    NSNumber *value = nil;
    if ( kind == HEADER ) {
        value = _headerViewSizeDic[key];
    }
    else if( kind == FOOTER ){
        value = _footerViewSizeDic[key];
    }    
    if ( value == nil ) {
        return -1;
    }
    return [value floatValue];
}


- (void)setHeightForHeader:(CGFloat)height at:(NSInteger)section
{
    [self setHeight:height headerFooterKind:HEADER at:section];
}

- (void)setHeightForFooter:(CGFloat)height at:(NSInteger)section
{
    [self setHeight:height headerFooterKind:FOOTER at:section];
}

- (CGFloat)heightForHeaderAt:(NSInteger)section
{
    return [self getHeightForHeaderfooterKind:HEADER at:section];
}

- (CGFloat)heightForFooterAt:(NSInteger)section
{
    return [self getHeightForHeaderfooterKind:FOOTER at:section]; 
}


#pragma mark - UI Event Handle


// 指定要監聽某個 cell 上的某個 ui，這邊要注意，你要監聽的 UIResponder 一定要設定為一個 property，那到時觸發事件後，你想要知道是屬於哪個 cell 或哪個 model，再另外反查
- (void)addTarget:(nullable id)target 
           action:(nonnull SEL)action
 forControlEvents:(UIControlEvents)event 
           onCell:(nonnull Class)cellClass
     propertyName:(nonnull NSString*)property
{
    KHEventHandleData *eventData = [KHEventHandleData new];
    eventData.target = target;
    eventData.action = action;
    eventData.event = event;
    eventData.cellClass = cellClass;
    eventData.propertyName = property;
    [_eventDatas addObject:eventData];
}

- (void)addTarget:(nullable id)target
           action:(nonnull SEL)action
 forControlEvents:(UIControlEvents)event 
           onCell:(nonnull Class)cellClass 
    propertyNames:(nonnull NSArray<NSString*>*)properties
{
    for ( NSString *propertyName in properties ) {
        [self addTarget:target action:action forControlEvents:event onCell:cellClass propertyName:propertyName];
    }
}

- (void)removeTarget:(nullable id)target action:(nonnull SEL)action forControlEvents:(UIControlEvents)event onCell:(nonnull Class)cellClass propertyName:(nonnull NSString*)property
{
    for ( int i=0 ; i<_eventDatas.count ; i++ ) {
        KHEventHandleData *eventData = _eventDatas[i];
        if (eventData.target == target &&
            eventData.action == action &&
            eventData.cellClass == cellClass &&
            [eventData.propertyName isEqualToString:property] ) {
            [eventData removeEventTargetFromAllCellViews];
            [_eventDatas removeObjectAtIndex:i];
            break;
        }
    }
}

- (void)removeTarget:(nullable id)target action:(nonnull SEL)action forControlEvents:(UIControlEvents)event onCell:(nonnull Class)cellClass
{
    for ( int i=0 ; i<_eventDatas.count ; i++ ) {
        KHEventHandleData *eventData = _eventDatas[i];
        if (eventData.target == target &&
            eventData.action == action &&
            eventData.cellClass == cellClass) {
            [eventData removeEventTargetFromAllCellViews];
            [_eventDatas removeObjectAtIndex:i];
            break;
        }
    }
}



- (void)removeAllTarget
{
    for ( int i=0 ; i<_eventDatas.count ; i++ ) {
        KHEventHandleData *eventData = _eventDatas[i];
        [eventData removeEventTargetFromAllCellViews];
    }
    
    [_eventDatas removeAllObjects];
}

- (void)observeUIControlFor:(id)cell
{
    for ( int i=0 ; i<_eventDatas.count ; i++ ) {
        KHEventHandleData *eventData = _eventDatas[i];
        [eventData addEventTargetForCellView:cell];
    }
}




#pragma mark - UIScrollViewDelegate

// any offset changes
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat totalOffset = scrollView.contentOffset.y;
    CGFloat frameHeight = self.frame.size.height;
    CGFloat contentSizeHeight = scrollView.contentSize.height;
    
    if (contentSizeHeight >= frameHeight ) {
        totalOffset += frameHeight;
    }
    
    if( self.enabledLoadingMore ){
        if (!_showLoadingMore && !_hasOnEndReached) {
            if (totalOffset + self.onEndReachedThresHold >= contentSizeHeight) {
                [self showLoadingMoreIndicator:YES];
                if ([self.kh_delegate respondsToSelector:@selector(tableViewOnEndReached:)]) {
                    [self.kh_delegate tableViewOnEndReached:self];
                }
                _hasOnEndReached = YES;
            }
        }
        else {
            if (totalOffset + self.onEndReachedThresHold < contentSizeHeight) {
                _hasOnEndReached = NO;
            }
        }
    }
    
    if ( self.kh_delegate && [self.kh_delegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
        [self.kh_delegate scrollViewDidScroll:scrollView];
    }
}



#pragma mark - Refresh

- (void)setRefreshTitle:(NSAttributedString *)refreshTitle
{
    _refreshTitle = refreshTitle;
    _refreshControl.attributedTitle = _refreshTitle;
}

- (UIRefreshControl* _Nonnull)refreshControl
{
    return _refreshControl;
}

- (void)refreshHead:(id)sender
{
    if ( self.kh_delegate && [self.kh_delegate respondsToSelector:@selector(tableViewOnPulldown:refreshControl:)]) {
        [self.kh_delegate tableViewOnPulldown:self refreshControl:_refreshControl];
    }
}


- (void)endRefreshing
{
    if (_refreshControl.refreshing) {
        [_refreshControl endRefreshing];
    }
    if (_showLoadingMore) {
        [self showLoadingMoreIndicator:NO];
    }
}

- (void)setEnabledPulldownRefresh:(BOOL)enabledPulldownRefresh
{
    _enabledPulldownRefresh = enabledPulldownRefresh;
    if (enabledPulldownRefresh) {
        if ( _refreshControl ) {
            [self addSubview: _refreshControl ];
        }
    }
    else{
        if ( _refreshControl ) {
            [_refreshControl removeFromSuperview];
        }
    }
}


#pragma mark - Loading More

- (void)setEnabledLoadingMore:(BOOL)enabledLoadingMore
{
    _enabledLoadingMore = enabledLoadingMore;
    
    //  若 disable 的時候， indicator 正在顯示，就要把它關閉
    if (_showLoadingMore && !_enabledLoadingMore) {
        [self showLoadingMoreIndicator:NO];
    }
}

- (void)showLoadingMoreIndicator:(BOOL)show
{
    if (_showLoadingMore==show) {
        return;
    }
    _showLoadingMore = show;
    if(!_firstLoadHeaderFooter) return;
    self.loadingIndicator.hidden = !_showLoadingMore;
//    [self reloadSections:[NSIndexSet indexSetWithIndex:_sections.count] withRowAnimation:UITableViewRowAnimationAutomatic];

}


#pragma mark - Cell

//- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    _needReload = NO;
    // LoadingIndicator section has no cells.
    if ( _sections.count == 0 || (self.enabledLoadingMore && section == _sections.count )) {
        return 0;
    }
    
    NSArray *array = _sections[section];
    return array.count;
}

//  設定 cell size
//  每新增一個 cell，前面的每個 cell 都 size 都會重新取得
//  假設現在有四個cell，再新增一個，那個method就會呼叫五次，最後再呼叫一次 cellForItemAtIndexPath:
//  ◆ 注意：這邊跟 TableView 不同，當 reuse cell 的時候，並不會再呼叫一次，操你媽的
//- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *arr = _sections[indexPath.section];
    id model = arr[indexPath.row];
    KHPairInfo *pairInfo = [self getPairInfo: model ];
    if ( !pairInfo ) {
        pairInfo = [self addPairInfo:model];
    }
    CGSize cellSize = pairInfo.cellSize;
    
    if ( cellSize.width <= 0 && cellSize.height <= 0 ) {
        NSString *cellName = [self getMappingCellFor:model index:indexPath ];
        CGSize default_size = [self getDefaultSizeForCellClass:NSClassFromString(cellName)];
        if( default_size.width >= 0 && default_size.height >=0 ){
            cellSize = default_size;
            pairInfo.cellSize = cellSize;
        }
        else if ( [cellName isEqualToString:@"UITableViewCell"] ) {
            pairInfo.cellSize = CGSizeMake(self.frame.size.width - self.contentInset.left - self.contentInset.right, 44);
        }
        else if( [cellName isEqualToString:@"UITableContainerCell"] ){
            UIView *customView = [self modelForIndexPath:indexPath];
            pairInfo.cellSize = (CGSize){self.frame.size.width - self.contentInset.left - self.contentInset.right,customView.frame.size.height};
        }
        else{
            @try{
                UINib *nib = [UINib nibWithNibName:cellName bundle:[NSBundle mainBundle]];
                NSArray *arr = [nib instantiateWithOwner:nil options:nil];        
                UIView *prototype_cell = arr[0];
                cellSize = prototype_cell.frame.size;
                pairInfo.cellSize = cellSize;
            }
            @catch(NSException *exception) {
                pairInfo.cellSize = CGSizeMake(self.frame.size.width - self.contentInset.left - self.contentInset.right, 44);
            }
        }
    }
    
    //    CGSize size = [cellSizeValue CGSizeValue];
//    NSLog(@"KHTableView >> %ld cell size %@", (long)indexPath.row, NSStringFromCGSize(cellSize));
    
    return pairInfo.cellSize.height;
}


// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
//- (UITableViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    _firstReload = YES;
//    NSLog(@"KHTableView >> %ld cell config", (long)indexPath.row );
    NSMutableArray *modelArray = _sections[indexPath.section];
    
    if ( modelArray == nil ) {
        NSException *exception = [NSException exceptionWithName:@"Invalid table data" reason:[NSString stringWithFormat:@"section %ld is not exist", (long)indexPath.section] userInfo:nil];
        @throw exception;
    }
    
    id model = modelArray[indexPath.row];
    
    if ( model == nil ) {
        NSException *exception = [NSException exceptionWithName:@"Invalid model data" reason:@"model is nil" userInfo:nil];
        @throw exception;
    }
    
    // class name 當作 identifier
    NSString *cellName = [self getMappingCellFor:model index:indexPath ];
    if ( cellName == nil ) {
        @throw [NSException exceptionWithName:@"Invalid Model Class" reason:[NSString stringWithFormat: @"Can't find any cell class mapping with this class %@", NSStringFromClass([model class])] userInfo:nil];
    }

    UITableViewCell *cell = nil;
    if ( [cellName isEqualToString:@"UITableViewCell"] ) {
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
        cell = [self dequeueReusableCellWithIdentifier: identifier ];
        if ( !cell ){
            cell = [[UITableViewCell alloc] initWithStyle:cellModel.cellStyle reuseIdentifier: identifier ];
        }
    }
    else{
        @try {
            //        cell = [self dequeueReusableCellWithReuseIdentifier:cellName forIndexPath:indexPath ];
            cell = [self dequeueReusableCellWithIdentifier:cellName forIndexPath:indexPath];
        }
        @catch (NSException *exception) {
            if([[NSBundle mainBundle] pathForResource:cellName ofType:@"nib"] != nil) {
                UINib*nib = [UINib nibWithNibName:cellName bundle:nil];
                [self registerNib:nib forCellReuseIdentifier:cellName];
            }
            else{
                [self registerClass:NSClassFromString(cellName) forCellReuseIdentifier:cellName];
            }
            cell = [self dequeueReusableCellWithIdentifier:cellName forIndexPath:indexPath];
        }
    }
    
    //  每個 cell 只會執行一次，做初始設定
    if ( !cell.kh_hasConfig ) {
        cell.kh_hasConfig = YES;
        // 監聽 cell 上的 ui event
        [self observeUIControlFor:cell];
        if ( self.kh_delegate && [self.kh_delegate respondsToSelector:@selector(tableView:newCell:model:indexPath:)] ) {
            [self.kh_delegate tableView:self newCell:cell model:model indexPath:indexPath];
        }
    }

    // 讓 cell 可以透過 pairInfo 物件查到 model
    KHPairInfo *pairInfo = [self getPairInfo: model ];
    cell.pairInfo = pairInfo;
    
    //  把 model 載入 cell
    [cell onLoad:model];
    

    return cell;
}

#pragma mark - Section


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _sections.count + (self.enabledLoadingMore ? 1 : 0);
}

#pragma mark - Header / Footer


- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    id model = [self headerModelAt:section];
    if ( [model isKindOfClass:[NSString class]]) {
        return model;
    }
    return nil;
}

- (NSString*)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    id model = [self footerModelAt:section];
    if ( [model isKindOfClass:[NSString class]]) {
        return model;
    }
    return nil;
}

//  for header custom view
- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    _firstLoadHeaderFooter = YES;
    id model = [self headerModelAt:section];
    if ( [model isKindOfClass:[UIView class]]) {
        return model;
    }
    return nil;
}

//  for footer custom view
- (UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    _firstLoadHeaderFooter = YES;
    if ( _sections.count == 0 || (self.enabledLoadingMore && section == _sections.count ) ) {
        KHTableViewLoadingFooter *footer = (KHTableViewLoadingFooter*)[tableView dequeueReusableHeaderFooterViewWithIdentifier:NSStringFromClass([KHTableViewLoadingFooter class])];
        footer.indicatorView = self.loadingIndicator;
        return footer;
    }
    
    id model = [self footerModelAt:section];
    if ( [model isKindOfClass:[UIView class]]) {
        return model;
    }
    return nil;
}

#pragma mark - Header / Footer Height


// header size
//- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    // LoadingIndicator section has no section header.
    if ( section >= _sections.count ) {
        return 0;
    }
    
    float height = [self heightForHeaderAt:section];
    return height;
}

// footer size
//- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if ( self.enabledLoadingMore && section == _sections.count ) {
        
        // Margin Vertical: 10
        return self.loadingIndicator.frame.size.height + 20;
    }
    else if( section >= _sections.count ){
        return 0;
    }
    
    float height = [self heightForFooterAt:section];
    return height;
}

/**
 *顯示 headerView 之前，可以在這裡對 headerView 做一些顯示上的調整，例如改變字色或是背景色
 */
- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if( [view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *thfv = (UITableViewHeaderFooterView*)view;
        if( _headerBgColor ) thfv.contentView.backgroundColor = _headerBgColor;
        if( _headerTextColor ) thfv.textLabel.textColor = _headerTextColor;
        if(_headerFont) thfv.textLabel.font = _headerFont;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    if( [view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *thfv = (UITableViewHeaderFooterView*)view;
        if( _footerBgColor ) thfv.contentView.backgroundColor = _footerBgColor;
        if( _footerTextColor ) thfv.textLabel.textColor = _footerTextColor;
        if( _footerFont ) thfv.textLabel.font = _footerFont;
    }
}


#pragma mark - UITableViewDelegate

//- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( self.kh_delegate && [self.kh_delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)] ) {
        [self.kh_delegate tableView:(KHTableView*)tableView didSelectRowAtIndexPath:indexPath];
    }
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( self.kh_delegate && [self.kh_delegate respondsToSelector:@selector(tableView:willDisplayCell:forRowAtIndexPath:)] ) {
        [self.kh_delegate tableView:self willDisplayCell:cell forRowAtIndexPath:indexPath];
    }
    
}


#pragma mark - Array Observe

//  插入
-(void)insertObject:(id)object index:(NSUInteger)index inArray:(nonnull NSMutableArray *)array
{
    KHPairInfo *pairInfo = [self getPairInfo: object ];
    if ( !pairInfo ) {
        [self addPairInfo:object];
    }
    
    if (_firstReload && self.isNeedAnimation) {
        [self addInsertAnimation:[NSIndexPath indexPathForRow:index inSection:array.kh_section]];
        [self runItemAnimation];
    }
    else{
        [self reloadData];
    }
}

//  插入 多項
-(void)insertObjects:(NSArray *)objects indexs:(NSIndexSet *)indexs inArray:(nonnull NSMutableArray *)array
{
    for ( id model in objects ) {
        KHPairInfo *pairInfo = [self getPairInfo: model ];
        if ( !pairInfo ) {
            [self addPairInfo:model];
        }
    }
    
    if (_firstReload && self.isNeedAnimation){
        [indexs enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
            [self addInsertAnimation:[NSIndexPath indexPathForRow:idx inSection:array.kh_section]];
        }];
        [self runItemAnimation];
    }
    else{
        [self reloadData];
    }
}

//  刪除
-(void)removeObject:(id)object index:(NSUInteger)index inArray:(nonnull NSMutableArray *)array
{
    [self removePairInfo:object];
    
    if (_firstReload) {
        if (self.isNeedAnimation) {
            [self addRemoveAnimation:[NSIndexPath indexPathForRow:index inSection:array.kh_section]];
            [self runItemAnimation];
        }
        else {
            [self reloadData];
        }
    }
    
}

//  刪除全部
-(void)removeObjects:(NSArray *)objects indexs:(NSIndexSet *)indexs inArray:(nonnull NSMutableArray *)array
{
    for ( id model in objects ) {
        [self removePairInfo:model];
    }
    
    if (_firstReload) {
        if (self.isNeedAnimation) {
            [indexs enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                [self addRemoveAnimation:[NSIndexPath indexPathForRow:idx inSection:array.kh_section]];
            }];
            [self runItemAnimation];
        }
        else {
            [self reloadData];
        }
    } 
}

//  取代
-(void)replacedObject:(id)oldObj newObject:(id)newObj index:(NSUInteger)index inArray:(nonnull NSMutableArray *)array
{
    [self replacePairInfo:oldObj new:newObj];
    
    if (_firstReload) {
        if (self.isNeedAnimation) {
            [self addReloadAnimation:[NSIndexPath indexPathForRow:index inSection:array.kh_section]];
            [self runItemAnimation];
        }
        else {
            [self reloadData];
        }
    }
}

//  更新
-(void)update:(id)object index:(NSUInteger)index inArray:(nonnull NSMutableArray *)array
{
    if (_firstReload) {
        if (self.isNeedAnimation) {
            [self addReloadAnimation:[NSIndexPath indexPathForRow:index inSection:array.kh_section]];
            [self runItemAnimation];
        }
        else {
            [self reloadData];
        }
    }
}


#pragma mark - Animation

- (void)setNeedsRunAnimation
{
    if( self.isNeedAnimation && !needUpdate ){
        needUpdate = YES;
        __weak typeof (self) w_self = self;
        __weak NSMutableArray *w_animationQueue = _item_animationQueue;
        __weak NSMutableArray *w_section_animationQueue = _section_animationQueue;
        dispatch_async( dispatch_get_main_queue(), ^{
            [w_self beginUpdates];

            NSMutableArray *removeQueue = [w_animationQueue objectAtIndex:CellAnimation_Remove];
            [w_self deleteRowsAtIndexPaths:removeQueue withRowAnimation:UITableViewRowAnimationTop];
            
            NSMutableArray *insertQueue = [w_animationQueue objectAtIndex:CellAnimation_Insert];
            [w_self insertRowsAtIndexPaths:insertQueue withRowAnimation:UITableViewRowAnimationBottom];
            
            NSMutableArray *reloadQueue = [w_animationQueue objectAtIndex:CellAnimation_Reload];
            [w_self reloadRowsAtIndexPaths:reloadQueue withRowAnimation:UITableViewRowAnimationFade];
            
            
            // section animation
            NSIndexSet *insertSectionSet = [w_section_animationQueue objectAtIndex:CellAnimation_Insert];
            if( insertSectionSet.count > 0 )[w_self insertSections: insertSectionSet withRowAnimation:UITableViewRowAnimationBottom];
            
            NSIndexSet *reloadSectionSet = [w_section_animationQueue objectAtIndex:CellAnimation_Reload];
            if( reloadSectionSet.count > 0 )[w_self reloadSections:reloadSectionSet withRowAnimation:UITableViewRowAnimationFade];
            
            NSIndexSet *removeSectionSet = [w_section_animationQueue objectAtIndex:CellAnimation_Remove];
            if( removeSectionSet.count > 0 )[w_self deleteSections: removeSectionSet withRowAnimation:UITableViewRowAnimationTop];
            
            [w_self endUpdates];
            [w_self clearItemAnimationQueue];
            [w_self clearSectionAnimationQueue];
            needUpdate = NO;
            
        });
    }
}

- (void)runItemAnimation
{
    NSMutableArray *removeQueue = [_item_animationQueue objectAtIndex:CellAnimation_Remove];
    if( removeQueue.count > 0 ){
        [self deleteRowsAtIndexPaths:removeQueue withRowAnimation:UITableViewRowAnimationTop];
    }
    
    NSMutableArray *insertQueue = [_item_animationQueue objectAtIndex:CellAnimation_Insert];
    if( insertQueue.count > 0 ){
        [self insertRowsAtIndexPaths:insertQueue withRowAnimation:UITableViewRowAnimationBottom];
    }
    
    NSMutableArray *reloadQueue = [_item_animationQueue objectAtIndex:CellAnimation_Reload];
    if( reloadQueue.count > 0 ){
        [self reloadRowsAtIndexPaths:reloadQueue withRowAnimation:UITableViewRowAnimationFade];
    }
    
    [self clearItemAnimationQueue];
}

- (void)clearItemAnimationQueue
{
    for ( NSMutableArray *array in _item_animationQueue ) {
        [array removeAllObjects];
    }    
}



// item animation

- (void)addInsertAnimation:(NSIndexPath*)indexPath
{
    if ( !self.isNeedAnimation ) return;
    NSMutableArray *animQueue = _item_animationQueue[CellAnimation_Insert];
    [animQueue addObject:indexPath];
}

- (void)addRemoveAnimation:(NSIndexPath*)indexPath
{
    if ( !self.isNeedAnimation ) return;
    NSMutableArray *animQueue = _item_animationQueue[CellAnimation_Remove];
    [animQueue addObject:indexPath];
}

- (void)addReloadAnimation:(NSIndexPath*)indexPath
{
    if ( !self.isNeedAnimation ) return;
    NSMutableArray *animQueue = _item_animationQueue[CellAnimation_Reload];
    [animQueue addObject:indexPath];
}


//  sectin animation
- (void)runSectionAnimation
{
    NSMutableIndexSet *removeSet = _section_animationQueue[CellAnimation_Remove];
    if (removeSet.count>0) {
        [self deleteSections:removeSet withRowAnimation:UITableViewRowAnimationTop];
    }
    
    NSMutableIndexSet *insertSet = _section_animationQueue[CellAnimation_Insert];
    if (insertSet.count>0) {
        [self insertSections:insertSet withRowAnimation:UITableViewRowAnimationBottom];
    }
    
    NSMutableIndexSet *reloadSet = _section_animationQueue[CellAnimation_Reload];
    if (reloadSet) {
        [self reloadSections:reloadSet withRowAnimation:UITableViewRowAnimationFade];
    }
    
    [self clearSectionAnimationQueue];
}

- (void)clearSectionAnimationQueue
{
    for ( NSMutableIndexSet *indexSet in _section_animationQueue ) {
        [indexSet removeAllIndexes];
    }
}


- (void)addInsertSectionAnimation:(NSUInteger)index
{
    if ( !self.isNeedAnimation ) return;
    NSMutableIndexSet *insertSet = _section_animationQueue[CellAnimation_Insert];
    [insertSet addIndex:index];
    //    [self setNeedsRunAnimation];
    
}

- (void)addRemoveSectionAnimation:(NSUInteger)index
{
    if ( !self.isNeedAnimation ) return;
    NSMutableIndexSet *removeSet = _section_animationQueue[CellAnimation_Remove];
    [removeSet addIndex:index];
    //    [self setNeedsRunAnimation];
}

- (void)addReloadSectionAnimation:(NSUInteger)index
{
    if ( !self.isNeedAnimation ) return;
    NSMutableIndexSet *reloadSet = _section_animationQueue[CellAnimation_Reload];
    [reloadSet addIndex:index];
    //    [self setNeedsRunAnimation];
}


@end


#pragma mark - ==========================

@implementation KHTableViewLoadingFooter

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.backgroundColor = [UIColor clearColor];
    
    self.indicatorView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
}

- (void)setIndicatorView:(UIView *)indicatorView
{
    // WillSet...
    if (_indicatorView != indicatorView) {
        
        [_indicatorView removeFromSuperview];
        [self addSubview:indicatorView];
        
        _indicatorView = indicatorView;
    }
    
    // DidSet...
}

@end

#pragma mark - ==========================


@implementation UITableContainerCell
{
    NSArray *h_constraints;
    NSArray *v_constraints;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.backgroundColor = [UIColor clearColor];
//    self.nonReuseCustomView.frame = (CGRect){CGPointZero, self.bounds.size.width, self.nonReuseCustomView.frame.size.height };
}


- (void)onLoad:(UIView*)view
{
    if( self.nonReuseCustomView ){
        [self.nonReuseCustomView removeFromSuperview];
        self.nonReuseCustomView = nil;
        [self.contentView removeConstraints:h_constraints];
        [self.contentView removeConstraints:v_constraints];
    }
    self.nonReuseCustomView = view;
    [self.contentView addSubview: view ];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    h_constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|" options:0 metrics:nil views:@{@"view":view}];
    v_constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:0 metrics:nil views:@{@"view":view}]; 
    [self.contentView addConstraints:h_constraints];
    [self.contentView addConstraints:v_constraints];
}

@end


#pragma mark - ==========================
