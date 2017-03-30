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
    _headerViewDic = [[NSMutableDictionary alloc] initWithCapacity: 5 ];
    _footerViewDic = [[NSMutableDictionary alloc] initWithCapacity: 5 ];
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

    
    //  register UICollectionContainerCell for non reuse cell
    [self setMappingModel:[UIView class] cell:[UICollectionContainerCell class]];
    
    // register loading footer
    [self registerClass:[KHCollectionViewLoadingFooter class] forSupplementaryViewOfKind:FOOTER withReuseIdentifier:NSStringFromClass([KHCollectionViewLoadingFooter class])];
    // init loading footer indicator view
    UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    [indicatorView startAnimating];
    indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    _loadingIndicator = indicatorView;
    
    //  預先定義 header footer 
    //  register heater footer container view
    [self registerClass:[KHContainerReusableView class] forSupplementaryViewOfKind:HEADER withReuseIdentifier:NSStringFromClass([KHContainerReusableView class])];
    [self registerClass:[KHContainerReusableView class] forSupplementaryViewOfKind:FOOTER withReuseIdentifier:NSStringFromClass([KHContainerReusableView class])];
    
    [self setMappingModel:[UIView class] headerClass:[KHContainerReusableView class]];
    [self setMappingModel:[UIView class] footerClass:[KHContainerReusableView class]];
    
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
    NSString *cellName = [self getMappingCellFor:object index:nil];
    if ( cellName == nil ){
        pairInfo.pairCellName = cellName;
        pairInfo.cellSize = [self getCellDefaultSizeFor:NSClassFromString(cellName)];
    }
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
    if( _firstReload ) [self insertSections:[NSIndexSet indexSetWithIndex:array.kh_section]];
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
        if( _firstReload ) [self deleteSections:[NSIndexSet indexSetWithIndex:array.kh_section]];
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
        [self setCellDefaultSize:prototype.frame.size class:cellClass];
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


- (void)setCellDefaultSize:(CGSize)cellSize class:(Class _Nonnull)cellClass
{
    NSString *cellName = NSStringFromClass(cellClass);
    NSValue *value = [NSValue valueWithCGSize:cellSize];
    _cellDefaultSizeDic[cellName] = value; 
}

- (CGSize)getCellDefaultSizeFor:(Class _Nonnull)cellClass
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

- (void)setMappingModel:(Class _Nonnull)modelClass viewClass:(Class _Nonnull)reusableViewClass kind:(NSString*)kind
{
    NSMutableDictionary *viewNameDic = nil;
    if ( kind == HEADER ) {
        viewNameDic = _headerViewDic;
    }
    else if( kind == FOOTER ){
        viewNameDic = _footerViewDic;
    }
    
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
    
    viewNameDic[modelName] = viewName;
    
    //  登錄 header view nib
    
    if([[NSBundle mainBundle] pathForResource:viewName ofType:@"nib"] != nil) {
        UINib *nib = [UINib nibWithNibName:viewName bundle:nil];
        [self registerNib:nib forSupplementaryViewOfKind:kind withReuseIdentifier:viewName];
    }
    else {
        [self registerClass:reusableViewClass forSupplementaryViewOfKind:kind withReuseIdentifier:viewName];
    }
}

- (void)setMappingModel:(Class _Nonnull)modelClass headerClass:(Class _Nonnull)reusableViewClass
{
    [self setMappingModel:modelClass viewClass:reusableViewClass kind:HEADER];
}

- (void)setMappingModel:(Class _Nonnull)modelClass footerClass:(Class _Nonnull)reusableViewClass
{
    [self setMappingModel:modelClass viewClass:reusableViewClass kind:FOOTER];
}

#pragma mark Get View Name

- (NSString *_Nullable)getReusableViewNameFor:(id _Nonnull)model kind:(NSString*)kind
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
    
    if ( kind == HEADER ) {
        return _headerViewDic[modelName];
    }
    else if( kind == FOOTER ){
        return _footerViewDic[modelName];
    }
    return nil;
}

