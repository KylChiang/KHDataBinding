

POD:
===
因為我沒有更新到 cocoapods 的資料庫，所以這樣用
> pod 'KHDataBinding', :git => 'https://github.com/gevin/KHDataBinding.git'

大綱：
===

**一、使用方法**

1. 建立你的 Model
2. 建立你的 Cell
3. Cell 裡實作 onLoad:(id)model
4. 建立 KHTableView
5. 初始配置
6. KVOModel 轉換 json 為 data model object
7. 設定 header / footer
8. 實作 KHTableViewDelegate
9. Cell 上的 UI 事件
10. 下拉更新、上拉載更多



使用方法：
===

## 1.建立你的 Model
根據 API 回傳的 json struct，來建立相應的 model， 我使用 http://uifaces.com/api 來做測試<br>
這個網站開放的 api  ，它可以讓你隨機取得數筆假的個人資料，每筆個人會有姓名、地址、電話、照片...等等<br>
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

## 2.建立你的 Cell
繼承自 UITableViewCell 或 UICollectionViewCell，一定要有一個 xib file，我的流程裡，會自動去找與 cell class 同名的 xib，然後建立 instance。<br>
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

## 3. Cell 裡實作 onLoad:(id)model
onLoad 裡實作的是把 UserModel 的資料填入 UserInfoCell 的動作<br>

```objc
#import <UIKit/UIKit.h>
#import "KHCell.h"
#import "UserModel.h"

@interface UserInfoCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imgUserPic;
@property (weak, nonatomic) IBOutlet UILabel *labelName;
@property (weak, nonatomic) IBOutlet UILabel *labelGender;
@property (weak, nonatomic) IBOutlet UILabel *labelPhone;
@property (weak, nonatomic) IBOutlet UIButton *btnRemove;
@property (weak, nonatomic) IBOutlet UIButton *btnReplace;
@property (weak, nonatomic) IBOutlet UISwitch *sw;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintImgTrillingSpace;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UILabel *labelTextDisplay;

@end


@implementation UserInfoCell
- (void)onLoad:(UserModel*)model
{
    self.labelName.text = [NSString stringWithFormat:@"%@ %@", model.name.first, model.name.last];
    self.labelGender.text = model.gender;
    self.labelPhone.text = model.phone;
    self.imgUserPic.image = nil;
    [self loadImageURL:model.picture.medium imageView:self.imgUserPic placeHolder:nil brokenImage:nil animation:YES];
    self.labelTextDisplay.text = model.testText;
    self.textField.text = model.testText;
    self.sw.on = model.swValue;
}
@end
```

若你的 cell 有需要下載圖片，可使用 

```objc
@interface UITableViewCell (KHCell)
- (void)loadImageURL:(nonnull NSString*)urlString imageView:(nullable UIImageView*)imageView placeHolder:(nullable UIImage*)placeHolderImage brokenImage:(nullable UIImage*)brokenImage animation:(BOOL)animated;
@end
```
dataBinding 會幫你記錄是哪個cell下載，不會受到 reuse cell 影響


## 4. 建立 KHTableView

若是透過 xib，請在 xib 拉一個 UITableView，並且將其 class 手動改為 KHTableView<BR>
再拉關聯到 controller 即可。<BR>

若是自行建立
>KHTableView *tableView = [[KHTableView alloc] initWithFrame:(CGRect){0,0,320,400} style:UITableViewStylePlain];

## 5. 初始配置

進行初始配置
1. 設定 delegate
2. 設定 cell model 的 mapping
3. 建立一個 section array

```objc
// first important thing, assign delegate
self.tableView.kh_delegate = self;

// config model/cell mapping
[self.tableView setMappingModel:[UserModel class] cell:[UserInfoCell class]];

// create an empty section array, if you add an UserModel model into userList, it will display an UserInfoColCell in tableView
userList = [self.tableView createSection];
```
之後你對 section array 加一筆資料model，tableView 就會同步新增一個 cell 顯示在 View 上<BR>

完整寫法
```objc
- (void)viewDidLoad
{
    [super viewDidLoad];

    //  first important thing, assign delegate
    self.tableView.kh_delegate = self;

    //  config model/cell mapping 
    [self.tableView setMappingModel:[UserModel class] cell:[UserInfoCell class]];

    //  create an empty section array, if you add an UserModel model into userList, it will display an UserInfoColCell in tableView
    userList = [self.tableView createSection];

    //  query model from api
    [self fetchUsers];
}
```

