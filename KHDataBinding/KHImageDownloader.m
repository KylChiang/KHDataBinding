//
//  Created by GevinChen on 2015/12/13.
//  Copyright © 2015年 GevinChen. All rights reserved.
//

#import "KHImageDownloader.h"
#import <CommonCrypto/CommonDigest.h>

static KHImageDownloader *sharedInstance;

@implementation KHImageDownloader


+(KHImageDownloader*)instance
{
    
    static dispatch_once_t pred;
    
    // partial fix for the "new" concurrency issue
    if (sharedInstance) return sharedInstance;
    // partial because it means that +sharedInstance *may *return an un-initialized instance
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
        _listeners = [[NSMutableDictionary alloc] initWithCapacity: 5 ];
        
        NSString *cachePath = [self getCachePath];
        if (![[NSFileManager defaultManager] fileExistsAtPath:cachePath]){
            NSError *error = nil;
            [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:NO attributes:nil error:&error]; //Create folder
            if (error) {
                NSLog(@"cache image folder create fail. code %ld, %@", (long)error.code, error.domain );
            }
        }
        
//        plistPath = [cachePath stringByAppendingString:@"imageNames.plist"];
//        @synchronized( _imageNamePlist ) {
//            if ( ![[NSFileManager defaultManager] fileExistsAtPath: plistPath ] ) {
//                _imageNamePlist = [[NSMutableDictionary alloc] initWithCapacity: 5 ];
//                [_imageNamePlist writeToFile:plistPath atomically:YES ];
//            }else{
//                _imageNamePlist = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
//            }
//        }
        
//        [self updateImageDiskCache];
    }
    return self;
}

- (void)listenDownload:(NSDictionary*)info
{
    NSString *url = info[@"url"];
    NSMutableArray *array = _listeners[url];
    if ( array == nil ) {
        array = [[NSMutableArray alloc] initWithCapacity: 5 ];
        _listeners[url] = array;
    }
    [array addObject:info];
}

//  圖片下載完成，通知所有需要用到這張圖的 model
- (void)notifyDownloadCompleted:(NSString*)urlString image:(UIImage*)image error:(NSError*)error;
{
    NSMutableArray *array = _listeners[urlString];
    [_listeners removeObjectForKey:urlString];
    for ( NSDictionary *info in array ) {
        void(^completed)(UIImage *,NSError*) = info[@"handler"];
        id linker = info[@"linker"];
        KHPairInfo *cellLinker = nil;
        if ( linker != [NSNull null] ) {
            cellLinker = linker;
        }

        
        if ( !error ){
            //  若有 cellProxy，就要比對目前的 cell 跟 model 還有沒有對映，有的話才讓 cell 載入圖片
            //  因為 cell 是 reuse，所以有可能呼叫下載的當下 model 與 cell，跟下載完成時的 model 與 cell 是不一樣的
            //  不檢查的話，會導致 cell 可能現在是別的 model 在使用，結果上面的圖片突然變了
            if ( cellLinker ) {
                
                //  如果這個 cell 已經被別的 model 拿去用的話，就會變 nil
                if( cellLinker.cell != nil ){
                    completed(image,error);
                    //  因為圖片產生不是在主執行緒，所以要多加這段，才能圖片正確顯示
                    [cellLinker.cell setNeedsLayout];
                }
            }
            else{
                completed(image,error);
            }
        }else{
            completed(nil,error);
        }
    }
}

- (BOOL)isDownloading:(NSString*)url
{
    NSMutableArray *array = _listeners[url];
    return array ? YES : NO;
}


