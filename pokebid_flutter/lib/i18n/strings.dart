import 'locale_controller.dart';

/// 集中管理所有 UI 文案。中英並排，依當前語言回傳對應字串。
/// 用法：`Text(L.home)` 或帶參數 `L.offerReceived(name)`。
/// 因 MaterialApp 在語言切換時整棵重建，getter 會自動重新求值。
class L {
  static bool get _en => localeController.isEnglish;
  static String _t(String zh, String en) => _en ? en : zh;

  // ── Bottom navigation ──────────────────────────────────────────────────
  static String get navHome => _t('首頁', 'Home');
  static String get navMarket => _t('掛售區', 'Market');
  static String get navPost => _t('發佈', 'Post');
  static String get navDex => _t('圖鑑', 'Dex');
  static String get navMe => _t('我的', 'Me');

  // ── Common buttons / actions ───────────────────────────────────────────
  static String get cancel => _t('取消', 'Cancel');
  static String get confirm => _t('確認', 'Confirm');
  static String get ok => _t('確定', 'OK');
  static String get save => _t('儲存', 'Save');
  static String get delete => _t('刪除', 'Delete');
  static String get edit => _t('編輯', 'Edit');
  static String get send => _t('傳送', 'Send');
  static String get submit => _t('送出', 'Submit');
  static String get close => _t('關閉', 'Close');
  static String get retry => _t('重試', 'Retry');
  static String get loading => _t('載入中…', 'Loading…');
  static String get search => _t('搜尋', 'Search');
  static String get all => _t('全部', 'All');
  static String get done => _t('完成', 'Done');
  static String get viewMore => _t('查看更多', 'View more');
  static String get back => _t('返回', 'Back');

  // ── Listing / posting ──────────────────────────────────────────────────
  static String get postProduct => _t('發佈商品', 'Post a listing');
  static String get listingPosted => _t('商品已上架！', 'Listing posted!');

  // ── Splash ─────────────────────────────────────────────────────────────
  static String get splashTagline =>
      _t('寶可夢卡牌交易平台', 'Pokémon TCG Marketplace');

  // ── Auth / login ───────────────────────────────────────────────────────
  static String get loginRequired => _t('需要登入', 'Login required');
  static String loginToDo(String action) =>
      _t('登入後即可$action', 'Log in to $action');
  static String get signInWithGoogle => _t('使用 Google 登入', 'Sign in with Google');
  static String get logout => _t('登出', 'Log out');
  static String get logoutAccount => _t('登出帳號', 'Log out');
  static String get logoutConfirm => _t('確定要登出嗎？', 'Are you sure you want to log out?');

  // ── Settings sections ──────────────────────────────────────────────────
  static String get settings => _t('設定', 'Settings');
  static String get language => _t('語言', 'Language');
  static String get displayLanguage => _t('顯示語言', 'Display language');
  static String get selectLanguage => _t('選擇語言', 'Select language');
  static String get about => _t('關於', 'About');
  static String get version => _t('版本', 'Version');
  static String get safetyTips => _t('安全交易提示', 'Safe trading tips');
  static String get privacyPolicy => _t('私隱政策', 'Privacy Policy');
  static String get termsOfService => _t('服務條款', 'Terms of Service');
  static String get deleteAccount => _t('刪除帳號', 'Delete account');

  // ── Home screen ────────────────────────────────────────────────────────
  static String get messages => _t('訊息', 'Messages');
  static String get nearbyShops => _t('附近卡鋪', 'Nearby shops');
  static String get nearbyShopsSubtitle =>
      _t('找出離你最近的實體卡店', 'Find physical card stores near you');
  static String get recentlyViewed => _t('最近瀏覽', 'Recently viewed');
  static String get clear => _t('清除', 'Clear');
  static String get latestListings => _t('最新上架', 'Latest listings');
  static String get viewAll => _t('查看全部', 'View all');
  static String get noListings => _t('目前沒有上架商品', 'No listings yet');
  static String get sold => _t('已售出', 'Sold');
  static String get welcomeTitle => _t('歡迎來到 TCGspot', 'Welcome to TCGspot');
  static String get welcomeSubtitle =>
      _t('寶可夢卡牌交易平台', 'Pokémon TCG Marketplace');

