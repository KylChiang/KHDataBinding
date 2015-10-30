//
//  TableViewBindHelper.m
//  DataBindTest
//
//  Created by GevinChen on 2015/9/26.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import "KHTableViewBindHelper.h"
#import <CommonCrypto/CommonDigest.h>
#import <objc/runtime.h>

@implementation KHTableViewBindHelper

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
    self = [super init];
    if (self) {
        [self initImpl];
        self.tableView = tableView;
    }
    return self;
}

- (void)initImpl
{
    _sectionArray = [[NSMutableArray alloc] initWithCapacity: 10 ];
    _imageCache = [[NSMutableDictionary alloc] initWithCapacity: 5 ];
    _imageDownloadTag = [[NSMutableArray alloc] initWithCapacity: 5 ];
    plistPath = [[self getCachePath] stringByAppendingString:@"imageNames.plist"];
    _headerHeight = 10;
    
    @synchronized( _imageNamePlist ) {
        if ( ![[NSFileManager defaultManager] fileExistsAtPath: plistPath ] ) {
            _imageNamePlist = [[NSMutableDictionary alloc] initWithCapacity: 5 ];
            [_imageNamePlist writeToFile:plistPath atomically:YES ];
        }else{
            _imageNamePlist = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
        }
    }
}

#pragma mark - Property

- (void)setTableView:(UITableView *)tableView
{
    _tableView = tableView;
    _tableView.delegate = self;
    _tableView.dataSource = self;
}

- (void)setEnableRefreshHeader:(BOOL)enableRefreshHeader
{
    _enableRefreshHeader = enableRefreshHeader;
    if (_enableRefreshHeader) {
        if (_refreshHeader==nil) {
            _refreshHeader = [[EGORefreshTableHeaderView alloc] initWithTableView:_tableView];
            _refreshHeader.delegate = self;
            [_refreshHeader locateView];
        }
        else{
            _refreshHeader.tableView = _tableView;
        }
    }
    else{
        _refreshHeader.tableView = nil;
    }
}

- (void)setEnableRefreshFooter:(BOOL)enableRefreshFooter
{
    _enableRefreshFooter = enableRefreshFooter;
    if (_enableRefreshFooter) {
        if ( _refreshFooter==nil ) {
            _refreshFooter = [[EGORefreshTableFooterView alloc] initWithTableView:_tableView];
            _refreshFooter.delegate = self;
            [_refreshFooter locateView];
        }
        else{
            _refreshFooter.tableView = _tableView;
        }
    }
    else{
        _refreshFooter.tableView = nil;
    }
}

#pragma mark - Bind Array (Public)


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

#pragma mark - UIControl Handle (Public)

