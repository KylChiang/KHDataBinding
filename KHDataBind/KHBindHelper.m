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
#import <CCBottomRefreshControl/UIScrollView+BottomRefreshControl.h>

static KHImageDownloader *sharedInstance;

@implementation KHImageDownloader


+(KHImageDownloader*)instance
{

    static dispatch_once_t pred;
    
    // partial fix for the "new" concurrency issue
    if (sharedInstance) return sharedInstance;
    // partial because it means that +sharedInstance *may* return an un-initialized instance
    // this is from http://stackoverflow.com/questions/20895214/why-should-we-separate-alloc-and-init-calls-to-avoid-deadlocks-in-objective-c/20895427#20895427
    
    dispatch_once(&pred, ^{
        sharedInstance = [KHImageDownloader alloc];
        sharedInstance = [sharedInstance init];
    });
    
    return sharedInstance;
}

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
        
//        [self updateImageDiskCache];
    }
    return self;
}

- (void)loadImageURL:(NSString *)urlString cell:(id)cell completed:(void (^)(UIImage *))completed
{
    if ( urlString == nil || urlString.length == 0 ) {
        NSException *exception = [NSException exceptionWithName:@"url invalid" reason:@"image url is nil or length is 0" userInfo:nil];
        @throw exception;
    }
    
    // @todo: 這邊要加一個功能，可以把cell 記下來，然後最後圖片下載完後，再通知每一個cell顯示圖片
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
        [cell setNeedsLayout];
    }
    else {
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
                    if ( image ) {
                        //  下載成功後，要存到 cache
                        [self saveToCache:image key:urlString];
                    }
                    
                    if ( cell ) {
                        //  檢查 model 是否還有match，有的話，才做後續處理
                        if ( [cell model] == cur_model ) {
                            completed(image);
                            //  因為圖片產生不是在主執行緒，所以要多加這段，才能圖片正確顯示
                            [cell setNeedsLayout];
                        }
                    }
                    else{
                        completed(image);
                    }
                    //  移除標記，表示沒有在下載，配合 _imageCache，就可以知道是否下載完成
                    [_imageDownloadTag removeObject:urlString];
                    
                });
            }
            else{
                [_imageDownloadTag removeObject:urlString];
                printf("download fail %s \n", [urlString UTF8String]);
            }
        });
    }
}

- (void)removeCache:(NSString*)key
{
    //  清除 mem cache
    [_imageCache removeObjectForKey:key];
    
    //  清除 disk cache
    [self removeDiskCache:key];
}

- (void)removeDiskCache:(NSString*)key
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
    [self saveImageToDisk:image key:key];
}

- (void)saveImageToDisk:(nonnull UIImage*)image key:(NSString*)key
{
    //  依 key 從 plist 中取出 image file name
    NSDictionary *imageInfoDic = [_imageNamePlist objectForKey:key];
    
    NSString *imageName = nil;
    //  若沒有 file name，就隨機產生一個，並寫入 plist
    if ( imageInfoDic == nil ) {
        //  新建一個檔名，存在cache
        NSString *keymd5 = [self MD5: key ];
        imageName = [[keymd5 substringWithRange: (NSRange){0,16} ] stringByAppendingString:@".png"];
        
        //  存進 list
        _imageNamePlist[key] = @{@"image":imageName,
                                 @"time":@([[NSDate date] timeIntervalSince1970])};
        
        //  儲存 name list
        [_imageNamePlist writeToFile:plistPath atomically:YES];
    }
    else{
        //  取出 image name
        imageName = imageInfoDic[@"image"];
        //  更新時間
        _imageNamePlist[key] = @{@"image":imageName,
                                 @"time":@([[NSDate date] timeIntervalSince1970])};
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
    
//#ifdef DEBUG
//    printf("save cache image %s\n", [path UTF8String] );
//#endif
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
        //  讀取圖片
        image = [self getImageFromDisk:key];
        
        if ( image ) {
            //  存入 memory 快取
            _imageCache[key] = image;
        }
    }
    
    return image;
}

