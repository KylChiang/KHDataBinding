
使用方法：
===

####1.建立你的 Model

####2.建立你的 Cell
繼承自 UITableViewCell 或 UICollectionViewCell，一定要有一個 nib file，我的流程裡，會自動去找與 cell class 同名的 nib，然後建立 instance

####3. Cell 裡實作 onLoad:(id)model 
這個 method 不存在原本的類別裡，是流程需要，額外加的。實作內容就是 model 資料填入 cell


####4. 建立 data binder 的 instance
在 tableview 所在的 controller，建立 建立時，傳入 table view 與 delegate 作為參數

####5. 建立綁定的 array

####6. 設定 model 與 cell 的綁定

####7. 填入資料
