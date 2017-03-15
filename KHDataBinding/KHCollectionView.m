//
//  KHCollectionView.m
//  KHDataBindingDemo
//
//  Created by GevinChen on 2017/3/2.
//  Copyright © 2017年 omg. All rights reserved.
//

#import "KHCollectionView.h"





#pragma mark - ==========================


@interface KHCollectionViewLoadingFooter : UICollectionReusableView

@property (nonatomic, strong) UIView *indicatorView;

@end

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

@interface KHContainerReusableView : UICollectionReusableView

@property (nonatomic, strong) UIView *contentView; 

@end


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
    _animationQueue = [[NSMutableArray alloc] initWithCapacity: 3 ];
    _eventDatas = [[NSMutableArray alloc] initWithCapacity: 10 ];
    
    _headerModelDic = [[NSMutableDictionary alloc] initWithCapacity: 10 ];
    _footerModelDic = [[NSMutableDictionary alloc] initWithCapacity: 10 ];
    _headerViewDic = [[NSMutableDictionary alloc] initWithCapacity: 5 ];
    _footerViewDic = [[NSMutableDictionary alloc] initWithCapacity: 5 ];
    _headerViewSizeDic = [[NSMutableDictionary alloc] initWithCapacity: 5 ];
    _footerViewSizeDic = [[NSMutableDictionary alloc] initWithCapacity: 5 ];
    
    //  init animation queue struct
    [_animationQueue addObject: [[NSMutableArray alloc] initWithCapacity: 10 ] ]; // insert
    [_animationQueue addObject: [[NSMutableArray alloc] initWithCapacity: 10 ] ]; // remove
    [_animationQueue addObject: [[NSMutableArray alloc] initWithCapacity: 10 ] ]; // reload    
    
    //  init UIRefreshControl
    _headRefreshControl = [[UIRefreshControl alloc] init];
    _headRefreshControl.backgroundColor = [UIColor clearColor];
    _headRefreshControl.tintColor = [UIColor lightGrayColor]; // spinner color
    [_headRefreshControl addTarget:self
                            action:@selector(refreshHead:)
                  forControlEvents:UIControlEventValueChanged];
    NSDictionary *attributeDic = @{NSForegroundColorAttributeName:[UIColor lightGrayColor],
                                   NSFontAttributeName:[UIFont boldSystemFontOfSize:14]};
    refreshTitle = [[NSAttributedString alloc] initWithString:@"Pull down to reload!" attributes:attributeDic];
    _headRefreshControl.attributedTitle = refreshTitle;//[[NSAttributedString alloc] initWithString:@"Pull down to reload!" attributes:attributeDic];
    
    // register loading footer
    [self registerClass:[KHCollectionViewLoadingFooter class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:NSStringFromClass([KHCollectionViewLoadingFooter class])];
    
    //  register heater footer container view
    [self registerClass:[KHContainerReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:NSStringFromClass([KHContainerReusableView class])];
    [self registerClass:[KHContainerReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:NSStringFromClass([KHContainerReusableView class])];
    
    // init loading footer indicator view
    UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    [indicatorView startAnimating];
    indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    _loadingIndicator = indicatorView;
//    _onEndReachedThresHold = 44.0f;
    
    [self setMappingModel:[UIView class] headerClass:[KHContainerReusableView class]];
    [self setMappingModel:[UIView class] footerClass:[KHContainerReusableView class]];
    
    //  assign delegate
    self.delegate = self;
    self.dataSource = self;
}


#pragma mark - autoExpandHeight

// @todo: 要再找個 時間點執行 constraintHeight.constant = xxx;
- (void)setAutoExpandHeight:(BOOL)autoExpandHeight
{
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
//    pairInfo.binder = self;
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

//  連結 model 與 cell
//- (void)pairedModel:(id)model cell:(UICollectionViewCell*)cell
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
//    pairInfo.cell = cell;
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
        array.kh_delegate = nil;
        array.kh_section = 0;
        [_sections removeObject: array ];
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
    [_sections addObject:array];
    [self observeArray:array];
}

- (void)removeSection:(NSMutableArray *_Nonnull)array
{
    [_sections removeObject:array];
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


#pragma mark - Config Model Cell Mapping

//  設定對映
- (void)setMappingModel:(Class _Nonnull)modelClass cell:(Class _Nonnull)cellClass
{
    NSString *modelName = NSStringFromClass(modelClass);
    NSString *cellName = NSStringFromClass(cellClass);
    _cellClassDic[modelName] = cellName;

    UINib*nib = [UINib nibWithNibName:cellName bundle:nil];
    [self registerNib:nib forCellWithReuseIdentifier:cellName];
}

//  設定對映，使用 block 處理
- (void)setMappingModel:(Class _Nonnull)modelClass block:( Class _Nullable(^ _Nonnull)(id _Nonnull model, NSIndexPath *_Nonnull index))mappingBlock
{
    NSString *modelName = NSStringFromClass(modelClass);
    _cellClassDic[modelName] = [mappingBlock copy];
}

//  取得對映的 cell class
- (NSString *_Nullable)getMappingCellFor:(id _Nonnull)model index:(NSIndexPath *_Nullable)index
{
    NSString *modelName = NSStringFromClass( [model class] );
    
    /*
     Gevin note:
     NSString 我透過 [cellClass mappingModelClass]; 取出 class 轉成字串，會得到 NSString
     但是透過 NSString 的實體，取得 class 轉成字串，卻會是 __NSCFConstantString
     2017-02-13 : 改直接用 class 做檢查
     
     */
    if ( [model isKindOfClass: [NSString class] ] ) {
        modelName = @"NSString";
    }
    else if( [model isKindOfClass:[NSDictionary class]] ){
        modelName = @"NSDictionary";
    }
    else if( [model isKindOfClass:[NSArray class]] ){
        modelName = @"NSArray";
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
        @throw [NSException exceptionWithName:@"Invalid Model Class" reason:[NSString stringWithFormat: @"Can't find any CellName map with this class %@", modelName ] userInfo:nil];
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
    KHPairInfo *pairInfo = [self getPairInfo:model];
    if ( !pairInfo ) {
        pairInfo = [self addPairInfo:model];
    }
    pairInfo.cellSize = cellSize;
}

- (void)setCellSize:(CGSize)cellSize models:(NSArray *_Nonnull)models
{
    for ( id model in models ) {
        [self setCellSize:cellSize model:model];
    }
}


#pragma mark - Config Model Header/Footer Mapping

- (void)setMappingModel:(Class _Nonnull)modelClass headerClass:(Class _Nonnull)reusableViewClass
{
    NSString *modelName = NSStringFromClass(modelClass);
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
    else if( modelClass == [UIView class]){
        modelName = @"UIView";
    }
    
    NSString *headerViewName = NSStringFromClass(reusableViewClass);
    _headerViewDic[modelName] = headerViewName;
    
    //  登錄 header view nib
    UINib *nib = [UINib nibWithNibName:headerViewName bundle:nil];
    [self registerNib:nib forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:headerViewName];

}

- (void)setMappingModel:(Class _Nonnull)modelClass footerClass:(Class _Nonnull)reusableViewClass
{
    NSString *modelName = NSStringFromClass(modelClass);
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
    else if( modelClass == [UIView class]){
        modelName = @"UIView";
    }
    
    NSString *footerViewName = NSStringFromClass(reusableViewClass);
    _footerViewDic[modelName] = footerViewName;
    
    //  登錄 footer view nib
    UINib *nib = [UINib nibWithNibName:footerViewName bundle:nil];
    [self registerNib:nib forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:footerViewName];
    
}

//  取得對映的 header
- (NSString *_Nullable)getHeaderNameFor:(id _Nonnull)model
{
    NSString *modelName = NSStringFromClass([model class]);
    if ( [model isKindOfClass:[NSDictionary class]]) {
        modelName = @"NSDictionary";
    }
    else if([model isKindOfClass:[NSArray class]]){
        modelName = @"NSArray";
    }
    else if([model isKindOfClass:[NSString class]]){
        modelName = @"NSString";
    }
    else if([model isKindOfClass:[NSNumber class]]){
        modelName = @"NSNumber";
    }
    else if([model isKindOfClass:[UIView class]]){
        modelName = @"UIView";
    }
    
    return _headerViewDic[modelName];
}

//  取得對映的 footer
- (NSString *_Nullable)getFooterNameFor:(id _Nonnull)model
{
    NSString *modelName = NSStringFromClass([model class]);
    if ( [model isKindOfClass:[NSDictionary class]]) {
        modelName = @"NSDictionary";
    }
    else if([model isKindOfClass:[NSArray class]]){
        modelName = @"NSArray";
    }
    else if([model isKindOfClass:[NSString class]]){
        modelName = @"NSString";
    }
    else if([model isKindOfClass:[NSNumber class]]){
        modelName = @"NSNumber";
    }
    else if([model isKindOfClass:[UIView class]]){
        modelName = @"UIView";
    }
    
    return _footerViewDic[modelName];
}

- (void)setHeaderModel:(id _Nonnull)model atIndex:(NSInteger)sectionIndex
{
    if ( sectionIndex >= _sections.count ) {
        NSLog(@"Warring!!! the section index %d of header model out of bound %d.", (int)sectionIndex, (int)_sections.count );
        return;
    }
    NSMutableArray *sectionArray = _sections[sectionIndex];
    NSValue *key = [NSValue valueWithNonretainedObject:sectionArray];
    _headerModelDic[key] = model;
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
    if ( sectionIndex >= _sections.count ) {
        NSLog(@"Warring!!! the section index %d of footer model out of bound %d.", (int)sectionIndex, (int)_sections.count );
        return;
    }
    NSMutableArray *sectionArray = _sections[sectionIndex];
    NSValue *key = [NSValue valueWithNonretainedObject:sectionArray];
    _footerModelDic[key] = model;
}

- (void)setFooterModels:(NSArray *_Nonnull)models
{
    for ( int i=0; i<models.count; i++ ) {
        id model = models[i];
        [self setFooterModel:model atIndex:i];
    }
}

- (id _Nullable)getHeaderModelAt:(NSInteger)section
{
    NSMutableArray *sectionArray = _sections[section];
    NSValue *key = [NSValue valueWithNonretainedObject:sectionArray];
    id model = _headerModelDic[key];
    return model;
}

- (id _Nullable)getFooterModelAt:(NSInteger)section
{
    NSMutableArray *sectionArray = _sections[section];
    NSValue *key = [NSValue valueWithNonretainedObject:sectionArray];
    id model = _footerModelDic[key];
    return model;    
}


#pragma mark - Header/Footer Size


- (void)setSize:(CGSize)size headerModel:(id _Nonnull)headerModel
{
    NSValue *value = [NSValue valueWithCGSize:size];
    NSValue *key = [NSValue valueWithNonretainedObject:headerModel];
    _headerViewSizeDic[key] = value;
}

- (void)setSize:(CGSize)size footerModel:(id _Nonnull)footerModel
{
    NSValue *value = [NSValue valueWithCGSize:size];
    NSValue *key = [NSValue valueWithNonretainedObject:footerModel];
    _footerViewSizeDic[key] = value;
}

- (CGSize)getSizeHeaderModel:(id _Nonnull)headerModel
{
    NSValue *key = [NSValue valueWithNonretainedObject:headerModel];
    NSValue *value = _headerViewSizeDic[key];
    if ( value == nil ) {
        return CGSizeMake(-1, -1);
    }
    return [value CGSizeValue];
}

- (CGSize)getSizeFooterModel:(id _Nonnull)footerModel
{
    NSValue *key = [NSValue valueWithNonretainedObject:footerModel];
    NSValue *value = _footerViewSizeDic[key];
    if ( value == nil ) {
        return CGSizeMake(-1, -1);
    }
    return [value CGSizeValue];
}



#pragma mark - UI Event Handle


// 指定要監聽某個 cell 上的某個 ui，這邊要注意，你要監聽的 UIResponder 一定要設定為一個 property，那到時觸發事件後，你想要知道是屬於哪個 cell 或哪個 model，再另外反查
- (void)addTarget:(nullable id)target action:(nonnull SEL)action forControlEvents:(UIControlEvents)event onCell:(nonnull Class)cellClass propertyName:(nonnull NSString*)property
{
    KHEventHandleData *eventData = [KHEventHandleData new];
    eventData.target = target;
    eventData.action = action;
    eventData.event = event;
    eventData.cellClass = cellClass;
    eventData.propertyName = property;
    [_eventDatas addObject:eventData];
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


#pragma mark - Lookup back

//  透過某個 responder UI，取得 cell
- (nullable UICollectionViewCell*)getCellByUIControl:(UIView *_Nonnull)responderUI
{
    if ( responderUI.superview == nil ) {
        return nil;
    }
    UICollectionViewCell *cell = nil;
    UIView *superView = responderUI.superview;
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
- (nullable id)getModelByUIControl:(UIView *_Nonnull)responderUI
{
    UICollectionViewCell *cell = [self getCellByUIControl: responderUI ];
    if ( cell == nil ) {
        return nil;
    }
    id model = [self modelForCell: cell ];
    return model;
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

- (void)refreshHead:(id)sender
{
    if ( self.kh_delegate && [self.kh_delegate respondsToSelector:@selector(collectionViewOnPulldown:refreshControl:)]) {
        [self.kh_delegate collectionViewOnPulldown:self refreshControl:_headRefreshControl];
    }
}


- (void)endRefreshing
{
    if (_headRefreshControl.refreshing) {
        [_headRefreshControl endRefreshing];
    }
}

- (void)setEnabledPulldownRefresh:(BOOL)enabledPulldownRefresh
{
    _enabledPulldownRefresh = enabledPulldownRefresh;
    if (enabledPulldownRefresh) {
        if ( _headRefreshControl ) {
            [self addSubview: _headRefreshControl ];
        }
    }
    else{
        if ( _headRefreshControl ) {
            [_headRefreshControl removeFromSuperview];
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
    
    // LoadingIndicator section has no cells.
    if ( _sections.count == 0 || (self.enabledLoadingMore && section == _sections.count )) {
        return 0;
    }
    
    NSArray *array = _sections[section];
    NSLog(@"KHCollectionView >> section %ld , cell count %ld", (long)section, array.count);
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
    CGSize cellSize = pairInfo.cellSize;
    
    if ( cellSize.width == 0 && cellSize.height == 0 ) {
        NSString *cellName = [self getMappingCellFor:model index:indexPath ];
        UINib *nib = [UINib nibWithNibName:cellName bundle:[NSBundle mainBundle]];
        NSArray *arr = [nib instantiateWithOwner:nil options:nil];        
        _prototype_cell = arr[0];
        cellSize = _prototype_cell.frame.size;
        pairInfo.cellSize = cellSize;
    }
    
    //    CGSize size = [cellSizeValue CGSizeValue];
    NSLog(@"KHCollectionView >> [%ld,%ld] cell size %@", (long)indexPath.section,(long)indexPath.row, NSStringFromCGSize(cellSize));
    
    return pairInfo.cellSize;
}


// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    _firstReload = YES;
    NSLog(@"KHCollectionView >> [%ld,%ld] cell config", (long)indexPath.section,(long)indexPath.row );
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
    
    UICollectionViewCell *cell = nil;
    @try {
        cell = [self dequeueReusableCellWithReuseIdentifier:cellName forIndexPath:indexPath ];
    }
    @catch (NSException *exception) {
        UINib*nib = [UINib nibWithNibName:cellName bundle:nil];
        [self registerNib:nib forCellWithReuseIdentifier:cellName];
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
    if ([kind isEqualToString:UICollectionElementKindSectionFooter] &&
        ( _sections.count == 0 || (self.enabledLoadingMore && indexPath.section == _sections.count )) ) {
        KHCollectionViewLoadingFooter *footer = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                                                                                   withReuseIdentifier:NSStringFromClass([KHCollectionViewLoadingFooter class])
                                                                                          forIndexPath:indexPath];
        footer.indicatorView = self.loadingIndicator;
        return footer;
    }
    
    id model = nil;
    NSString *reusableViewName = nil;
    if ( kind == UICollectionElementKindSectionHeader && _headerModelDic.count > 0  ) {
        model = [self getHeaderModelAt:indexPath.section];
        reusableViewName = [self getHeaderNameFor:model];
    }
    else if( kind == UICollectionElementKindSectionFooter && _footerModelDic.count > 0  ){
        NSMutableArray *sectionArray = _sections[indexPath.section];
        NSValue *key = [NSValue valueWithNonretainedObject:sectionArray];
        model = _footerModelDic[key];
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
        UINib *nib = [UINib nibWithNibName:reusableViewName bundle:nil];
        [self registerNib:nib forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:reusableViewName ];
        reusableView = [self dequeueReusableSupplementaryViewOfKind:kind
                                                withReuseIdentifier:reusableViewName
                                                       forIndexPath:indexPath];;
    }
    
    //  每個 cell 只會執行一次，做初始設定
    if ( !reusableView.kh_hasConfig && ![reusableView isKindOfClass:[KHContainerReusableView class]] ) {
        reusableView.kh_hasConfig = YES;
        // 監聽 cell 上的 ui event
        [self observeUIControlFor:reusableView];
        if(kind == UICollectionElementKindSectionHeader && 
           self.kh_delegate && 
           [self.kh_delegate respondsToSelector:@selector(collectionView:newHeader:model:indexPath:)]){
            [self.kh_delegate collectionView:self newHeader:reusableView model:model indexPath:indexPath];
        }
        else if(kind == UICollectionElementKindSectionFooter && 
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
        NSLog(@"KHCollectionView >> section %d header size 0,0", section);
        return CGSizeZero;
    }
    
    NSMutableArray *sectionArray = _sections[section];
    NSValue *key = [NSValue valueWithNonretainedObject:sectionArray];
    id headerModel = _headerModelDic[key];
    
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
            UINib *nib = [UINib nibWithNibName:headerViewName bundle:nil];
            NSArray *arr = [nib instantiateWithOwner:nil options:nil ];
            UICollectionReusableView *headerView = arr[0];
            [self setSize:headerView.frame.size headerModel:headerModel];
            size = headerView.frame.size;
        }
    }
    NSLog(@"KHCollectionView >> section %d header size %@", section, NSStringFromCGSize(size));
    return size;
}

// footer size
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section
{
    
    if ( self.enabledLoadingMore && section == _sections.count ) {
        // Margin Vertical: 10
        NSLog(@"KHCollectionView >> section %d footer size %@", section, NSStringFromCGSize(CGSizeMake(collectionView.bounds.size.width, CGRectGetHeight(self.loadingIndicator.frame) + 20)));
        return CGSizeMake(collectionView.bounds.size.width, CGRectGetHeight(self.loadingIndicator.frame) + 20);
    }
    else if( section >= _sections.count ){
        NSLog(@"KHCollectionView >> section %d footer size 0,0", section);
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
            UINib *nib = [UINib nibWithNibName:footerViewName bundle:nil];
            NSArray *arr = [nib instantiateWithOwner:nil options:nil ];
            UICollectionReusableView *footerView = arr[0];
            [self setSize:footerView.frame.size footerModel:footerModel];
            size = footerView.frame.size;
        }
    }
    
    NSLog(@"KHCollectionView >> section %d footer size %@", section, NSStringFromCGSize(size));
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
-(void)arrayInsert:(NSMutableArray*)array insertObject:(id)object index:(NSIndexPath*)index
{
    KHPairInfo *pairInfo = [self getPairInfo: object ];
    if ( !pairInfo ) {
        [self addPairInfo:object];
    }

    if (_firstReload && self.isNeedAnimation) {
        [self runInsertAnimation:index];
    }
    else{
        [self reloadData];
    }
}

//  插入 多項
//-(void)arrayInsertSome:(NSMutableArray *)array insertObjects:(NSArray *)objects indexes:(NSArray *)indexes
//{
//    for ( id model in objects ) {
//        KHPairInfo *pairInfo = [self getPairInfo: model ];
//        if ( !pairInfo ) {
//            [self addPairInfo:model];
//        }
//    }
//
//    if (_firstReload && self.isNeedAnimation){
//        for ( NSIndexPath *index in indexes ) {
//            [self runInsertAnimation:index];
//        }
//    }
//    else{
//        [self reloadData];
//    }
//}

//  刪除
-(void)arrayRemove:(NSMutableArray*)array removeObject:(id)object index:(NSIndexPath*)index
{
    [self removePairInfo:object];
    
    if (_firstReload && self.isNeedAnimation) {
        [self runRemoveAnimation:index];
    }
    else {
        [self reloadData];
    }

}

//  刪除全部
//-(void)arrayRemoveSome:(NSMutableArray *)array removeObjects:(NSArray *)objects indexs:(NSArray *)indexes
//{
//    for ( id model in objects ) {
//        [self removePairInfo:model];
//    }
//
//    if (_firstReload && self.isNeedAnimation) {
//        for ( NSIndexPath *index in indexes ) {
//            [self runRemoveAnimation:index];
//        }
//    } else {
//        [self reloadData];
//    }
//}

//  取代
-(void)arrayReplace:(NSMutableArray*)array newObject:(id)newObj replacedObject:(id)oldObj index:(NSIndexPath*)index
{
    [self replacePairInfo:oldObj new:newObj];
    
    if (_firstReload && self.isNeedAnimation) {
        [self runReloadAnimation:index];
    }
    else {
        [self reloadData];
    }
}

//  更新
-(void)arrayUpdate:(NSMutableArray*)array update:(id)object index:(NSIndexPath*)index
{
    if (_firstReload && self.isNeedAnimation) {
        [self runReloadAnimation:index];
    }
//    else {
//        [self reloadData];
//    }
}

//// 更新全部
//-(void)arrayUpdateAll:( nonnull NSMutableArray*)array
//{
//    [self reloadData];
//}

#pragma mark - Animation

- (void)setNeedsRunAnimation
{
    if( self.isNeedAnimation && !needUpdate ){
        needUpdate = YES;
        __weak typeof (self) w_self = self;
        __weak NSMutableArray *w_animationQueue = _animationQueue;
        dispatch_async( dispatch_get_main_queue(), ^{
            [w_self performBatchUpdates:^{
                
                NSMutableArray *insertQueue = [w_animationQueue objectAtIndex:CellAnimation_Insert];
                [w_self insertItemsAtIndexPaths: insertQueue ];
                
                NSMutableArray *reloadQueue = [w_animationQueue objectAtIndex:CellAnimation_Reload];
                [w_self reloadItemsAtIndexPaths:reloadQueue ];
                
                NSMutableArray *removeQueue = [w_animationQueue objectAtIndex:CellAnimation_Remove];
                [w_self deleteItemsAtIndexPaths: removeQueue ];
                
                [w_self clearAnimationQueue];
            } completion:^(BOOL finished) {
                needUpdate = NO;
            }];
        });
    }
}

- (void)runInsertAnimation:(NSIndexPath*)indexPath
{
    if ( !self.isNeedAnimation ) return;
    NSMutableArray *_insertAnimArray = _animationQueue[CellAnimation_Insert];
    [_insertAnimArray addObject:indexPath];
    [self setNeedsRunAnimation];
}

- (void)runRemoveAnimation:(NSIndexPath*)indexPath
{
    if ( !self.isNeedAnimation ) return;
    NSMutableArray *_removeAnimArray = _animationQueue[CellAnimation_Remove];
    [_removeAnimArray addObject:indexPath];
    [self setNeedsRunAnimation];
}

- (void)runReloadAnimation:(NSIndexPath*)indexPath
{
    if ( !self.isNeedAnimation ) return;
    NSMutableArray *_reloadAnimArray = _animationQueue[CellAnimation_Reload];
    [_reloadAnimArray addObject:indexPath];
    [self setNeedsRunAnimation];
}

- (void)clearAnimationQueue
{
    for ( NSMutableArray *array in _animationQueue ) {
        [array removeAllObjects];
    }
}

@end
