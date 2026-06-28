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

  // ── Notifications ──────────────────────────────────────────────────────
  static String get notifications => _t('通知', 'Notifications');
  static String get markAllRead => _t('全部已讀', 'Mark all read');
  static String get noNotifications => _t('目前沒有通知', 'No notifications');
  static String get viewProduct => _t('查看商品', 'View listing');
  static String get acceptOffer => _t('接受出價', 'Accept offer');
  static String get rejectOffer => _t('拒絕', 'Decline');
  static String get confirmAccept => _t('確認接受', 'Confirm');
  static String acceptOfferConfirm(String buyer, int amount) =>
      _t('接受 $buyer 的 HK\$$amount 出價？\n商品將標示為已售出。',
        'Accept $buyer\'s offer of HK\$$amount?\nThe listing will be marked as sold.');
  static String get notifMissingListing => _t('通知缺少商品資訊', 'Notification is missing listing info');
  static String get noPendingOfferMaybeHandled =>
      _t('找不到待處理的出價（可能已被處理）', 'No pending offer found (may already be handled)');
  static String get noPendingOffer => _t('找不到待處理的出價', 'No pending offer found');
  static String get offerRejected => _t('已拒絕出價', 'Offer declined');
  static String actionFailed(String e) => _t('操作失敗：$e', 'Action failed: $e');
  static String get sellerFallback => _t('賣家', 'Seller');

  // ── Relative time ──────────────────────────────────────────────────────
  static String get justNow => _t('剛剛', 'just now');
  static String minutesAgo(int n) => _t('$n 分鐘前', '${n}m ago');
  static String hoursAgo(int n) => _t('$n 小時前', '${n}h ago');
  static String daysAgo(int n) => _t('$n 天前', '${n}d ago');

  // ── Chat ───────────────────────────────────────────────────────────────
  static String get chatSafetyText =>
      _t('平台不經手金流，請查看對方評價、慎防詐騙。',
        'We don\'t handle payments. Check the other party\'s reviews and beware of scams.');
  static String get chatSafetyLink => _t(' 安全提示 ›', ' Safety tips ›');
  static String get inquiring => _t('詢問中', 'Inquiring');
  static String sayHello(String name) => _t('向 $name 打聲招呼吧！', 'Say hello to $name!');
  static String get messageHint => _t('輸入訊息...', 'Type a message...');
  static String get quickReplies => _t('快速回覆', 'Quick replies');
  static List<String> get quickReplyOptions => _en
      ? const [
          'Is this still available?',
          'Is the price negotiable?',
          'Which grading company?',
          'Can you share more photos?',
          'How much is shipping?',
        ]
      : const ['請問還有貨嗎？', '可以議價嗎？', '請問評級是什麼機構？', '可以提供更多圖片嗎？', '請問運費是多少？'];

  // ── Deal card ──────────────────────────────────────────────────────────
  static String get dealConfirm => _t('成交確認', 'Deal confirmed');
  static String get dealDone => _t('買賣成交 🎉', 'Deal closed 🎉');
  static String dealPrice(int amount) => _t('成交價：HK\$$amount', 'Final price: HK\$$amount');
  static String get viewListingDetail => _t('查看商品詳情', 'View listing details');
  static String get reviewBuyer => _t('評價買家', 'Review buyer');
  static String get reviewDone => _t('已完成評價', 'Review submitted');
  static String get otherParty => _t('對方', 'the other party');

  // ── Review sheet ───────────────────────────────────────────────────────
  static String reviewTitle(String name) => _t('評價 $name', 'Review $name');
  static String get rating => _t('評分', 'Rating');
  static String get deliveryMethod => _t('交易方式', 'Delivery method');
  static String get deliveryMeetup => _t('面交', 'Meetup');
  static String get deliverySf => _t('SF順豐', 'SF Express');
  static String get deliveryOther => _t('其他', 'Other');
  static String get commentOptional => _t('留言（選填）', 'Comment (optional)');
  static String get commentHint => _t('分享你的交易體驗...', 'Share your trading experience...');
  static String get submitReview => _t('送出評價', 'Submit review');

  // ── Conversations list ─────────────────────────────────────────────────
  static String get buyerLabel => _t('買家', 'Buyer');
  static String get sellerLabel => _t('賣家', 'Seller');
  static String get noMessagesYet => _t('尚無訊息，點擊開始對話', 'No messages yet — tap to start');
  static String get noConversations => _t('還沒有任何對話', 'No conversations yet');
  static String get noConversationsHint =>
      _t('在商品頁聯絡賣家即可開始對話', 'Contact a seller on a listing to start chatting');
  static String get loginToViewMessages => _t('請先登入以查看訊息', 'Log in to view your messages');
  static String get login => _t('登入', 'Log in');

  // ── Received offers ────────────────────────────────────────────────────
  static String get receivedOffers => _t('收到的出價', 'Offers received');
  static String acceptAmountConfirm(String amount) =>
      _t('接受 HK\$$amount 的出價？', 'Accept the offer of HK\$$amount?');
  static String get acceptOfferDetail =>
      _t('商品將會自動下架，其他出價將被拒絕。\n接受後請在聊天室中與買家商討交易方式。',
        'The listing will be delisted and other offers declined.\nArrange the trade with the buyer in chat afterwards.');
  static String get offerAcceptedToast =>
      _t('已接受出價！請在聊天室中與買家溝通交易方式',
        'Offer accepted! Arrange the trade with the buyer in chat.');
  static String get noReceivedOffers => _t('目前沒有收到出價', 'No offers received yet');
  static String get pendingReply => _t('待回覆', 'Pending');
  static String get offerAmount => _t('出價金額', 'Offer amount');

  // ── Profile / Settings ─────────────────────────────────────────────────
  static String get guest => _t('訪客', 'Guest');
  static String get editProfile => _t('編輯個人資料', 'Edit profile');
  static String get statListing => _t('掛售中', 'Listed');
  static String get statCollection => _t('收藏', 'Collection');
  static String get statCollectionValue => _t('收藏價值', 'Value');
  // section headers
  static String get sectionMine => _t('我的', 'Mine');
  static String get sectionTrade => _t('交易', 'Trading');
  static String get sectionAccount => _t('帳號', 'Account');
  static String get sectionNotifySettings => _t('通知設定', 'Notifications');
  // mine entries
  static String get myListings => _t('我的掛售', 'My listings');
  static String get myCollection => _t('我的收藏', 'My collection');
  static String get txHistory => _t('交易紀錄', 'Transaction history');
  static String get myReviews => _t('我的評價', 'My reviews');
  static String itemsCount(int n) => _t('$n 項', '$n');
  static String cardsCount(int n) => _t('$n 張', '$n');
  static String recordsCount(int n) => _t('$n 筆', '$n');
  static String get none => _t('暫無', 'None');
  static String reviewsSummary(String avg, int n) =>
      _t('$avg ★ ($n則)', '$avg ★ ($n)');
  // trade entries
  static String get myMessages => _t('我的訊息', 'My messages');
  static String get followedSellers => _t('我追蹤的賣家', 'Followed sellers');
  // account entries
  static String get phoneVerify => _t('電話認證', 'Phone verification');
  static String get verified => _t('已認證 ✓', 'Verified ✓');
  static String get notVerified => _t('未認證', 'Not verified');
  static String get doPhoneVerify => _t('進行電話認證', 'verify your phone');
  static String get adminPanel => _t('管理後台', 'Admin panel');
  // notify settings
  static String get notifyNewMsg => _t('新訊息通知', 'New message alerts');
  static String get notifyNewMsgSub => _t('收到買家訊息時通知', 'Notify when a buyer messages you');
  static String get notifyPriceDrop => _t('收藏價格提醒', 'Price alerts');
  static String get notifyPriceDropSub =>
      _t('收藏卡牌市價變動時通知', 'Notify when your collection\'s market value changes');
  // listing management
  static String get loginToViewListings =>
      _t('請先登入以查看掛售商品', 'Log in to view your listings');
  static String get noListingsYet => _t('尚未掛售任何商品', 'No listings yet');
  static String get delist => _t('下架', 'Delist');
  static String get delistTitle => _t('下架商品', 'Delist item');
  static String delistConfirm(String name) => _t('確定要下架「$name」嗎？', 'Delist "$name"?');
  static String get confirmDelist => _t('確認下架', 'Delist');
  static String editItemTitle(String name) => _t('編輯「$name」', 'Edit "$name"');
  static String get priceLabel => _t('價格 (HK\$)', 'Price (HK\$)');
  static String marketUpdated(int n) => _t('已更新 $n 筆市價', 'Updated $n market prices');
  // delete account
  static String get deleteAccountWarning =>
      _t('此操作無法復原。你的掛售商品、出價、收藏及個人資料將被永久刪除。',
        'This cannot be undone. Your listings, offers, collection, and profile will be permanently deleted.');
  static String get deleteAccountPrompt =>
      _t('請輸入「確認刪除」以繼續：', 'Type "DELETE" to continue:');
  static String get deleteConfirmWord => _t('確認刪除', 'DELETE');
  static String get permanentDelete => _t('永久刪除', 'Delete permanently');
  static String deleteFailed(String e) => _t('刪除失敗：$e', 'Delete failed: $e');
  static String get logoutAccountBtn => _t('登出帳號', 'Log out');
  // collection
  static String get noCollection => _t('尚無收藏', 'No collection yet');
  static String get goToDexToCollect => _t('前往圖鑑加入收藏', 'Add cards from the Dex');
  static String holdingCount(int n) => _t('持有中 ($n)', 'Holding ($n)');
  static String soldCountSeg(int n) => _t('已售出 ($n)', 'Sold ($n)');
  static String get noHolding => _t('無持有中收藏', 'Nothing in holding');
  static String get noSoldRecord => _t('尚無售出記錄', 'No sales recorded');
  static String costHkd(String v) => _t('成本 HK\$$v', 'Cost HK\$$v');
  static String soldOn(String date) => _t('售出 $date', 'Sold $date');
  static String get sellAction => _t('售出', 'Sell');
  static String recordSellTitle(String name) => _t('記錄售出　$name', 'Record sale　$name');
  static String costAndMarket(String cost, String market) =>
      _t('成本 HK\$$cost　·　參考市價 HK\$$market', 'Cost HK\$$cost　·　Market HK\$$market');
  static String get actualSalePrice => _t('實際售出價格', 'Actual sale price');
  static String get confirmSell => _t('確認售出', 'Confirm sale');
  static String get saleRecorded => _t('已記錄售出', 'Sale recorded');
  // PL summary
  static String get collectionTotalValue => _t('收藏總市值', 'Total collection value');
  static String get updateMarket => _t('更新市價', 'Refresh');
  static String get totalCost => _t('總成本', 'Total cost');
  static String get profitLoss => _t('盈虧', 'P/L');
  static String get returnRate => _t('報酬率', 'Return');
  static String soldCards(dynamic n) => _t('已售出 $n 張', 'Sold $n');
  static String realizedPl(String sign, String v) =>
      _t('已實現盈虧　$sign HK\$$v', 'Realized P/L　$sign HK\$$v');
  static String marketRateNote(String rate) =>
      _t('市值依 SNKRDUNK 日本成交價　1 JPY ≈ $rate HKD',
        'Value based on SNKRDUNK Japan sales　1 JPY ≈ $rate HKD');
  // reviews
  static String get noReviews => _t('還沒有評價', 'No reviews yet');
  static String reviewsTotal(int n) => _t('共 $n 則', '$n reviews');
  // tx history
  static String soldRecords(int n) => _t('售出紀錄 ($n)', 'Sold ($n)');
  static String purchaseRecords(int n) => _t('購買紀錄 ($n)', 'Purchases ($n)');
  static String get noSoldRecords => _t('還沒有售出紀錄', 'No sales yet');
  static String get noPurchaseRecords => _t('還沒有購買紀錄', 'No purchases yet');
  static String get productFallback => _t('商品', 'Item');
  static String salePrice(int p) => _t('售價 HK\$$p', 'Sold for HK\$$p');
  static String purchasePrice(int amount, String sellerPart) =>
      _t('成交價 HK\$$amount$sellerPart', 'Paid HK\$$amount$sellerPart');
  static String sellerSuffix(String name) => _t('  賣家：$name', '  Seller: $name');
  static String get tagSold => _t('已售出', 'Sold');
  static String get tagPurchased => _t('已購買', 'Purchased');

  // ── Login screen ───────────────────────────────────────────────────────
  static String get loginTagline => _t('日版寶可夢卡牌交易平台', 'Japanese Pokémon TCG Marketplace');
  static String get featBrowseTitle => _t('瀏覽日版圖鑑', 'Browse the Dex');
  static String get featBrowseSub => _t('查看完整日版卡牌系列', 'Explore full Japanese card sets');
  static String get featChatTitle => _t('即時聊天', 'Instant chat');
  static String get featChatSub => _t('直接與賣家聯絡議價', 'Message sellers and negotiate directly');
  static String get featRecordTitle => _t('成交紀錄', 'Trade records');
  static String get featRecordSub => _t('追蹤收藏市值變化', 'Track your collection\'s value');
  static String get signInGoogleBtn => _t('使用 Google 帳號登入', 'Sign in with Google');
  static String get signInAppleBtn => _t('透過 Apple 登入', 'Sign in with Apple');
  static String get browseWithoutLogin => _t('先瀏覽，不登入', 'Browse without signing in');
  static String get loginAgreement =>
      _t('登入即代表同意使用條款及隱私政策', 'By signing in you agree to the Terms and Privacy Policy');

  // ── Review sheet (standalone) ──────────────────────────────────────────
  static String get reviewHelpsBuyers => _t('你的評價會幫助其他買家', 'Your review helps other buyers');
  static String get commentHintOptional =>
      _t('分享你的交易體驗（選填）', 'Share your trading experience (optional)');
  static String get reviewSubmitted =>
      _t('評價已送出，感謝你的回饋！', 'Review submitted. Thanks for your feedback!');

  // ── Edit profile ───────────────────────────────────────────────────────
  static String get errEnterDisplayName => _t('請填寫顯示名稱', 'Please enter a display name');
  static String get errUsernameTooShort => _t('用戶名至少需要 3 個字元', 'Username needs at least 3 characters');
  static String get errUsernameChars =>
      _t('只能使用英文小寫、數字、底線', 'Only lowercase letters, numbers, and underscores');
  static String get errUsernameTaken => _t('此用戶名已被使用', 'This username is taken');
  static String get profileUpdated => _t('個人資料已更新', 'Profile updated');
  static String get errSaveFailed => _t('儲存失敗，請稍後再試', 'Save failed. Please try again.');
  static String get chooseAvatar => _t('選擇頭像', 'Choose avatar');
  static String get displayNameLabel => _t('顯示名稱 *', 'Display name *');
  static String get displayNameHint => _t('你的公開名稱', 'Your public name');
  static String get usernameLabel => _t('用戶名 *', 'Username *');
  static String get bioLabel => _t('個人簡介', 'Bio');
  static String get bioHint => _t('介紹一下自己...', 'Tell others about yourself...');

  // ── Seller profile ─────────────────────────────────────────────────────
  static String get followSeller => _t('追蹤賣家', 'follow this seller');
  static String get sellerHome => _t('賣家主頁', 'Seller profile');
  static String get followers => _t('追蹤者', 'Followers');
  static String get listingActive => _t('上架中', 'Listed');
  static String ratingCount(int n) => _t('評分 ($n)', 'Rating ($n)');
  static String get following => _t('已追蹤', 'Following');
  static String get follow => _t('追蹤', 'Follow');
  static String buyerReviews(int n) => _t('買家評價 ($n)', 'Reviews ($n)');
  static String sellerListings(int n) => _t('上架商品 ($n)', 'Listings ($n)');
  static String get noTextReview => _t('（無文字評價）', '(no written review)');

  // ── Legal screen ───────────────────────────────────────────────────────
  static String effectiveDate(String date) => _t('生效日期：$date', 'Effective date: $date');
  static String get legalContact =>
      _t('如對本文件有任何疑問，請透過 TCGspot 內的客服管道或電子郵件與我們聯絡。',
        'If you have any questions about this document, please contact us through TCGspot\'s in-app support channel or by email.');

  // ── Dex ────────────────────────────────────────────────────────────────
  static String get imageNotAvailable => _t('暫時未提供該卡圖', 'Card image not available yet');
  static String get dexTitleSuffix => _t(' 圖鑑', ' Dex');
  static String get searchCardHint => _t('搜尋卡牌名稱...', 'Search card name...');
  static String get tabSetDex => _t('📦 系列圖鑑', '📦 Sets');
  static String get tabPokemonDex => _t('🐾 精靈圖鑑', '🐾 Pokémon');
  static String get cardNotFound => _t('找不到卡牌', 'No cards found');
  static String dexLoadFailed(String e) => _t('載入失敗：$e', 'Failed to load: $e');
  static String get branchBox => _t('卡盒', 'Boxes');
  static String get branchBoxDesc => _t('擴充包', 'Booster packs');
  static String get branchDeck => _t('牌組', 'Decks');
  static String get branchDeckDesc => _t('Deck / 禮盒', 'Decks / gift boxes');
  static String get branchPromoDesc => _t('特典卡', 'Promo cards');
  static String get noBoxData => _t('尚無卡盒資料', 'No box data yet');
  static String get noDeckData => _t('尚無牌組資料', 'No deck data yet');
  static String promoSeriesCount(int n) => _t('PROMO 系列（$n）', 'PROMO sets ($n)');
  static String get noPromoData => _t('尚無 PROMO 資料', 'No PROMO data yet');
  static String get seriesShort => _t('系列', 'Series');
  static String get newestFirst => _t('最新在前', 'Newest first');
  static String get oldestFirst => _t('最舊在前', 'Oldest first');
  static String get otherSeries => _t('其他系列', 'Other series');
  static String get myCollectionValue => _t('我的收藏總價值', 'My collection value');
  static String collectedCount(int n) => _t('已收 $n 張', '$n collected');
  static String trendDays(int n) =>
      _t('近 $n 日走勢 · 以市場參考價計算', 'Last $n days · based on market reference price');
  static String get marketRefPriceNote => _t('以市場參考價計算', 'Based on market reference price');
  static String setYearCount(String year, int total) => _t('$year · $total 張', '$year · $total cards');
  static String seriesGroupCount(int n, String latest) =>
      _t('$n 個系列$latest', '$n sets$latest');
  static String latestDateSuffix(String date) => _t(' · 最新 $date', ' · latest $date');
  static String get loadFailedTitle => _t('無法載入資料', 'Failed to load data');
  static String get addToCollection => _t('加入收藏', 'add to collection');
  static String get addToCollectionBtn => _t('加入收藏', 'Add to collection');
  static String get chooseGradeTitle => _t('選擇分級加入收藏', 'Choose a grade to add');
  static String get latestSalePrice => _t('價格為 SNKRDUNK 最新成交價', 'Price: SNKRDUNK latest sale');
  // TCG series names
  static String seriesName(String key) {
    const zh = {
      'm': 'Mega 系列', 'sv': '朱＆紫系列', 's': '劍＆盾系列', 'sp': '劍盾特別系列',
      'sm': '太陽＆月亮系列', 'xy': 'XY 系列', 'cp': 'XY 概念包系列', 'bw': '黑＆白系列',
      'dp': '鑽石＆珍珠系列', 'pt': '白金系列', 'l': 'LEGEND 系列', 'adv': 'ADV（紅寶石）系列',
      'classic1': '初代系列', 'neo': 'Neo（金銀）系列', 'ecard': 'e卡系列', 'pcg': 'PCG（EX）系列',
    };
    const en = {
      'm': 'Mega Series', 'sv': 'Scarlet & Violet', 's': 'Sword & Shield', 'sp': 'Sword & Shield Special',
      'sm': 'Sun & Moon', 'xy': 'XY Series', 'cp': 'XY Concept Pack', 'bw': 'Black & White',
      'dp': 'Diamond & Pearl', 'pt': 'Platinum Series', 'l': 'LEGEND Series', 'adv': 'ADV (Ruby) Series',
      'classic1': 'Classic Series', 'neo': 'Neo (Gold/Silver)', 'ecard': 'e-Card Series', 'pcg': 'PCG (EX) Series',
    };
    return (_en ? en : zh)[key] ?? otherSeries;
  }

  // ── Dex set grid ───────────────────────────────────────────────────────
  static String setTotalDate(int total, String date) =>
      _t('$total 張 · $date', '$total cards · $date');
  static String get sortNumAsc => _t('編號 ↑', 'No. ↑');
  static String get sortNumDesc => _t('編號 ↓', 'No. ↓');
  static String get sortRarity => _t('稀有度', 'Rarity');
  static String get noCardsInSet => _t('此系列暫無卡牌資料', 'No card data for this set yet');
  static String setNotFetched(String id) =>
      _t('$id 尚未抓取或仍在更新中。\n下拉可重新載入。',
        '$id hasn\'t been fetched or is still updating.\nPull down to reload.');

  // ── Dex card detail ────────────────────────────────────────────────────
  static String get collected => _t('已收藏', 'Collected');
  static String collectCardTitle(String name) => _t('收藏　$name', 'Collect　$name');
  static String currentMarket(String hkd, String jpy) =>
      _t('當前市價：HK\$$hkd　(¥$jpy)', 'Market: HK\$$hkd　(¥$jpy)');
  static String get yourCost => _t('你的成本價', 'Your cost');
  static String collectedToast(String label, String name) =>
      _t('已收藏　$label　$name', 'Collected　$label　$name');
  static String get anonymous => _t('匿名', 'Anonymous');
  static String get txSaved => _t('成交紀錄已儲存', 'Transaction saved');
  static String get priceStats => _t('成交價格統計', 'Price statistics');
  static String get noTxHintAdd =>
      _t('尚無成交紀錄，點下方「新增」記錄成交', 'No transactions yet. Tap "Add" below to record one.');
  static String get avgSalePrice => _t('平均成交價', 'Average price');
  static String get statHigh => _t('最高', 'High');
  static String get statAvg => _t('平均', 'Avg');
  static String get statLow => _t('最低', 'Low');
  static String get recentTx => _t('近期成交紀錄', 'Recent transactions');
  static String get add => _t('新增', 'Add');
  static String get noTxRecords => _t('暫無成交紀錄', 'No transactions yet');
  static String get noTxHintTap => _t('點「新增」記錄你的成交', 'Tap "Add" to record your sale');
  static String get psaPopCount => _t('PSA Pop 數量', 'PSA Pop count');
  static String get total => _t('總計：', 'Total: ');
  static String totalCards(int n) => _t('$n 張', '$n cards');
  static String get addCollectShort => _t('＋收藏', '+ Collect');
  static String daysShort(int d) => _t('$d日', '${d}d');
  static String get psaPriceTrend => _t('PSA 10 價格走勢', 'PSA 10 price trend');
  static String get addTxTitle => _t('新增成交紀錄', 'Add transaction');
  static String get gradeFieldHint => _t('評級（如 PSA 10）', 'Grade (e.g. PSA 10)');
  static String get amountFieldHint => _t('成交金額 HK\$', 'Amount HK\$');
  static String get buyerFieldHint => _t('買家（選填）', 'Buyer (optional)');

  // ── Login required dialog ──────────────────────────────────────────────
  static String get pleaseLogin => _t('請先登入', 'Please log in');
  static String loginToAction(String action) => _t('登入後才能$action。', 'Log in to $action.');
  static String get featureNeedsLogin => _t('此功能需要登入帳號。', 'This feature requires an account.');
  static String get later => _t('稍後', 'Later');
  static String get goLogin => _t('前往登入', 'Log in');

  // ── Followed sellers ───────────────────────────────────────────────────
  static String get noFollowedSellers => _t('尚未追蹤任何賣家', 'Not following any sellers yet');
  static String get followHint => _t('在賣家頁面點「追蹤」即可加入', 'Tap "Follow" on a seller\'s page to add them');

  // ── Nearby shops ───────────────────────────────────────────────────────
  static String get noShopData => _t('暫無卡鋪資料', 'No shop data yet');
  static String get regionAll => _t('全部', 'All');
  static String get regionHkIsland => _t('香港島', 'HK Island');
  static String get regionKowloon => _t('九龍', 'Kowloon');
  static String get regionNt => _t('新界', 'New Territories');
  static String get regionIslands => _t('離島', 'Islands');
  static String get noShopInRegion => _t('此區暫無卡鋪', 'No shops in this region yet');
  static String get noLocationNote =>
      _t('未取得定位，以下依名稱排序。開啟定位權限可顯示距離。',
        'Location unavailable; sorted by name. Enable location to show distances.');
  static String get navigate => _t('導航', 'Directions');
  static String get callShop => _t('致電', 'Call');

  // ── Wishlist ───────────────────────────────────────────────────────────
  static String get wishlistTitle => _t('願望清單', 'Wishlist');
  static String get addToWishlist => _t('加入願望清單', 'add to wishlist');
  static String get wishlistEmptyHint2 =>
      _t('在圖鑑卡片頁按愛心 ♥ 加入想要的卡', 'Tap the heart ♥ on a card to add it');
  static String get addWish => _t('新增願望', 'Add wish');
  static String get addWishAction => _t('新增願望', 'add a wish');
  static String get addWishDesc =>
      _t('輸入想要的卡片關鍵字（卡名），有符合的新上架會通知你。',
        'Enter a keyword (card name) for the card you want; you\'ll be notified of matching new listings.');
  static String get keywordLabel => _t('關鍵字（卡名）', 'Keyword (card name)');
  static String get budgetMaxOptional => _t('預算上限（選填）', 'Max budget (optional)');
  static String get add2 => _t('加入', 'Add');
  static String get enterKeyword => _t('請輸入關鍵字', 'Please enter a keyword');
  static String get addedToWishlist => _t('已加入願望清單', 'Added to wishlist');
  static String get wishlistEmpty => _t('願望清單是空的', 'Your wishlist is empty');
  static String get wishlistEmptyHint =>
      _t('點右下「＋新增願望」加入想要的卡', 'Tap "+ Add wish" to add cards you want');
  static String budgetMax(int p) => _t('預算上限 HK\$$p', 'Max budget HK\$$p');
  static String get notifyOnMatch => _t('有新上架符合時會通知你', 'We\'ll notify you when a match is listed');

  // ── Announcement ───────────────────────────────────────────────────────
  static String get announcementDetail => _t('公告詳情', 'Announcement');

  // ── Phone (WhatsApp) verification ──────────────────────────────────────
  static String get errInvalidPhone => _t('請輸入有效電話號碼', 'Please enter a valid phone number');
  static String get errEnterOtp => _t('請輸入驗證碼', 'Please enter the verification code');
  static String get whatsappVerifySuccess => _t('WhatsApp 認證成功 ✓', 'WhatsApp verification successful ✓');
  static String get otpWrongOrExpired => _t('驗證碼錯誤或已過期', 'Code is incorrect or expired');
  static String get whatsappVerify => _t('WhatsApp 認證', 'WhatsApp Verification');
  static String get verifyPhoneTitle => _t('用 WhatsApp 認證電話', 'Verify your phone via WhatsApp');
  static String get verifyPhoneDesc =>
      _t('驗證碼會透過 WhatsApp 發送。認證後，你的用戶名旁會顯示「已認證」標誌，提升交易信任度。',
        'The code is sent via WhatsApp. Once verified, a "Verified" badge appears next to your name to build trust.');
  static String get phoneNumber => _t('電話號碼', 'Phone number');
  static String get otherRegionNote => _t('其他地區請自行輸入 +國碼', 'For other regions, include your +country code');
  static String otpSentTo(String phone) =>
      _t('已透過 WhatsApp 發送驗證碼至 $phone', 'Code sent via WhatsApp to $phone');
  static String get enterOtpHint => _t('輸入 6 位數驗證碼', 'Enter the 6-digit code');
  static String get reenterNumber => _t('重新輸入號碼', 'Re-enter number');
  static String get confirmVerify => _t('確認驗證', 'Verify');
  static String get sendOtp => _t('發送驗證碼', 'Send code');

  // ── Onboarding ─────────────────────────────────────────────────────────
  static String get obSkip => _t('跳過', 'Skip');
  static String get obNext => _t('下一步', 'Next');
  static String get obStart => _t('開始使用 🎉', 'Get started 🎉');
  static String get obWelcomeTitle => _t('歡迎來到 TCGspot', 'Welcome to TCGspot');
  static String get obWelcomeSubtitle => _t('香港最大的寶可夢卡牌\nC2C 交易平台', 'Hong Kong\'s largest Pokémon\nTCG C2C marketplace');
  static String get obWelcomeBody =>
      _t('在這裡你可以買賣珍稀卡牌，查閱市場行情，建立你的收藏圖鑑。',
        'Buy and sell rare cards, check market prices, and build your collection Dex.');
  static String get obMarketTitle => _t('掛售區', 'Marketplace');
  static String get obMarketSubtitle => _t('瀏覽所有在售卡牌', 'Browse all cards for sale');
  static String get obMarketBody =>
      _t('可以按系列、稀有度、成色篩選。點入卡牌可查看詳情、出價或直接聯絡賣家。',
        'Filter by set, rarity, and condition. Tap a card to see details, make an offer, or contact the seller.');
  static String get obPostTitle => _t('發佈商品', 'Post a listing');
  static String get obPostSubtitle => _t('輕鬆上架你的卡牌', 'List your cards easily');
  static String get obPostBody =>
      _t('點底部「＋」按鈕，填寫卡名、價格、上傳照片即可上架。支援 PSA 評級卡，可輸入 Cert 號自動抓取 Pop 數據。',
        'Tap the "+" button, fill in name and price, and upload photos. PSA cards are supported — enter the Cert number to auto-fetch Pop data.');
  static String get obDexTitle => _t('圖鑑', 'Dex');
  static String get obDexSubtitle => _t('你的專屬卡牌百科', 'Your personal card encyclopedia');
  static String get obDexBody =>
      _t('查閱每張卡的 SNKRDUNK 日本市場成交價、PSA Pop 數量，並追蹤你的收藏總價值。',
        'Check each card\'s SNKRDUNK Japan sale prices and PSA Pop counts, and track your collection\'s total value.');

  // ── Report & Block ─────────────────────────────────────────────────────
  static String get report => _t('檢舉', 'Report');
  static String get reportTitle => _t('檢舉', 'Report');
  static String get reportReason => _t('檢舉原因', 'Reason');
  static String get reportDetailsHint =>
      _t('補充說明（選填）', 'Additional details (optional)');
  static String get reportSubmit => _t('送出檢舉', 'Submit report');
  static String get reportSubmitted =>
      _t('已收到你的檢舉，我們會盡快處理。', 'Report received. We\'ll review it shortly.');
  static String get reportFailed => _t('檢舉失敗，請稍後再試', 'Report failed. Please try again.');
  static String get reportNeedLogin => _t('檢舉', 'report');
  // 檢舉原因選項
  static String get reasonScam => _t('懷疑詐騙', 'Suspected scam');
  static String get reasonFake => _t('仿冒 / 假貨', 'Counterfeit / fake');
  static String get reasonProhibited => _t('違禁 / 違法物品', 'Prohibited / illegal item');
  static String get reasonOffensive => _t('冒犯 / 不當內容', 'Offensive / inappropriate');
  static String get reasonSpam => _t('垃圾訊息 / 廣告', 'Spam / advertising');
  static String get reasonHarassment => _t('騷擾 / 辱罵', 'Harassment / abuse');
  static String get reasonOther => _t('其他', 'Other');

  static String get block => _t('封鎖', 'Block');
  static String get unblock => _t('解除封鎖', 'Unblock');
  static String blockConfirm(String name) =>
      _t('確定要封鎖 $name 嗎？\n你將不再看到對方的掛售與訊息。',
        'Block $name?\nYou will no longer see their listings or messages.');
  static String get blocked => _t('已封鎖', 'Blocked');
  static String get unblocked => _t('已解除封鎖', 'Unblocked');
  static String get blockNeedLogin => _t('封鎖用戶', 'block users');
  static String get blockedUsers => _t('封鎖的用戶', 'Blocked users');
  static String get noBlockedUsers => _t('沒有封鎖任何用戶', 'No blocked users');

  // ── Coach mark ─────────────────────────────────────────────────────────
  static String coachStep(int cur, int total) => _t('步驟 $cur / $total', 'Step $cur / $total');
  static String get coachSkip => _t('跳過引導', 'Skip tour');
  static String get coachDone => _t('完成引導 🎉', 'Done 🎉');
  static String get coachNext => _t('下一步  →', 'Next  →');

  // ── Pokémon Dex ────────────────────────────────────────────────────────
  static String get pokemonBack => _t('精靈', 'Pokémon');
  static String get pokemonDexTitle => _t('精靈圖鑑', 'Pokémon Dex');
  static String get searchPokemonHint => _t('搜尋精靈名稱或編號...', 'Search Pokémon name or number...');
  static String pokemonCount(int n) => _t('共 $n 隻精靈', '$n Pokémon');
  static String get noPokemon => _t('找不到精靈', 'No Pokémon found');
  static String noCardsForPokemon(String name) =>
      _t('找不到「$name」相關卡片', 'No cards found for "$name"');
  static String get pokemonNotInDb => _t('資料庫可能未收錄此精靈', 'This Pokémon may not be in our database yet');
  // Pokémon name by current locale
  static String pokemonName(Map<String, dynamic> p) =>
      _en ? (p['en'] as String? ?? '') : (p['zh'] as String? ?? p['en'] as String? ?? '');
}
