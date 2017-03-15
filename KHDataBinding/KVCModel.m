//
//  KVCModel.m
//
//  Created by gevin.chen on 2015/4/19.
//  Copyright (c) 2015年 gevin.chen. All rights reserved.
//

#import "KVCModel.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

@implementation KVCModel

-(id)initWithDict:(NSDictionary*)dic
{

    self = [super init];
    if (self) {
        if ( [dic isKindOfClass:[NSDictionary class]]) {
            [self injectDict:dic];
        }
        
    }
    return self;
}

-(void)injectDict:(NSDictionary*)dic
{
    [KVCModel injectDictionary:dic toObject:self keyCorrespond:_keyCorrespondDic];
}

-(void)setProperty:(NSString*)jsonKey correspondKey:(NSString*)pName
{
    if (_keyCorrespondDic==nil) {
        _keyCorrespondDic = [[NSMutableDictionary alloc] initWithCapacity:5];
    }
    [_keyCorrespondDic setObject:jsonKey forKey:pName];
}

-(NSDictionary*)dict
{
    return [KVCModel dictionaryWithObj:self keyCorrespond:_keyCorrespondDic];
}

-(NSString*)jsonString
{
    NSDictionary *dic = [self dict];
    NSError *error;
    // 把 NSDictionary 轉成 NSData
    NSData *data = [NSJSONSerialization dataWithJSONObject: dic options:NSJSONWritingPrettyPrinted error:&error];  
    if ( error ) {
        NSLog(@"NSJSONSerialization error:%ld, %@, %@", (long)error.code, error.domain, error.description );
        return nil;
    }
    NSString *result = [[NSString alloc] initWithData: data encoding:NSUTF8StringEncoding];
    return result;
}

-(NSData*)jsonData
{
    NSDictionary*dic = [self dict];
    NSError *error;
    // 把 NSDictionary 轉成 NSData
    NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&error];
    if ( error ) {
        NSLog(@"NSJSONSerialization error:%ld, %@, %@", (long)error.code, error.domain, error.description );
        return nil;
    }
    return data;
}




/**
 將某物件轉換成 dictionary，物件的 property 都會變成 dictionary 裡的 key

 @param object 待轉換的物件
 @param correspondDic 轉換的 property name， 物件的property name (key)/ 轉到dictionary 時顯示的 key name ( value) <BR>
                      例如 MyClass 有個 property 叫 myAge，我轉成 dictionary 時，myAge 想改叫 userAge，這邊我可以傳入
                      @{@"myAge":@"userAge"}
 @return 轉換完成的 dictionary
 */