- (UIImage*)getImageFromDisk:(NSString*)key
{
    //  從 name list 取出對映的名字
    NSDictionary *imageInfoDic = _imageNamePlist[key];
    
    //  若沒有 image info，就表示 memory cache 跟 disk 都沒有這張圖
    if ( imageInfoDic == nil ) {
        return nil;
    }
    
    NSString *imageName = imageInfoDic[@"image"];
    NSString *imagePath = [self getCachePath];
    imagePath = [imagePath stringByAppendingString:imageName ];
    //  讀取圖片
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:imagePath];
    
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
    NSDictionary *imageInfoDic = _imageNamePlist[key];
    if ( imageInfoDic ) {
        return imageInfoDic[@"image"];
    }
    return nil;
}

//  把舊的刪掉
- (void)updateImageDiskCache
{
    // 檢查每張圖的時間，超過 48 小時的就刪掉
    NSTimeInterval twoDaysInterval = 2 * 24 * 60 * 60;
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval time_limit = now - twoDaysInterval;
    NSArray *allkeys = [_imageNamePlist allKeys];
    for ( int i=0; i<allkeys.count; i++ ) {
        NSString *key = allkeys[i];
        NSDictionary *imageInfoDic = _imageNamePlist[key];
        NSNumber *timeStamp = imageInfoDic[@"time"];
        if ( time_limit > [timeStamp doubleValue] ) {
            [self removeDiskCache:key];
        }
    }
    
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
    [[KHImageDownloader instance] loadImageURL:urlString cell:cell completed:completed];
}




#pragma mark - Array Observe

//  新增
-(void)arrayAdd:(NSMutableArray*)array newObject:(id)object index:(NSIndexPath*)index
{
    
}

//  批次新增
-(void)arrayAdd:(NSMutableArray *)array newObjects:(NSArray *)objects indexs:(NSArray *)indexs
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

//  插入
-(void)arrayInsert:(NSMutableArray*)array insertObject:(id)object index:(NSIndexPath*)index
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




#pragma mark - KHTableBindHelper
#pragma mark - 


@implementation KHTableBindHelper