  // ── Marketplace ────────────────────────────────────────────────────────
  static String get marketTitleSuffix => _t(' 掛售區', ' Market');
  static String get searchHint =>
      _t('搜尋卡名、賣家、系列 ID...', 'Search card, seller, set ID...');
  static String get wishlist => _t('願望清單', 'Wishlist');
  static String get sortLatest => _t('最新上架', 'Latest');
  static String get sortPriceLow => _t('價格最低', 'Price: low');
  static String get sortPriceHigh => _t('價格最高', 'Price: high');
  static String searchCount(String q, int n) =>
      _t('搜尋「$q」：$n 件', '"$q": $n items');
  static String totalCount(int n) => _t('共 $n 件商品', '$n items');
  static String noSearchResult(String q) =>
      _t('找不到「$q」相關商品', 'No results for "$q"');
  static String get noMarketListings => _t('目前沒有掛售商品', 'No listings yet');
  static String get filterTitle => _t('篩選條件', 'Filters');
  static String get priceRange => _t('價格區間 (HK\$)', 'Price range (HK\$)');
  static String get priceMin => _t('最低', 'Min');
  static String get priceMax => _t('最高', 'Max');
  static String get grade => _t('評級', 'Grade');
  static String get setSeries => _t('系列', 'Set');
  static String get addToWishlistCondition =>
      _t('將此條件加入願望清單', 'Save this search to wishlist');
  static String get wishlistAdded =>
      _t('已加入願望清單，有符合的新上架會通知你',
        'Added to wishlist. You\'ll be notified of matching listings.');
  static String get reset => _t('重設', 'Reset');
  static String get applyFilter => _t('套用篩選', 'Apply');

  // ── Card grid item / listing badges ────────────────────────────────────
  static String get auction => _t('競標', 'Auction');
  static String get buyNow => _t('直購', 'Buy now');
  static String bidsCount(String timeInfo, int n) =>
      _t('$timeInfo · $n 出價', '$timeInfo · $n bids');

  // ── Offer sheet ────────────────────────────────────────────────────────
  static String get makeOfferTitle => _t('出價議價', 'Make an offer');
  static String sellerPriceLine(String grade, String price) =>
      _t('$grade · 賣家定價 HK\$$price', '$grade · Listed at HK\$$price');
  static String get yourOffer => _t('你的出價 (HK\$)', 'Your offer (HK\$)');
  static String offerTooHigh(String price) =>
      _t('出價需低於賣家定價 HK\$$price', 'Offer must be below the listed price HK\$$price');
  static String offerHint(String price) =>
      _t('賣家定價 HK\$$price，你可以低於此金額出價',
        'Listed at HK\$$price. You can offer below this.');
  static String get submitOffer => _t('送出出價', 'Submit offer');
  static String get invalidAmount => _t('請輸入有效金額', 'Please enter a valid amount');
  static String get offerSent => _t('出價已送出，等待賣家回覆', 'Offer sent. Waiting for the seller.');
  static String offerFailed(String e) => _t('出價失敗：$e', 'Offer failed: $e');

  // ── Card detail ────────────────────────────────────────────────────────
  static String get productDetail => _t('商品詳情', 'Listing details');
  static String get writeReview => _t('撰寫評價', 'write a review');
  static String get makeOfferAction => _t('出價', 'make an offer');
  static String get contactSeller => _t('聯絡賣家', 'contact the seller');
  static String get buyPrice => _t('直購價', 'Buy now price');
  static String get metaGrade => _t('評級', 'Grade');
  static String get metaType => _t('類型', 'Type');
  static String get metaCondition => _t('狀況', 'Condition');
  static String get metaListedTime => _t('上架時間', 'Listed');
  static String get preferredMeetup => _t('優先面交地點', 'Preferred meetup spots');
  static String sellerStats(String rating, int sales) =>
      _t('$rating · $sales 筆成交', '$rating · $sales sales');
  static String get soldNotice =>
      _t('此商品已成交，僅買賣雙方可查看', 'This listing is sold. Only buyer and seller can view it.');
  static String get myListingNotice =>
      _t('這是你的商品，可在「我的 → 我的掛售」管理',
        'This is your listing. Manage it in Me → My Listings.');
  static String offerAcceptedBanner(String amount) =>
      _t('賣家已接受你的出價 HK\$$amount！請前往聊天室溝通交易',
        'Seller accepted your offer of HK\$$amount! Head to the chat to arrange the deal.');
  static String offerRejectedBanner(String amount) =>
      _t('你的出價 HK\$$amount 已被拒絕', 'Your offer of HK\$$amount was declined.');
  static String offerPendingBanner(String amount) =>
      _t('你已出價 HK\$$amount，等待賣家回覆', 'You offered HK\$$amount. Waiting for the seller.');
  static String get thisIsYourListing => _t('這是你的商品', 'This is your listing');
  static String get reviewed => _t('已評價', 'Reviewed');
  static String get reviewSeller => _t('評價賣家', 'Review seller');
  static String get contactShort => _t('聯絡', 'Contact');
  static String get contactSellerBtn => _t('聯絡賣家', 'Contact seller');
  static String get offering => _t('出價中', 'Offered');
  static String get makeOfferShort => _t('出價', 'Offer');