+(NSDictionary*)dictionaryWithObj:(id)object keyCorrespond:(NSDictionary*)correspondDic
{
    NSMutableDictionary *tmpDic = [[NSMutableDictionary alloc] init];
    // 解析 property
    unsigned int numOfProperties;
    objc_property_t *properties = class_copyPropertyList( [object class], &numOfProperties );
    for ( unsigned int pi = 0; pi < numOfProperties; pi++ ) {
        
        objc_property_t property = properties[pi];
        
        NSString *propertyName = [[NSString alloc] initWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        NSString *propertyType = [[NSString alloc] initWithCString:property_getAttributes(property) encoding:NSUTF8StringEncoding];
        
        // NSLog(@"name:%@ , type:%@", propertyName, propertyType );
        // 把值取出，若是 nil ，沒有值，就不做下面的事，不然塞 nil 到 dictionary 會出例外
        id value = [object valueForKey: propertyName ];
        if ( value == nil || [value isKindOfClass:[NSNull class]] ) {
            continue;
        }
        
        // 取出 dictionary key
        // 檢查有沒有要轉換不同 json key 的 property name
        NSString *pkey = nil;
        if ( correspondDic ) {
            pkey = correspondDic[propertyName];
        }
        if ( pkey == nil ) {
            pkey = propertyName;
        }
        
        // char *
        if ( [propertyType hasPrefix:@"T*" ] ) {
            NSString *tmpStr = [NSString stringWithUTF8String: (__bridge void*)value ]; // 在 arc 中 id 不能直接轉成 char *
            [tmpDic setObject: tmpStr forKey: pkey ];
        }
        else{
            //  若是 class 物件，那檢查是不是 objc 的原生資料類別，是的話就直接塞進 dictionary，不是的話就進下一層遞迴，再做一次解析
            if([propertyType hasPrefix:@"T@"]){
                //  UIImage
                if ([value isKindOfClass:[UIImage class]]) {
                    // 要把 image 轉成 base64 string
                    NSData *data = UIImagePNGRepresentation( value );
                    NSString *base64String = [data base64EncodedStringWithOptions:0];
                    [tmpDic setObject: base64String forKey: pkey ];
                }
                //  NSArray
                else if( [value isKindOfClass:[NSArray class]] ) {
                    NSArray *dictionaryArr = [KVCModel convertDictionarys:value keyCorrespond:correspondDic ];
                    [tmpDic setObject: dictionaryArr forKey: pkey ];
                }
                else if ([value isKindOfClass:[NSString class]] ||
                    [value isKindOfClass:[NSNumber class]] ||
                    [value isKindOfClass:[NSDate class]] ||
                    [value isKindOfClass:[NSData class]] ||
                    [value isKindOfClass:[NSDictionary class]]) {
                    [tmpDic setObject: value forKey: pkey ];
                }
                else{
                    //  若不是以上那些型別的物件，那有可能是自訂的物件，那就轉換成 dictionary
                    NSDictionary *objDic = [KVCModel dictionaryWithObj:value keyCorrespond:correspondDic];
                    [tmpDic setObject: objDic forKey: pkey ];
                }
            }
            //  若不是 class 物件，就直接塞進 dictionary
            else{
                //  property type 不是物件，但是實際型別卻是 NSNumber，那就是 BOOL 值，BOOL 值要正確的轉成 JSON 的裡的 boolean，要傳入 @YES 或 @NO
                if ( [value isKindOfClass:[NSNumber class]] ) {
                    [tmpDic setObject: [value intValue] == 1 ? @YES : @NO forKey: pkey ];
                }
                else{
                    [tmpDic setObject: value forKey: pkey ];
                }
            }
            
        }
#if !__has_feature(objc_arc)
        [propertyName release];
        [propertyType release];
#endif
    }
    free( properties );
#if !__has_feature(objc_arc)
    return [tmpDic autorelease];
#else
    return tmpDic;
#endif
    
}

/**
 將某物件轉換成 dictionary，物件的 property 都會變成 dictionary 裡的 key
 
 @param object 待轉換的物件
 @return 轉換完成的 dictionary
 */
+(NSDictionary*)dictionaryWithObj:(id)object
{
    return [KVCModel dictionaryWithObj:object keyCorrespond:nil];
}

//  把 json string 轉成 object
+(id)objectWithJSONString:(NSString*)jsonString objectClass:(Class)cls keyCorrespond:(NSDictionary*)correspondDic
{
    NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    id object = [KVCModel objectWithJSON:data objectClass:cls keyCorrespond:correspondDic];
    return object;
}


//  把 json string 轉成 object
+(id)objectWithJSON:(NSData*)jsonData objectClass:(Class)cls keyCorrespond:(NSDictionary*)correspondDic
{
    NSError *error = nil;
    id jsonObject = [NSJSONSerialization JSONObjectWithData: jsonData
                                                        options: kNilOptions
                                                          error: &error];
    if ( error ) {
        NSLog(@"NSJSONSerialization error:%ld, %@, %@", (long)error.code, error.domain, error.description );
        return nil;
    }
    
    id object = nil;
    if ( [jsonObject isKindOfClass:[NSDictionary class]]) {
        object = [KVCModel objectWithDictionary:jsonObject objectClass:cls keyCorrespond:correspondDic];
    }
    else if( [jsonObject isKindOfClass:[NSArray class]]){
        object = [KVCModel convertArray:jsonObject toClass:cls keyCorrespond:correspondDic];
    }
    
    return object;
}


//  把 dictionary 轉成 object
+(id)objectWithDictionary:(NSDictionary*)dict objectClass:(Class)cls keyCorrespond:(NSDictionary*)correspondDic
{
    id object = [[cls alloc] init];
    
    [KVCModel injectDictionary:dict toObject:object keyCorrespond:correspondDic];
    
    return object;
}

+(id)objectWithDictionary:(NSDictionary*)dict objectClass:(Class)cls
{
    return [KVCModel objectWithDictionary:dict objectClass:cls keyCorrespond:nil];
}



/**
 將 dictionary 裡的值，填入到傳入的物件裡，物件的 property 與 dictionary 的 key 同名，值就會填入 property 裡
 
 @param jsonDic 儲存值的 dictionary
 @param object 欲接收值的物件
 */
+(void)injectDictionary:(NSDictionary*)jsonDic toObject:(id)object keyCorrespond:(NSDictionary*)correspondDic
{
    if ( jsonDic == nil ) return;
    // 解析 property
    unsigned int numOfProperties;
    objc_property_t *properties = class_copyPropertyList( [object class], &numOfProperties );
    for ( unsigned int pi = 0; pi < numOfProperties; pi++ ) {
        
        objc_property_t property = properties[pi];
        
        NSString *propertyName = [[NSString alloc] initWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        NSString *propertyType = [[NSString alloc] initWithCString:property_getAttributes(property) encoding:NSUTF8StringEncoding];
        
        // 檢查有沒 key mapping
        NSString *json_key = nil;
        if ( correspondDic ) {
            json_key = correspondDic[ propertyName ];
        }
        if (json_key==nil) {
            json_key = propertyName;
        }
        
        //  從 dictionary 中取出值
        id value = [jsonDic objectForKey: json_key ];
        
        //  值為 nil 或是 NSNull 物件就略過
        if ( value == nil || [value isKindOfClass:[NSNull class]] ){
            continue;
        }
        
        // 不是物件，直接丟值進去
        if ( ![propertyType hasPrefix:@"T@" ] ){
            [object setValue: value forKey: propertyName ];
        }
        // 是個物件
        else if( [propertyType hasPrefix:@"T@" ] ) {
            
            // 如果 property 是 UIImage，那要把 dictionary 裡的 value 做 decode base64
            if ( [value isKindOfClass:[UIImage class]] ) {
                NSString *string = [KVCModel base64Decode: value ];
                NSData *data = [string dataUsingEncoding:NSASCIIStringEncoding];
                UIImage *image = [[UIImage alloc] initWithData: data ];
                [object setValue: image forKey:propertyName ];
            }
            // 若 value 是 NSDictionary，那預期 property 是某種 class type
            else if ( [value isKindOfClass: [NSDictionary class] ] ) {
                
                // 取得 property 的 class
                NSArray *comp = [propertyType componentsSeparatedByString:@"\""];
                Class _class = NSClassFromString( comp[1] );
                
                // 把 value(Dictionary) 轉成物件
                id obj = [[_class alloc] init];
                [KVCModel injectDictionary:value toObject:obj keyCorrespond:correspondDic];
                // 填入
                [object setValue: obj forKey: propertyName ];
            }
            // 若 value 是 NSArray，預期 json dictionary 裡的 array ，會是裝一堆 dictionary
            else if( [value isKindOfClass: [NSArray class] ] ){
                /*
                 因為 obj-c 沒有泛型，所以如果有 property 是 Array 我就會不知道它底下的 dictionary 該轉成什麼 class type
                 所以我自訂一個方法，就是額外宣告一個沒有用的 property 叫 classof_xxxx，xxxx 是 array property 的 property
                 name ， classof_xxxx 的 type 就是用來解析 array property 的 class type
                 ex:
                 @property (nonatomic) NSArray *stores;
                 @property (nonatomic) StoreModel *classof_stores;
                 
                 因為有一個 array property 叫 stores，所以我就固定去找有沒有 classof_stores
                 有的話，那我知道 classof_stores 的 type 是 StoreModel
                 stores 底下的 dictionary 就轉換成 StoreModel
                 
                 */
                
                // 找 class 參考，看有沒有宣告 classOf{xxxx} 的 property，如果有，那那個 property 的 type，就是 value 用的 type
                NSMutableArray *arrayVal = nil;
                
                //  檢查 object 有沒有 classof_xxxx 這樣的 property
                NSString *arrayElementClassRef_property = [NSString stringWithFormat:@"classof_%@", propertyName ];
                //
                objc_property_t classRefProperty = class_getProperty( [object class], [arrayElementClassRef_property UTF8String] );
                // array 元素的 class
                Class arrayElementClass = NULL;
                if ( classRefProperty != NULL ) {
                    NSString *clsRef_propertyType = [[NSString alloc] initWithCString:property_getAttributes(classRefProperty) encoding:NSUTF8StringEncoding];
                    // 取得 class
                    NSArray *comp = [clsRef_propertyType componentsSeparatedByString:@"\""];
                    arrayElementClass = NSClassFromString( comp[1] );
                }
                
                //  如果有指定 array element class，那就把 array 內容轉成指定 class
                if ( arrayElementClass != NULL ) { // && [arrayElementClass isSubclassOfClass:[KVCModel class] ]
                    //  把 array element 都轉成指定 class 的 object
                    arrayVal = [KVCModel convertArray:value toClass:arrayElementClass keyCorrespond:correspondDic];
                }
                else{
                    //  Gevin note:
                    //  用 isKindOfClass 辨別 NSArray 或 NSMutableArray，會失敗，經測試，一個 NSArray 的 object，做 [object isKindOfClass:[NSMutableArray class]]
                    //  的檢查，回傳值也會是 true，幹，做 [object respondsToSelector: @selector(addObject:)] 也會是 true，但當你真的呼叫 object addObject: 時，就 crash  給你看
                    //  目前找不到快速的檢測方法，所以改以檢查 propertyType 的型別
                    //  如果 property type 是 mutable array 那最後就一定是要把 mutable array 丟進去，不是的話就隨意
                    
                    //  檢查 property 的 array type
                    NSArray *typeCompos = [propertyType componentsSeparatedByString:@"\""];
                    NSString *clearType = typeCompos[1];
                    if( [clearType isEqualToString:@"NSMutableArray"]){
                        arrayVal = [[NSMutableArray alloc] initWithArray: value ];
                    }
                    else{
                        arrayVal = value;
                    }
                }
                
                //  把最終的 array 填入 object property
                [object setValue: arrayVal forKey: propertyName ];
            }
            else{
                // 如果是其它 class 就直接塞值
                [object setValue: value forKey: propertyName ];
            }
        }
#if !__has_feature(objc_arc)
        [propertyName release];
        [propertyType release];
#endif
    }
    free( properties );
}

/**
 將 dictionary 裡的值，填入到傳入的物件裡，物件的 property 與 dictionary 的 key 同名，值就會填入 property 裡
 
 @param jsonDic 儲存值的 dictionary
 @param object 欲接收值的物件
 */
+(void)injectDictionary:(NSDictionary*)jsonDic toObject:(id)object
{
    [KVCModel injectDictionary:jsonDic toObject:object keyCorrespond:nil];
}


//  把一個物件的值，轉成另一個物件
+(id)objectWithModel:(id)model objectClass:(Class)cls
{
    NSDictionary *dict = [KVCModel dictionaryWithObj:model];
    id object = [cls new];
    [KVCModel injectDictionary:dict toObject:object ];
    return object;
}

//  把一個model的值，填到另一個 model
+(void)injectWithModel:(id)model toObject:(id)object
{
    NSDictionary *dict = [KVCModel dictionaryWithObj:model];
    [KVCModel injectDictionary:dict toObject:object ];
}






+(NSMutableArray*)convertArray:(NSArray*)array toClass:(Class)cls keyCorrespond:(NSDictionary*)correspondDic
{
    if ( ![array isKindOfClass:[NSArray class] ] ) {
        return nil;
    }
    NSMutableArray *finalArray = [NSMutableArray array];
    for ( NSInteger i=0; i<array.count; i++) {
        id dic = array[i];
        if ( [dic isKindOfClass:[NSDictionary class] ]) {
            id object = [[cls alloc] init];
            [KVCModel injectDictionary:dic toObject:object keyCorrespond:correspondDic];
            [finalArray addObject:object];
        }
        else{
            [finalArray addObject:dic];
        }
    }
    return finalArray;
    
}

+(NSMutableArray*)convertDictionarys:(NSArray*)array keyCorrespond:(NSDictionary*)correspondDic
{
    if ( ![array isKindOfClass:[NSArray class] ] ) {
        return nil;
    }
    NSMutableArray *finalArray = [NSMutableArray array];
    for ( NSInteger i=0; i<array.count; i++) {
        id object = array[i];
        // 若是 iOS 原生資料型別，就直接加入，不再做轉換
        if ([object isKindOfClass:[NSString class]] ||
            [object isKindOfClass:[NSNumber class]] ||
            [object isKindOfClass:[NSDate class]]   ||
            [object isKindOfClass:[NSData class]]   ||
            [object isKindOfClass:[NSDictionary class]]    ){
            [finalArray addObject: object ];
        }
        //  若是 array ，就進下一層的遞迴
        else if( [object isKindOfClass:[NSArray class]] ){
            __unused NSArray *array = [KVCModel convertDictionarys:object keyCorrespond:correspondDic];
        }
        //  若是其它型別的物件，就轉換成 dictionary
        else {
            NSDictionary *dict = [KVCModel dictionaryWithObj:object keyCorrespond:correspondDic];
            [finalArray addObject:dict];
        }
    }
    return finalArray;
}




// 下面功能是 ios 7 之後才支援

+ (NSString*)base64Encode:(NSString*)plainString
{
    NSData *plainData = [plainString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64String = [plainData base64EncodedStringWithOptions:0];
//    NSLog(@"%@", base64String); // Zm9v
    return base64String;
}

+ (NSString*)base64Decode:(NSString*)base64String
{
    NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
    NSString *decodedString = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];
    return decodedString;
}



@end
