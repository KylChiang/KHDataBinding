
大綱：
===

**使用方法**
1.建立你的 Model
2.建立你的 Cell
3. Cell 裡實作 onLoad:(id)model 
4. 建立 data binder 的 instance，與相關設定
5. 資料放入 array
6. 實作 KHTableViewDelegate

**調整  cell height 或是 cell size**


使用方法：
===

####1.建立你的 Model
根據 API 回傳的 json struct，來建立相應的 model， 我使用 http://uifaces.com/api 來做測試<br />
這個網站開放的 api  ，它可以讓你隨機取得數筆假的個人資料，每筆個人會有姓名、地址、電話、照片...等等<br />
讓你用來做測試。

```objc
@interface Location : NSObject
@property (nonatomic, strong) NSString *state;
@property (nonatomic, strong) NSString *street;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) NSString *zip;
@end

@interface Name : NSObject
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *first;
@property (nonatomic, strong) NSString *last;
@end

@interface Picture : NSObject
@property (nonatomic, strong) NSString *large;
@property (nonatomic, strong) NSString *thumbnail;
@property (nonatomic, strong) NSString *medium;
@end

@interface User : NSObject
@property (nonatomic, strong) NSString *sha256;
@property (nonatomic, strong) NSString *cell;
@property (nonatomic, strong) NSString *phone;
@property (nonatomic, strong) NSString *nationality;
@property (nonatomic, strong) NSString *version;
@property (nonatomic, strong) NSString *dob;
@property (nonatomic, strong) NSString *registered;
@property (nonatomic, strong) Picture *picture;
@property (nonatomic, strong) NSString *sha1;
@property (nonatomic, strong) NSString *dNI;
@property (nonatomic, strong) Location *location;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *salt;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *md5;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) Name *name;
@property (nonatomic, strong) NSString *gender;
@end

@interface UserModel : NSObject
@property (nonatomic, strong) User *user;
@property (nonatomic) NSNumber *testNum;
@end

```

####2.建立你的 Cell
繼承自 UITableViewCell 或 UICollectionViewCell，一定要有一個 xib file，我的流程裡，會自動去找與 cell class 同名的 xib，然後建立 instance。<br />
我建立一個 UserInfoCell.h ，UserInfoCell.m，UserInfoCell.xib

```objc
@interface UserInfoCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imgUserPic;
@property (weak, nonatomic) IBOutlet UILabel *lbName;
@property (weak, nonatomic) IBOutlet UILabel *lbGender;
@property (weak, nonatomic) IBOutlet UILabel *lbPhone;
@property (weak, nonatomic) IBOutlet UIButton *btn;
@property (weak, nonatomic) IBOutlet UISwitch *sw;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintImgTrillingSpace;
@property (weak, nonatomic) IBOutlet UIButton *btnUpdate;
@property (weak, nonatomic) IBOutlet UILabel *lbTest;
@property (weak, nonatomic) IBOutlet UILabel *lbNumber;


@end

```
####3. Cell 裡實作 onLoad:(id)model 
這個 method 是用 category 另外自訂的。實作內容就是 model 資料填入 cell<br />
下面的 code 寫的就是把  UserModel 的 property 取得的資料，逐項填入 UserInfoCell 的 UI 裡<br />
<br />
如果 cell 裡有需要從網路上下載圖片，就用下面的寫法。

```objc
[self.cellProxy loadImageWithURL:model.user.picture.medium completed:^(UIImage *image) {
     self.imgUserPic.image = image;
}];
```
給予網址，下載完成後，會呼叫  completed block，你在 block 裡填寫要把 image 放進哪個 UI 裡<br />
<br />

完整寫法
```objc
@implementation UserInfoCell

- (void)onLoad:(UserModel*)model
{
    self.lbName.text = [NSString stringWithFormat:@"%@ %@", model.user.name.first,model.user.name.last];
    self.lbGender.text = model.user.gender;
    self.lbPhone.text = model.user.phone;
    if (model.testNum == nil ) {
        model.testNum = @0;
    }
    self.lbTest.text = [model.testNum stringValue];
    self.imgUserPic.image = nil;
    [self.cellProxy loadImageWithURL:model.user.picture.medium completed:^(UIImage *image) {
        self.imgUserPic.image = image;
    }];
    
    NSIndexPath *index = [self.cellProxy indexPathOfModel];
    self.lbNumber.text = [NSString stringWithFormat:@"%i", index.row ];
}

@end
```