//  設定需要監聽的 ui control 及事件
- (void)tagUIControl:(nonnull UIControl*)control cell:(id)cell
{
    if (_uiDic==nil) {
        _uiDic = [[NSMutableDictionary alloc] initWithCapacity:5];
    }
    
    //  宣告
    NSString *propertyName = nil;
    
    //  取得 property name
    unsigned int numOfProperties;
    objc_property_t *properties = class_copyPropertyList( [cell class], &numOfProperties );
    for ( unsigned int pi = 0; pi < numOfProperties; pi++ ) {
        
        objc_property_t property = properties[pi];
        
        NSString *pname = [[NSString alloc] initWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        id object = [cell valueForKey:pname];
        if ( [object isKindOfClass:[UIControl class]] && control == object ) {
            propertyName = pname;
            break;
        }
    }
    
    //  取出這個 property name 的 ui，因為會有很多個 cell，所以會記錄多個 ui
    NSMutableArray *uiArr = _uiDic[propertyName];
    
    //  若先前沒有記錄這個 property，就建構一個新的
    if ( uiArr == nil ) {
        uiArr = [[NSMutableArray alloc ] init];
        [_uiDic setObject:uiArr forKey:propertyName];
    }
    
    //  把 ui 記錄下來
    [uiArr addObject:control];
    
    //  設定 ui 要回應 touch up inside 事件
    [control addTarget:self action:@selector(controlEventTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    //  設定 ui 要回應 value changed 事件
    [control addTarget:self action:@selector(controlEventValueChanged:) forControlEvents:UIControlEventValueChanged];
    
}

//  UI Event
- (void)addTarget:(nonnull id)target action:(nonnull SEL)action event:(UIControlEvents)event propertyName:(nonnull NSString*)pname
{
    NSMethodSignature* signature1 = [target methodSignatureForSelector:action];
    NSInvocation *eventInvocation = [NSInvocation invocationWithMethodSignature:signature1];
    [eventInvocation setTarget:target];
    [eventInvocation setSelector:action];
    
    if ( _invocationDic == nil ) {
        _invocationDic = [[NSMutableDictionary alloc] initWithCapacity: 5 ];
    }
    
    //  透過 property name 取出一個 dictionary ，這個 dic 裡，以事件的編號為key，value 就是 controller 用來回應事件的 selector
    NSMutableDictionary *eventDic = [_invocationDic objectForKey: pname ];
    if ( eventDic == nil ) {
        eventDic = [NSMutableDictionary new];
        [_invocationDic setObject:eventDic forKey:pname];
    }
    
    NSString *eventKey = [NSString stringWithFormat:@"%ld", event ];
    [eventDic setObject: eventInvocation forKey:eventKey ];
    
}

//
- (void)removeTarget:(nonnull id)target action:(nullable SEL)action propertyName:(NSString*)pName
{
    NSMutableDictionary *_eventDic = _invocationDic[pName];
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
- (void)removeTarget:(nonnull id)target propertyName:(nonnull NSString*)pName;
{
    NSMutableDictionary *_eventDic = _invocationDic[pName];
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
- (nullable id)getTargetByAction:(nonnull SEL)action propertyName:(nonnull NSString*)pName;
{
    NSMutableDictionary *_eventDic = _invocationDic[pName];
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


#pragma mark - Image (Public)

- (void)loadImageURL:(NSString *)urlString target:(KHCell*)cell completed:(void (^)(UIImage *))completed
{
    for ( NSString *str in _imageDownloadTag ) {
        if ( [str isEqualToString:urlString] ) {
            //  正在下載中，結束
            return;
        }
    }
    
    //  先看 cache 有沒有，有的話就直接用
    UIImage *image = [self getImageFromCache:urlString];
    if (image) {
        completed(image);
    }
    else {
        id cur_model = cell.model;
        // cache 裡找不到就下載
        dispatch_async( dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            printf("download start %s \n", [urlString UTF8String] );
            //  標記說，這個url正在下載，不要再重覆下載
            [_imageDownloadTag addObject:urlString];
            NSURL *url = [NSURL URLWithString:urlString];
            NSData *data = [[NSData alloc] initWithContentsOfURL:url];
            if ( data ) {
                dispatch_async( dispatch_get_main_queue(), ^{
                    UIImage *image = [[UIImage alloc] initWithData:data];
                    //  下載成功後，要存到 cache
                    [self saveToCache:image key:urlString];
//                    printf("download completed %s \n", [urlString UTF8String] );
                    //  檢查 model 是否還有對映，有的話，才做後續處理
                    if ( cell.model == cur_model ) {
                        completed(image);
                        //  因為圖片產生不是在主執行緒，所以要多加這段，才能圖片正確顯示
                        [cell setNeedsLayout];
                    }
                    //  移除標記，表示沒有在下載，配合 _imageCache，就可以知道是否下載完成
                    [_imageDownloadTag removeObject:urlString];
                });
            }
            else{
                printf("download fail %s \n", [urlString UTF8String]);
            }
        });
    }
}

- (void)clearCache:(NSString*)key
{
    
}

- (void)clearAllCache
{
    
}

- (void)saveToCache:(nonnull UIImage*)image key:(NSString*)key
{
    //  記錄在 memory cache
    [_imageCache setObject:image forKey:key];
    
    //  依 key 從 plist 中取出 image file name
    NSString *imageName = [_imageNamePlist objectForKey:key];
    //  若沒有 file name，就隨機產生一個，並寫入 plist
    if ( imageName == nil ) {
        //  新建一個檔名，存在cache
        NSString *keymd5 = [self MD5: key ];
        imageName = [[keymd5 substringWithRange: (NSRange){0,16} ] stringByAppendingString:@".png"];
        
        //  存進 list
        _imageNamePlist[key] = imageName;
        
        //  儲存 name list
        [_imageNamePlist writeToFile:plistPath atomically:YES];
    }
    
    //  圖片路徑
    NSString *path = [[self getCachePath] stringByAppendingString:imageName];

    //  圖片是否存在，存在就刪掉
    if ( [[NSFileManager defaultManager] fileExistsAtPath:path] ) {
        NSError *err = nil;
        [[NSFileManager defaultManager] removeItemAtPath:path error:&err];
        if (err) {
            printf("delete cache image error, name:%s \n", [imageName UTF8String] );
        }
    }

    //  儲存圖片
    NSData *pngData = UIImagePNGRepresentation(image);
    [pngData writeToFile:path atomically:YES];

}

- (UIImage*)getImageFromCache:(NSString*)key
{
    //  從 memory 快取串取出圖片
    UIImage *image = _imageCache[key];
    
    // 若沒有資料，就試從 disk 讀取
    if ( image == nil ) {
        //  從 name list 取出對映的名字
        NSString *imageName = _imageNamePlist[key];
        
        //  若沒有 image name，就表示 memory cache 跟 disk 都沒有這張圖
        if ( imageName == nil ) {
            return nil;
        }
        
        NSString *imagePath = [self getCachePath];
        imagePath = [imagePath stringByAppendingString:imageName ];
        //  讀取圖片
        image = [[UIImage alloc] initWithContentsOfFile:imagePath];
        
        //  存入 memory 快取
        _imageCache[key] = image;
    }
    
    return image;
}



#pragma mark - Private

- (NSString*)getCachePath
{
    NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachePath = [cachePaths  objectAtIndex:0];
    cachePath = [cachePath stringByAppendingString:@"khdatabind"];
    return cachePath;
}

//- (NSString *)md5:(NSString *)str
//{
//    const char *cStr = [str UTF8String];
//    unsigned char result[CC_MD5_DIGEST_LENGTH];
//    CC_MD5( cStr, strlen(cStr), result );
//    return [NSString
//            stringWithFormat: @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
//            result[0], result[1],
//            result[2], result[3],
//            result[4], result[5],
//            result[6], result[7],
//            result[8], result[9],
//            result[10], result[11],
//            result[12], result[13],
//            result[14], result[15]
//            ];
//    
//}

- (NSString*)MD5:(NSString *)str
{
    // Create pointer to the string as UTF8
    const char *ptr = [str UTF8String];
    
    // Create byte array of unsigned chars
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    // Create 16 byte MD5 hash value, store in buffer
    CC_MD5(ptr, strlen(ptr), md5Buffer);
    
    // Convert MD5 value in the buffer to NSString of hex values
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++){
        [output appendFormat:@"%02x",md5Buffer[i]];
    }
    return output;
}


//  監聽的 ui control 發出事件
- (void)eventCall:(UIControlEvents)event ui:(UIControl*)ui
{
    NSString *tag = nil;
    KHCell *cell = nil;

    // 找出自己的 parent cell
    UIView *view = ui;
    while (!cell) {
        if ( view.superview == nil ) {
            break;
        }
        if ( [view.superview isKindOfClass:[KHCell class]]) {
            cell = (KHCell*)view.superview;
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

//  新增
-(void)arrayAdd:(KHObservableArray*)array newObject:(id)object index:(NSIndexPath*)index
{
    [_tableView insertRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationBottom];
}

//  批次新增
-(void)arrayAdd:(KHObservableArray *)array newObjects:(NSArray *)objects indexs:(NSArray *)indexs
{
//    [_tableView insertRowsAtIndexPaths:indexs withRowAnimation:UITableViewRowAnimationBottom];
    // Gevin note: 若在初始的時候，使用 insertRowsAtIndexPaths:indexs ，取得的 content 會不對，而且找不到
    //  時間點來取，好像是要等它動畫跑完才會正確
    //  改用 reloadData
    [_tableView reloadData];
}

//  刪除
-(void)arrayRemove:(KHObservableArray*)array removeObject:(id)object index:(NSIndexPath*)index
{
    [_tableView deleteRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationMiddle];
}

//  刪除全部
-(void)arrayRemoveAll:(KHObservableArray *)array indexs:(NSArray *)indexs
{
    [_tableView deleteRowsAtIndexPaths:indexs withRowAnimation:UITableViewRowAnimationTop];
}

//  插入
-(void)arrayInsert:(KHObservableArray*)array insertObject:(id)object index:(NSIndexPath*)index
{
    [_tableView insertRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationBottom];
}

//  取代
-(void)arrayReplace:(KHObservableArray*)array newObject:(id)newObj replacedObject:(id)oldObj index:(NSIndexPath*)index
{
    [_tableView reloadRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationMiddle];
}

//  更新
-(void)arrayUpdate:(KHObservableArray*)array update:(id)object index:(NSIndexPath*)index
{
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
//    printf("row count: %ld of section %ld\n", models.count, models.section );
    return models.count;
}

// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
//    printf("config cell %ld \n", indexPath.row );
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
//    printf("section count: %ld\n", _sectionArray.count );
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
//    printf("cell %ld height %f\n", indexPath.row, height);
    return height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( _delegate && [_delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)] ) {
        [_delegate tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
}

//- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
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


#pragma mark - UIScrollView

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (_refreshHeader) {
        [_refreshHeader egoRefreshScrollViewDidScroll:self.tableView];
    }
    
    if(_refreshFooter) {
        [_refreshFooter egoRefreshScrollViewDidScroll:self.tableView];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (_refreshHeader) {
        [_refreshHeader egoRefreshScrollViewDidEndDragging:self.tableView];
    }
    
    if(_refreshFooter) {
        [_refreshFooter egoRefreshScrollViewDidEndDragging:self.tableView];
    }
}

#pragma mark - EGO Refresh

- (void)egoRefreshTableDidTriggerRefresh:(EGORefreshPos)aRefreshPos
{
    _isRefresh = YES;
    if ( aRefreshPos == EGORefreshHeader ) {
        if ( _delegate && [_delegate respondsToSelector:@selector(refreshTrigger:)]) {
            [_delegate refreshTrigger:_tableView];
        }
    }
    
    if( aRefreshPos == EGORefreshFooter ){
        if ( _delegate && [_delegate respondsToSelector:@selector(loadMoreTrigger:)]) {
            [_delegate loadMoreTrigger:_tableView];
        }
    }
}

- (BOOL)egoRefreshTableDataSourceIsLoading:(UIView*)view
{
    return _isRefresh;
}

//- (NSDate*)egoRefreshTableDataSourceLastUpdated:(UIView*)view
//{
//    
//}


- (void)refreshCompleted
{
    if ( _refreshHeader ) {
        [_refreshHeader egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
    }
    
    if( _refreshFooter ){
        [_refreshFooter egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
        [_refreshFooter locateView]; // 因為載入更多後，content size 會有變動，所以要重新定位
    }
    _isRefresh = NO;
}




@end
