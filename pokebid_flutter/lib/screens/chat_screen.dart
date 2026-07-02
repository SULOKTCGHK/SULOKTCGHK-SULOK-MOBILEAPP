import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/card_model.dart';
import '../services/chat_service.dart';
import '../services/listing_service.dart';
import '../services/review_service.dart';
import 'card_detail_screen.dart';
import 'seller_profile_screen.dart';
import 'legal_screen.dart';
import '../i18n/strings.dart';
import '../services/block_service.dart';
import '../widgets/report_sheet.dart';

class ChatScreen extends StatefulWidget {
  final String sellerName;
  final String sellerAvatar;
  final String? sellerIg;
  final String? sellerId;
  final PokemonCard? card;
  // 若已知對話 ID（例如賣家從對話列表開啟），直接載入該對話
  final String? conversationId;

  const ChatScreen({
    super.key,
    required this.sellerName,
    required this.sellerAvatar,
    this.sellerIg,
    this.sellerId,
    this.card,
    this.conversationId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<ChatMessage> _messages = [];
  String? _conversationId;
  bool _showSafety = true;
  String? _myId;
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _myId = await ChatService.myId()
          .timeout(const Duration(seconds: 5));

      String convId;
      if (widget.conversationId != null && widget.conversationId!.isNotEmpty) {
        // 已知對話 ID，直接使用
        convId = widget.conversationId!;
      } else {
        // If no sellerId, fall back to offline mode
        if (widget.sellerId == null || widget.sellerId!.isEmpty ||
            widget.sellerId == _myId) {
          if (mounted) setState(() => _loading = false);
          return;
        }

        convId = await ChatService.getOrCreateConversation(
          sellerId: widget.sellerId!,
          cardId: widget.card?.supabaseId,
          cardName: widget.card?.name,
          cardPrice: widget.card?.price,
        ).timeout(const Duration(seconds: 8));
      }
      _conversationId = convId;

      final msgs = await ChatService.getMessages(convId)
          .timeout(const Duration(seconds: 8));
      if (mounted) setState(() { _messages = msgs; _loading = false; });

      ChatService.subscribe(
        conversationId: convId,
        onMessage: (msg) {
          if (mounted) {
            setState(() => _messages.add(msg));
            _scrollToBottom();
          }
        },
      );

      _scrollToBottom(delay: 300);
    } catch (e) {
      // On any error/timeout, show empty chat instead of spinning forever
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    ChatService.unsubscribe();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom({int delay = 100}) {
    Future.delayed(Duration(milliseconds: delay), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() { _sending = true; });
    _msgCtrl.clear();

    if (_conversationId == null) {
      // Mock mode fallback (no seller ID)
      setState(() {
        _messages.add(ChatMessage(
          id: DateTime.now().toString(),
          conversationId: '',
          senderId: _myId ?? 'me',
          content: text,
          createdAt: DateTime.now(),
        ));
        _sending = false;
      });
      _scrollToBottom();
      return;
    }

    try {
      await ChatService.sendMessage(
        conversationId: _conversationId!,
        content: text,
      );
      // Realtime will deliver our own message back via subscription
    } catch (_) {
      // If realtime fails, add locally
      setState(() {
        _messages.add(ChatMessage(
          id: DateTime.now().toString(),
          conversationId: _conversationId!,
          senderId: _myId ?? '',
          content: text,
          createdAt: DateTime.now(),
        ));
      });
      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // 傳送圖片（相簿選取 → 上傳 storage → 圖片訊息）
  Future<void> _sendImage() async {
    if (_conversationId == null || _sending) return;
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null || !mounted) return;
    setState(() => _sending = true);
    try {
      final bytes = await picked.readAsBytes();
      await ChatService.sendImageMessage(
        conversationId: _conversationId!,
        bytes: bytes,
        fileName: picked.name,
      );
      // Realtime 會把訊息推回來
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('圖片傳送失敗'), backgroundColor: Color(0xFFE74C3C)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _blockUser() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(L.block, style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(L.blockConfirm(widget.sellerName)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(L.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE74C3C), foregroundColor: Colors.white),
            child: Text(L.block),
          ),
        ],
      ),
    );
    if (ok != true || widget.sellerId == null) return;
    await BlockService.block(widget.sellerId!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L.blocked)));
      Navigator.pop(context); // 封鎖後離開聊天室
    }
  }

  void _openSellerProfile() {
    if (widget.sellerId == null) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => SellerProfileScreen(
        sellerId: widget.sellerId!,
        sellerName: widget.sellerName,
      ),
    ));
  }

  Future<void> _openIG() async {
    final ig = widget.sellerIg?.replaceAll('@', '') ?? '';
    if (ig.isEmpty) return;
    final url = Uri.parse('https://www.instagram.com/$ig/');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  String _timeStr(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
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
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Color(0xFF374151), size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: widget.sellerId != null ? _openSellerProfile : null,
          child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF9EC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFDE68A), width: 1),
            ),
            child: Center(child: Text(widget.sellerAvatar,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                    color: Color(0xFFE8A52A)))),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.sellerName,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                    color: Color(0xFF111827))),
            if (widget.sellerIg != null && widget.sellerIg!.isNotEmpty)
              Text(
                widget.sellerIg!.startsWith('@') ? widget.sellerIg! : '@${widget.sellerIg}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
              ),
          ]),
        ])),
        actions: [
          if (widget.sellerIg != null && widget.sellerIg!.isNotEmpty)
            IconButton(
              onPressed: _openIG,
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE1306C), Color(0xFFF77737), Color(0xFF833AB4)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
              ),
            ),
          if (widget.sellerId != null && widget.sellerId!.isNotEmpty && widget.sellerId != _myId)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF374151)),
              onSelected: (v) {
                if (v == 'report') {
                  showReportSheet(context, targetType: 'user', targetId: widget.sellerId!);
                } else if (v == 'block') {
                  _blockUser();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'report', child: Row(children: [
                  const Icon(Icons.flag_outlined, size: 18, color: Color(0xFF6B7280)),
                  const SizedBox(width: 10), Text(L.report),
                ])),
                PopupMenuItem(value: 'block', child: Row(children: [
                  const Icon(Icons.block, size: 18, color: Color(0xFFE74C3C)),
                  const SizedBox(width: 10),
                  Text(L.block, style: const TextStyle(color: Color(0xFFE74C3C))),
                ])),
              ],
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 安全交易提示（可關閉）
          if (_showSafety)
            Container(
              color: const Color(0xFFFFFBEB),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(children: [
                const Icon(Icons.verified_user_outlined, size: 15, color: Color(0xFFB8860B)),
                const SizedBox(width: 6),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LegalScreen.safety())),
                    child: Text.rich(TextSpan(children: [
                      TextSpan(text: L.chatSafetyText,
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF92400E))),
                      TextSpan(text: L.chatSafetyLink,
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFFB8860B))),
                    ])),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _showSafety = false),
                  child: const Padding(padding: EdgeInsets.only(left: 6),
                      child: Icon(Icons.close, size: 14, color: Color(0xFFB8860B))),
                ),
              ]),
            ),
          // Card reference (可點擊查看商品內容)
          if (widget.card != null)
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => CardDetailScreen(
                  card: widget.card!, isFavorited: false, onFavChanged: (_) {}),
              )),
              child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: widget.card!.type.bgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: Text(widget.card!.type.emoji,
                      style: const TextStyle(fontSize: 18))),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.card!.name,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                          color: Color(0xFF111827))),
                  Text('${widget.card!.grade} · HK\$ ${_formatPrice(widget.card!.price)}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(L.inquiring,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
                          color: Color(0xFF16A34A))),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 16, color: Color(0xFFD1D5DB)),
              ]),
            ),
            ),

          // Messages
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(
                    color: Color(0xFFE8A52A), strokeWidth: 2))
                : _messages.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.chat_bubble_outline, size: 48, color: Color(0xFFD1D5DB)),
                    const SizedBox(height: 12),
                    Text(L.sayHello(widget.sellerName),
                        style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
                  ]))
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final msg = _messages[i];
                      if (msg.content.startsWith('__DEAL__:')) {
                        final amISeller = widget.sellerId != _myId;
                        return _DealCard(
                          content: msg.content,
                          time: _timeStr(msg.createdAt),
                          otherPartyId: widget.sellerId,
                          otherPartyName: widget.sellerName,
                          amISeller: amISeller,
                        );
                      }
                      final isMine = msg.senderId == _myId;
                      return _MessageBubble(
                        text: msg.content,
                        imageUrl: msg.imageUrl,
                        time: _timeStr(msg.createdAt),
                        isMine: isMine,
                        sellerAvatar: widget.sellerAvatar,
                      );
                    },
                  ),
          ),

          // Input bar
          Container(
            padding: EdgeInsets.only(
              left: 12, right: 12, top: 10,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 0.5)),
            ),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Color(0xFF9CA3AF)),
                onPressed: _showQuickReplies,
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36),
                icon: const Icon(Icons.photo_outlined, color: Color(0xFF9CA3AF)),
                onPressed: _sendImage,
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _msgCtrl,
                    style: const TextStyle(fontSize: 14),
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: L.messageHint,
                      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _send,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: _sending
                        ? const Color(0xFFE8A52A).withValues(alpha: 0.5)
                        : const Color(0xFFE8A52A),
                    shape: BoxShape.circle,
                  ),
                  child: _sending
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  String _formatPrice(int price) => price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  void _showQuickReplies() {
    final quickReplies = L.quickReplyOptions;
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
            Text(L.quickReplies,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: quickReplies.map((r) => GestureDetector(
                onTap: () { Navigator.pop(context); _msgCtrl.text = r; },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
                  ),
                  child: Text(r, style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
                ),
              )).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── Message Bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final String text;
  final String? imageUrl;
  final String time;
  final bool isMine;
  final String sellerAvatar;

  const _MessageBubble({
    required this.text, this.imageUrl, required this.time,
    required this.isMine, required this.sellerAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF9EC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: Text(sellerAvatar,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: Color(0xFFE8A52A)))),
            ),
            const SizedBox(width: 6),
          ],
          Column(
            crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // 圖片訊息：直接顯示圖（點擊放大）；文字訊息：氣泡
              if (imageUrl != null)
                GestureDetector(
                  onTap: () => showDialog(
                    context: context,
                    barrierColor: Colors.black87,
                    builder: (ctx) => GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: InteractiveViewer(
                        child: Center(child: CachedNetworkImage(imageUrl: imageUrl!)),
                      ),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl!,
                      width: MediaQuery.of(context).size.width * 0.55,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: MediaQuery.of(context).size.width * 0.55, height: 160,
                        color: const Color(0xFFF3F4F6),
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 120, height: 90, color: const Color(0xFFF3F4F6),
                        child: const Icon(Icons.broken_image_outlined, color: Color(0xFF9CA3AF)),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMine ? const Color(0xFFE8A52A) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMine ? 16 : 4),
                      bottomRight: Radius.circular(isMine ? 4 : 16),
                    ),
                    boxShadow: [BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4, offset: const Offset(0, 2),
                    )],
                  ),
                  child: Text(text,
                      style: TextStyle(
                        fontSize: 14,
                        color: isMine ? Colors.white : const Color(0xFF111827),
                        height: 1.4,
                      )),
                ),
              const SizedBox(height: 3),
              Text(time, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
            ],
          ),
          if (isMine) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ── 成交系統訊息卡片 ────────────────────────────────────────────────────────────