//  取得對映的 header
- (NSString *_Nullable)getHeaderNameFor:(id _Nonnull)model
{
    return [self getReusableViewNameFor:model kind:HEADER];
}

//  取得對映的 footer
- (NSString *_Nullable)getFooterNameFor:(id _Nonnull)model
{
    return [self getReusableViewNameFor:model kind:FOOTER];
}


#pragma mark Set Model At Section

- (void)setHeaderFooter:(NSString*)kind model:(id _Nonnull)model atIndex:(NSInteger)sectionIndex
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

- (void)setHeaderModel:(id _Nonnull)model atIndex:(NSInteger)sectionIndex
{
    [self setHeaderFooter:HEADER
                    model:model
                  atIndex:sectionIndex];
}

- (void)setHeaderModels:(NSArray *_Nonnull)models
{
    for ( int i=0; i<models.count; i++ ) {
        id model = models[i];
        [self setHeaderModel:model atIndex:i];
    }
}

- (void)setFooterModel:(id _Nonnull)model atIndex:(NSInteger)sectionIndex
{
    [self setHeaderFooter:FOOTER
                    model:model
                  atIndex:sectionIndex];

}

- (void)setFooterModels:(NSArray *_Nonnull)models
{
    for ( int i=0; i<models.count; i++ ) {
        id model = models[i];
        [self setFooterModel:model atIndex:i];
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
    UICollectionReusableView* view = [self supplementaryViewForElementKind:HEADER atIndexPath:[NSIndexPath indexPathWithIndex:section]];
    return view;
}

- (id _Nullable)footerViewAt:(NSInteger)section
{
    UICollectionReusableView* view = [self supplementaryViewForElementKind:FOOTER atIndexPath:[NSIndexPath indexPathWithIndex:section]];
    return view;
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

#pragma mark - Header/Footer Size

- (void)setSize:(CGSize)size headerfooterModel:(id _Nonnull)model kind:(NSString*)kind
{
    NSValue *value = [NSValue valueWithCGSize:size];
    NSValue *key = [NSValue valueWithNonretainedObject:model];
    if ( kind == HEADER ) {
        _headerViewSizeDic[key] = value;
    }
    else if( kind == FOOTER ){
        _footerViewSizeDic[key] = value;
    }    
}

- (CGSize)getSizeForHeaderfooterModel:(id _Nonnull)model kind:(NSString*)kind
{
    NSValue *key = [NSValue valueWithNonretainedObject:model];
    NSValue *value = nil;
    if ( kind == HEADER ) {
        value = _headerViewSizeDic[key];
    }
    else if( kind == FOOTER ){
        value = _footerViewSizeDic[key];
    }    
    if ( value == nil ) {
        return CGSizeMake(-1, -1);
    }
    return [value CGSizeValue];
}

- (void)setSize:(CGSize)size headerModel:(id _Nonnull)headerModel
{
    [self setSize:size headerfooterModel:headerModel kind:HEADER];
}

- (void)setSize:(CGSize)size footerModel:(id _Nonnull)footerModel
{
    [self setSize:size headerfooterModel:footerModel kind:FOOTER];
}

- (CGSize)getSizeHeaderModel:(id _Nonnull)headerModel
{
    return [self getSizeForHeaderfooterModel:headerModel kind:HEADER];
}

- (CGSize)getSizeFooterModel:(id _Nonnull)footerModel
{
    return [self getSizeForHeaderfooterModel:footerModel kind:FOOTER];
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
    
    if( self.enabledLoadingMore ){
        if (!_hasCalledOnEndReached) {
            if (totalOffset + self.onEndReachedThresHold >= contentSizeHeight) {
                if ([self.kh_delegate respondsToSelector:@selector(collectionViewOnEndReached:)]) {
                    [self.kh_delegate collectionViewOnEndReached:self];
                }
                
                _hasCalledOnEndReached = YES;
            }
        } else {
            if (totalOffset + self.onEndReachedThresHold < contentSizeHeight) {
                _hasCalledOnEndReached = NO;
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
    if ( self.kh_delegate && [self.kh_delegate respondsToSelector:@selector(collectionViewOnPulldown:refreshControl:)]) {
        [self.kh_delegate collectionViewOnPulldown:self refreshControl:_refreshControl];
    }
}


- (void)endRefreshing
{
    if (_refreshControl.refreshing) {
        [_refreshControl endRefreshing];
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
    if ( _enabledLoadingMore == enabledLoadingMore ) {
        return;
    }
    _enabledLoadingMore = enabledLoadingMore;
    
    //  多加一個 section，但是只顯示 footer
    if( _firstLoadHeaderFooter ){
        if ( _enabledLoadingMore ) {
            [self insertSections:[NSIndexSet indexSetWithIndex:_sections.count]];
        }else{
            [self deleteSections:[NSIndexSet indexSetWithIndex:_sections.count]];
        }
    }
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
//    NSLog(@"KHCollectionView >> section %ld , cell count %ld", (long)section, array.count);
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
        if ([cellName isEqualToString:NSStringFromClass([UICollectionContainerCell class])]) {
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
//    NSLog(@"KHCollectionView >> [%ld,%ld] cell size %@", (long)indexPath.section,(long)indexPath.row, NSStringFromCGSize(cellSize));
    
    return pairInfo.cellSize;
}


// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    _firstReload = YES;
//    NSLog(@"KHCollectionView >> [%ld,%ld] cell config", (long)indexPath.section,(long)indexPath.row );
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
        KHCollectionViewLoadingFooter *footer = [collectionView dequeueReusableSupplementaryViewOfKind:FOOTER
                                                                                   withReuseIdentifier:NSStringFromClass([KHCollectionViewLoadingFooter class])
                                                                                          forIndexPath:indexPath];
        footer.indicatorView = self.loadingIndicator;
        return footer;
    }
    
    id model = nil;
    NSString *reusableViewName = nil;
    if ( kind == HEADER && _headerModelDic.count > 0  ) {
        model = [self headerModelAt:indexPath.section];
        reusableViewName = [self getHeaderNameFor:model];
    }
    else if( kind == FOOTER && _footerModelDic.count > 0  ){
        model = [self footerModelAt:indexPath.section];
        reusableViewName = [self getFooterNameFor:model];
    }
    
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
    
    CGSize size = [self getSizeHeaderModel:headerModel];
    // size 為 -1 -1，代表先前完全都沒設定過
    if ( size.width == -1 && size.height == -1 ) {
        if ( [headerModel isKindOfClass:[UIView class]]) {
            UIView *view = headerModel;
            [self setSize:(CGSize)view.frame.size headerModel:view];
            size = view.frame.size;
        }
        else{
            NSString *headerViewName = [self getHeaderNameFor:headerModel];
            if([[NSBundle mainBundle] pathForResource:headerViewName ofType:@"nib"] != nil) {
                UINib *nib = [UINib nibWithNibName:headerViewName bundle:nil];
                NSArray *arr = [nib instantiateWithOwner:nil options:nil ];
                UICollectionReusableView *headerView = arr[0];
                [self setSize:headerView.frame.size headerModel:headerModel];
                size = headerView.frame.size;
            }
            else{
                [self setSize:(CGSize){100,100} headerModel:headerModel];
                size = (CGSize){100,100};
            }
        }
    }
//    NSLog(@"KHCollectionView >> section %ld header size %@", (long)section, NSStringFromCGSize(size));
    return size;
}

// footer size
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section
{
    
    if ( self.enabledLoadingMore && section == _sections.count ) {
        // Margin Vertical: 10
//        NSLog(@"KHCollectionView >> section %ld footer size %@", (long)section, NSStringFromCGSize(CGSizeMake(collectionView.bounds.size.width, CGRectGetHeight(self.loadingIndicator.frame) + 20)));
        return CGSizeMake(collectionView.bounds.size.width, CGRectGetHeight(self.loadingIndicator.frame) + 20);
    }
    else if( section >= _sections.count ){
//        NSLog(@"KHCollectionView >> section %ld footer size 0,0", (long)section);
        return CGSizeZero;
    }
    
    NSMutableArray *sectionArray = _sections[section];
    NSValue *key = [NSValue valueWithNonretainedObject:sectionArray];
    id footerModel = _footerModelDic[key];
    
    if ( footerModel == nil || footerModel == [NSNull null] ) return CGSizeZero;
    
    CGSize size = [self getSizeFooterModel:footerModel];
    // size 為 -1 -1，代表先前完全都沒設定過
    if ( size.width == -1 && size.height == -1 ) {
        if ( [footerModel isKindOfClass:[UIView class]]) {
            UIView *view = footerModel;
            [self setSize:(CGSize)view.frame.size footerModel:footerModel];
            size = view.frame.size;
        }
        else{
            NSString *footerViewName = [self getFooterNameFor:footerModel];
            if([[NSBundle mainBundle] pathForResource:footerViewName ofType:@"nib"] != nil) {
                UINib *nib = [UINib nibWithNibName:footerViewName bundle:nil];
                NSArray *arr = [nib instantiateWithOwner:nil options:nil ];
                UICollectionReusableView *footerView = arr[0];
                [self setSize:footerView.frame.size footerModel:footerModel];
                size = footerView.frame.size;
            }
            else{
                [self setSize:(CGSize){100,100} footerModel:footerModel];
                size = (CGSize){100,100};
            }
        }
    }
    
//    NSLog(@"KHCollectionView >> section %ld footer size %@", (long)section, NSStringFromCGSize(size));
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
        [self runInsertAnimation:[NSIndexPath indexPathForRow:index inSection:array.kh_section]];
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
            [self runInsertAnimation:[NSIndexPath indexPathForRow:idx inSection:array.kh_section]];
        }];
    }
    else{
        [self reloadData];
    }
}

//  刪除
-(void)removeObject:(id)object index:(NSUInteger)index inArray:(nonnull NSMutableArray *)array
{
    [self removePairInfo:object];
    
    if (_firstReload && self.isNeedAnimation) {
        [self runRemoveAnimation:[NSIndexPath indexPathForRow:index inSection:array.kh_section]];
    }
//    else {
//        [self reloadData];
//    }

}

//  刪除全部
-(void)removeObjects:(NSArray *)objects indexs:(NSIndexSet *)indexs inArray:(nonnull NSMutableArray *)array
{
    for ( id model in objects ) {
        [self removePairInfo:model];
    }

    if (_firstReload && self.isNeedAnimation) {
        [indexs enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
            [self runRemoveAnimation:[NSIndexPath indexPathForRow:idx inSection:array.kh_section]];
        }];
    } 
//    else {
//        [self reloadData];
//    }
}

//  取代
-(void)replacedObject:(id)oldObj newObject:(id)newObj index:(NSUInteger)index inArray:(nonnull NSMutableArray *)array
{
    [self replacePairInfo:oldObj new:newObj];
    
    if (_firstReload && self.isNeedAnimation) {
        [self runReloadAnimation:[NSIndexPath indexPathForRow:index inSection:array.kh_section]];
    }
//    else {
//        [self reloadData];
//    }
}

//  更新
-(void)update:(id)object index:(NSUInteger)index inArray:(nonnull NSMutableArray *)array
{
    if (_firstReload && self.isNeedAnimation) {
        [self runReloadAnimation:[NSIndexPath indexPathForRow:index inSection:array.kh_section]];
    }
    else {
        [self reloadData];
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
                NSMutableArray *insertQueue = [w_item_animationQueue objectAtIndex:CellAnimation_Insert];
                if( insertQueue.count > 0 )[w_self insertItemsAtIndexPaths: insertQueue ];
                
                NSMutableArray *reloadQueue = [w_item_animationQueue objectAtIndex:CellAnimation_Reload];
                if( reloadQueue.count > 0 )[w_self reloadItemsAtIndexPaths:reloadQueue ];
                
                NSMutableArray *removeQueue = [w_item_animationQueue objectAtIndex:CellAnimation_Remove];
                if( removeQueue.count > 0 )[w_self deleteItemsAtIndexPaths: removeQueue ];
                
                // section animation
                NSIndexSet *insertSectionSet = [w_section_animationQueue objectAtIndex:CellAnimation_Insert];
                if( insertSectionSet.count > 0 )[w_self insertSections: insertSectionSet ];
                
                NSIndexSet *reloadSectionSet = [w_section_animationQueue objectAtIndex:CellAnimation_Reload];
                if( reloadSectionSet.count > 0 )[w_self reloadSections:reloadSectionSet ];
                
                NSIndexSet *removeSectionSet = [w_section_animationQueue objectAtIndex:CellAnimation_Remove];
                if( removeSectionSet.count > 0 )[w_self deleteSections: removeSectionSet ];
                
                [w_self clearAnimationQueue];
            } completion:^(BOOL finished) {
                needUpdate = NO;
            }];
        });
    }
}