- (void)loadImageURL:(NSString *)urlString pairInfo:(KHPairInfo*)pairInfo completed:(void (^)(UIImage *,NSError*))completed
{
    //  檢查網址是有有效
    if ( urlString == nil || urlString.length == 0 ) {
        NSException *exception = [NSException exceptionWithName:@"url invalid" reason:@"image url is nil or length is 0" userInfo:nil];
        @throw exception;
    }
    
    //  檢查看目前這個 url 是否正在下載中
    // @todo: 這邊要加一個功能，可以把cell 記下來，然後最後圖片下載完後，再通知每一個cell顯示圖片
    BOOL isDownloading = [self isDownloading:urlString ];
    if (isDownloading) {
        NSDictionary *infoDic = @{@"url":urlString,
                                  @"pairInfo":pairInfo ? pairInfo : [NSNull null],
                                  @"handler":completed};
        [self listenDownload:infoDic];
        return;
    }
    //  重點在於當取得圖片時，要檢查 cell 是否有變更，有變更的話，就不能呼叫 call back
    
    //  先看 cache 有沒有，有的話就直接用
    UIImage *image = [self getImageFromCache:urlString];
    if (image) {
        completed(image, nil);
        if(pairInfo.cell) [(UIView*)pairInfo.cell setNeedsLayout];
    }
    else {
        // cache 裡找不到就下載
        if( self.debugLog ) NSLog(@"<KHImageDownloader> download %@", urlString );
        
        //  標記說，這個url正在下載，不要再重覆下載
        NSDictionary *infoDic = @{@"url":urlString,
                                  @"pairInfo":pairInfo ? pairInfo : [NSNull null],
                                  @"handler":completed};
        [self listenDownload:infoDic];
        NSString *urlencodeString = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,(CFStringRef)urlString,NULL,
                                                                                              CFSTR("!$'()*+,-;?@_~%#[]"),
                                                                                              kCFStringEncodingUTF8));
        //  建立連線，下載
        NSURL *url = [NSURL URLWithString:urlencodeString];
        NSOperationQueue *queue = [NSOperationQueue mainQueue];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
            
            UIImage *image = [[UIImage alloc] initWithData:data];
            
            if ( !image && error ) {
                NSLog(@"<KHImageDownloader> download fail %@", urlString);
            }
            else {
                if( self.debugLog ) NSLog(@"<KHImageDownloader> download success %@", urlString );
            }
            
            //  下載成功後，要存到 cache
            if ( image ) [self saveToCache:image key:urlString];
            //  通知所有傾聽這個 image download 的 model
            [self notifyDownloadCompleted:urlString image:image error:error];
        }];
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
    for ( NSInteger i=0; i<files.count; i++) {
        NSString *fileName = files[i];
        NSRange range = [fileName rangeOfString:@".plist"];
        if ( range.location != NSNotFound ) {
            continue;
        }
        NSString *filePath = [[self getCachePath] stringByAppendingPathComponent: fileName ];
        [[NSFileManager defaultManager] removeItemAtPath:filePath error: &error];
        if( error ){
            NSLog(@"remove image cache folder error, code %ld, %@", (long)error.code, error.domain );
        }
    }
    [_imageNamePlist removeAllObjects];
    [_imageNamePlist writeToFile:plistPath atomically:YES];
}

- (void)saveToCache:(nonnull UIImage*)image key:(NSString*)key
{
    //  記錄在 memory cache
    [_imageCache setObject:image forKey:key];
    
    //  Gevin Note: NSURLConnection 自己已經有 cache 了，不用自己做
//    [self saveImageToDisk:image key:key];
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
//        NSLog(@"image cache %@ , %@", key, imageName );
//        NSLog(@"<KHImageDownload> check 2. image size %@", NSStringFromCGSize( image.size ) );

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
    NSTimeInterval twoDaysInterval = 2  *24  *60  *60;
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval time_limit = now - twoDaysInterval;
    NSArray *allkeys = [_imageNamePlist allKeys];
    for ( NSInteger i=0; i<allkeys.count; i++ ) {
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
    CC_MD5(ptr, (CC_LONG)strlen(ptr), md5Buffer);
    
    // Convert MD5 value in the buffer to NSString of hex values
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH  *2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++){
        [output appendFormat:@"%02x",md5Buffer[i]];
    }
    return output;
}



@end