class _DealCard extends StatefulWidget {
  final String content;
  final String time;
  final String? otherPartyId;   // 對方的 userId
  final String? otherPartyName;
  final bool amISeller;

  const _DealCard({
    required this.content,
    required this.time,
    this.otherPartyId,
    this.otherPartyName,
    this.amISeller = false,
  });

  @override
  State<_DealCard> createState() => _DealCardState();
}

class _DealCardState extends State<_DealCard> {
  bool _reviewed = false;

  Map<String, dynamic>? get _data {
    try {
      final json = widget.content.substring('__DEAL__:'.length);
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (_) { return null; }
  }

  void _openListing(String listingId) async {
    final card = await ListingService.getListingById(listingId);
    if (card != null && mounted) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => CardDetailScreen(card: card, isFavorited: false, onFavChanged: (_) {}),
      ));
    }
  }

  void _openReview(String listingId) async {
    if (widget.otherPartyId == null) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReviewSheet(
        otherPartyId: widget.otherPartyId!,
        otherPartyName: widget.otherPartyName ?? L.otherParty,
        listingId: listingId,
        amISeller: widget.amISeller,
        onDone: () => setState(() => _reviewed = true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data == null) return const SizedBox.shrink();
    final amount = data['amount'] as int? ?? 0;
    final listingId = data['listing_id'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(children: [
        Row(children: [
          const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
          const SizedBox(width: 8),
          Text(L.dealConfirm, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
        ]),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: listingId.isNotEmpty ? () => _openListing(listingId) : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18),
                const SizedBox(width: 6),
                Text(L.dealDone, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF15803D))),
              ]),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(L.dealPrice(amount),
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 10),
              if (listingId.isNotEmpty)
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(L.viewListingDetail, style: const TextStyle(fontSize: 12, color: Color(0xFF16A34A), fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios, size: 11, color: Color(0xFF16A34A)),
                ]),
              const SizedBox(height: 4),
              Text(widget.time, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        // 評價按鈕
        if (widget.otherPartyId != null && !_reviewed)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openReview(listingId),
              icon: const Icon(Icons.star_outline, size: 16, color: Color(0xFFE8A52A)),
              label: Text(
                widget.amISeller ? L.reviewBuyer : L.reviewSeller,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFB45309)),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE8A52A)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          )
        else if (_reviewed)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF16A34A)),
              const SizedBox(width: 4),
              Text(L.reviewDone, style: const TextStyle(fontSize: 12, color: Color(0xFF16A34A))),
            ]),
          ),
      ]),
    );
  }
}

