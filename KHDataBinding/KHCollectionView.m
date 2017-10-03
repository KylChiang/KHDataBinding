//
//  KHCollectionView.m
//  KHDataBindingDemo
//
//  Created by GevinChen on 2017/3/2.
//  Copyright © 2017年 omg. All rights reserved.
//

#import "KHCollectionView.h"



#define HEADER UICollectionElementKindSectionHeader 
#define FOOTER UICollectionElementKindSectionFooter


@implementation KHCollectionView


- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout
{
    self = [super initWithFrame:frame collectionViewLayout:layout];
    
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
    _sections = [[NSMutableArray alloc] initWithCapacity: 10 ];
    // _sync_sections = [[NSMutableArray alloc] initWithCapacity: 10 ];
    
    _isNeedAnimation = YES;
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
    _reusableViewDic = [[NSMutableDictionary alloc] initWithCapacity: 5 ];
    _reusableViewSizeDic = [[NSMutableDictionary alloc] initWithCapacity: 5 ];
    
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

    
    //  register UICollectionContainerCell for non reuse cell
    [self setMappingModel:[UIView class] cell:[UICollectionContainerCell class]];
    
    //  預先定義 header footer 
    //  register heater footer container view
    [self registerClass:[KHContainerReusableView class] forSupplementaryViewOfKind:HEADER withReuseIdentifier:NSStringFromClass([KHContainerReusableView class])];
    [self registerClass:[KHContainerReusableView class] forSupplementaryViewOfKind:FOOTER withReuseIdentifier:NSStringFromClass([KHContainerReusableView class])];
    //  定義 model 也可以是 View，如果是 View 就直接裝進來
    [self setMappingModel:[UIView class] reusableViewClass:[KHContainerReusableView class]];

    // init loading footer indicator view
    UIView *loadingMoreView = [[UIView alloc] initWithFrame:(CGRect){0,0, 320,30}];
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    [indicator startAnimating];
    indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    [loadingMoreView addSubview:indicator];
    indicator.translatesAutoresizingMaskIntoConstraints = NO;
    [indicator addConstraint:[NSLayoutConstraint constraintWithItem:indicator
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:nil
                                                          attribute:NSLayoutAttributeNotAnAttribute
                                                         multiplier:1
                                                           constant:20]];
    [indicator addConstraint:[NSLayoutConstraint constraintWithItem:indicator
                                                          attribute:NSLayoutAttributeHeight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:nil
                                                          attribute:NSLayoutAttributeNotAnAttribute
                                                         multiplier:1
                                                           constant:20]];
    [loadingMoreView addConstraint:[NSLayoutConstraint constraintWithItem:indicator 
                                                                attribute:NSLayoutAttributeCenterX
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:loadingMoreView
                                                                attribute:NSLayoutAttributeCenterX
                                                               multiplier:1 
                                                                 constant:0]];
    [loadingMoreView addConstraint:[NSLayoutConstraint constraintWithItem:indicator 
                                                                attribute:NSLayoutAttributeCenterY
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:loadingMoreView
                                                                attribute:NSLayoutAttributeCenterY
                                                               multiplier:1 
                                                                 constant:0]];
    
    _loadingIndicator = loadingMoreView;
    self.loadingIndicator.hidden = YES;
    _onEndReachedThresHold = 30.0f;
    _showLoadingMore = NO;
    
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
    pairInfo.collectionView = self;
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

- (UICollectionViewCell *_Nullable)cellForModel:(id _Nonnull)model
{
    NSIndexPath *index = [self indexPathForModel: model ];
    UICollectionViewCell *cell = [self cellForItemAtIndexPath: index ];
    return cell;
}

- (id _Nullable)modelForCell:(UICollectionViewCell *_Nonnull)cell
{
    NSIndexPath* index = [self indexPathForCell:cell];
    id model = [self modelForIndexPath:index];
    return model;
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
- (nullable UICollectionViewCell*)cellForUI:(UIControl *_Nonnull)uiControl
{
    if ( uiControl.superview == nil ) {
        return nil;
    }
    UICollectionViewCell *cell = nil;
    UIView *superView = uiControl.superview;
    while ( superView ) {
        if ( [superView isKindOfClass:[UICollectionViewCell class]] ) {
            cell = (UICollectionViewCell *)superView;
            break;
        }
        superView = superView.superview;
    }
    return cell;
}

//  透過某個 responder UI，取得 model
- (nullable id)modelForUI:(UIControl *_Nonnull)uiControl
{
    UICollectionViewCell *cell = [self cellForUI: uiControl ];
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
    else if( [modelClass isSubclassOfClass:[UIView class]] ){
        modelName = @"UIView";
    }
    else{
        modelName = NSStringFromClass(modelClass);
    }
    NSString *cellName = NSStringFromClass(cellClass);
    _cellClassDic[modelName] = cellName;
    
    if([[NSBundle mainBundle] pathForResource:cellName ofType:@"nib"] != nil) {
        UINib *nib = [UINib nibWithNibName:cellName bundle:nil];
        [self registerNib:nib forCellWithReuseIdentifier:cellName];
        NSArray *views = [nib instantiateWithOwner:nil options:nil];
        UIView *prototype = views[0];
        [self setDefaultSize:prototype.frame.size forCellClass:cellClass];
    }
    else {
        [self registerClass:cellClass forCellWithReuseIdentifier:cellName];
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
        //@throw [NSException exceptionWithName:@"Invalid Model Class" reason:[NSString stringWithFormat: @"Can't find any CellName map with this class %@", modelName ] userInfo:nil];
        NSLog(@"KHCollectionView !!!! warnning !!!! Can't find any CellName mapping with this class %@", modelName );
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
        NSLog(@"KHCollectionView !!! warning !!! the model pass to set cell size method is nil");
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


#pragma mark - Config Model Header/Footer Mapping

#pragma mark Mapping

- (void)setMappingModel:(Class _Nonnull)modelClass reusableViewClass:(Class _Nonnull)reusableViewClass
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
    NSString *viewName = NSStringFromClass(reusableViewClass);
    
    _reusableViewDic[modelName] = viewName;
    
    //  登錄 header view nib
    
    if([[NSBundle mainBundle] pathForResource:viewName ofType:@"nib"] != nil) {
        UINib *nib = [UINib nibWithNibName:viewName bundle:nil];
        [self registerNib:nib forSupplementaryViewOfKind:HEADER withReuseIdentifier:viewName];
        [self registerNib:nib forSupplementaryViewOfKind:FOOTER withReuseIdentifier:viewName];
    }
    else {
        [self registerClass:reusableViewClass forSupplementaryViewOfKind:HEADER withReuseIdentifier:viewName];
        [self registerClass:reusableViewClass forSupplementaryViewOfKind:FOOTER withReuseIdentifier:viewName];
    }
}

//  取得對映的 header / footer class name 
- (NSString *_Nullable)getReusableViewNameFor:(id _Nonnull)model
{
    NSString *modelName;
    if ( [model isKindOfClass:[NSDictionary class]]) {
        modelName = @"NSDictionary";
    }
    else if([model isKindOfClass:[NSArray class]]){
        modelName = @"NSArray";
    }
    else if([model isKindOfClass:[NSString class]]){
        modelName = @"NSString";
    }
    else if([model isKindOfClass:[UIView class]]){
        modelName = @"UIView";
    }
    else{
        modelName = NSStringFromClass([model class]);
    }
    
    return _reusableViewDic[modelName];
}


#pragma mark Set Model At Section

- (void)setHeaderFooter:(NSString*)kind model:(id _Nullable)model atIndex:(NSInteger)sectionIndex
{
    if ( sectionIndex >= _sections.count ) {
        NSLog(@"Warring!!! the section index %d of %@ model out of bound %d.", (int)sectionIndex, kind == HEADER ? @"header":@"footer", (int)_sections.count );
        return;
    }
    NSMutableArray *sectionArray = _sections[sectionIndex];
    NSValue *key = [NSValue valueWithNonretainedObject:sectionArray];
    
    if ( kind == HEADER ) {
        _headerModelDic[key] = model;
    }
    else if( kind == FOOTER ){
        _footerModelDic[key] = model;
    }
}

- (void)setHeaderModel:(id _Nullable)model atIndex:(NSInteger)sectionIndex
{
    [self setHeaderFooter:HEADER
                    model:model
                  atIndex:sectionIndex];
}

- (void)setHeaderModels:(NSArray *_Nullable)models
{
    if (models) {
        for ( int i=0; i<models.count; i++ ) {
            id model = models[i];
            [self setHeaderModel:model atIndex:i];
        }
    }
    else{
        int section_cnt = _sections.count;
        for ( int i=0; i<section_cnt; i++ ) {
            [self setHeaderModel:nil atIndex:i];
        }
    }
}

- (void)setFooterModel:(id _Nullable)model atIndex:(NSInteger)sectionIndex
{
    [self setHeaderFooter:FOOTER
                    model:model
                  atIndex:sectionIndex];

}

- (void)setFooterModels:(NSArray *_Nullable)models
{
    if (models) {
        for ( int i=0; i<models.count; i++ ) {
            id model = models[i];
            [self setFooterModel:model atIndex:i];
        }
    }
    else{
        int section_cnt = _sections.count;
        for ( int i=0; i<section_cnt; i++ ) {
            [self setFooterModel:nil atIndex:i];
        }
    }
}

#pragma mark Get Model From Section

- (id _Nullable)getHeaderFooterModelAt:(NSInteger)section kind:(NSString*)kind
{
    NSMutableArray *sectionArray = _sections[section];
    NSValue *key = [NSValue valueWithNonretainedObject:sectionArray];
    
    if ( kind == HEADER ) {
        id model = _headerModelDic[key];
        return model;
    }
    else if( kind == FOOTER ){
        id model = _footerModelDic[key];
        return model;
    }
    
    return nil;
}

- (id _Nullable)headerModelAt:(NSInteger)section
{
    return [self getHeaderFooterModelAt:section kind:HEADER];
}

- (id _Nullable)footerModelAt:(NSInteger)section
{
    return [self getHeaderFooterModelAt:section kind:FOOTER];    
}

- (id _Nullable)headerViewAt:(NSInteger)section
{
    UICollectionReusableView* view = [self supplementaryViewForElementKind:HEADER atIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
    return view;
}

- (id _Nullable)footerViewAt:(NSInteger)section
{
    UICollectionReusableView* view = [self supplementaryViewForElementKind:FOOTER atIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
    return view;
}


#pragma mark Get Header Footer Sectoin

- (NSInteger)sectionForHeaderFooterModel:(id _Nonnull)model
{
    for ( int i=0; i<_sections.count; i++) {
        NSArray *array = _sections[i];
        NSValue *key = [NSValue valueWithNonretainedObject:array];
        id tmp_model = _headerModelDic[key];
        if ( tmp_model == model ) {
            return i;
        }
        tmp_model = _footerModelDic[key];
        if ( tmp_model == model ) {
            return i;
        }
    }
    return -1;
}

- (NSInteger)sectionForHeaderFooterUI:(UIView* _Nonnull)ui
{
    for ( int i=0; i<_sections.count; i++) {
        NSArray *array = _sections[i];
        NSValue *key = [NSValue valueWithNonretainedObject:array];
        id tmp_model = _headerModelDic[key];
        if ( tmp_model != nil && [tmp_model isKindOfClass:[UIView class]] ) {
            UIView *view = (UIView *)tmp_model;
            if ( [ui isDescendantOfView:view] ) {
                return i;
            }
        }
        tmp_model = _footerModelDic[key];
        if ( tmp_model != nil && [tmp_model isKindOfClass:[UIView class]] ) {
            UIView *view = (UIView *)tmp_model;
            if ( [ui isDescendantOfView:view] ) {
                return i;
            }
        }        
    }
    return -1;
}


#pragma mark - Header/Footer Size

- (void)setHeaderFooterSize:(CGSize)size model:(id _Nonnull)model
{
    NSValue *value = [NSValue valueWithCGSize:size];
    NSValue *key = [NSValue valueWithNonretainedObject:model];
    
    _reusableViewSizeDic[key] = value;
}

- (CGSize)getHeaderFooterSizeModel:(id _Nonnull)model
{
    NSValue *key = [NSValue valueWithNonretainedObject:model];
    NSValue *value = _reusableViewSizeDic[key];
    if ( value == nil ) {
        return CGSizeMake(-1, -1);
    }
    return [value CGSizeValue];
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

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat totalOffset = scrollView.contentOffset.y;
    CGFloat frameHeight = self.frame.size.height;
    CGFloat contentSizeHeight = scrollView.contentSize.height;
    
    if (contentSizeHeight >= frameHeight ) {
        totalOffset += frameHeight;
    }
    
    //  note:
    //  多加一個 _firstReload 判斷，是因為 tableView 或 collectionView 在設定 contentInset 時
    //  也會觸發這裡，真他媽莫名奇妙，操，所以卡一個都初始完資料(_firstReload) 才能做裡面的檢查
    if(self.enabledLoadingMore && _firstReload){
        //  _hasOnEndReached 用來限制確保 collectionViewOnEndReached: 在條件達成時
        //  只呼叫一次，直到條件不符合的時候，才解開限制，之後條件再達成才會再觸發一次
        if (!_showLoadingMore&&!_hasOnEndReached) {
            if (totalOffset + self.onEndReachedThresHold >= contentSizeHeight) {
                [self showLoadingMoreIndicator:YES];
                if ([self.kh_delegate respondsToSelector:@selector(collectionViewOnEndReached:)]) {
                    [self.kh_delegate collectionViewOnEndReached:self];
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

//  把每個 cell 重新填入資料
- (void)refreshCells
{
    for ( KHPairInfo *pairInfo in _pairDic) {
        [pairInfo loadModelToCell];
    }
}

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
    if ( self.kh_delegate && [self.kh_delegate respondsToSelector:@selector(collectionViewOnPulldown:refreshControl:)]) {
        [self.kh_delegate collectionViewOnPulldown:self refreshControl:_refreshControl];
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
//    [self reloadSections:[NSIndexSet indexSetWithIndex:_sections.count]];
}


#pragma mark - Cell

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    _needReload = NO;
    
    // LoadingIndicator section has no cells.
    if ( _sections.count == 0 || (self.enabledLoadingMore && section == _sections.count )) {
        return 0;
    }
    
    NSArray *array = _sections[section];
    if(self.debug) NSLog(@"KHCollectionView >> section %ld , cell count %ld", (long)section, array.count);
    return array.count;
}

//  設定 cell size
//  每新增一個 cell，前面的每個 cell 都 size 都會重新取得
//  假設現在有四個cell，再新增一個，那個method就會呼叫五次，最後再呼叫一次 cellForItemAtIndexPath:
//  ◆ 注意：這邊跟 TableView 不同，當 reuse cell 的時候，並不會再呼叫一次，操你媽的
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
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
        else if ([cellName isEqualToString:NSStringFromClass([UICollectionContainerCell class])]) {
            UIView *view = pairInfo.model;
            pairInfo.cellSize = view.frame.size;
        }
        else{
            @try{
                UINib *nib = [UINib nibWithNibName:cellName bundle:[NSBundle mainBundle]];
                NSArray *arr = [nib instantiateWithOwner:nil options:nil];        
                _prototype_cell = arr[0];
                cellSize = _prototype_cell.frame.size;
                pairInfo.cellSize = cellSize;
            }
            @catch(NSException *exception){
                pairInfo.cellSize = CGSizeMake(100, 100);
            }
        }
        
    }
    
    //    CGSize size = [cellSizeValue CGSizeValue];
    if(self.debug) NSLog(@"KHCollectionView >> [%ld,%ld] cell size %@", (long)indexPath.section,(long)indexPath.row, NSStringFromCGSize(cellSize));
    
    return pairInfo.cellSize;
}


// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    _firstReload = YES;
    if(self.debug) NSLog(@"KHCollectionView >> [%ld,%ld] cell config", (long)indexPath.section,(long)indexPath.row );
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
    
    UICollectionViewCell *cell = nil;
    @try {
        cell = [self dequeueReusableCellWithReuseIdentifier:cellName forIndexPath:indexPath ];
    }
    @catch (NSException *exception) {
        if([[NSBundle mainBundle] pathForResource:cellName ofType:@"nib"] != nil) {
            UINib*nib = [UINib nibWithNibName:cellName bundle:nil];
            [self registerNib:nib forCellWithReuseIdentifier:cellName];
        }
        else{
            [self registerClass:NSClassFromString(cellName) forCellWithReuseIdentifier:cellName];
        }
        
        cell = [self dequeueReusableCellWithReuseIdentifier:cellName forIndexPath:indexPath ];
    }
    
    //  每個 cell 只會執行一次，做初始設定
    if ( !cell.kh_hasConfig ) {
        cell.kh_hasConfig = YES;
        // 監聽 cell 上的 ui event
        [self observeUIControlFor:cell];
        if( self.kh_delegate && [self.kh_delegate respondsToSelector:@selector(collectionView:newCell:model:indexPath:)]  ){
            [self.kh_delegate collectionView:self newCell:cell model:model indexPath:indexPath];
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

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return _sections.count + (self.enabledLoadingMore ? 1 : 0);
}


#pragma mark - Header / Footer

- (UICollectionReusableView*)collectionView:(UICollectionView *)collectionView
          viewForSupplementaryElementOfKind:(NSString *)kind
                                atIndexPath:(NSIndexPath *)indexPath
{
    _firstLoadHeaderFooter = YES;
    if ([kind isEqualToString:FOOTER] &&
        ( _sections.count == 0 || (self.enabledLoadingMore && indexPath.section == _sections.count )) ) {
        //  若是 loading more，就把 self.loadingIndicator 當作 model 傳入
        KHContainerReusableView *footer = [collectionView dequeueReusableSupplementaryViewOfKind:FOOTER
                                                                             withReuseIdentifier:NSStringFromClass([KHContainerReusableView class])
                                                                                    forIndexPath:indexPath];
        [footer onLoad: _loadingIndicator ];
        return footer;
    }
    
    id model = nil;
    NSString *reusableViewName = nil;
    if ( kind == HEADER && _headerModelDic.count > 0  ) {
        model = [self headerModelAt:indexPath.section];
    }
    else if( kind == FOOTER && _footerModelDic.count > 0  ){
        model = [self footerModelAt:indexPath.section];
    }
    reusableViewName = [self getReusableViewNameFor:model];
    
    if ( model == nil || model == [NSNull null] ) return nil;
    
    UICollectionReusableView *reusableView = nil;
    @try{
        reusableView = [self dequeueReusableSupplementaryViewOfKind:kind
                                                withReuseIdentifier:reusableViewName
                                                       forIndexPath:indexPath];
    }
    @catch( NSException *e ){
        if([[NSBundle mainBundle] pathForResource:reusableViewName ofType:@"nib"] != nil) {
            UINib *nib = [UINib nibWithNibName:reusableViewName bundle:nil];
            [self registerNib:nib forSupplementaryViewOfKind:HEADER withReuseIdentifier:reusableViewName ];
        }else{
            [self registerClass:NSClassFromString(reusableViewName) forSupplementaryViewOfKind:HEADER withReuseIdentifier:reusableViewName ];
        }
        reusableView = [self dequeueReusableSupplementaryViewOfKind:kind
                                                withReuseIdentifier:reusableViewName
                                                       forIndexPath:indexPath];;
    }
    
    //  每個 cell 只會執行一次，做初始設定
    if ( !reusableView.kh_hasConfig && ![reusableView isKindOfClass:[KHContainerReusableView class]] ) {
        reusableView.kh_hasConfig = YES;
        // 監聽 cell 上的 ui event
        [self observeUIControlFor:reusableView];
        if(kind == HEADER && 
           self.kh_delegate && 
           [self.kh_delegate respondsToSelector:@selector(collectionView:newHeader:model:indexPath:)]){
            [self.kh_delegate collectionView:self newHeader:reusableView model:model indexPath:indexPath];
        }
        else if(kind == FOOTER && 
                self.kh_delegate && 
                [self.kh_delegate respondsToSelector:@selector(collectionView:newFooter:model:indexPath:)]){
            [self.kh_delegate collectionView:self newFooter:reusableView model:model indexPath:indexPath];
        }
    }
    
    KHPairInfo *pairInfo = [self getPairInfo: model ];
    if ( !pairInfo ) {
        pairInfo = [self addPairInfo:model];
    }
    reusableView.pairInfo = pairInfo;
    [reusableView onLoad: model ];
    
    return reusableView;
}




#pragma mark - Header / Footer Size

// header size
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    // LoadingIndicator section has no section header.
    if ( section >= _sections.count || section >= _headerModelDic.count ) {
//        NSLog(@"KHCollectionView >> section %ld header size 0,0", (long)section);
        return CGSizeZero;
    }
    
    id headerModel = [self headerModelAt:section];
    
    if ( headerModel == nil || headerModel == [NSNull null] ) return CGSizeZero;
    
    CGSize size = [self getHeaderFooterSizeModel:headerModel];
    // size 為 -1 -1，代表先前完全都沒設定過
    if ( size.width == -1 && size.height == -1 ) {
        if ( [headerModel isKindOfClass:[UIView class]]) {
            UIView *view = headerModel;
            [self setHeaderFooterSize:view.frame.size model:view];
            size = view.frame.size;
        }
        else{
            NSString *viewName = [self getReusableViewNameFor:headerModel];
            if([[NSBundle mainBundle] pathForResource:viewName ofType:@"nib"] != nil) {
                UINib *nib = [UINib nibWithNibName:viewName bundle:nil];
                NSArray *arr = [nib instantiateWithOwner:nil options:nil ];
                UICollectionReusableView *headerView = arr[0];
                [self setHeaderFooterSize:headerView.frame.size model:headerModel];
                size = headerView.frame.size;
            }
            else{
                [self setHeaderFooterSize:(CGSize){100,100} model:headerModel];
                size = (CGSize){100,100};
            }
        }
    }
    if(self.debug) NSLog(@"KHCollectionView >> section %ld header size %@", (long)section, NSStringFromCGSize(size));
    return size;
}

// footer size
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section
{
    
    if ( self.enabledLoadingMore && section == _sections.count ) {
        // Margin Vertical: 10
        if(self.debug) NSLog(@"KHCollectionView >> section %ld footer size %@", (long)section, NSStringFromCGSize(CGSizeMake(collectionView.bounds.size.width, CGRectGetHeight(self.loadingIndicator.frame) + 20)));
        return CGSizeMake(collectionView.bounds.size.width, CGRectGetHeight(self.loadingIndicator.frame) + 20);
    }
    else if( section >= _sections.count ){
        if(self.debug) NSLog(@"KHCollectionView >> section %ld footer size 0,0", (long)section);
        return CGSizeZero;
    }
    
    NSMutableArray *sectionArray = _sections[section];
    NSValue *key = [NSValue valueWithNonretainedObject:sectionArray];
    id footerModel = _footerModelDic[key];
    
    if ( footerModel == nil || footerModel == [NSNull null] ) return CGSizeZero;
    
    CGSize size = [self getHeaderFooterSizeModel:footerModel];
    // size 為 -1 -1，代表先前完全都沒設定過
    if ( size.width == -1 && size.height == -1 ) {
        if ( [footerModel isKindOfClass:[UIView class]]) {
            UIView *view = footerModel;
            [self setHeaderFooterSize:view.frame.size model:footerModel];
            size = view.frame.size;
        }
        else{
            NSString *viewName = [self getReusableViewNameFor:footerModel];
            if([[NSBundle mainBundle] pathForResource:viewName ofType:@"nib"] != nil) {
                UINib *nib = [UINib nibWithNibName:viewName bundle:nil];
                NSArray *arr = [nib instantiateWithOwner:nil options:nil ];
                UICollectionReusableView *footerView = arr[0];
                [self setHeaderFooterSize:footerView.frame.size model:footerModel];
                size = footerView.frame.size;
            }
            else{
                [self setHeaderFooterSize:(CGSize){100,100} model:footerModel];
                size = (CGSize){100,100};
            }
        }
    }
    
    if(self.debug) NSLog(@"KHCollectionView >> section %ld footer size %@", (long)section, NSStringFromCGSize(size));
    return size;
}


#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ( self.kh_delegate && [self.kh_delegate respondsToSelector:@selector(collectionView:didSelectItemAtIndexPath:)] ) {
        [self.kh_delegate collectionView:(KHCollectionView*)collectionView didSelectItemAtIndexPath:indexPath];
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
        __weak NSMutableArray *w_item_animationQueue = _item_animationQueue;
        __weak NSMutableArray *w_section_animationQueue = _section_animationQueue;
        
        dispatch_async( dispatch_get_main_queue(), ^{
            [w_self performBatchUpdates:^{
                // item animation
                NSMutableArray *removeQueue = [w_item_animationQueue objectAtIndex:CellAnimation_Remove];
                if( removeQueue.count > 0 ){
                    [w_self deleteItemsAtIndexPaths: removeQueue ];
                }
                
                NSMutableArray *insertQueue = [w_item_animationQueue objectAtIndex:CellAnimation_Insert];
                if( insertQueue.count > 0 ){
                    [w_self insertItemsAtIndexPaths: insertQueue ];
                }
                NSMutableArray *reloadQueue = [w_item_animationQueue objectAtIndex:CellAnimation_Reload];
                if( reloadQueue.count > 0 ){
                    [w_self reloadItemsAtIndexPaths:reloadQueue ];
                }
                
                [w_self clearItemAnimationQueue];
                
                // section animation
                NSIndexSet *removeSectionSet = [w_section_animationQueue objectAtIndex:CellAnimation_Remove];
                if( removeSectionSet.count > 0 )
                    [w_self deleteSections: removeSectionSet ];

                NSIndexSet *insertSectionSet = [w_section_animationQueue objectAtIndex:CellAnimation_Insert];
                if( insertSectionSet.count > 0 )
                    [w_self insertSections: insertSectionSet ];
                
                NSIndexSet *reloadSectionSet = [w_section_animationQueue objectAtIndex:CellAnimation_Reload];
                if( reloadSectionSet.count > 0 )
                    [w_self reloadSections:reloadSectionSet ];
                
                [w_self clearSectionAnimationQueue];
            } completion:^(BOOL finished) {
                needUpdate = NO;
            }];
        });
    }
}

- (void)runItemAnimation
{
    NSMutableArray *removeQueue = [_item_animationQueue objectAtIndex:CellAnimation_Remove];
    if( removeQueue.count > 0 ){
        [self deleteItemsAtIndexPaths: removeQueue ];
    }
    
    NSMutableArray *insertQueue = [_item_animationQueue objectAtIndex:CellAnimation_Insert];
    if( insertQueue.count > 0 ){
        [self insertItemsAtIndexPaths: insertQueue ];
    }
    NSMutableArray *reloadQueue = [_item_animationQueue objectAtIndex:CellAnimation_Reload];
    if( reloadQueue.count > 0 ){
        [self reloadItemsAtIndexPaths:reloadQueue ];
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
        [self deleteSections:removeSet];
    }

    NSMutableIndexSet *insertSet = _section_animationQueue[CellAnimation_Insert];
    if (insertSet.count>0) {
        [self insertSections:insertSet];
    }
    
    NSMutableIndexSet *reloadSet = _section_animationQueue[CellAnimation_Reload];
    if (reloadSet) {
        [self reloadSections:reloadSet];
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


@implementation KHContainerReusableView

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.backgroundColor = [UIColor clearColor];
    
    self.contentView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
}


- (void)onLoad:(UIView*)view
{
    if(self.contentView==view){
        return;
    }
    
    [view removeFromSuperview];
    self.contentView = view;
    [self addSubview: view ];
    
    //    view.frame = (CGRect){0,0,view.frame.size};
}


@end



#pragma mark - ==========================


@implementation UICollectionContainerCell
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
    if(self.nonReuseCustomView==view){
        return;
    }
    
    [self.contentView removeConstraints:h_constraints];
    [self.contentView removeConstraints:v_constraints];
    
    /* note:
     不能對 self.nonResuseCustomView 做 removeFromSuperview
     因為會有個情況， cell A 的 self.nonResuseCustomView 已經 add 到 cell B 裡了
     然後 cell A 因為要載入，而做 [self.nonResuseCustomView removeFromSuperview]
     就會造成 cell B 經跑完程序了，結果你這裡又把 view 移除，到時顯示上就會變成 cell B 的內容是空的
     */

    [view removeFromSuperview];
    self.nonReuseCustomView = view;
    
    if (self.contentView.subviews.count>0) {
        NSArray *views = self.contentView.subviews;
        for (UIView *view in views) {
            [view removeFromSuperview];
        }
    }
    
    [self.contentView addSubview: view ];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    h_constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|" options:0 metrics:nil views:@{@"view":view}];
    v_constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:0 metrics:nil views:@{@"view":view}]; 
    [self.contentView addConstraints:h_constraints];
    [self.contentView addConstraints:v_constraints];
}

@end


#pragma mark - ==========================