//  sectin animation

- (void)runInsertSectionAnimation:(NSUInteger)index
{
    if ( !self.isNeedAnimation ) return;
    NSMutableIndexSet *_insertSet = _section_animationQueue[CellAnimation_Insert];
    [_insertSet addIndex:index];
    [self setNeedsRunAnimation];
}

- (void)runRemoveSectionAnimation:(NSUInteger)index
{
    if ( !self.isNeedAnimation ) return;
    NSMutableIndexSet *_removeSet = _section_animationQueue[CellAnimation_Remove];
    [_removeSet addIndex:index];
    [self setNeedsRunAnimation];
}

- (void)runReloadSectionAnimation:(NSUInteger)index
{
    if ( !self.isNeedAnimation ) return;
    NSMutableIndexSet *_reloadSet = _section_animationQueue[CellAnimation_Reload];
    [_reloadSet addIndex:index];
    [self setNeedsRunAnimation];
}

// item animation

- (void)runInsertAnimation:(NSIndexPath*)indexPath
{
    if ( !self.isNeedAnimation ) return;
    NSMutableArray *_insertAnimArray = _item_animationQueue[CellAnimation_Insert];
    [_insertAnimArray addObject:indexPath];
    [self setNeedsRunAnimation];
}

- (void)runRemoveAnimation:(NSIndexPath*)indexPath
{
    if ( !self.isNeedAnimation ) return;
    NSMutableArray *_removeAnimArray = _item_animationQueue[CellAnimation_Remove];
    [_removeAnimArray addObject:indexPath];
    [self setNeedsRunAnimation];
}

- (void)runReloadAnimation:(NSIndexPath*)indexPath
{
    if ( !self.isNeedAnimation ) return;
    NSMutableArray *_reloadAnimArray = _item_animationQueue[CellAnimation_Reload];
    [_reloadAnimArray addObject:indexPath];
    [self setNeedsRunAnimation];
}

- (void)clearAnimationQueue
{
    for ( NSMutableArray *array in _item_animationQueue ) {
        [array removeAllObjects];
    }
    
    for ( NSMutableIndexSet *indexSet in _section_animationQueue ) {
        [indexSet removeAllIndexes];
    }
}

@end



#pragma mark - ==========================


@implementation KHCollectionViewLoadingFooter

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


@implementation KHContainerReusableView

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.backgroundColor = [UIColor clearColor];
    
    self.contentView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
}


- (void)onLoad:(UIView*)view
{
    if( self.contentView ){
        [self.contentView removeFromSuperview];
        self.contentView = nil;
    }
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









