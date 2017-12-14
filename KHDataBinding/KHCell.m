//
//  KHPairInfo.m
//
//  Created by GevinChen on 2015/9/26.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import "KHCore.h"
#import "KHCell.h"
#import "KHDataBinding.h"
#import "KHTableView.h"
#import "KHCollectionView.h"
#import <objc/runtime.h>

NSString *const kCellSize = @"kCellSize";
NSString *const kCellHeight = @"kCellHeight";

static int instanceIDGen = 0;
@implementation KHPairInfo
{
    int instanceID;
    
    BOOL observerFlag;
}


- (instancetype)init
{
    self = [super init];
    if (self) {
        instanceID = instanceIDGen++;
        self.cellSize = (CGSize){0,0};
        self.enabledObserveModel = YES;
        observerFlag = NO;
    }
    return self;
}

- (void)dealloc
{
    if (_model &&
        ![_model isKindOfClass:[UIView class]] &&
        ![_model isKindOfClass:[NSDictionary class]] && 
        ![_model isKindOfClass:[NSArray class]] && 
        ![_model isKindOfClass:[NSString class]] && 
        ![_model isKindOfClass:[NSNumber class]]) {
        [self deObserveModel];
    }
}



- (void)setModel:(id)model
{
    if (_model && 
        ![_model isKindOfClass:[UIView class]] &&
        ![_model isKindOfClass:[NSDictionary class]] && 
        ![_model isKindOfClass:[NSArray class]] && 
        ![_model isKindOfClass:[NSString class]] && 
        ![_model isKindOfClass:[NSNumber class]] ) {
        [self deObserveModel];
    }
    _model = model;
    if (_model &&
        ![_model isKindOfClass:[UIView class]] &&
        ![_model isKindOfClass:[NSDictionary class]] && 
        ![_model isKindOfClass:[NSArray class]] && 
        ![_model isKindOfClass:[NSString class]] && 
        ![_model isKindOfClass:[NSNumber class]] ) {
        [self observeModel];
    }
}

- (id _Nullable)cell
{
    if ( self.tableView ) {
        UITableViewCell *cell = [self.tableView cellForModel:self.model];
        return cell;
    }
    else if( self.collectionView ){
        UICollectionViewCell *cell = [self.collectionView cellForModel:self.model];
        return cell;
    }
    return nil;
}


//  取得目前的 index
- (NSIndexPath* _Nullable)indexPath
{
    if (self.tableView) {
        NSIndexPath *index = [self.tableView indexPathForModel:self.model];
        return index;
    }
    else if(self.collectionView){
        NSIndexPath *index = [self.collectionView indexPathForModel:self.model];
        return index;
    }
    return nil;
}

#pragma mark - public

/**
 記錄額外的資料，有一些可能不會在 model 上的資料
 例如 cell 的 ui 顯示狀態
 
 @param key 資料的 key
 @param valueObj 資料本體
 */
- (void)setUserInfo:(id)key value:(id)valueObj
{
    if ( _userInfo == nil ) {
        _userInfo = [NSMutableDictionary dictionaryWithCapacity:10];
    }
    _userInfo[key] = valueObj;
}


/**
 取得先前記錄的資料
 
 @param key 資料的key
 @return 資料本身
 */
- (id)getUserInfo:(id)key
{
    if ( _userInfo ) {
        return _userInfo[key];
    }
    return nil;
}

#pragma mark - KVO