// ── 評價 BottomSheet ────────────────────────────────────────────────────────────
class _ReviewSheet extends StatefulWidget {
  final String otherPartyId;
  final String otherPartyName;
  final String listingId;
  final bool amISeller;
  final VoidCallback onDone;

  const _ReviewSheet({
    required this.otherPartyId,
    required this.otherPartyName,
    required this.listingId,
    required this.amISeller,
    required this.onDone,
  });

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  int _stars = 5;
  String? _delivery; // meetup / sf / other
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  static List<(String, String, IconData)> get _deliveryOptions => [
    ('meetup', L.deliveryMeetup, Icons.handshake_outlined),
    ('sf', L.deliverySf, Icons.local_shipping_outlined),
    ('other', L.deliveryOther, Icons.swap_horiz),
  ];

  @override
  void dispose() { _commentCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    await ReviewService.submitReview(
      sellerId: widget.otherPartyId,
      listingId: widget.listingId,
      rating: _stars,
      comment: _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
      deliveryMethod: _delivery,
      role: widget.amISeller ? 'seller' : 'buyer',
    );
    if (mounted) {
      Navigator.pop(context);
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 36, height: 4,
          decoration: BoxDecoration(color: const Color(0xFFD1D5DB), borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Text(L.reviewTitle(widget.otherPartyName),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
        const SizedBox(height: 16),

        // 星星評分
        Text(L.rating, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 8),
        Row(children: List.generate(5, (i) => GestureDetector(
          onTap: () => setState(() => _stars = i + 1),
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Icon(i < _stars ? Icons.star_rounded : Icons.star_outline_rounded,
              color: const Color(0xFFE8A52A), size: 36),
          ),
        ))),
        const SizedBox(height: 16),

        // 交易方式
        Text(L.deliveryMethod, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 8),
        Row(children: _deliveryOptions.map((opt) {
          final (val, label, icon) = opt;
          final sel = _delivery == val;
          return Expanded(child: GestureDetector(
            onTap: () => setState(() => _delivery = sel ? null : val),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: sel ? const Color(0xFFE8A52A) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: sel ? const Color(0xFFE8A52A) : const Color(0xFFE5E7EB)),
              ),
              child: Column(children: [
                Icon(icon, size: 20, color: sel ? Colors.white : const Color(0xFF6B7280)),
                const SizedBox(height: 4),
                Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: sel ? Colors.white : const Color(0xFF374151))),
              ]),
            ),
          ));
        }).toList()),
        const SizedBox(height: 16),

        // 留言
        Text(L.commentOptional, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 8),
        TextField(
          controller: _commentCtrl,
          maxLines: 3,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: L.commentHint,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 0.5)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 0.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE8A52A), width: 1)),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE8A52A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _submitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(L.submitReview, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}
