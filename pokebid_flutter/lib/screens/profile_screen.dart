import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';
import '../services/listing_service.dart';
import '../services/offer_service.dart';
import '../services/profile_service.dart';
import '../models/card_model.dart';
import 'auth/login_screen.dart';
import 'received_offers_screen.dart';
import 'followed_sellers_screen.dart';
import 'card_detail_screen.dart';
import 'edit_profile_screen.dart';
import 'conversations_list_screen.dart';
import 'legal_screen.dart';
import '../widgets/unread_dot.dart';
import '../services/push_service.dart';
import '../i18n/locale_controller.dart';
import '../i18n/strings.dart';
import '../widgets/verified_badge.dart';
import '../widgets/ig_link.dart';
import '../widgets/login_required.dart';
import 'phone_verify_screen.dart';
import 'admin/admin_screen.dart';
import '../services/admin_service.dart';
import '../services/notification_service.dart';
import '../services/review_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _notifyNewMsg = true;
  bool _notifyPriceDrop = true;
  String _language = '繁體中文';
  List<Map<String, dynamic>> _collection = [];
  int _collectionValue = 0;
  Map<String, dynamic> _summary = {};
  bool _isAdmin = false;
  bool _loadingCollection = false;
  bool _refreshingMarket = false;
  int _colTab = 0; // 0 持有中 / 1 已售出

  // Real profile
  UserProfile? _profile;
  bool _loadingProfile = false;

  // My listings
  List<PokemonCard> _myListings = [];
  bool _loadingMyListings = false;

  // My reviews
  List<Review> _reviews = [];
  bool _loadingReviews = false;

  // Transaction history
  List<PokemonCard> _soldListings = [];
  List<Map<String, dynamic>> _purchases = [];
  bool _loadingTx = false;
  int _txTab = 0; // 0 售出 / 1 買入

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 1, vsync: this);
    _loadPrefs();
    _loadCollection();
    _loadMyListings();
    _loadProfile();
    _loadReviews();
    _loadTxHistory();
    AdminService.isAdmin().then((v) { if (mounted) setState(() => _isAdmin = v); });
  }

  Future<void> _loadProfile() async {
    if (!AuthService.isLoggedIn) return;
    setState(() => _loadingProfile = true);
    final p = await ProfileService.getOrCreateMyProfile();
    if (mounted) setState(() { _profile = p; _loadingProfile = false; });
  }

  void _openEditProfile() async {
    if (_profile == null) return;
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => EditProfileScreen(
        profile: _profile!,
        onSaved: _loadProfile,
      ),
    ));
  }

  Future<void> _loadMyListings() async {
    if (!AuthService.isLoggedIn) return;
    setState(() => _loadingMyListings = true);
    try {
      final res = await ListingService.getMyListings(AuthService.userId);
      if (mounted) setState(() => _myListings = res);
    } finally {
      if (mounted) setState(() => _loadingMyListings = false);
    }
  }

  Future<void> _loadReviews() async {
    if (!AuthService.isLoggedIn) return;
    setState(() => _loadingReviews = true);
    try {
      final res = await ReviewService.getForSeller(AuthService.userId);
      if (mounted) setState(() => _reviews = res);
    } finally {
      if (mounted) setState(() => _loadingReviews = false);
    }
  }

  Future<void> _loadTxHistory() async {
    if (!AuthService.isLoggedIn) return;
    setState(() => _loadingTx = true);
    try {
      final sold = await ListingService.getMySoldListings(AuthService.userId);
      final bought = await OfferService.getMyPurchases();
      if (mounted) setState(() { _soldListings = sold; _purchases = bought; });
    } finally {
      if (mounted) setState(() => _loadingTx = false);
    }
  }

  Future<void> _deactivateListing(PokemonCard card) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(L.delistTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(L.delistConfirm(card.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text(L.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(L.confirmDelist),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ListingService.deactivateListing(card.supabaseId!);
    _loadMyListings();
  }

  Future<void> _editListing(PokemonCard card) async {
    final priceCtrl = TextEditingController(text: card.price.toString());
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text(L.editItemTitle(card.name),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          Text(L.priceLabel,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: Color(0xFF374151))),
          const SizedBox(height: 8),
          TextField(
            controller: priceCtrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixText: 'HK\$ ',
              filled: true, fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE8A52A), width: 1.5)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final price = int.tryParse(priceCtrl.text.trim());
                if (price == null || price <= 0) return;
                await ListingService.updateListingPrice(card.supabaseId!, price);
                if (context.mounted) Navigator.pop(context);
                _loadMyListings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE8A52A),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text(L.save, style: const TextStyle(fontSize: 15,
                  fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifyNewMsg = prefs.getBool('notify_msg') ?? true;
      _notifyPriceDrop = prefs.getBool('notify_price') ?? true;
      _language = prefs.getString('language') ?? '繁體中文';
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notify_msg', _notifyNewMsg);
    await prefs.setBool('notify_price', _notifyPriceDrop);
    await prefs.setString('language', _language);
  }

  Future<void> _loadCollection() async {
    setState(() => _loadingCollection = true);
    final items = await SupabaseService.getCollection();
    final summary = await SupabaseService.getCollectionSummary();
    if (mounted) setState(() {
      _collection = items;
      _summary = summary;
      _collectionValue = ((summary['value'] as num?) ?? 0).round();
      _loadingCollection = false;
    });
  }

  Future<void> _refreshMarket() async {
    if (_refreshingMarket) return;
    setState(() => _refreshingMarket = true);
    final n = await SupabaseService.refreshCollectionMarket();
    await _loadCollection();
    if (mounted) {
      setState(() => _refreshingMarket = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(L.marketUpdated(n)), duration: const Duration(seconds: 2)));
    }
  }

  String _fmt(int p) => p.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  Future<void> _deleteAccount() async {
    // 第一步：輸入確認文字
    final confirmCtrl = TextEditingController();
    final typed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(L.deleteAccount, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFE74C3C))),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(L.deleteAccountWarning, style: const TextStyle(fontSize: 13.5, height: 1.5, color: Color(0xFF374151))),
            const SizedBox(height: 16),
            Text(L.deleteAccountPrompt, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: confirmCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: L.deleteConfirmWord,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(L.cancel)),
            ElevatedButton(
              onPressed: confirmCtrl.text == L.deleteConfirmWord ? () => Navigator.pop(ctx, true) : null,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE74C3C), foregroundColor: Colors.white),
              child: Text(L.permanentDelete),
            ),
          ],
        ),
      ),
    );
    confirmCtrl.dispose();
    if (typed != true || !mounted) return;

    // 第二步：執行刪除
    try {
      await AuthService.deleteAccount();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(L.deleteFailed('$e')),
          backgroundColor: const Color(0xFFE74C3C),
        ));
      }
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(L.logout),
        content: Text(L.logoutConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text(L.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(L.logout, style: const TextStyle(color: Color(0xFFE74C3C))),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await PushService.clearToken();
      await AuthService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = AuthService.isLoggedIn;
    final displayName = _profile?.displayName ?? (isLoggedIn ? AuthService.displayName : L.guest);
    final username = _profile?.username ?? '';
    final avatarEmoji = _profile?.avatarEmoji ?? '🎴';
    final bio = _profile?.bio ?? '';
    final igHandle = _profile?.igHandle ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: const Color(0xFFE5E7EB)),
        ),
        titleSpacing: 16,
        title: Text(L.navMe,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500,
                color: Color(0xFF111827))),
        actions: [
          if (isLoggedIn && _profile != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Color(0xFF9CA3AF), size: 20),
              onPressed: _openEditProfile,
              tooltip: L.editProfile,
            ),
          if (isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout, color: Color(0xFF9CA3AF), size: 20),
              onPressed: _signOut,
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Profile header ─────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(children: [
                  // Emoji avatar
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF9EC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
                    ),
                    child: Center(child: _loadingProfile
                        ? const SizedBox(width: 24, height: 24,
                            child: CircularProgressIndicator(
                                color: Color(0xFFE8A52A), strokeWidth: 2))
                        : Text(isLoggedIn ? avatarEmoji : '👤',
                            style: const TextStyle(fontSize: 34))),
                  ),
                  const SizedBox(width: 14),

                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Flexible(child: Text(displayName,
                            style: const TextStyle(fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827)),
                            maxLines: 1, overflow: TextOverflow.ellipsis)),
                        if (_profile?.phoneVerified ?? false) ...[
                          const SizedBox(width: 5),
                          const VerifiedBadge(size: 14, showLabel: true),
                        ],
                        if ((_profile?.igHandle ?? '').trim().isNotEmpty) ...[
                          const SizedBox(width: 5),
                          IgLink(handle: _profile!.igHandle, size: 15),
                        ],
                      ]),
                      if (_reviews.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFE8A52A), size: 14),
                          const SizedBox(width: 2),
                          Text(
                            '${(_reviews.fold<int>(0, (s, r) => s + r.rating) / _reviews.length).toStringAsFixed(1)}  (${_reviews.length})',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                          ),
                        ]),
                      ],
                      if (username.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text('@$username',
                            style: const TextStyle(fontSize: 12,
                                color: Color(0xFF9CA3AF))),
                      ],
                      if (bio.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(bio, maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12,
                                color: Color(0xFF6B7280))),
                      ],
                      if (igHandle.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(children: [
                          const Icon(Icons.camera_alt_outlined, size: 12,
                              color: Color(0xFF9CA3AF)),
                          const SizedBox(width: 3),
                          Text('@$igHandle',
                            style: const TextStyle(fontSize: 12,
                                color: Color(0xFF9CA3AF))),
                        ]),
                      ],
                    ],
                  )),

                  // Login button if not logged in
                  if (!isLoggedIn)
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const LoginScreen())),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8A52A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(L.login,
                            style: const TextStyle(fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white)),
                      ),
                    ),
                ]),
                const SizedBox(height: 16),

                // Stats
                Row(children: [
                  _statItem(L.statListing, '${_myListings.length}'),
                  _divider(),
                  _statItem(L.statCollection, '${_collection.length}'),
                  _divider(),
                  _statItem(L.statCollectionValue, 'HK\$${_fmt(_collectionValue)}'),
                ]),
              ],
            ),
          ),

          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabCtrl,
              labelColor: const Color(0xFFE8A52A),
              unselectedLabelColor: const Color(0xFF6B7280),
              indicatorColor: const Color(0xFFE8A52A),
              indicatorWeight: 2,
              labelStyle: const TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w500),
              tabs: [
                Tab(text: L.settings),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildSettings(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) => Expanded(
    child: Column(children: [
      Text(value, style: const TextStyle(fontSize: 16,
          fontWeight: FontWeight.w600, color: Color(0xFF111827))),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 11,
          color: Color(0xFF9CA3AF))),
    ]),
  );

  Widget _divider() => Container(
      width: 0.5, height: 28, color: const Color(0xFFE5E7EB));

  Widget _buildMyListings() {
    if (!AuthService.isLoggedIn) {
      return Center(child: Text(L.loginToViewListings,
          style: const TextStyle(color: Color(0xFF9CA3AF))));
    }
    if (_loadingMyListings) {
      return const Center(child: CircularProgressIndicator(
          color: Color(0xFFE8A52A), strokeWidth: 2));
    }
    if (_myListings.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sell_outlined, size: 48, color: Color(0xFFD1D5DB)),
            const SizedBox(height: 12),
            Text(L.noListingsYet, style: const TextStyle(color: Color(0xFF9CA3AF))),
          ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myListings.length,
      itemBuilder: (_, i) {
        final card = _myListings[i];
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => CardDetailScreen(
                card: card, isFavorited: false, onFavChanged: (_) {}))),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
            ),
            child: Row(children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: card.imageUrls.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: card.imageUrls.first,
                        width: 56, height: 56, fit: BoxFit.cover,
                        placeholder: (_, __) => _imgPlaceholder(card),
                        errorWidget: (_, __, ___) => _imgPlaceholder(card),
                      )
                    : _imgPlaceholder(card),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(card.name, style: const TextStyle(fontSize: 14,
                    fontWeight: FontWeight.w500, color: Color(0xFF111827))),
                Text('${card.grade} · ${card.timeInfo}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                Text('HK\$${_fmt(card.price)}',
                    style: const TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w700, color: Color(0xFF16A34A))),
              ])),
              // Action buttons
              Column(children: [
                GestureDetector(
                  onTap: () => _editListing(card),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF9EC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE8A52A).withOpacity(0.4)),
                    ),
                    child: Text(L.edit, style: const TextStyle(fontSize: 11,
                        fontWeight: FontWeight.w500, color: Color(0xFFE8A52A))),
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => _deactivateListing(card),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE74C3C).withOpacity(0.4)),
                    ),
                    child: Text(L.delist, style: const TextStyle(fontSize: 11,
                        fontWeight: FontWeight.w500, color: Color(0xFFE74C3C))),
                  ),
                ),
              ]),
            ]),
          ),
        );
      },
    );
  }

  Widget _imgPlaceholder(PokemonCard card) => Container(
    width: 56, height: 56,
    color: card.type.bgColor,
    child: Center(child: Text(card.type.emoji,
        style: const TextStyle(fontSize: 24))),
  );

  // 我的掛售頁（供 Navigator.push 用）
  Widget _myListingsPage() => Scaffold(
    backgroundColor: const Color(0xFFF5F6FA),
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.chevron_left, color: Color(0xFF374151), size: 28),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(L.myListings, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
      bottom: PreferredSize(preferredSize: const Size.fromHeight(0.5),
        child: Container(height: 0.5, color: const Color(0xFFE5E7EB))),
    ),
    body: _buildMyListings(),
  );

  Widget _myCollectionPage() => Scaffold(
    backgroundColor: const Color(0xFFF5F6FA),
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.chevron_left, color: Color(0xFF374151), size: 28),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(L.myCollection, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
      bottom: PreferredSize(preferredSize: const Size.fromHeight(0.5),
        child: Container(height: 0.5, color: const Color(0xFFE5E7EB))),
    ),
    body: _buildMyCollection(),
  );

  Widget _myReviewsPage() {
    final avg = _reviews.isEmpty ? 0.0 : _reviews.fold<int>(0, (s, r) => s + r.rating) / _reviews.length;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Color(0xFF374151), size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(L.myReviews, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: const Color(0xFFE5E7EB))),
      ),
      body: _reviews.isEmpty
        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.star_outline, size: 56, color: Color(0xFFD1D5DB)),
            const SizedBox(height: 12),
            Text(L.noReviews, style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))),
          ]))
        : ListView(padding: const EdgeInsets.all(16), children: [
            // 評分摘要
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
              ),
              child: Row(children: [
                Column(children: [
                  Text(avg.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                  Row(children: List.generate(5, (i) => Icon(
                    i < avg.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: const Color(0xFFE8A52A), size: 18))),
                  const SizedBox(height: 4),
                  Text(L.reviewsTotal(_reviews.length), style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                ]),
                const SizedBox(width: 24),
                Expanded(child: Column(children: List.generate(5, (i) {
                  final star = 5 - i;
                  final count = _reviews.where((r) => r.rating == star).length;
                  final pct = count / _reviews.length;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      Text('$star', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                      const SizedBox(width: 4),
                      const Icon(Icons.star_rounded, size: 11, color: Color(0xFFE8A52A)),
                      const SizedBox(width: 6),
                      Expanded(child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(value: pct, minHeight: 6,
                          backgroundColor: const Color(0xFFF3F4F6), color: const Color(0xFFE8A52A)),
                      )),
                      const SizedBox(width: 6),
                      Text('$count', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                    ]),
                  );
                }))),
              ]),
            ),
            ..._reviews.map((r) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _reviewTile(r))),
          ]),
    );
  }

  Widget _txHistoryPage() => Scaffold(
    backgroundColor: const Color(0xFFF5F6FA),
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.chevron_left, color: Color(0xFF374151), size: 28),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(L.txHistory, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
      bottom: PreferredSize(preferredSize: const Size.fromHeight(0.5),
        child: Container(height: 0.5, color: const Color(0xFFE5E7EB))),
    ),
    body: _buildTxHistory(),
  );

  Widget _buildMyCollection() {
    if (_loadingCollection) {
      return const Center(child: CircularProgressIndicator(
          color: Color(0xFFE8A52A), strokeWidth: 2));
    }
    if (_collection.isEmpty) {
      return Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.collections_bookmark_outlined,
            size: 48, color: Color(0xFFD1D5DB)),
        const SizedBox(height: 12),
        Text(L.noCollection,
            style: const TextStyle(fontSize: 15, color: Color(0xFF9CA3AF))),
        const SizedBox(height: 6),
        Text(L.goToDexToCollect,
            style: const TextStyle(fontSize: 13, color: Color(0xFFD1D5DB))),
      ]));
    }
    final rate = (_summary['rate'] as num?)?.toDouble() ?? 0.0515;
    final holding = _collection.where((e) => (e['status'] as String?) != 'sold').toList();
    final sold = _collection.where((e) => (e['status'] as String?) == 'sold').toList();
    final list = _colTab == 0 ? holding : sold;
    return Column(children: [
      _plSummaryCard(),
      // 持有中 / 已售出 切換
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Row(children: [
          _colSeg(L.holdingCount(holding.length), 0),
          const SizedBox(width: 8),
          _colSeg(L.soldCountSeg(sold.length), 1),
        ]),
      ),
      Expanded(
        child: list.isEmpty
            ? Center(child: Text(_colTab == 0 ? L.noHolding : L.noSoldRecord,
                style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: list.length,
                itemBuilder: (_, i) => _collectionItem(list[i], rate),
              ),
      ),
    ]);
  }

  Widget _colSeg(String label, int idx) {
    final sel = _colTab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _colTab = idx),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: sel ? const Color(0xFFE8A52A) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8)),
          child: Text(label, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                  color: sel ? Colors.white : const Color(0xFF6B7280))),
        ),
      ),
    );
  }

  Widget _collectionItem(Map<String, dynamic> item, double rate) {
    final grade = (item['grade'] as String?) ?? 'RAW';
    final costHkd = ((item['cost_hkd'] as num?)?.toDouble() ?? 0);
    final isSold = (item['status'] as String?) == 'sold';
    final soldHkd = ((item['sold_price_hkd'] as num?)?.toDouble() ?? 0);
    final marketHkd = ((item['market_jpy'] as num?)?.toDouble() ?? 0) * rate;
    // 已售出 → 已實現盈虧(售價-成本)；持有中 → 未實現(市值-成本)
    final refVal = isSold ? soldHkd : marketHkd;
    final pl = refVal - costHkd;
    final up = pl >= 0;
    final gradeColor = grade == 'PSA10'
        ? const Color(0xFFE8A52A)
        : grade == 'PSA9' ? const Color(0xFF2980B9) : const Color(0xFF6B7280);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: const Color(0xFFFEF9EC), borderRadius: BorderRadius.circular(10)),
          child: const Center(child: Text('🎴', style: TextStyle(fontSize: 24))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(child: Text(item['card_name'] as String? ?? '',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF111827)))),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(color: gradeColor.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
              child: Text(grade == 'RAW' ? L.rawCard : grade,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: gradeColor)),
            ),
          ]),
          const SizedBox(height: 2),
          Text(L.costHkd(_fmt(costHkd.round())),
              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          if (isSold)
            Text(L.soldOn((item['sold_at'] as String?)?.split('T').first ?? ''),
                style: const TextStyle(fontSize: 10.5, color: Color(0xFFB6BCC6))),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('HK\$${_fmt(refVal.round())}',
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          Text('${up ? '+' : '-'}HK\$${_fmt(pl.abs().round())}',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: up ? const Color(0xFF16A34A) : const Color(0xFFDC2626))),
          const SizedBox(height: 3),
          Row(mainAxisSize: MainAxisSize.min, children: [
            if (!isSold) ...[
              GestureDetector(
                onTap: () => _sellItem(item),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFF16A34A), borderRadius: BorderRadius.circular(6)),
                  child: Text(L.sellAction, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 6),
            ],
            GestureDetector(
              onTap: () async {
                await SupabaseService.removeFromCollection(item['card_id'] as String, grade: grade);
                _loadCollection();
              },
              child: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFD1D5DB)),
            ),
          ]),
        ]),
      ]),
    );
  }

  Future<void> _sellItem(Map<String, dynamic> item) async {
    final rate = (_summary['rate'] as num?)?.toDouble() ?? 0.0515;
    final marketHkd = (((item['market_jpy'] as num?)?.toDouble() ?? 0) * rate).round();
    final costHkd = ((item['cost_hkd'] as num?)?.toDouble() ?? 0).round();
    final ctrl = TextEditingController(text: marketHkd > 0 ? '$marketHkd' : '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(L.recordSellTitle('${item['card_name'] ?? ''}'), style: const TextStyle(fontSize: 15)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(L.costAndMarket(_fmt(costHkd), _fmt(marketHkd)),
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: L.actualSalePrice, prefixText: 'HK\$ ', isDense: true),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(L.cancel)),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(L.confirmSell)),
        ],
      ),
    );
    if (ok != true) return;
    final price = num.tryParse(ctrl.text.trim()) ?? 0;
    await SupabaseService.markSold(
        item['card_id'] as String, (item['grade'] as String?) ?? 'RAW', price);
    await _loadCollection();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(L.saleRecorded), duration: const Duration(seconds: 2)));
    }
  }

  Widget _plSummaryCard() {
    final cost = ((_summary['cost'] as num?) ?? 0).round();
    final value = ((_summary['value'] as num?) ?? 0).round();
    final pl = ((_summary['pl'] as num?) ?? 0).round();
    final plPct = ((_summary['plPct'] as num?) ?? 0).toDouble();
    final up = pl >= 0;
    final plColor = up ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1F2937), Color(0xFF111827)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(L.collectionTotalValue, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
          const Spacer(),
          GestureDetector(
            onTap: _refreshMarket,
            child: Row(children: [
              _refreshingMarket
                  ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFFE8A52A)))
                  : const Icon(Icons.refresh, size: 14, color: Color(0xFFE8A52A)),
              const SizedBox(width: 3),
              Text(L.updateMarket, style: const TextStyle(fontSize: 11, color: Color(0xFFE8A52A))),
            ]),
          ),
        ]),
        const SizedBox(height: 6),
        Text('HK\$${_fmt(value)}',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _plMini(L.totalCost, 'HK\$${_fmt(cost)}', Colors.white70)),
          Expanded(child: _plMini(L.profitLoss, '${up ? '+' : '-'}HK\$${_fmt(pl.abs())}', plColor)),
          Expanded(child: _plMini(L.returnRate, '${up ? '+' : ''}${plPct.toStringAsFixed(1)}%', plColor)),
        ]),
        if (((_summary['soldCount'] as int?) ?? 0) > 0) ...[
          const SizedBox(height: 10),
          Container(height: 0.5, color: const Color(0xFF374151)),
          const SizedBox(height: 8),
          Builder(builder: (_) {
            final realized = ((_summary['realized'] as num?) ?? 0).round();
            final rUp = realized >= 0;
            final rColor = rUp ? const Color(0xFF34D399) : const Color(0xFFF87171);
            return Row(children: [
              Text(L.soldCards(_summary['soldCount']), style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
              const Spacer(),
              Text(L.realizedPl(rUp ? '+' : '-', _fmt(realized.abs())),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: rColor)),
            ]);
          }),
        ],
        const SizedBox(height: 4),
        Text(L.marketRateNote((_summary['rate'] as num? ?? 0.0515).toStringAsFixed(4)),
            style: const TextStyle(fontSize: 9.5, color: Color(0xFF6B7280))),
      ]),
    );
  }

  Widget _plMini(String label, String value, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
    ]);
  }

  Widget _reviewTile(Review r) {
    final deliveryLabel = switch (r.deliveryMethod) {
      'meetup' => L.deliveryMeetup,
      'sf' => L.deliverySf,
      'other' => L.deliveryOther,
      _ => null,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFE8A52A).withOpacity(0.15),
            child: Text(r.reviewerName.substring(0, 1).toUpperCase(),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFB45309))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.reviewerName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
            Row(children: [
              ...List.generate(5, (i) => Icon(
                i < r.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                color: const Color(0xFFE8A52A), size: 14)),
              if (deliveryLabel != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(deliveryLabel, style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
                ),
              ],
            ]),
          ])),
          Text(_reviewDate(r.createdAt), style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
        ]),
        if (r.comment != null && r.comment!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(r.comment!, style: const TextStyle(fontSize: 13, color: Color(0xFF374151), height: 1.5)),
        ],
      ]),
    );
  }

  String _reviewDate(DateTime dt) {
    return '${dt.year}/${dt.month.toString().padLeft(2,'0')}/${dt.day.toString().padLeft(2,'0')}';
  }

  // ── Transaction History Tab ───────────────────────────────────────────────
  Widget _buildTxHistory() {
    return Column(children: [
      // 售出 / 買入 切換
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Container(
          decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.all(3),
          child: Row(children: [
            _txSeg(L.soldRecords(_soldListings.length), 0),
            _txSeg(L.purchaseRecords(_purchases.length), 1),
          ]),
        ),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: _loadingTx
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE8A52A), strokeWidth: 2))
          : _txTab == 0 ? _buildSoldList() : _buildBoughtList(),
      ),
    ]);
  }

  Widget _txSeg(String label, int idx) => Expanded(
    child: GestureDetector(
      onTap: () => setState(() { _txTab = idx; _loadTxHistory(); }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: _txTab == idx ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: _txTab == idx ? [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 4)] : [],
        ),
        child: Text(label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.5, fontWeight: FontWeight.w600,
            color: _txTab == idx ? const Color(0xFF111827) : const Color(0xFF9CA3AF),
          )),
      ),
    ),
  );

  Widget _buildSoldList() {
    if (_soldListings.isEmpty) {
      return Center(child: Text(L.noSoldRecords, style: const TextStyle(color: Color(0xFF9CA3AF))));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _soldListings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final c = _soldListings[i];
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => CardDetailScreen(card: c, isFavorited: false, onFavChanged: (_) {}),
          )),
          child: _txCard(
            imageUrls: c.imageUrls,
            name: c.name,
            sub: L.salePrice(c.price),
            tag: L.tagSold,
            tagColor: const Color(0xFF16A34A),
          ),
        );
      },
    );
  }

  Widget _buildBoughtList() {
    if (_purchases.isEmpty) {
      return Center(child: Text(L.noPurchaseRecords, style: const TextStyle(color: Color(0xFF9CA3AF))));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _purchases.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final p = _purchases[i];
        final listing = p['listings'] as Map<String, dynamic>?;
        final name = listing?['name'] as String? ?? L.productFallback;
        final imageUrls = (listing?['image_urls'] as List?)?.cast<String>() ?? [];
        final sellerName = listing?['seller_name'] as String? ?? '';
        final amount = p['amount'] as int? ?? 0;
        final listingId = p['listing_id'] as String?;
        return GestureDetector(
          onTap: listingId == null ? null : () async {
            final card = await ListingService.getListingById(listingId);
            if (card != null && mounted) {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => CardDetailScreen(card: card, isFavorited: false, onFavChanged: (_) {}),
              ));
            }
          },
          child: _txCard(
            imageUrls: imageUrls,
            name: name,
            sub: L.purchasePrice(amount, sellerName.isNotEmpty ? L.sellerSuffix(sellerName) : ''),
            tag: L.tagPurchased,
            tagColor: const Color(0xFF2980B9),
          ),
        );
      },
    );
  }

  Widget _txCard({
    required List<String> imageUrls,
    required String name,
    required String sub,
    required String tag,
    required Color tagColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: imageUrls.isNotEmpty
            ? Image.network(imageUrls.first, width: 56, height: 56, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _txImgPlaceholder())
            : _txImgPlaceholder(),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
          const SizedBox(height: 3),
          Text(sub, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: tagColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
          child: Text(tag, style: TextStyle(fontSize: 11, color: tagColor, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _txImgPlaceholder() => Container(
    width: 56, height: 56, color: const Color(0xFFF3F4F6),
    child: const Icon(Icons.image_not_supported_outlined, size: 24, color: Color(0xFFD1D5DB)),
  );

  Widget _buildSettings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 我的功能入口
        _sectionHeader(L.sectionMine),
        _settingCard(children: [
          _arrowTile(
            icon: Icons.storefront_outlined,
            iconColor: const Color(0xFFE8A52A),
            title: L.myListings,
            trailing: L.itemsCount(_myListings.length),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _myListingsPage())),
          ),
          const Divider(height: 0.5, color: Color(0xFFF3F4F6)),
          _arrowTile(
            icon: Icons.collections_bookmark_outlined,
            iconColor: const Color(0xFF8E44AD),
            title: L.myCollection,
            trailing: L.cardsCount(_collection.length),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _myCollectionPage())),
          ),
          const Divider(height: 0.5, color: Color(0xFFF3F4F6)),
          _arrowTile(
            icon: Icons.receipt_long_outlined,
            iconColor: const Color(0xFF2980B9),
            title: L.txHistory,
            trailing: L.recordsCount(_soldListings.length + _purchases.length),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _txHistoryPage())),
          ),
          const Divider(height: 0.5, color: Color(0xFFF3F4F6)),
          _arrowTile(
            icon: Icons.star_outline_rounded,
            iconColor: const Color(0xFFE8A52A),
            title: L.myReviews,
            trailing: _reviews.isEmpty ? L.none : L.reviewsSummary((_reviews.fold<int>(0, (s, r) => s + r.rating) / _reviews.length).toStringAsFixed(1), _reviews.length),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _myReviewsPage())),
          ),
        ]),

        const SizedBox(height: 16),

        const SizedBox(height: 4),
        // 交易
        _sectionHeader(L.sectionTrade),
        _settingCard(children: [
          _arrowTile(
            icon: Icons.forum_outlined,
            iconColor: const Color(0xFF2980B9),
            title: L.myMessages,
            trailing: '',
            unreadTypes: const ['message'],
            onTap: () {
              NotificationService.markReadByTypes(['message']);
              Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const ConversationsListScreen()));
            },
          ),
          const Divider(height: 0.5, color: Color(0xFFF3F4F6)),
          _arrowTile(
            icon: Icons.local_offer_outlined,
            iconColor: const Color(0xFF8E44AD),
            title: L.receivedOffers,
            trailing: '',
            unreadTypes: const ['offer_received'],
            onTap: () {
              NotificationService.markReadByTypes(['offer_received']);
              Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const ReceivedOffersScreen()));
            },
          ),
          const Divider(height: 0.5, color: Color(0xFFF3F4F6)),
          _arrowTile(
            icon: Icons.people_outline,
            iconColor: const Color(0xFF16A34A),
            title: L.followedSellers,
            trailing: '',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const FollowedSellersScreen()));
            },
          ),
        ]),

        const SizedBox(height: 16),

        // 帳號資訊
        _sectionHeader(L.sectionAccount),
        _settingCard(children: [
          _arrowTile(
            icon: Icons.person_outline,
            iconColor: const Color(0xFFE8A52A),
            title: L.editProfile,
            trailing: _profile != null ? '@${_profile!.username}' : '',
            onTap: _profile != null ? _openEditProfile : () {},
          ),
          const Divider(height: 0.5, color: Color(0xFFF3F4F6)),
          _arrowTile(
            icon: Icons.verified_outlined,
            iconColor: const Color(0xFF2980B9),
            title: L.phoneVerify,
            trailing: (_profile?.phoneVerified ?? false) ? L.verified : L.notVerified,
            onTap: () async {
              if (!await requireLogin(context, action: L.doPhoneVerify)) return;
              if (!mounted) return;
              final ok = await Navigator.push<bool>(context,
                  MaterialPageRoute(builder: (_) => const PhoneVerifyScreen()));
              if (ok == true) _loadProfile();
            },
          ),
          if (_isAdmin) ...[
            const Divider(height: 0.5, color: Color(0xFFF3F4F6)),
            _arrowTile(
              icon: Icons.admin_panel_settings_outlined,
              iconColor: const Color(0xFFE8A52A),
              title: L.adminPanel,
              trailing: '',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AdminScreen())),
            ),
          ],
        ]),

        const SizedBox(height: 16),

        // 通知
        _sectionHeader(L.sectionNotifySettings),
        _settingCard(children: [
          _switchTile(
            icon: Icons.chat_bubble_outline,
            iconColor: const Color(0xFF2980B9),
            title: L.notifyNewMsg,
            subtitle: L.notifyNewMsgSub,
            value: _notifyNewMsg,
            onChanged: (v) {
              setState(() => _notifyNewMsg = v);
              _savePrefs();
            },
          ),
          const Divider(height: 0.5, color: Color(0xFFF3F4F6)),
          _switchTile(
            icon: Icons.trending_down,
            iconColor: const Color(0xFF27AE60),
            title: L.notifyPriceDrop,
            subtitle: L.notifyPriceDropSub,
            value: _notifyPriceDrop,
            onChanged: (v) {
              setState(() => _notifyPriceDrop = v);
              _savePrefs();
            },
          ),
        ]),

        const SizedBox(height: 16),

        // 語言
        _sectionHeader(L.language),
        _settingCard(children: [
          _arrowTile(
            icon: Icons.language,
            iconColor: const Color(0xFF8E44AD),
            title: L.displayLanguage,
            trailing: _language,
            onTap: _showLanguagePicker,
          ),
        ]),

        const SizedBox(height: 16),

        // 關於
        _sectionHeader(L.about),
        _settingCard(children: [
          _arrowTile(icon: Icons.info_outline, iconColor: const Color(0xFF6B7280),
              title: L.version, trailing: 'v1.0.0', onTap: () {}),
          const Divider(height: 0.5, color: Color(0xFFF3F4F6)),
          _arrowTile(icon: Icons.verified_user_outlined, iconColor: const Color(0xFF16A34A),
              title: L.safetyTips, trailing: '', onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => LegalScreen.safety()))),
          const Divider(height: 0.5, color: Color(0xFFF3F4F6)),
          _arrowTile(icon: Icons.shield_outlined, iconColor: const Color(0xFF6B7280),
              title: L.privacyPolicy, trailing: '', onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => LegalScreen.privacy()))),
          const Divider(height: 0.5, color: Color(0xFFF3F4F6)),
          _arrowTile(icon: Icons.description_outlined, iconColor: const Color(0xFF6B7280),
              title: L.termsOfService, trailing: '', onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => LegalScreen.terms()))),
        ]),

        const SizedBox(height: 16),

        // 登出
        if (AuthService.isLoggedIn) ...[
          GestureDetector(
            onTap: _signOut,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE74C3C).withValues(alpha: 0.3), width: 0.5),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.logout, color: Color(0xFFE74C3C), size: 18),
                const SizedBox(width: 8),
                Text(L.logoutAccountBtn, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFFE74C3C))),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          // 刪除帳號（Apple App Store 要求）
          GestureDetector(
            onTap: _deleteAccount,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE74C3C).withValues(alpha: 0.2), width: 0.5),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.delete_forever_outlined, color: Color(0xFF9CA3AF), size: 18),
                const SizedBox(width: 8),
                Text(L.deleteAccount, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF9CA3AF))),
              ]),
            ),
          ),
        ],

        const SizedBox(height: 100),
      ],
    );
  }

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title, style: const TextStyle(fontSize: 12,
        fontWeight: FontWeight.w500, color: Color(0xFF9CA3AF))),
  );

  Widget _settingCard({required List<Widget> children}) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
    ),
    child: Column(children: children),
  );

  Widget _switchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 14,
                fontWeight: FontWeight.w500, color: Color(0xFF111827))),
            Text(subtitle, style: const TextStyle(fontSize: 11,
                color: Color(0xFF9CA3AF))),
          ])),
          Switch(value: value, onChanged: onChanged,
              activeColor: const Color(0xFFE8A52A)),
        ]),
      );

  Widget _arrowTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String trailing,
    required VoidCallback onTap,
    List<String>? unreadTypes,
  }) =>
      GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(children: [
            Builder(builder: (_) {
              final box = Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 17),
              );
              return unreadTypes != null
                  ? UnreadDot(types: unreadTypes, top: -3, right: -3, child: box)
                  : box;
            }),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 14,
                fontWeight: FontWeight.w500, color: Color(0xFF111827)))),
            if (trailing.isNotEmpty)
              Text(trailing, style: const TextStyle(fontSize: 13,
                  color: Color(0xFF9CA3AF))),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18,
                color: Color(0xFFD1D5DB)),
          ]),
        ),
      );

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(L.selectLanguage, style: const TextStyle(fontSize: 16,
                fontWeight: FontWeight.w600, color: Color(0xFF111827))),
            const SizedBox(height: 12),
            ...['繁體中文', 'English'].map((lang) =>
                GestureDetector(
                  onTap: () async {
                    setState(() => _language = lang);
                    await LocaleController.instance.toggleByLabel(lang);
                    if (mounted) Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 4),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(
                          color: Color(0xFFF3F4F6), width: 0.5)),
                    ),
                    child: Row(children: [
                      Text(lang, style: const TextStyle(fontSize: 14,
                          color: Color(0xFF111827))),
                      const Spacer(),
                      if (_language == lang)
                        const Icon(Icons.check,
                            color: Color(0xFFE8A52A), size: 18),
                    ]),
                  ),
                )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
