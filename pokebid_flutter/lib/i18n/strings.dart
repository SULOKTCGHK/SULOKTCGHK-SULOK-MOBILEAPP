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
}