- (void)observeModel
{
    if(observerFlag) return;
    observerFlag = YES;
    // 解析 property
    unsigned int numOfProperties;
    objc_property_t *properties = class_copyPropertyList( [self.model class], &numOfProperties );
    for ( unsigned int pi = 0; pi < numOfProperties; pi++ ) {
        //  取出 property name
        objc_property_t property = properties[pi];
        NSString *propertyName = [[NSString alloc] initWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        [self.model addObserver:self forKeyPath:propertyName options:NSKeyValueObservingOptionNew context:NULL]; //NSKeyValueObservingOptionOld
    }
}

- (void)deObserveModel
{
    if (!observerFlag) return;
    observerFlag = NO;
    // 解析 property
    unsigned int numOfProperties;
    objc_property_t *properties = class_copyPropertyList( [self.model class], &numOfProperties );
    for ( unsigned int pi = 0; pi < numOfProperties; pi++ ) {
        //  取出 property name
        objc_property_t property = properties[pi];
        NSString *propertyName = [[NSString alloc] initWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        [self.model removeObserver:self forKeyPath:propertyName];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
//    NSLog(@"%d : kvo >> [%@] %@ value: %@", linkerID, NSStringFromClass([object class]),keyPath, change[@"new"] );
    //  note:
    //  這邊的用意是，不希望連續呼叫太多次的 onload，所以用gcd，讓更新在下一個 run loop 執行
    //  如果連續修改多個 property 就不會連續呼叫多次 onload 而影響效能
    if( self.enabledObserveModel && !needUpdate ){
        needUpdate = YES;
        __weak typeof (self) w_self = self;
        dispatch_async( dispatch_get_main_queue(), ^{
            id cell = w_self.cell;
            if(cell){
                self.enabledObserveModel = NO;
                [cell onLoad: self.model];
                self.enabledObserveModel = YES;
            }
            needUpdate = NO;
        });
    }
}

#pragma mark - Image download

//  從網路下載圖片，下載完後，呼叫 callback
- (void)loadImageURL:(nonnull NSString*)urlString completed:(nullable void(^)(UIImage*image,NSError*error))completedHandle
{
    if ( urlString == nil || urlString.length == 0 ) {
        NSLog(@"** *image download wrong!!" );
        completedHandle(nil,nil);
        return;
    }
    [[KHImageDownloader instance] loadImageURL:urlString cellLinker:self completed:completedHandle ];
}

- (void)loadImageURL:(nonnull NSString*)urlString imageView:(nullable UIImageView*)imageView placeHolder:(nullable UIImage*)placeHolderImage brokenImage:(nullable UIImage*)brokenImage animation:(BOOL)animated
{
    [self loadImageURL:urlString imageView:imageView placeHolder:placeHolderImage brokenImage:brokenImage animation:animated completed:nil];
}

//  從網路下載圖片，下載完後，直接把圖片填入到傳入的 imageView 裡
- (void)loadImageURL:(nonnull NSString*)urlString imageView:(nullable UIImageView*)imageView placeHolder:(nullable UIImage*)placeHolderImage brokenImage:(nullable UIImage*)brokenImage animation:(BOOL)animated completed:(nullable void(^)(UIImageView*imageView, UIImage*image, NSError*error))completedHandle
{
    //  若圖片下載過了，就直接呈現
    UIImage *image = [[KHImageDownloader instance] getImageFromCache:urlString];
    if( image == nil ){
        imageView.image = placeHolderImage;
    }
    else{
        imageView.image = image;
        if(completedHandle) completedHandle(imageView,image,nil);
        return;
    }
    
    if ( urlString == nil || urlString.length == 0 ) {
        NSLog(@"** *image download wrong!!" );
        if ( animated ) {
            [UIView transitionWithView:imageView
                              duration:0.3f
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{
                                imageView.image = brokenImage ? brokenImage : placeHolderImage;
                            } completion:nil];
        }
        else{
            imageView.image = brokenImage ? brokenImage : placeHolderImage;
        }
        if(completedHandle) completedHandle(imageView,nil,[NSError errorWithDomain:NSURLErrorDomain code:-1000 userInfo:nil]);
        return;
    }
    
    [[KHImageDownloader instance] loadImageURL:urlString cellLinker:self completed:^(UIImage*image, NSError*error){
        if ( error ) {
            if ( animated ) {
                [UIView transitionWithView:imageView
                                  duration:0.3f
                                   options:UIViewAnimationOptionTransitionCrossDissolve
                                animations:^{
                                    imageView.image = brokenImage;
                                } completion:nil];
            }
            else{
                imageView.image = brokenImage;
            }
        }
        else{
            //  如果 imageView 是在沒有圖片的狀態下，要賦予圖片，那才做過渡動畫，不然就直接給圖
            if ( imageView.image == nil || imageView.image == placeHolderImage || imageView.image == brokenImage ) {
                [UIView transitionWithView:imageView
                                  duration:0.3f
                                   options:UIViewAnimationOptionTransitionCrossDissolve
                                animations:^{
                                    imageView.image = image;
                                } completion:nil];
            }
            else{
                imageView.image = image;
            }
        }
        if(completedHandle) completedHandle(imageView,image,error);
    }];
}

//  更新 model 不做更新，用在 cell 裡執行修改 model，因為 model 修改後會自動觸發更新，所以當你修改不想要做更新時，可執行此 method
- (void)modifyModelNoNotify:(void(^)(id _Nonnull model))modifyBlock
{
    BOOL originSetting = self.enabledObserveModel; 
    self.enabledObserveModel = NO;
    modifyBlock( self.model );
    self.enabledObserveModel = originSetting;
}



@end

@implementation UITableViewCellModel

- (instancetype)init
{
    if ( self = [super init] ) {
        self.cellStyle = UITableViewCellStyleValue1;
    }
    return self;
}

@end

@implementation UITableViewCell (KHCell)


+ (Class)mappingModelClass
{
    return [UITableViewCellModel class];
}

const void* hasConfig_key;

- (void)setKh_hasConfig:(BOOL)kh_hasConfig
{
    objc_setAssociatedObject(self, &hasConfig_key, @(kh_hasConfig), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


- (BOOL)kh_hasConfig
{
    return objc_getAssociatedObject(self, &hasConfig_key);
}


const void *pairInfoKey;

- (void)setPairInfo:(KHPairInfo *)pairInfo
{
    objc_setAssociatedObject(self, &pairInfoKey, pairInfo, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (KHPairInfo*)pairInfo
{
    return objc_getAssociatedObject(self, &pairInfoKey);
}

//  目前配對的 model
- (nullable id)model
{
    return self.pairInfo.model;
}

- (nullable NSIndexPath*)indexPath
{
    if ([KHCore shareCore].isStandalone) {
        return self.pairInfo.indexPath;
    } else {
        return self.indexPath;
    }
}

- (void)onLoad:(UITableViewCellModel*)model
{
    self.textLabel.text = model.text;
    if ( model.textFont ) self.textLabel.font = model.textFont;
    if ( model.textColor ) self.textLabel.textColor = model.textColor;
    self.imageView.image = model.image;

    self.detailTextLabel.text = model.detail;
    if ( model.detailFont ) self.detailTextLabel.font = model.detailFont;
    if ( model.detailColor) self.detailTextLabel.textColor = model.detailColor;
    
    self.accessoryType = model.accessoryType;
    self.selectionStyle = model.selectionType;
    self.backgroundColor = model.backgroundColor;
    self.accessoryView = model.accessoryView;
    self.backgroundView = model.backgroundView;
    if( [self respondsToSelector:@selector(setSeparatorInset:)] )self.separatorInset = model.separatorInset;
    if( [self respondsToSelector:@selector(setLayoutMargins:)] ) self.layoutMargins = model.layoutMargins;
    if( [self respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)] ) self.preservesSuperviewLayoutMargins = model.preservesSuperviewLayoutMargins;
}

- (void)removeFromSuperview
{
    [super removeFromSuperview];
    
    if ([KHCore shareCore].isStandalone) {
        [self.pairInfo deObserveModel];
    }
}

//  從網路下載圖片，下載完後，呼叫 callback
- (void)loadImageURL:(nonnull NSString*)urlString 
           completed:(nullable void(^)( UIImage*,  NSError*))completedHandle
{
    [self.pairInfo loadImageURL:urlString completed:completedHandle];
}

//  從網路下載圖片，下載完後，直接把圖片填入到傳入的 imageView 裡
//  從網路下載圖片，下載完後，直接把圖片填入到傳入的 imageView 裡
- (void)loadImageURL:(nonnull NSString*)urlString 
           imageView:(nullable UIImageView*)imageView
         placeHolder:(nullable UIImage*)placeHolderImage 
         brokenImage:(nullable UIImage*)brokenImage
           animation:(BOOL)animated
{
    [self.pairInfo loadImageURL:urlString
                      imageView:imageView
                    placeHolder:placeHolderImage
                    brokenImage:brokenImage
                      animation:animated
                      completed:nil];
}

//  從網路下載圖片，下載完後，直接把圖片填入到傳入的 imageView 裡
- (void)loadImageURL:(nonnull NSString*)urlString
           imageView:(nullable UIImageView*)imageView
         placeHolder:(nullable UIImage*)placeHolderImage
         brokenImage:(nullable UIImage*)brokenImage
           animation:(BOOL)animated
           completed:(nullable void(^)( UIImageView*imageView, UIImage*image, NSError*error))completedHandle
{
    [self.pairInfo loadImageURL:urlString
                      imageView:imageView
                    placeHolder:placeHolderImage
                    brokenImage:brokenImage
                      animation:animated
                      completed:completedHandle];
}

//  更新 model 不做更新，用在 cell 裡執行修改 model，因為 model 修改後會自動觸發更新，所以當你修改不想要做更新時，可執行此 method
- (void)modifyModelNoNotify:(void(^)(id _Nonnull model))modifyBlock
{
    [self.pairInfo modifyModelNoNotify:modifyBlock];
}


@end

//  沒有實際用處，只是為了符合 cell mapping 的規則
@implementation UICollectionViewCellModel


@end


@implementation UICollectionReusableView (KHCell)

const void *pairInfoKey;


+ (Class)mappingModelClass
{
    return [UICollectionViewCellModel class];
}

const void* hasConfig_key;

- (void)setKh_hasConfig:(BOOL)kh_hasConfig
{
    objc_setAssociatedObject(self, &hasConfig_key, @(kh_hasConfig), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


- (BOOL)kh_hasConfig
{
    return objc_getAssociatedObject(self, &hasConfig_key);
}


- (void)setPairInfo:(KHPairInfo *)pairInfo
{
    objc_setAssociatedObject(self, &pairInfoKey, pairInfo, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (KHPairInfo*)pairInfo
{
    return objc_getAssociatedObject(self, &pairInfoKey);
}

//  目前配對的 model
- (nullable id)model
{
    return self.pairInfo.model;
}

- (nullable NSIndexPath*)indexPath
{
    if ([KHCore shareCore].isStandalone) {
        return self.pairInfo.indexPath;
    } else {
        return self.indexPath;
    }
}

- (void)onLoad:(id)model
{
    //  override by subclass
}

- (void)removeFromSuperview
{
    [super removeFromSuperview];
    
    if ([KHCore shareCore].isStandalone) {
        [self.pairInfo deObserveModel];
    }
}

//  從網路下載圖片，下載完後，呼叫 callback
- (void)loadImageURL:(nonnull NSString*)urlString 
           completed:(nullable void(^)( UIImage*image,  NSError*error))completedHandle
{
    [self.pairInfo loadImageURL:urlString completed:completedHandle];
}

//  從網路下載圖片，下載完後，直接把圖片填入到傳入的 imageView 裡
- (void)loadImageURL:(nonnull NSString*)urlString 
           imageView:(nullable UIImageView*)imageView
         placeHolder:(nullable UIImage*)placeHolderImage 
         brokenImage:(nullable UIImage*)brokenImage
           animation:(BOOL)animated
{
    [self.pairInfo loadImageURL:urlString
                      imageView:imageView
                    placeHolder:placeHolderImage
                    brokenImage:brokenImage
                      animation:animated
                      completed:nil];    
}

//  從網路下載圖片，下載完後，直接把圖片填入到傳入的 imageView 裡
- (void)loadImageURL:(nonnull NSString*)urlString
           imageView:(nullable UIImageView*)imageView
         placeHolder:(nullable UIImage*)placeHolderImage
         brokenImage:(nullable UIImage*)brokenImage
           animation:(BOOL)animated
           completed:(nullable void(^)( UIImageView*imageView, UIImage*image, NSError*error))completedHandle
{
    [self.pairInfo loadImageURL:urlString
                      imageView:imageView
                    placeHolder:placeHolderImage
                    brokenImage:brokenImage
                      animation:animated
                      completed:completedHandle];
}

//  更新 model 不做更新，用在 cell 裡執行修改 model，因為 model 修改後會自動觸發更新，所以當你修改不想要做更新時，可執行此 method
- (void)modifyModelNoNotify:(void(^)(id _Nonnull model))modifyBlock
{
    [self.pairInfo modifyModelNoNotify:modifyBlock];
}

@end


@implementation KHEventHandleData

- (instancetype)init
{
    self = [super init];
    
    _cellViews = [[NSMutableArray alloc] initWithCapacity:10];
    
    return self;
}

- (void)dealloc
{
    
}

- (void)addEventTargetForCellView:(UIView*)cellView
{
    if ( [cellView isKindOfClass: self.cellClass ] ) {
        //  若是我們要監聽的 cell ，從 cell 取出要監聽的 ui
        UIControl *uicontrol = [cellView valueForKey:self.propertyName];
        if (uicontrol) {
            //  避免重覆加入
            [uicontrol removeTarget:self.target action:self.action forControlEvents:self.event];
            [_cellViews removeObject:cellView];
            //  ui control 加入事件處理
            [uicontrol addTarget:self.target action:self.action forControlEvents:self.event ];
            [_cellViews addObject:cellView];
        } else {
            NSLog(@"⚠️⚠️⚠️⚠️⚠️ Warning from DataBinding!!! ⚠️⚠️⚠️⚠️⚠️");
            NSLog(@"You had register a UIControl name: ‼️ %@ ‼️ but not exists in this cell.", self.propertyName);
            NSLog(@"View class name: %@", NSStringFromClass([self class]));
        }
    }
}

- (void)removeEventTargetFromAllCellViews
{
    for( UIView *view in _cellViews ){
        UIControl *uicontrol = [view valueForKey:self.propertyName];
        [uicontrol removeTarget:self action:self.action forControlEvents:self.event];
    }
    [_cellViews removeAllObjects];
}



@end




