//
//  TableViewBindHelper.m
//  DataBindTest
//
//  Created by GevinChen on 2015/9/26.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import "KHBindHelper.h"
#import <CommonCrypto/CommonDigest.h>
#import <objc/runtime.h>

@implementation KHImageDownloader

#pragma mark - Image (Public)

- (instancetype)init
{
    self = [super init];
    if (self) {
        _imageCache = [[NSMutableDictionary alloc] initWithCapacity: 5 ];
        _imageDownloadTag = [[NSMutableArray alloc] initWithCapacity: 5 ];
        
        NSString *cachePath = [self getCachePath];
        if (![[NSFileManager defaultManager] fileExistsAtPath:cachePath]){
            NSError *error = nil;
            [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:NO attributes:nil error:&error]; //Create folder
            if (error) {
                NSLog(@"cache image folder create fail. code %ld, %@", error.code, error.domain );
            }
        }
        
        plistPath = [cachePath stringByAppendingString:@"imageNames.plist"];
        @synchronized( _imageNamePlist ) {
            if ( ![[NSFileManager defaultManager] fileExistsAtPath: plistPath ] ) {
                _imageNamePlist = [[NSMutableDictionary alloc] initWithCapacity: 5 ];
                [_imageNamePlist writeToFile:plistPath atomically:YES ];
            }else{
                _imageNamePlist = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
            }
        }
    }
    return self;
}

