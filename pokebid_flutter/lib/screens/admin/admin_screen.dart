import 'package:flutter/material.dart';
import '../../services/announcement_service.dart';
import '../../services/shop_service.dart';
import '../../services/admin_service.dart';
import 'post_announcement_sheet.dart';
import 'shop_form_sheet.dart';
import 'image_admin_tab.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 4, vsync: this);

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0.5,
        foregroundColor: const Color(0xFF111827),
        title: const Text('管理後台', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tab,
          labelColor: const Color(0xFFE8A52A),
          unselectedLabelColor: const Color(0xFF6B7280),
          indicatorColor: const Color(0xFFE8A52A),
          isScrollable: true,
          tabs: const [Tab(text: '公告'), Tab(text: '卡鋪'), Tab(text: '帳號'), Tab(text: '圖片')],
        ),
      ),
      body: TabBarView(controller: _tab, children: const [
        _AnnouncementsTab(), _ShopsTab(), _AccountsTab(), ImageAdminTab(),
      ]),
    );
  }
}

// ── 公告管理 ──────────────────────────────────────────────────────────────────
class _AnnouncementsTab extends StatefulWidget {
  const _AnnouncementsTab();
  @override
  State<_AnnouncementsTab> createState() => _AnnouncementsTabState();
}

class _AnnouncementsTabState extends State<_AnnouncementsTab> {
  List<Announcement> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await AnnouncementService.getAllForAdmin();
    if (mounted) setState(() { _items = r; _loading = false; });
  }

  void _post() {
    showModalBottomSheet(context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PostAnnouncementSheet(onPosted: _load));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFE8A52A),
        onPressed: _post,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('發佈公告', style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE8A52A), strokeWidth: 2))
          : _items.isEmpty
              ? const Center(child: Text('尚無公告', style: TextStyle(color: Color(0xFF9CA3AF))))
              : ListView(padding: const EdgeInsets.all(16), children: _items.map((a) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5)),
                    child: Row(children: [
                      Text(a.icon, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(a.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(a.subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ])),
                      Switch(
                        value: a.isActive,
                        activeColor: const Color(0xFF16A34A),
                        onChanged: (v) async { await AnnouncementService.setActive(a.id, v); _load(); },
                      ),
                      GestureDetector(
                        onTap: () async {
                          final ok = await _confirm(context, '刪除公告「${a.title}」？');
                          if (ok) { await AnnouncementService.deleteAnnouncement(a.id); _load(); }
                        },
                        child: const Padding(padding: EdgeInsets.all(4),
                            child: Icon(Icons.delete_outline, size: 18, color: Color(0xFFD1D5DB))),
                      ),
                    ]),
                  );
                }).toList()),
    );
  }
}

// ── 卡鋪管理 ──────────────────────────────────────────────────────────────────
class _ShopsTab extends StatefulWidget {
  const _ShopsTab();
  @override
  State<_ShopsTab> createState() => _ShopsTabState();
}

class _ShopsTabState extends State<_ShopsTab> {
  List<CardShop> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await ShopService.getShops(includeInactive: true);
    r.sort((a, b) => a.name.compareTo(b.name));
    if (mounted) setState(() { _items = r; _loading = false; });
  }

  void _edit([CardShop? shop]) {
    showModalBottomSheet(context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShopFormSheet(shop: shop, onSaved: _load));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFE8A52A),
        onPressed: () => _edit(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('新增卡鋪', style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE8A52A), strokeWidth: 2))
          : _items.isEmpty
              ? const Center(child: Text('尚無卡鋪，點右下新增', style: TextStyle(color: Color(0xFF9CA3AF))))
              : ListView(padding: const EdgeInsets.all(16), children: _items.map((s) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5)),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(s.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text([s.district, s.address].where((e) => e != null && e.isNotEmpty).join('・'),
                            style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('${s.lat.toStringAsFixed(4)}, ${s.lng.toStringAsFixed(4)}',
                            style: const TextStyle(fontSize: 10.5, color: Color(0xFFB6BCC6))),
                      ])),
                      GestureDetector(onTap: () => _edit(s),
                          child: const Padding(padding: EdgeInsets.all(4),
                              child: Icon(Icons.edit_outlined, size: 18, color: Color(0xFF2980B9)))),
                      GestureDetector(
                        onTap: () async {
                          final ok = await _confirm(context, '刪除「${s.name}」？');
                          if (ok) { await ShopService.deleteShop(s.id); _load(); }
                        },
                        child: const Padding(padding: EdgeInsets.all(4),
                            child: Icon(Icons.delete_outline, size: 18, color: Color(0xFFD1D5DB))),
                      ),
                    ]),
                  );
                }).toList()),
    );
  }
}

// ── 帳號管理（讀取）──────────────────────────────────────────────────────────
class _AccountsTab extends StatefulWidget {
  const _AccountsTab();
  @override
  State<_AccountsTab> createState() => _AccountsTabState();
}

class _AccountsTabState extends State<_AccountsTab> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await AdminService.listProfiles(search: _searchCtrl.text);
    if (mounted) setState(() { _users = r; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: TextField(
          controller: _searchCtrl,
          onSubmitted: (_) => _load(),
          decoration: InputDecoration(
            hintText: '搜尋用戶名 / 顯示名稱',
            prefixIcon: const Icon(Icons.search, size: 20),
            filled: true, fillColor: Colors.white, isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
      ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFE8A52A), strokeWidth: 2))
            : _users.isEmpty
                ? const Center(child: Text('無用戶', style: TextStyle(color: Color(0xFF9CA3AF))))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: _users.length,
                    itemBuilder: (_, i) {
                      final u = _users[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5)),
                        child: Row(children: [
                          CircleAvatar(radius: 18, backgroundColor: const Color(0xFFFEF9EC),
                              child: Text(u['avatar_emoji'] as String? ?? '🎴', style: const TextStyle(fontSize: 18))),
                          const SizedBox(width: 10),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Flexible(child: Text(u['display_name'] as String? ?? '',
                                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                                  maxLines: 1, overflow: TextOverflow.ellipsis)),
                              if (u['phone_verified'] == true) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.verified, size: 13, color: Color(0xFF2980B9)),
                              ],
                            ]),
                            Text('@${u['username'] ?? ''}',
                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF9CA3AF))),
                          ])),
                          Text((u['created_at'] as String?)?.split('T').first ?? '',
                              style: const TextStyle(fontSize: 10.5, color: Color(0xFFB6BCC6))),
                        ]),
                      );
                    }),
      ),
    ]);
  }
}

Future<bool> _confirm(BuildContext context, String msg) async {
  final r = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
    content: Text(msg),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
      ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE74C3C)),
        onPressed: () => Navigator.pop(ctx, true),
        child: const Text('刪除', style: TextStyle(color: Colors.white))),
    ],
  ));
  return r ?? false;
}
