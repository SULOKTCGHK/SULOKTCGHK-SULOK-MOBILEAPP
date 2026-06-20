import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import 'chat_screen.dart';
import 'auth/login_screen.dart';

class ConversationsListScreen extends StatefulWidget {
  const ConversationsListScreen({super.key});

  @override
  State<ConversationsListScreen> createState() =>
      _ConversationsListScreenState();
}

class _ConversationsListScreenState extends State<ConversationsListScreen> {
  List<Conversation> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!AuthService.isLoggedIn) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final convs = await ChatService.getMyConversations();
      if (mounted) setState(() { _conversations = convs; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openChat(Conversation c) async {
    final initials = c.otherPartyName.length >= 2
        ? c.otherPartyName.substring(0, 2).toUpperCase()
        : c.otherPartyName.toUpperCase();
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => ChatScreen(
        sellerName: c.otherPartyName,
        sellerAvatar: initials,
        sellerId: c.otherPartyId,
        conversationId: c.id,
      ),
    ));
    _load(); // 回來時刷新最後訊息
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '剛剛';
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分鐘前';
    if (diff.inHours < 24) return '${diff.inHours} 小時前';
    if (diff.inDays < 7) return '${diff.inDays} 天前';
    return '${dt.month}/${dt.day}';
  }

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
        title: const Text('訊息',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500,
                color: Color(0xFF111827))),
      ),
      body: !AuthService.isLoggedIn
          ? _loginPrompt()
          : _loading
              ? const Center(child: CircularProgressIndicator(
                  color: Color(0xFFE8A52A), strokeWidth: 2))
              : _conversations.isEmpty
                  ? _empty()
                  : RefreshIndicator(
                      color: const Color(0xFFE8A52A),
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _conversations.length,
                        separatorBuilder: (_, __) => const Divider(
                            height: 0.5, thickness: 0.5,
                            indent: 76, color: Color(0xFFF3F4F6)),
                        itemBuilder: (_, i) => _tile(_conversations[i]),
                      ),
                    ),
    );
  }

  Widget _tile(Conversation c) {
    final initials = c.otherPartyName.length >= 2
        ? c.otherPartyName.substring(0, 2).toUpperCase()
        : c.otherPartyName.toUpperCase();
    return InkWell(
      onTap: () => _openChat(c),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          // Avatar
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF9EC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFDE68A), width: 1),
            ),
            child: Center(child: Text(initials,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                    color: Color(0xFFE8A52A)))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Row(children: [
                Flexible(child: Text(c.otherPartyName,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15,
                        fontWeight: FontWeight.w600, color: Color(0xFF111827)))),
                const SizedBox(width: 6),
                // 角色標籤
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: c.amISeller
                        ? const Color(0xFFEFF6FF)
                        : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(c.amISeller ? '買家' : '賣家',
                      style: TextStyle(fontSize: 10,
                          color: c.amISeller
                              ? const Color(0xFF2980B9)
                              : const Color(0xFF16A34A))),
                ),
              ])),
              const SizedBox(width: 6),
              Text(_timeAgo(c.lastMessageAt),
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
            ]),
            const SizedBox(height: 3),
            if (c.cardName.isNotEmpty)
              Text('🎴 ${c.cardName}',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Color(0xFFE8A52A))),
            const SizedBox(height: 2),
            Text(c.lastMessage ?? '尚無訊息，點擊開始對話',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13,
                    color: c.lastMessage != null
                        ? const Color(0xFF6B7280)
                        : const Color(0xFFBCC0C7))),
          ])),
        ]),
      ),
    );
  }

  Widget _empty() => Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: const [
    Icon(Icons.forum_outlined, size: 56, color: Color(0xFFD1D5DB)),
    SizedBox(height: 14),
    Text('還沒有任何對話',
        style: TextStyle(fontSize: 15, color: Color(0xFF9CA3AF))),
    SizedBox(height: 6),
    Text('在商品頁聯絡賣家即可開始對話',
        style: TextStyle(fontSize: 13, color: Color(0xFFD1D5DB))),
  ]));

  Widget _loginPrompt() => Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.forum_outlined, size: 56, color: Color(0xFFD1D5DB)),
    const SizedBox(height: 14),
    const Text('請先登入以查看訊息',
        style: TextStyle(fontSize: 15, color: Color(0xFF9CA3AF))),
    const SizedBox(height: 16),
    ElevatedButton(
      onPressed: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const LoginScreen())),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE8A52A),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: const Text('登入'),
    ),
  ]));
}
