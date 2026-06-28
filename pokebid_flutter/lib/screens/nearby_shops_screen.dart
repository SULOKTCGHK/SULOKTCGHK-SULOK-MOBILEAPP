import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/shop_service.dart';
import '../i18n/strings.dart';

class NearbyShopsScreen extends StatefulWidget {
  const NearbyShopsScreen({super.key});

  @override
  State<NearbyShopsScreen> createState() => _NearbyShopsScreenState();
}

class _NearbyShopsScreenState extends State<NearbyShopsScreen> {
  List<CardShop> _shops = [];
  bool _loading = true;
  bool _hasLocation = false;
  String _region = '';   // '' = 全部
  String _district = ''; // '' = 全部
  final _searchCtrl = TextEditingController();
  String _query = '';

  // 目前大區內有哪些細區（給子篩選用）
  List<String> get _districts {
    final base = _region.isEmpty ? _shops : _shops.where((s) => s.region == _region);
    final set = base
        .map((s) => s.district)
        .whereType<String>()
        .where((d) => d.isNotEmpty)
        .toSet()
        .toList();
    set.sort();
    return set;
  }

  List<CardShop> get _filtered {
    final q = _query.trim().toLowerCase();
    return _shops.where((s) {
      if (_region.isNotEmpty && s.region != _region) return false;
      if (_district.isNotEmpty && s.district != _district) return false;
      if (q.isNotEmpty) {
        final hay = '${s.name} ${s.district ?? ''} ${s.address ?? ''}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await ShopService.nearbyShops();
    if (mounted) {
      setState(() {
        _shops = r.shops;
        _hasLocation = r.hasLocation;
        _loading = false;
      });
    }
  }

  Future<void> _openMaps(CardShop s) async {
    final name = Uri.encodeComponent(s.name);
    final uri = Uri.parse('https://www.google.com/maps/search/$name/@${s.lat},${s.lng},15z');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  String _dist(double? km) {
    if (km == null) return '';
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0.5,
        foregroundColor: const Color(0xFF111827),
        title: Text(L.nearbyShops, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE8A52A), strokeWidth: 2))
          : _shops.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.storefront_outlined, size: 48, color: Color(0xFFD1D5DB)),
                  const SizedBox(height: 12),
                  Text(L.noShopData, style: const TextStyle(fontSize: 15, color: Color(0xFF9CA3AF))),
                ]))
              : Column(children: [
                  _searchBar(),
                  _regionBar(),
                  if (_region.isNotEmpty && _districts.isNotEmpty) _districtBar(),
                  Expanded(
                    child: _filtered.isEmpty
                        ? Center(child: Text(L.noShopInRegion,
                            style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                if (!_hasLocation)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(10)),
                                    child: Row(children: [
                                      const Icon(Icons.location_off, size: 16, color: Color(0xFFB8860B)),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(L.noLocationNote,
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)))),
                                      GestureDetector(onTap: _load,
                                          child: Text(L.retry, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFB8860B)))),
                                    ]),
                                  ),
                                ..._filtered.map(_shopCard),
                              ],
                            ),
                          ),
                  ),
                ]),
    );
  }

  Widget _regionBar() {
    final regions = <(String, String)>[
      ('', L.regionAll),
      ('香港島', L.regionHkIsland),
      ('九龍', L.regionKowloon),
      ('新界', L.regionNt),
      ('離島', L.regionIslands),
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final r in regions) ...[
            GestureDetector(
              onTap: () => setState(() { _region = r.$1; _district = ''; }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: _region == r.$1 ? const Color(0xFFE8A52A) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(r.$2,
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: _region == r.$1 ? Colors.white : const Color(0xFF6B7280))),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ]),
      ),
    );
  }

  Widget _searchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _query = v),
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: L.searchShopHint,
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 20),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Color(0xFF9CA3AF)),
                  onPressed: () { _searchCtrl.clear(); setState(() => _query = ''); })
              : null,
          filled: true, fillColor: const Color(0xFFF3F4F6),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _districtBar() {
    final districts = ['', ..._districts]; // '' = 全部
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final d in districts) ...[
            GestureDetector(
              onTap: () => setState(() => _district = d),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _district == d ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(d.isEmpty ? L.regionAll : d,
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: _district == d ? Colors.white : const Color(0xFF6B7280))),
              ),
            ),
            const SizedBox(width: 6),
          ],
        ]),
      ),
    );
  }

  Widget _shopCard(CardShop s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(s.name,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)))),
          if (s.distanceKm != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFFE8A52A).withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.near_me, size: 11, color: Color(0xFFB8860B)),
                const SizedBox(width: 3),
                Text(_dist(s.distanceKm),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFB8860B))),
              ]),
            ),
        ]),
        if (s.district != null || s.address != null) ...[
          const SizedBox(height: 4),
          Text([s.district, s.address].where((e) => e != null && e.isNotEmpty).join('・'),
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280))),
        ],
        if (s.hours != null && s.hours!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text('🕒 ${s.hours}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF9CA3AF))),
        ],
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _btn(Icons.directions, L.navigate, const Color(0xFF2980B9), () => _openMaps(s))),
          if (s.phone != null && s.phone!.isNotEmpty) ...[
            const SizedBox(width: 8),
            Expanded(child: _btn(Icons.phone, L.callShop, const Color(0xFF16A34A), () => _call(s.phone!))),
          ],
        ]),
      ]),
    );
  }

  Widget _btn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: color)),
        ]),
      ),
    );
  }
}
