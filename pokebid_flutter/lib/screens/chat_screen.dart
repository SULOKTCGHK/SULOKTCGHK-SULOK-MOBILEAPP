import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/card_model.dart';
import '../services/chat_service.dart';
import 'card_detail_screen.dart';

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
        title: Row(children: [
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
        ]),
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
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
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
                  Text('${widget.card!.grade} · NT\$ ${_formatPrice(widget.card!.price)}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('詢問中',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
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
                    Text('向 ${widget.sellerName} 打聲招呼吧！',
                        style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
                  ]))
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final msg = _messages[i];
                      final isMine = msg.senderId == _myId;
                      return _MessageBubble(
                        text: msg.content,
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
                    decoration: const InputDecoration(
                      hintText: '輸入訊息...',
                      hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
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
                        ? const Color(0xFFE8A52A).withOpacity(0.5)
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
    final quickReplies = [
      '請問還有貨嗎？',
      '可以議價嗎？',
      '請問評級是什麼機構？',
      '可以提供更多圖片嗎？',
      '請問運費是多少？',
    ];
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
            const Text('快速回覆',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
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
  final String time;
  final bool isMine;
  final String sellerAvatar;

  const _MessageBubble({
    required this.text, required this.time,
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
                    color: Colors.black.withOpacity(0.05),
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