#### 給定  cell height 或是 cell size 預設值
當 Cell display 時，KHTableView 會拿 xib 裡設定的 size 當作預設 cell size<BR>
當您不希望 KHTableView 讀取 xib size 來自動幫您決定 cell size 時，可以使用<BR>
> - (void)setDefaultSize:(CGSize)cellSize forCellClass:(Class _Nonnull)cellClass;
來設定 cell 的預設值，而在 render 後想要改變 cell size 再使用  <BR>
> - (void)setCellSize:(CGSize)cellSize model:(id _Nonnull)model;
來動態調整 cell size。<BR>

```objc
[tableView setDefaultSize:(CGSize){320,60} forCellClass:[User]];
```
## 6. KVOModel 轉換 json 為 data model object

透過 api 取得的 json 最後轉換成 NSDictionary<BR>
可以使用 KVCModel 來做轉換成 Model object<BR>

```objc
UserModel *model = [KVCModel objectWithDictionary:jsonDict objectClass:[UserModel class]];
```

## 7. 設定 header / footer

當需要顯示 header 或是 footer 時，可使用<BR>
> - (void)setHeaderModel:(id _Nullable)model at:(NSInteger)section;

但傳入的 model 必須是 UIView 或是 NSString<BR>

```objc
    //  set string as section 0 header / footer
    [self.tableView setHeaderModel:@"UserModel List Header" at:0];
    [self.tableView setFooterModel:@"UserModel List Footer" at:0];
    
    //  set custom view as  section 1 header / footer
    MyTableHeaderView *headerView = [MyTableHeaderView create];
    [headerView.button addTarget:self action:@selector(btnHeaderClicked:) forControlEvents:UIControlEventTouchUpInside];
    [headerView.button setTitle:@"header button" forState:UIControlStateNormal];
    headerView.button.layer.cornerRadius = 5;
    headerView.button.layer.borderColor = [UIColor colorWithRed:0.5 green:0.5 blue:1 alpha:1].CGColor;
    headerView.button.layer.borderWidth = 1.0f;
    [self.tableView setHeaderModel:headerView at:1];
```

## 8. 實作 KHTableViewDelegate

```objc
@protocol KHTableViewDelegate <NSObject,UIScrollViewDelegate>
@optional
- (void)tableView:(KHTableView*_Nonnull)tableView didSelectRowAtIndexPath:(NSIndexPath  *_Nonnull )indexPath;
- (void)tableView:(KHTableView *_Nonnull)tableView willDisplayCell:(nonnull UITableViewCell *)cell forRowAtIndexPath:(nonnull NSIndexPath *)indexPath;
//  when table view create a new cell 
- (void)tableView:(KHTableView*_Nonnull)tableView newCell:(UITableViewCell* _Nonnull)cell model:(id _Nonnull)model indexPath:(NSIndexPath  *_Nonnull )indexPath;
//  pull down to refresh
- (void)tableViewOnPulldown:(KHTableView*_Nonnull)tableView refreshControl:(UIRefreshControl *_Nonnull)refreshControl;
//  scroll reach bottom in table view
- (void)tableViewOnEndReached:(KHTableView*_Nonnull)tableView;
@end

```

## 9. Cell 上的 UI 事件

cell 上若有互動式的 UI，controller 若想要收到它們的事件，可以用<BR>
>- (void)addTarget:(nullable id)target action:(nonnull SEL)action forControlEvents:(UIControlEvents)event onCell:(nonnull Class)cellClass propertyName:(nonnull NSString*)property;
類似於 UIButton 的 addTarget: action: forControlEvents: ，只要這裡要再加上指定 cell 的 class，和 property(UI) 的名字<BR>
```objc
    // set event handle  
    [self.tableView addTarget:self
				action:@selector(cellBtnClicked:)
                  forControlEvents:UIControlEventTouchUpInside
                                  onCell:[UserInfoCell class]
                     propertyName:@"btn"];
                 
- (void)cellBtnClicked:(id)sender
{
    UserModel *model = [self.tableView modelForUI:sender];
    NSIndexPath *index = [self.tableView indexPathForModel:model];
    NSLog(@"cell %ld button clicked", (long)index.row );
}

```



## 10. 下拉更新、上拉載更多

