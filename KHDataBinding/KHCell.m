//
//  KHPairInfo.m
//
//  Created by GevinChen on 2015/9/26.
//  Copyright (c) 2015年 GevinChen. All rights reserved.
//

#import "KHCell.h"
#import "KHDataBinding.h"
#import <objc/runtime.h>

NSString* const kCellSize = @"kCellSize";
NSString* const kCellHeight = @"kCellHeight";

static int linkerIDGen = 0;
@implementation KHPairInfo
{
    int linkerID;
}


- (instancetype)init
{
    self = [super init];
    if (self) {
        linkerID = linkerIDGen++;
        self.cellSize = (CGSize){0,0};
        self.enabledObserveModel = YES;
    }
    return self;
}

- (void)dealloc
{
    [self deObserveModel];
}

- (void)setModel:(id)model
{
    if ( _model ) {
        [self deObserveModel];
    }
    _model = model;
    if ( _model ) {
        [self observeModel];
    }
}


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


- (void)observeModel
{
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
        dispatch_async( dispatch_get_main_queue(), ^{
            if(self.cell){
                [self.cell onLoad: self.model ];
            }
            needUpdate = NO;
        });
    }
}

//  取得目前的 index
- (NSIndexPath*)indexPath
{
    NSIndexPath *index = [self.binder indexPathOfModel:_model];
    return index;
}

//  從網路下載圖片，下載完後，呼叫 callback
- (void)loadImageURL:(nonnull NSString*)urlString completed:(nullable void(^)(UIImage*,NSError*))completedHandle
{
    if ( urlString == nil || urlString.length == 0 ) {
        NSLog(@"*** image download wrong!!" );
        completedHandle(nil,nil);
        return;
    }
    
    [[KHImageDownloader instance] loadImageURL:urlString cellLinker:self completed:completedHandle ];
}

//  從網路下載圖片，下載完後，直接把圖片填入到傳入的 imageView 裡
- (void)loadImageURL:(nonnull NSString*)urlString imageView:(nullable UIImageView*)imageView placeHolder:(nullable UIImage*)placeHolderImage brokenImage:(nullable UIImage*)brokenImage animation:(BOOL)animated
{
    //  若圖片下載過了，就直接呈現
    UIImage *image = [[KHImageDownloader instance] getImageFromCache:urlString];
    if( image == nil ){
        imageView.image = placeHolderImage;
    }
    else{
        imageView.image = image;
        return;
    }
    
    if ( urlString == nil || urlString.length == 0 ) {
        NSLog(@"*** image download wrong!!" );
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
    }];
}



@end

@implementation UITableViewCellModel

const void *pairInfoKey;

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
    
    [self.pairInfo deObserveModel];
}

@end

//  沒有實際用處，只是為了符合 cell mapping 的規則
@implementation UICollectionViewCellModel


@end


@implementation UICollectionViewCell (KHCell)

const void *pairInfoKey;

+ (Class)mappingModelClass
{
    return [UICollectionViewCellModel class];
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

- (void)onLoad:(id)model
{
    //  override by subclass
}

- (void)removeFromSuperview
{
    [super removeFromSuperview];
    
    [self.pairInfo deObserveModel];
}

@end


@implementation UICollectionReusableView (KHCell)

+ (Class)mappingModelClass
{
    return [UICollectionViewCellModel class];
}

- (void)onLoad:(id)model
{
    //  override by subclass
}


@end
