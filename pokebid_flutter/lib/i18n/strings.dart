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
      _t('如對本文件有任何疑問，請透過 PokeBid 內的客服管道或電子郵件與我們聯絡。',
        'If you have any questions about this document, please contact us through PokeBid\'s in-app support channel or by email.');
}
