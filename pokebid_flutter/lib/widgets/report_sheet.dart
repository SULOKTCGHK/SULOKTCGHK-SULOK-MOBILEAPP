import 'package:flutter/material.dart';
import '../services/report_service.dart';
import '../widgets/login_required.dart';
import '../i18n/strings.dart';

/// 開啟檢舉彈窗。需先登入。
Future<void> showReportSheet(
  BuildContext context, {
  required String targetType, // 'listing' | 'user' | 'message' | 'review'
  required String targetId,
}) async {
  if (!await requireLogin(context, action: L.reportNeedLogin)) return;
  if (!context.mounted) return;
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ReportSheet(targetType: targetType, targetId: targetId),
  );
}

class _ReportSheet extends StatefulWidget {
  final String targetType;
  final String targetId;
  const _ReportSheet({required this.targetType, required this.targetId});

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  String? _reason;
  final _detailsCtrl = TextEditingController();
  bool _submitting = false;

  List<MapEntry<String, String>> get _reasons => [
        MapEntry('scam', L.reasonScam),
        MapEntry('fake', L.reasonFake),
        MapEntry('prohibited', L.reasonProhibited),
        MapEntry('offensive', L.reasonOffensive),
        MapEntry('spam', L.reasonSpam),
        MapEntry('harassment', L.reasonHarassment),
        MapEntry('other', L.reasonOther),
      ];

  @override
  void dispose() {
    _detailsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reason == null) return;
    setState(() => _submitting = true);
    final ok = await ReportService.submit(
      targetType: widget.targetType,
      targetId: widget.targetId,
      reason: _reason!,
      details: _detailsCtrl.text,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? L.reportSubmitted : L.reportFailed),
      backgroundColor: ok ? const Color(0xFF16A34A) : const Color(0xFFE74C3C),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 36, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Row(children: [
            const Icon(Icons.flag_outlined, size: 20, color: Color(0xFFE74C3C)),
            const SizedBox(width: 8),
            Text(L.reportTitle, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          ]),
          const SizedBox(height: 16),
          Text(L.reportReason, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
          const SizedBox(height: 8),
          ..._reasons.map((e) => GestureDetector(
                onTap: () => setState(() => _reason = e.key),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(children: [
                    Icon(_reason == e.key ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        size: 20, color: _reason == e.key ? const Color(0xFFE8A52A) : const Color(0xFFD1D5DB)),
                    const SizedBox(width: 10),
                    Text(e.value, style: const TextStyle(fontSize: 14, color: Color(0xFF111827))),
                  ]),
                ),
              )),
          const SizedBox(height: 8),
          TextField(
            controller: _detailsCtrl,
            maxLines: 2,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: L.reportDetailsHint,
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
              filled: true, fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 0.5)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 0.5)),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_reason == null || _submitting) ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE74C3C),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE5E7EB),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _submitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(L.reportSubmit, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }
}