  // ── SNKRDUNK reference card ────────────────────────────────────────────
  static String get snkrTitle => _t('SNKRDUNK 日本市場成交', 'SNKRDUNK Japan market sales');
  static String get snkrSubtitle => _t('近期實際成交價（日圓）', 'Recent actual sale prices (JPY)');
  static String get snkrLoading => _t('查詢中...', 'Loading...');
  static String get snkrNoData =>
      _t('SNKRDUNK 暫無此卡成交資料', 'No SNKRDUNK sales data for this card');
  static String get rawCard => _t('生卡', 'Raw');
  static String get noSales => _t('無成交', 'No sales');
  static String salesCount(dynamic n) => _t('$n 筆', '$n sales');
  static String get snkrRecent => _t('PSA 10 近期成交', 'PSA 10 recent sales');
  static String get snkrTrend => _t('PSA 10 走勢', 'PSA 10 trend');
  static String get days7 => _t('7日', '7d');
  static String get days30 => _t('30日', '30d');
  static String psaUpdated(String date) => _t('更新：$date', 'Updated: $date');

  // ── Post listing form ──────────────────────────────────────────────────
  static String get postListingTitle => _t('上架掛售', 'Post a listing');
  static String photosCount(int n) => _t('$n/4 張照片', '$n/4 photos');
  static String get uploadPhotos => _t('上傳卡牌照片（最多4張）', 'Upload card photos (up to 4)');
  static String get pickFromDex => _t('從圖鑑選卡（選填）', 'Pick from Dex (optional)');
  static String get cardName => _t('卡牌名稱', 'Card name');
  static String get cardNameHint =>
      _t('例如：リザードン ex / 初版 リザードン', 'e.g. Charizard ex / 1st Edition Charizard');
  static String get productType => _t('商品類型', 'Listing type');
  static String get rawUngraded => _t('RAW 未鑑定', 'RAW (ungraded)');
  static String get rawDesc => _t('原卡，未經鑑定', 'Raw card, not graded');
  static String get gradedCard => _t('鑑定卡', 'Graded');
  static String get gradedDesc => _t('PSA / BGS / CGC 等', 'PSA / BGS / CGC, etc.');
  static String get gradingCompany => _t('鑑定公司', 'Grading company');
  static String get gradeScore => _t('鑑定分數', 'Grade');
  static String gradeLevel(String company, String score) =>
      _t('鑑定等級：$company $score', 'Grade: $company $score');
  static String get optional => _t('選填', 'Optional');
  static String get certHint => _t('例：12345678', 'e.g. 12345678');
  static String get certHelper =>
      _t('輸入後系統自動抓取 PSA Pop · 同時填寫系列 + 卡號可讓圖鑑也顯示 Pop',
        'We\'ll auto-fetch PSA Pop. Add set + card number to show Pop in the Dex too.');
  static String get buyPriceLabel => _t('直購價格 (HK\$)', 'Buy now price (HK\$)');
  static String get setAndNumber => _t('系列 + 卡號（選填）', 'Set + card number (optional)');
  static String get description => _t('商品說明（選填）', 'Description (optional)');
  static String get descriptionHint =>
      _t('版本資訊、包裝狀況、交易方式...', 'Edition, condition, trade method...');
  static String get confirmPost => _t('確認上架', 'Post listing');
  static String get errEnterName => _t('請輸入卡牌名稱', 'Please enter the card name');
  static String get errEnterPrice => _t('請輸入有效價格', 'Please enter a valid price');
  static String get errPostFailed => _t('上架失敗，請稍後再試', 'Failed to post. Please try again.');
  static String get anonymousSeller => _t('匿名賣家', 'Anonymous seller');
  static String get justListed => _t('剛上架', 'Just listed');
  static String get selectSet => _t('選擇系列', 'Select set');
  static String get setSearchHint =>
      _t('搜尋系列名稱或 ID，如 sv8a', 'Search set name or ID, e.g. sv8a');
  static String get cardNumberHint => _t('卡號，如 217', 'Card no., e.g. 217');
  static String get pickFromDexTitle => _t('從圖鑑選卡', 'Pick from Dex');
  static String get dexSearchHint =>
      _t('搜尋卡片名稱（輸入 2 字以上）', 'Search card name (2+ characters)');
  static String get dexSearchPrompt => _t('輸入卡片名稱搜尋', 'Type a card name to search');
  static String get dexNoCard => _t('找不到卡片', 'No cards found');
  static String get meetupOptionalMulti => _t('（選填，可多選）', '(optional, multi-select)');
  static String get select => _t('選擇', 'Select');
  static String get tapToPickMeetup => _t('點擊選擇面交地點', 'Tap to choose meetup spots');
  static String get selectMeetup => _t('選擇面交地點', 'Choose meetup spots');
  static String doneCount(int n) => _t('完成（$n）', 'Done ($n)');
}
