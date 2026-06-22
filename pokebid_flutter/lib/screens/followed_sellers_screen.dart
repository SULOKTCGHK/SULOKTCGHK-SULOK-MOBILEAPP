import 'package:flutter/material.dart';
import '../services/follow_service.dart';
import 'seller_profile_screen.dart';

class FollowedSellersScreen extends StatefulWidget {
  const FollowedSellersScreen({super.key});

  @override
  State<FollowedSellersScreen> createState() => _FollowedSellersScreenState();
}

class _FollowedSellersScreenState extends State<FollowedSellersScreen> {
  List<Map<String, dynamic>> _sellers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final s = await FollowService.followedSellers();
    if (mounted) setState(() { _sellers = s; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('我追蹤的賣家', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: const Color(0xFF111827),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE8A52A), strokeWidth: 2))
          : _sellers.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
                  Icon(Icons.people_outline, size: 48, color: Color(0xFFD1D5DB)),
                  SizedBox(height: 12),
                  Text('尚未追蹤任何賣家', style: TextStyle(fontSize: 15, color: Color(0xFF9CA3AF))),
                  SizedBox(height: 6),
                  Text('在賣家頁面點「追蹤」即可加入', style: TextStyle(fontSize: 13, color: Color(0xFFD1D5DB))),
                ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _sellers.length,
                    itemBuilder: (_, i) {
                      final s = _sellers[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(color: const Color(0xFFFEF9EC), shape: BoxShape.circle),
                            child: Center(child: Text(s['avatar'] as String? ?? '🎴', style: const TextStyle(fontSize: 22))),
                          ),
                          title: Text(s['name'] as String? ?? '賣家',
                              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                          trailing: const Icon(Icons.chevron_right, size: 20, color: Color(0xFFD1D5DB)),
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(
                              builder: (_) => SellerProfileScreen(
                                sellerId: s['id'] as String,
                                sellerName: s['name'] as String? ?? '賣家',
                              ),
                            ));
                            _load(); // 回來重新整理（可能已取消追蹤）
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