####4. 建立 data binder 的 instance，與相關設定
在 tableview 所在的 controller，建立 建立時，傳入 table view 與 delegate 作為參數<br />
並且設定要不要開啟下拉更新

```objc
dataBinder.refreshHeadEnabled = YES;
dataBinder.headTitle = @"Pull Down To Refresh";
```

建立綁定的 array，之後 tableview 的內容都會與這個 array 同步，array 裡加入一筆資料， table view 就會多一個 cell

```objc
NSMutableArray<UserModel*> *userList = [dataBinder createBindArray];
```

除了上面的寫法，若 array 本身已經存在，可用下面的方式
```objc
[dataBinder bindArray:userList];
```

若要解除綁定
```objc
[dataBinder deBindArray:userList];
```

最後告訴 data binder， cell 與 model 的對映，這邊是用 UserModel 對應 UserInfoCell<br />
表示 data binder 走訪 array 若遇到  UserModel  的 object 就用 UserInfoCell 來顯示
```objc
[dataBinder bindModel:[UserModel class] cell:[UserInfoCell class]];
```
<br />

完整寫法
```objc
    //  init
    KHTableDataBinder*  dataBinder = [[KHTableDataBinder alloc] initWithTableView:self.tableView delegate:self];
    
    //  enable refresh header and footer
    dataBinder.refreshHeadEnabled = YES;
    dataBinder.refreshFootEnabled = NO;
    dataBinder.headTitle = @"Pull Down To Refresh";

    //  create bind array
    NSMutableArray<UserModel*> *userList = [dataBinder createBindArray];

    //  define cell mapping with model type
    [dataBinder bindModel:[UserModel class] cell:[UserInfoCell class]];

```
####5. 資料放入 array
把model object 放入綁定的 array，table view 的內容就會同步變化

```objc
    //  results 是由 NSDictionary array，這邊是把  NSDictionary array 轉成 UserModel array
    NSArray *users = [KVCModel convertArray:results toClass:[UserModel class] keyCorrespond:nil];
    [userList addObjectsFromArray:users];
```
####6. 實作 KHTableViewDelegate

```objc
@protocol KHTableViewDelegate 或 KHCollectionViewDelegate
@optional
//  當 user touch cell 的時候觸發
- (void)tableView:(nonnull UITableView*)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath;
//  下拉更新的時候觸發
- (void)tableViewRefreshHead:(nonnull UITableView*)tableView;
//  上拉的時候觸發
- (void)tableViewRefreshFoot:(nonnull UITableView*)tableView;
@end

@protocol KHCollectionViewDelegate
@optional
- (void)collectionView:(nonnull UICollectionView*)collectionView didSelectItemAtIndexPath:(nonnull NSIndexPath *)indexPath;
- (void)collectionViewRefreshHead:(nonnull UICollectionView*)collectionView;
- (void)collectionViewRefreshFoot:(nonnull UICollectionView*)collectionView;
@end
```

---
調整  cell height 或是 cell size
---

cell 的高或是 size，預設會讀取 xib 的原始設定，但若程式執行後想要修改，用以下寫法
```objc
UserModel *model = userList[0];
[dataBinder setCellHeight:60 model:model ];
```

若 UITableViewCell 的內容想要自動延展高度，只要把 cell height 設為 UITableViewAutomaticDimension 即可
```objc
[userList addObjectsFromArray:users];
for ( UserModel *model in userList ) {
    [dataBinder setCellHeight:UITableViewAutomaticDimension model:model ];
}
```

若是 UICollectionViewCell 想要自動延展高度，要用以下寫法。重點在設定 UICollectionViewFlowLayout.estimatedItemSize
```objc
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    layout.estimatedItemSize = CGSizeMake(100, 100);
```