- (void)loadImageURL:(NSString *)urlString cell:(id)cell completed:(void (^)(UIImage *))completed
{
    if ( urlString == nil || urlString.length == 0 ) {
        NSException *exception = [NSException exceptionWithName:@"url invalid" reason:@"image url is nil or length is 0" userInfo:nil];
        @throw exception;
    }
    
    for ( NSString *str in _imageDownloadTag ) {
        if ( [str isEqualToString:urlString] ) {
            //  正在下載中，結束
            return;
        }
    }
    id cur_model = cell ? [cell model] : nil;

    //  先看 cache 有沒有，有的話就直接用
    UIImage *image = [self getImageFromCache:urlString];
    if (image) {
        completed(image);
    }
    else {
        // cache 裡找不到就下載
        dispatch_async( dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            printf("download start %s \n", [urlString UTF8String] );
            //  標記說，這個url正在下載，不要再重覆下載
            [_imageDownloadTag addObject:urlString];
            NSURL *url = [NSURL URLWithString:urlString];
            NSData *data = [[NSData alloc] initWithContentsOfURL:url];
            if ( data ) {
                dispatch_async( dispatch_get_main_queue(), ^{
                    UIImage *image = [[UIImage alloc] initWithData:data];
                    if ( image ) {
                        //  下載成功後，要存到 cache
                        [self saveToCache:image key:urlString];
                        
                        //  檢查 model 是否還有對映，有的話，才做後續處理
                        if ( cell && [cell model] == cur_model ) {
                            completed(image);
                            //  因為圖片產生不是在主執行緒，所以要多加這段，才能圖片正確顯示
                            [cell setNeedsLayout];
                        }
                        //  移除標記，表示沒有在下載，配合 _imageCache，就可以知道是否下載完成
                        [_imageDownloadTag removeObject:urlString];
                    }
                    else{
                        printf("download fail %s \n", [urlString UTF8String]);
                    }
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
    //  清除 mem cache
    [_imageCache removeObjectForKey:key];
    
    //  清除 disk cache
    //-----------------------------------
    [self clearDiskCache:key];
}

- (void)clearDiskCache:(NSString*)key
{
    //  先取得圖片名稱
    NSString *imgFileName = [self getImageFileName:key];
    if ( imgFileName ) {
        //  拼湊出圖片路徑
        NSString *imgPath = [NSString stringWithFormat:@"%@%@", [self getCachePath], imgFileName ];
        //  檢查檔案是否存在，存在就刪除
        if ( [[NSFileManager defaultManager] fileExistsAtPath: imgPath ] ) {
            NSError *err = nil;
            //  刪除圖片
            [[NSFileManager defaultManager] removeItemAtPath:imgPath error:&err];
            if (err) {
                printf("delete cache image error, name:%s \n", [imgFileName UTF8String] );
            }
        }
        [_imageNamePlist removeObjectForKey:key];
        [_imageNamePlist writeToFile:plistPath atomically:YES];
    }
}

- (void)clearAllCache
{
    [_imageCache removeAllObjects];
    [_imageNamePlist removeAllObjects];
    
    NSError *error = nil;
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self getCachePath] error:&error];
    for ( int i=0; i<files.count; i++) {
        NSString *fileName = files[i];
        NSRange range = [fileName rangeOfString:@".plist"];
        if ( range.location != NSNotFound ) {
            continue;
        }
        NSString *filePath = [[self getCachePath] stringByAppendingPathComponent: fileName ];
        [[NSFileManager defaultManager] removeItemAtPath:filePath error: &error];
        if( error ){
            NSLog(@"remove image cache folder error, code %ld, %@", error.code, error.domain );
        }
    }
    [_imageNamePlist removeAllObjects];
    [_imageNamePlist writeToFile:plistPath atomically:YES];
}

- (void)saveToCache:(nonnull UIImage*)image key:(NSString*)key
{
    @synchronized( _imageCache ) {
        //  記錄在 memory cache
        [_imageCache setObject:image forKey:key];
    }
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
    
#ifdef DEBUG
    printf("save cache image %s\n", [path UTF8String] );
#endif
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
        @synchronized(_imageCache) {
            _imageCache[key] = image;
        }
    }
    
    return image;
}


- (NSString*)getCachePath
{
    NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachePath = [cachePaths  objectAtIndex:0];
    cachePath = [cachePath stringByAppendingString:@"/khcacheImages/"];
    return cachePath;
}

- (NSString*)getImageFileName:(NSString*)key
{
    return _imageNamePlist[key];
}


#pragma mark - Private

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



@end


@interface KHCellEventHandleData : NSObject

@property (nonatomic) Class cellClass;
@property (nonatomic) NSString *propertyName;
@property (nonatomic) UIControlEvents event;
@property (nonatomic) NSInvocation *invo;

@end

@implementation KHCellEventHandleData

@end


@implementation KHBindHelper

- (instancetype)init
{
    self = [super init];
    if (self) {
        _sectionArray = [[NSMutableArray alloc] initWithCapacity: 10 ];
        _modelBindMap = [[NSMutableDictionary alloc] initWithCapacity: 5 ];
        _cellCreateDic= [[NSMutableDictionary alloc] initWithCapacity: 5 ];
        _cellLoadDic= [[NSMutableDictionary alloc] initWithCapacity: 5 ];
        _imageDownloader = [KHImageDownloader new];
    }
    return self;
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
        KHCellEventHandleData *handleData = _cellUIEventHandles[i];
        
        if ( [cell isKindOfClass: handleData.cellClass ] ) {
            @try {
                //  依 data 記錄的 property name 取出 ui
                id uicontrol = [cell valueForKey: handleData.propertyName ];
                
                id oldtarget = [uicontrol targetForAction:@selector(controlEventTouchUpInside:event:) withSender:nil];
                if (!oldtarget) {
                    //  設定 ui 要回應 touch up inside 事件
                    [uicontrol addTarget:self action:@selector(controlEventTouchUpInside:event:) forControlEvents:UIControlEventTouchUpInside];
                    //  設定 ui 要回應 value changed 事件
                    [uicontrol addTarget:self action:@selector(controlEventValueChanged:event:) forControlEvents:UIControlEventValueChanged];
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
- (void)controlEventTouchUpInside:(id)ui event:(id)event
{
    [self eventCall:UIControlEventTouchUpInside ui:ui];
}

- (void)controlEventValueChanged:(id)ui event:(id)event
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
    
    //  確認這個 ui 是哪個 property
    for ( int i=0; i<_cellUIEventHandles.count; i++) {
        KHCellEventHandleData *handleData = _cellUIEventHandles[i];
        if ( [cell isKindOfClass: handleData.cellClass ] ) {
            @try {
                id uicontrol = [(NSObject*)cell valueForKey: handleData.propertyName ];
                if ( uicontrol == ui && event == handleData.event ) {
                    id model = cell.model;
                    [handleData.invo setArgument:&ui atIndex:2];
                    [handleData.invo setArgument:&model atIndex:3];
                    [handleData.invo invoke];
                }
            }
            @catch (NSException *exception) {
                continue;
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
    [_imageDownloader loadImageURL:urlString cell:cell completed:completed];
}





#pragma mark - Array Observe

//  新增
-(void)arrayAdd:(KHObservableArray*)array newObject:(id)object index:(NSIndexPath*)index
{
    
}

//  批次新增
-(void)arrayAdd:(KHObservableArray *)array newObjects:(NSArray *)objects indexs:(NSArray *)indexs
{

}

//  刪除
-(void)arrayRemove:(KHObservableArray*)array removeObject:(id)object index:(NSIndexPath*)index
{

}

//  刪除全部
-(void)arrayRemoveAll:(KHObservableArray *)array indexs:(NSArray *)indexs
{

}

//  插入
-(void)arrayInsert:(KHObservableArray*)array insertObject:(id)object index:(NSIndexPath*)index
{

}

//  取代
-(void)arrayReplace:(KHObservableArray*)array newObject:(id)newObj replacedObject:(id)oldObj index:(NSIndexPath*)index
{

}

//  更新
-(void)arrayUpdate:(KHObservableArray*)array update:(id)object index:(NSIndexPath*)index
{

}

-(void)arrayUpdateAll:(KHObservableArray *)array
{

}

@end




#pragma mark - KHTableBindHelper
#pragma mark - 


@implementation KHTableBindHelper

- (instancetype)init
{
    self = [super init];
    if (self) {
        _headerHeight = 10;
        _refreshPos = EGORefreshNone;
        
        // 預設 KHTableCellModel 配 KHTableViewCell
        [self bindModel:[KHTableCellModel class] cell:[KHTableViewCell class]];
        // KHTableViewCell 不使用 nib，使用預設的 UITableViewCell，所以自訂建立方式
        [self defineCell:[KHTableViewCell class] create:^id(KHTableCellModel *model) {
            KHTableViewCell *cell = [[KHTableViewCell alloc] initWithStyle:model.cellStyle reuseIdentifier:@"UITableViewCell" ];
            return cell;
        } load:nil];
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
        _headerHeight = 10;
        _refreshPos = EGORefreshNone;
        self.tableView = tableView;
        self.delegate = delegate;
        // 預設 KHTableCellModel 配 KHTableViewCell
        [self bindModel:[KHTableCellModel class] cell:[KHTableViewCell class]];
        // KHTableViewCell 不使用 nib，使用預設的 UITableViewCell，所以自訂建立方式
        [self defineCell:[KHTableViewCell class] create:^id(KHTableCellModel *model) {
            KHTableViewCell *cell = [[KHTableViewCell alloc] initWithStyle:model.cellStyle reuseIdentifier:@"UITableViewCell" ];
            return cell;
        } load:nil];

    }
    return self;
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
}

- (void)setEnableRefreshHeader:(BOOL)enableRefreshHeader
{
    _enableRefreshHeader = enableRefreshHeader;
    if (_enableRefreshHeader) {
        if (_refreshHeader==nil) {
            _refreshHeader = [[EGORefreshHeaderView alloc] initWithScrolView:_tableView];
            _refreshHeader.delegate = self;
            [_refreshHeader locateView];
        }
        else{
            _refreshHeader.scrollView = _tableView;
        }
    }
    else{
        if(_refreshHeader)_refreshHeader.scrollView = nil;
    }
}

- (void)setEnableRefreshFooter:(BOOL)enableRefreshFooter
{
    _enableRefreshFooter = enableRefreshFooter;
    if (_enableRefreshFooter) {
        if ( _refreshFooter==nil ) {
            _refreshFooter = [[EGORefreshFooterView alloc] initWithScrollView:_tableView];
            _refreshFooter.delegate = self;
            [_refreshFooter locateView];
        }
        else{
            _refreshFooter.scrollView = _tableView;
        }
    }
    else{
        if(_refreshFooter)_refreshFooter.scrollView = nil;
    }
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
    [_tableView reloadRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationFade];
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
                NSLog(@"new cell size %@", NSStringFromCGSize( cell.frame.size) );
            }
        }
    }
    
    //  設定 touch event handle
    [self listenUIControlOfCell:cell];
    
    //  assign reference
    cell.helper = self;
    cell.model = model;
    
    //  記錄 cell 的高
    model.cellHeight = cell.frame.size.height;
    
    //  把 model 載入 cell
    void(^loadBlock)(id cell, id model) = _cellLoadDic[cellName];
    if ( loadBlock ) {
        loadBlock( cell, model );
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
    _refreshPos = aRefreshPos;
    _isRefresh = YES;
    if ( aRefreshPos == EGORefreshHeader ) {
        if ( _delegate && [_delegate respondsToSelector:@selector(tableViewRefresh:)]) {
            [_delegate tableViewRefresh:_tableView];
        }
    }
    
    if( aRefreshPos == EGORefreshFooter ){
        if ( _delegate && [_delegate respondsToSelector:@selector(tableViewLoadMore:)]) {
            [_delegate tableViewLoadMore:_tableView];
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
        [_refreshHeader egoRefreshScrollViewDidFinishedLoading:self.tableView];
    }
    
    if( _refreshFooter ){
        [_refreshFooter egoRefreshScrollViewDidFinishedLoading:self.tableView];
        [_refreshFooter locateView]; // 因為載入更多後，content size 會有變動，所以要重新定位
    }
    _isRefresh = NO;
    _refreshPos = EGORefreshNone;
}


@end







#pragma mark - KHCollectionBindHelper
#pragma mark -


@implementation KHCollectionBindHelper



#pragma mark - Public

- (UICollectionViewFlowLayout*)layout
{
    return _collectionView.collectionViewLayout;
}

#pragma mark - Property Setter

- (void)setCollectionView:(UICollectionView *)collectionView
{
    _collectionView = collectionView;
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    
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

- (void)setEnableRefreshHeader:(BOOL)enableRefreshHeader
{
    _enableRefreshHeader = enableRefreshHeader;
    if (_enableRefreshHeader) {
        if (_refreshHeader==nil) {
            _refreshHeader = [[EGORefreshHeaderView alloc] initWithScrolView:_collectionView];
            _refreshHeader.delegate = self;
            [_refreshHeader locateView];
        }
        else{
            _refreshHeader.scrollView = _collectionView;
        }
    }
    else{
        if(_refreshHeader)_refreshHeader.scrollView = nil;
    }
}

- (void)setEnableRefreshFooter:(BOOL)enableRefreshFooter
{
    _enableRefreshFooter = enableRefreshFooter;
    if (_enableRefreshFooter) {
        if ( _refreshFooter==nil ) {
            _refreshFooter = [[EGORefreshFooterView alloc] initWithScrollView:_collectionView];
            _refreshFooter.delegate = self;
            [_refreshFooter locateView];
        }
        else{
            _refreshFooter.scrollView = _collectionView;
        }
    }
    else{
        if(_refreshFooter)_refreshFooter.scrollView = nil;
    }
}

#pragma mark - Array Observe

//  新增
-(void)arrayAdd:(KHObservableArray*)array newObject:(id)object index:(NSIndexPath*)index
{
//    [_tableView insertRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationBottom];
    [_collectionView insertItemsAtIndexPaths:@[index]];
}

//  批次新增
-(void)arrayAdd:(KHObservableArray *)array newObjects:(NSArray *)objects indexs:(NSArray *)indexs
{
    //    [_tableView insertRowsAtIndexPaths:indexs withRowAnimation:UITableViewRowAnimationBottom];
    // Gevin note: 若在初始的時候，使用 insertRowsAtIndexPaths:indexs ，取得的 content 會不對，而且找不到
    //  時間點來取，好像是要等它動畫跑完才會正確
    //  改用 reloadData
//    [_tableView reloadData];
    [_collectionView reloadData];
}

//  刪除
-(void)arrayRemove:(KHObservableArray*)array removeObject:(id)object index:(NSIndexPath*)index
{
//    [_tableView deleteRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationMiddle];
    [_collectionView deleteItemsAtIndexPaths:@[index]];
}

//  刪除全部
-(void)arrayRemoveAll:(KHObservableArray *)array indexs:(NSArray *)indexs
{
//    [_tableView deleteRowsAtIndexPaths:indexs withRowAnimation:UITableViewRowAnimationTop];
    [_collectionView deleteItemsAtIndexPaths:indexs];
}

//  插入
-(void)arrayInsert:(KHObservableArray*)array insertObject:(id)object index:(NSIndexPath*)index
{
//    [_tableView insertRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationBottom];
    [_collectionView insertItemsAtIndexPaths:@[index]];
}

//  取代
-(void)arrayReplace:(KHObservableArray*)array newObject:(id)newObj replacedObject:(id)oldObj index:(NSIndexPath*)index
{
//    [_tableView reloadRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationMiddle];
    [_collectionView reloadItemsAtIndexPaths:@[index]];
}

//  更新
-(void)arrayUpdate:(KHObservableArray*)array update:(id)object index:(NSIndexPath*)index
{
//    [_tableView reloadRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationFade];
    [_collectionView reloadItemsAtIndexPaths:@[index]];
}

-(void)arrayUpdateAll:(KHObservableArray *)array
{
//    [_tableView reloadSections:[NSIndexSet indexSetWithIndex:array.section] withRowAnimation:UITableViewRowAnimationAutomatic];
    [_collectionView reloadSections:[NSIndexSet indexSetWithIndex:array.section]];
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
            
            NSLog(@"cell size %@, layout size %@", NSStringFromCGSize(cell.frame.size), NSStringFromCGSize(layout.itemSize) );
        }
    }
    
    //  設定 touch event handle
    [self listenUIControlOfCell:cell];
    
    //  assign reference
    cell.helper = self;
    cell.model = model;
    
    //  把 model 載入 cell
    void(^loadBlock)(id cell, id model) = _cellLoadDic[modelName];
    if ( loadBlock ) {
        loadBlock( cell, model );
    }
    else {
        [cell onLoad:model];
    }
    
    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return _sectionArray.count;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ( _delegate && [_delegate respondsToSelector:@selector(collectionView:didSelectItemAtIndexPath:)] ) {
        [_delegate collectionView:collectionView didSelectItemAtIndexPath:indexPath];
    }
}


#pragma mark - UIScrollView

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (_refreshHeader) {
        [_refreshHeader egoRefreshScrollViewDidScroll:self.collectionView];
    }
    
    if(_refreshFooter) {
        [_refreshFooter egoRefreshScrollViewDidScroll:self.collectionView];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (_refreshHeader) {
        [_refreshHeader egoRefreshScrollViewDidEndDragging:self.collectionView];
    }
    
    if(_refreshFooter) {
        [_refreshFooter egoRefreshScrollViewDidEndDragging:self.collectionView];
    }
}

#pragma mark - EGO Refresh

- (void)egoRefreshTableDidTriggerRefresh:(EGORefreshPos)aRefreshPos
{
    _refreshPos = aRefreshPos;
    _isRefresh = YES;
    if ( aRefreshPos == EGORefreshHeader ) {
        if ( _delegate && [_delegate respondsToSelector:@selector(collectionViewRefresh:)]) {
            [_delegate collectionViewRefresh:self.collectionView];
        }
    }
    
    if( aRefreshPos == EGORefreshFooter ){
        if ( _delegate && [_delegate respondsToSelector:@selector(collectionViewLoadMore:)]) {
            [_delegate collectionViewLoadMore:self.collectionView];
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
        [_refreshHeader egoRefreshScrollViewDidFinishedLoading:self.collectionView];
    }
    
    if( _refreshFooter ){
        [_refreshFooter egoRefreshScrollViewDidFinishedLoading:self.collectionView];
        [_refreshFooter locateView]; // 因為載入更多後，content size 會有變動，所以要重新定位
    }
    _isRefresh = NO;
    _refreshPos = EGORefreshNone;
}


@end

