//
//  KHImageDownloader.m
//  KHDataBindDemo
//
//  Created by GevinChen on 2015/12/13.
//  Copyright © 2015年 omg. All rights reserved.
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
