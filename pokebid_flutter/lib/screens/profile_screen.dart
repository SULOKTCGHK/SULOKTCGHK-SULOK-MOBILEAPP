import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';
import '../services/listing_service.dart';
import '../services/profile_service.dart';
import '../models/card_model.dart';
import 'auth/login_screen.dart';
import 'received_offers_screen.dart';
import 'card_detail_screen.dart';
import 'edit_profile_screen.dart';
import 'conversations_list_screen.dart';
import 'legal_screen.dart';
import '../widgets/unread_dot.dart';
import '../services/notification_service.dart';

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
  bool _loadingCollection = false;

  // Real profile
  UserProfile? _profile;
  bool _loadingProfile = false;

  // My listings
  List<PokemonCard> _myListings = [];
  bool _loadingMyListings = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadPrefs();
    _loadCollection();
    _loadMyListings();
    _loadProfile();
    // Reload listings when switching to tab 0
    _tabCtrl.addListener(() {
      if (_tabCtrl.index == 0) _loadMyListings();
    });
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

  Future<void> _deactivateListing(PokemonCard card) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('下架商品', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('確定要下架「${card.name}」嗎？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('確認下架'),
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
          Text('編輯「${card.name}」',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          const Text('價格 (NT\$)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: Color(0xFF374151))),
          const SizedBox(height: 8),
          TextField(
            controller: priceCtrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixText: 'NT\$ ',
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
              child: const Text('儲存', style: TextStyle(fontSize: 15,
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
    final value = await SupabaseService.getCollectionTotalValue();
    if (mounted) setState(() {
      _collection = items;
      _collectionValue = value;
      _loadingCollection = false;
    });
  }

  String _fmt(int p) => p.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('登出'),
        content: const Text('確定要登出嗎？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('登出', style: TextStyle(color: Color(0xFFE74C3C))),
          ),
        ],
      ),
    );
    if (confirm == true) {
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
    final displayName = _profile?.displayName ?? (isLoggedIn ? AuthService.displayName : '訪客');
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
        title: const Text('我的',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500,
                color: Color(0xFF111827))),
        actions: [
          if (isLoggedIn && _profile != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Color(0xFF9CA3AF), size: 20),
              onPressed: _openEditProfile,
              tooltip: '編輯個人資料',
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
                      Text(displayName,
                          style: const TextStyle(fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827))),
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
                        child: const Text('登入',
                            style: TextStyle(fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white)),
                      ),
                    ),
                ]),
                const SizedBox(height: 16),

                // Stats
                Row(children: [
                  _statItem('掛售中', '${_myListings.length}'),
                  _divider(),
                  _statItem('收藏', '${_collection.length}'),
                  _divider(),
                  _statItem('收藏價值', 'NT\$${_fmt(_collectionValue)}'),
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
              tabs: const [
                Tab(text: '我的掛售'),
                Tab(text: '我的收藏'),
                Tab(text: '設定'),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildMyListings(),
                _buildMyCollection(),
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
      return const Center(child: Text('請先登入以查看掛售商品',
          style: TextStyle(color: Color(0xFF9CA3AF))));
    }
    if (_loadingMyListings) {
      return const Center(child: CircularProgressIndicator(
          color: Color(0xFFE8A52A), strokeWidth: 2));
    }
    if (_myListings.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sell_outlined, size: 48, color: Color(0xFFD1D5DB)),
            SizedBox(height: 12),
            Text('尚未掛售任何商品', style: TextStyle(color: Color(0xFF9CA3AF))),
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
                Text('NT\$${_fmt(card.price)}',
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
                    child: const Text('編輯', style: TextStyle(fontSize: 11,
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
                    child: const Text('下架', style: TextStyle(fontSize: 11,
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
        const Text('尚無收藏',
            style: TextStyle(fontSize: 15, color: Color(0xFF9CA3AF))),
        const SizedBox(height: 6),
        const Text('前往圖鑑加入收藏',
            style: TextStyle(fontSize: 13, color: Color(0xFFD1D5DB))),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _collection.length,
      itemBuilder: (_, i) {
        final item = _collection[i];
        final price = (item['estimated_price_ntd'] as int?) ?? 0;
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
              decoration: BoxDecoration(
                color: const Color(0xFFFEF9EC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                  child: Text('🎴', style: TextStyle(fontSize: 24))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item['card_name'] as String? ?? '',
                  style: const TextStyle(fontSize: 14,
                      fontWeight: FontWeight.w500, color: Color(0xFF111827))),
              Text(item['set_name'] as String? ?? '',
                  style: const TextStyle(fontSize: 12,
                      color: Color(0xFF9CA3AF))),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              if (price > 0)
                Text('NT\$ ${_fmt(price)}',
                    style: const TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF16A34A))),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () async {
                  await SupabaseService.removeFromCollection(
                      item['card_id'] as String);
                  _loadCollection();
                },
                child: const Icon(Icons.bookmark_remove_outlined,
                    size: 18, color: Color(0xFFD1D5DB)),
              ),
            ]),
          ]),
        );
      },
    );
  }

  Widget _buildSettings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 交易
        _sectionHeader('交易'),
        _settingCard(children: [
          _arrowTile(
            icon: Icons.forum_outlined,
            iconColor: const Color(0xFF2980B9),
            title: '我的訊息',
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
            title: '收到的出價',
            trailing: '',
            unreadTypes: const ['offer_received'],
            onTap: () {
              NotificationService.markReadByTypes(['offer_received']);
              Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const ReceivedOffersScreen()));
            },
          ),
        ]),

        const SizedBox(height: 16),

        // 帳號資訊
        _sectionHeader('帳號'),
        _settingCard(children: [
          _arrowTile(
            icon: Icons.person_outline,
            iconColor: const Color(0xFFE8A52A),
            title: '編輯個人資料',
            trailing: _profile != null ? '@${_profile!.username}' : '',
            onTap: _profile != null ? _openEditProfile : () {},
          ),
        ]),

        const SizedBox(height: 16),

        // 通知
        _sectionHeader('通知設定'),
        _settingCard(children: [
          _switchTile(
            icon: Icons.chat_bubble_outline,
            iconColor: const Color(0xFF2980B9),
            title: '新訊息通知',
            subtitle: '收到買家訊息時通知',
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
            title: '收藏價格提醒',
            subtitle: '收藏卡牌市價變動時通知',
            value: _notifyPriceDrop,
            onChanged: (v) {
              setState(() => _notifyPriceDrop = v);
              _savePrefs();
            },
          ),
        ]),

        const SizedBox(height: 16),

        // 語言
        _sectionHeader('語言'),
        _settingCard(children: [
          _arrowTile(
            icon: Icons.language,
            iconColor: const Color(0xFF8E44AD),
            title: '顯示語言',
            trailing: _language,
            onTap: _showLanguagePicker,
          ),
        ]),

        const SizedBox(height: 16),

        // 關於
        _sectionHeader('關於'),
        _settingCard(children: [
          _arrowTile(icon: Icons.info_outline, iconColor: const Color(0xFF6B7280),
              title: '版本', trailing: 'v1.0.0', onTap: () {}),
          const Divider(height: 0.5, color: Color(0xFFF3F4F6)),
          _arrowTile(icon: Icons.shield_outlined, iconColor: const Color(0xFF6B7280),
              title: '隱私政策', trailing: '', onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => LegalScreen.privacy()))),
          const Divider(height: 0.5, color: Color(0xFFF3F4F6)),
          _arrowTile(icon: Icons.description_outlined, iconColor: const Color(0xFF6B7280),
              title: '使用條款', trailing: '', onTap: () => Navigator.push(context,
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
                border: Border.all(color: const Color(0xFFE74C3C).withOpacity(0.3),
                    width: 0.5),
              ),
              child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, color: Color(0xFFE74C3C), size: 18),
                    SizedBox(width: 8),
                    Text('登出帳號',
                        style: TextStyle(fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFE74C3C))),
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
            const Text('選擇語言', style: TextStyle(fontSize: 16,
                fontWeight: FontWeight.w600, color: Color(0xFF111827))),
            const SizedBox(height: 12),
            ...['繁體中文', '简体中文', '日本語', 'English'].map((lang) =>
                GestureDetector(
                  onTap: () {
                    setState(() => _language = lang);
                    _savePrefs();
                    Navigator.pop(context);
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
