import 'package:flutter/material.dart';
import '../../services/shop_service.dart';

class ShopFormSheet extends StatefulWidget {
  final CardShop? shop; // null = 新增
  final VoidCallback onSaved;
  const ShopFormSheet({super.key, this.shop, required this.onSaved});

  @override
  State<ShopFormSheet> createState() => _ShopFormSheetState();
}

class _ShopFormSheetState extends State<ShopFormSheet> {
  late final _name = TextEditingController(text: widget.shop?.name ?? '');
  late final _district = TextEditingController(text: widget.shop?.district ?? '');
  late final _address = TextEditingController(text: widget.shop?.address ?? '');
  late final _lat = TextEditingController(text: widget.shop?.lat.toString() ?? '');
  late final _lng = TextEditingController(text: widget.shop?.lng.toString() ?? '');
  late final _phone = TextEditingController(text: widget.shop?.phone ?? '');
  late final _ig = TextEditingController(text: widget.shop?.igHandle ?? '');
  late final _hours = TextEditingController(text: widget.shop?.hours ?? '');
  late String _region = widget.shop?.region ?? '';
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _district, _address, _lat, _lng, _phone, _ig, _hours]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final lat = double.tryParse(_lat.text.trim());
    final lng = double.tryParse(_lng.text.trim());
    if (name.isEmpty) { setState(() => _error = '請輸入店名'); return; }
    if (lat == null || lng == null) { setState(() => _error = '經緯度需為數字（如 22.3193 / 114.1694）'); return; }
    setState(() { _busy = true; _error = null; });
    final data = <String, dynamic>{
      'name': name,
      'district': _district.text.trim(),
      'region': _region.isEmpty ? null : _region,
      'address': _address.text.trim(),
      'lat': lat, 'lng': lng,
      'phone': _phone.text.trim(),
      'ig_handle': _ig.text.trim(),
      'hours': _hours.text.trim(),
      'is_active': true,
    };
    if (widget.shop != null) data['id'] = widget.shop!.id;
    final ok = await ShopService.upsertShop(data);
    if (!mounted) return;
    if (ok) { Navigator.pop(context); widget.onSaved(); }
    else { setState(() { _busy = false; _error = '儲存失敗（確認你是 admin）'; }); }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.only(left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text(widget.shop == null ? '新增卡鋪' : '編輯卡鋪',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 16),
          _field(_name, '店名 *'),
          _field(_district, '地區（如 旺角）'),
          _regionPicker(),
          _field(_address, '地址'),
          Row(children: [
            Expanded(child: _field(_lat, '緯度 lat *', number: true)),
            const SizedBox(width: 10),
            Expanded(child: _field(_lng, '經度 lng *', number: true)),
          ]),
          const Padding(padding: EdgeInsets.only(bottom: 8),
            child: Text('💡 Google Maps 右鍵點店家位置可複製座標', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)))),
          _field(_phone, '電話'),
          _field(_ig, 'Instagram 帳號'),
          _field(_hours, '營業時間'),
          if (_error != null) ...[
            const SizedBox(height: 4),
            Text(_error!, style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
          ],
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE8A52A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('儲存', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _regionPicker() {
    const regions = ['香港島', '九龍', '新界', '離島'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('大區', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        const SizedBox(height: 6),
        Wrap(spacing: 8, children: [
          for (final r in regions)
            GestureDetector(
              onTap: () => setState(() => _region = _region == r ? '' : r),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _region == r ? const Color(0xFFE8A52A) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(r,
                    style: TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w600,
                        color: _region == r ? Colors.white : const Color(0xFF6B7280))),
              ),
            ),
        ]),
      ]),
    );
  }

  Widget _field(TextEditingController c, String label, {bool number = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: c,
      keyboardType: number ? const TextInputType.numberWithOptions(decimal: true, signed: true) : TextInputType.text,
      decoration: InputDecoration(
        labelText: label, isDense: true,
        filled: true, fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      ),
    ),
  );
}