- (instancetype)init
{
    self = [super init];
    if (self) {
        _headerHeight = 10;
//        _refreshPos = EGORefreshNone;
        
        //  init UIRefreshControl
        _refreshHeadControl = [[UIRefreshControl alloc] init];
        _refreshHeadControl.backgroundColor = [UIColor whiteColor];
        _refreshHeadControl.tintColor = [UIColor lightGrayColor]; // spinner color
        [_refreshHeadControl addTarget:self
                                action:@selector(refreshHead:)
                      forControlEvents:UIControlEventValueChanged];
        NSDictionary *attributeDic = @{NSForegroundColorAttributeName:[UIColor lightGrayColor]};
        _refreshHeadControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull down to reload!" attributes:attributeDic];

        
        _refreshFootControl = [[UIRefreshControl alloc] init];
        _refreshFootControl.backgroundColor = [UIColor whiteColor];
        _refreshFootControl.tintColor = [UIColor lightGrayColor]; // spinner color
        [_refreshFootControl addTarget:self
                                action:@selector(refreshFoot:)
                      forControlEvents:UIControlEventValueChanged];
        _refreshFootControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull up to load more!" attributes:attributeDic];

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
        _footerHeight = 0;
        
        //  init UIRefreshControl
        _refreshHeadControl = [[UIRefreshControl alloc] init];
        _refreshHeadControl.backgroundColor = [UIColor whiteColor];
        _refreshHeadControl.tintColor = [UIColor lightGrayColor]; // spinner color
        [_refreshHeadControl addTarget:self
                            action:@selector(refreshHead:)
                  forControlEvents:UIControlEventValueChanged];
        NSDictionary *attributeDic = @{NSForegroundColorAttributeName:[UIColor lightGrayColor]};
        _refreshHeadControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull down to reload!" attributes:attributeDic];

        _refreshFootControl = [[UIRefreshControl alloc] init];
        _refreshFootControl.backgroundColor = [UIColor whiteColor];
        _refreshFootControl.tintColor = [UIColor lightGrayColor]; // spinner color
        [_refreshFootControl addTarget:self
                                action:@selector(refreshFoot:)
                      forControlEvents:UIControlEventValueChanged];
        _refreshFootControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull up to load more!" attributes:attributeDic];

        
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

- (void)setRefreshHeadEnabled:(BOOL)refreshHeadEnabled
{
    _refreshHeadEnabled = refreshHeadEnabled;
    if (_refreshHeadEnabled) {
        if ( _refreshHeadControl ) {
            [_tableView addSubview: _refreshHeadControl ];
        }
    }
    else{
        if ( _refreshHeadControl ) {
            [_refreshHeadControl removeFromSuperview];
        }
    }
}

- (void)setRefreshFootEnabled:(BOOL)refreshFootEnabled
{
    _refreshFootEnabled = refreshFootEnabled;
    if ( _refreshFootEnabled ) {
        if (_refreshFootControl ) {
            _tableView.bottomRefreshControl = _refreshFootControl;
        }
    }
    else{
        _tableView.bottomRefreshControl = nil;
    }
}

#pragma mark - Array Observe

//  新增
-(void)arrayAdd:(NSMutableArray*)array newObject:(id)object index:(NSIndexPath*)index
{
    if (_hasInit) [_tableView insertRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationBottom];
}

//  批次新增
-(void)arrayAdd:(NSMutableArray *)array newObjects:(NSArray *)objects indexs:(NSArray *)indexs
{
    //    [_tableView insertRowsAtIndexPaths:indexs withRowAnimation:UITableViewRowAnimationBottom];
    // Gevin note: 若在初始的時候，使用 insertRowsAtIndexPaths:indexs ，取得的 content 會不對，而且找不到
    //  時間點來取，好像是要等它動畫跑完才會正確
    //  改用 reloadData
    [_tableView reloadData];
}

//  刪除
-(void)arrayRemove:(NSMutableArray*)array removeObject:(id)object index:(NSIndexPath*)index
{
    if (_hasInit) [_tableView deleteRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationMiddle];
}

//  刪除全部
-(void)arrayRemoveAll:(NSMutableArray *)array indexs:(NSArray *)indexs
{
    if (_hasInit) [_tableView deleteRowsAtIndexPaths:indexs withRowAnimation:UITableViewRowAnimationTop];
}

//  插入
-(void)arrayInsert:(NSMutableArray*)array insertObject:(id)object index:(NSIndexPath*)index
{
    if (_hasInit) [_tableView insertRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationBottom];
}

//  取代
-(void)arrayReplace:(NSMutableArray*)array newObject:(id)newObj replacedObject:(id)oldObj index:(NSIndexPath*)index
{
    if (_hasInit) [_tableView reloadRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationMiddle];
}

//  更新
-(void)arrayUpdate:(NSMutableArray*)array update:(id)object index:(NSIndexPath*)index
{
    if (_hasInit) [_tableView reloadRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationFade];
}

-(void)arrayUpdateAll:(NSMutableArray *)array
{
    if (_hasInit) [_tableView reloadSections:[NSIndexSet indexSetWithIndex:array.section] withRowAnimation:UITableViewRowAnimationAutomatic];
}


#pragma mark - Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSMutableArray *models = _sectionArray[section];
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

#pragma mark - UIRefreshControl

- (void)refreshHead:(id)sender
{
    if (_refreshHeadControl==nil ) {
        return;
    }
    if ( _delegate && [_delegate respondsToSelector:@selector(tableViewRefreshHead:)]) {
        [_delegate tableViewRefreshHead:_tableView];
    }
}

- (void)refreshFoot:(id)sender
{
    if (_refreshFootControl==nil ) {
        return;
    }
    if ( _delegate && [_delegate respondsToSelector:@selector(tableViewRefreshFoot:)]) {
        [_delegate tableViewRefreshFoot:_tableView];
    }
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


@end







#pragma mark - KHCollectionBindHelper
#pragma mark -


@implementation KHCollectionBindHelper

- (instancetype)init
{
    self = [super init];
    
    _hasInit = NO;
    
    //  init UIRefreshControl
    _refreshHeadControl = [[UIRefreshControl alloc] init];
    _refreshHeadControl.backgroundColor = [UIColor whiteColor];
    _refreshHeadControl.tintColor = [UIColor lightGrayColor]; // spinner color
    [_refreshHeadControl addTarget:self
                            action:@selector(refreshHead:)
                  forControlEvents:UIControlEventValueChanged];
    NSDictionary *attributeDic = @{NSForegroundColorAttributeName:[UIColor lightGrayColor]};
    _refreshHeadControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull down to reload!" attributes:attributeDic];
    
    _refreshFootControl = [[UIRefreshControl alloc] init];
    _refreshFootControl.backgroundColor = [UIColor whiteColor];
    _refreshFootControl.tintColor = [UIColor lightGrayColor]; // spinner color
    [_refreshFootControl addTarget:self
                            action:@selector(refreshFoot:)
                  forControlEvents:UIControlEventValueChanged];
    _refreshFootControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull up to load more!" attributes:attributeDic];

    
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

- (void)setRefreshHeadEnabled:(BOOL)refreshHeadEnabled
{
    _refreshHeadEnabled = refreshHeadEnabled;
    if (_refreshHeadEnabled) {
        if ( _refreshHeadControl ) {
            [_collectionView addSubview: _refreshHeadControl ];
        }
    }
    else{
        if ( _refreshHeadControl ) {
            [_refreshHeadControl removeFromSuperview];
        }
    }
}

- (void)setRefreshFootEnabled:(BOOL)refreshFootEnabled
{
    _refreshFootEnabled = refreshFootEnabled;
    if ( _refreshFootEnabled ) {
        if (_refreshFootControl ) {
            _collectionView.bottomRefreshControl = _refreshFootControl;
        }
    }
    else{
        _collectionView.bottomRefreshControl = nil;
    }
}

#pragma mark - Array Observe

//  新增
-(void)arrayAdd:(NSMutableArray*)array newObject:(id)object index:(NSIndexPath*)index
{
    if ( _hasInit ) {
        [_collectionView insertItemsAtIndexPaths:@[index]];
    }
}

//  批次新增
-(void)arrayAdd:(NSMutableArray *)array newObjects:(NSArray *)objects indexs:(NSArray *)indexs
{
    [_collectionView reloadData];
}

//  刪除
-(void)arrayRemove:(NSMutableArray*)array removeObject:(id)object index:(NSIndexPath*)index
{
    if ( _hasInit ) [_collectionView deleteItemsAtIndexPaths:@[index]];
}

//  刪除全部
-(void)arrayRemoveAll:(NSMutableArray *)array indexs:(NSArray *)indexs
{
    if ( _hasInit ) [_collectionView deleteItemsAtIndexPaths:indexs];
}

//  插入
-(void)arrayInsert:(NSMutableArray*)array insertObject:(id)object index:(NSIndexPath*)index
{
    if ( _hasInit ) [_collectionView insertItemsAtIndexPaths:@[index]];
}

//  取代
-(void)arrayReplace:(NSMutableArray*)array newObject:(id)newObj replacedObject:(id)oldObj index:(NSIndexPath*)index
{
    if ( _hasInit ) [_collectionView reloadItemsAtIndexPaths:@[index]];
}

//  更新
-(void)arrayUpdate:(NSMutableArray*)array update:(id)object index:(NSIndexPath*)index
{
    if ( _hasInit ) [_collectionView reloadItemsAtIndexPaths:@[index]];
}

-(void)arrayUpdateAll:(NSMutableArray *)array
{
    if ( _hasInit ) [_collectionView reloadSections:[NSIndexSet indexSetWithIndex:array.section]];
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
    if (_refreshHeadControl==nil ) {
        return;
    }
    if ( _delegate && [_delegate respondsToSelector:@selector(collectionViewRefreshHead:)]) {
        [_delegate collectionViewRefreshHead:_collectionView];
    }
}

- (void)refreshFoot:(id)sender
{
    if (_refreshFootControl==nil ) {
        return;
    }
    if ( _delegate && [_delegate respondsToSelector:@selector(collectionViewRefreshFoot:)]) {
        [_delegate collectionViewRefreshFoot:_collectionView];
    }
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


@end

