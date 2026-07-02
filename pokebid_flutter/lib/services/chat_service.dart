import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import 'supabase_service.dart';
import 'notification_service.dart';

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final String? imageUrl; // 圖片訊息
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.imageUrl,
    required this.createdAt,
  });

  factory ChatMessage.fromRow(Map<String, dynamic> row) => ChatMessage(
    id: row['id'] as String,
    conversationId: row['conversation_id'] as String,
    senderId: row['sender_id'] as String,
    content: row['content'] as String,
    imageUrl: row['image_url'] as String?,
    createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
  );
}

class Conversation {
  final String id;
  final String otherPartyId;
  final String otherPartyName;
  final String cardId;
  final String cardName;
  final int cardPrice;
  final bool amISeller;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime createdAt;

  const Conversation({
    required this.id,
    required this.otherPartyId,
    required this.otherPartyName,
    required this.cardId,
    required this.cardName,
    required this.cardPrice,
    required this.amISeller,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.createdAt,
  });

  DateTime get sortTime => lastMessageAt ?? createdAt;
}

class ChatService {
  static final _client = Supabase.instance.client;
  static RealtimeChannel? _channel;

  // ── Get or create a conversation ─────────────────────────────────────────
  static Future<String> getOrCreateConversation({
    required String sellerId,
    required String? cardId,
    String? cardName,
    int? cardPrice,
  }) async {
    final myId = AuthService.isLoggedIn
        ? AuthService.userId
        : await SupabaseService.getUserId();

    // Check if conversation already exists
    var query = _client
        .from('conversations')
        .select('id')
        .eq('buyer_id', myId)
        .eq('seller_id', sellerId);
    if (cardId != null && cardId.isNotEmpty) {
      query = query.eq('card_id', cardId);
    }
    final existing = await query.limit(1).maybeSingle();

    if (existing != null) return existing['id'] as String;

    // Create new conversation
    final res = await _client.from('conversations').insert({
      'buyer_id': myId,
      'seller_id': sellerId,
      'card_id': cardId ?? '',
      'card_name': cardName ?? '',
      'card_price': cardPrice ?? 0,
    }).select('id').single();

    return res['id'] as String;
  }

  // ── Get all conversations for current user (as buyer or seller) ──────────
  static Future<List<Conversation>> getMyConversations() async {
    final myId = AuthService.isLoggedIn
        ? AuthService.userId
        : await SupabaseService.getUserId();

    // 取得所有與我相關的對話（我是買家或賣家）
    final rows = await _client
        .from('conversations')
        .select()
        .or('buyer_id.eq.$myId,seller_id.eq.$myId');

    final convs = (rows as List).cast<Map<String, dynamic>>();
    if (convs.isEmpty) return [];

    // 收集另一方的 user id，批次查 profile 名稱
    final otherIds = <String>{};
    for (final c in convs) {
      final amISeller = c['seller_id'] == myId;
      final otherId = (amISeller ? c['buyer_id'] : c['seller_id']) as String? ?? '';
      if (otherId.isNotEmpty) otherIds.add(otherId);
    }

    final names = <String, String>{};
    if (otherIds.isNotEmpty) {
      try {
        final profs = await _client
            .from('profiles')
            .select('id, display_name, username')
            .inFilter('id', otherIds.toList());
        for (final p in (profs as List)) {
          names[p['id'] as String] =
              (p['display_name'] as String?)?.isNotEmpty == true
                  ? p['display_name'] as String
                  : (p['username'] as String? ?? '用戶');
        }
      } catch (_) {}
    }

    // 取最後一則訊息
    final result = <Conversation>[];
    for (final c in convs) {
      final convId = c['id'] as String;
      final amISeller = c['seller_id'] == myId;
      final otherId = (amISeller ? c['buyer_id'] : c['seller_id']) as String? ?? '';

      Map<String, dynamic>? lastMsg;
      try {
        lastMsg = await _client
            .from('messages')
            .select('content, created_at')
            .eq('conversation_id', convId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
      } catch (_) {}

      result.add(Conversation(
        id: convId,
        otherPartyId: otherId,
        otherPartyName: names[otherId] ?? (amISeller ? '買家' : '賣家'),
        cardId: c['card_id'] as String? ?? '',
        cardName: c['card_name'] as String? ?? '',
        cardPrice: c['card_price'] as int? ?? 0,
        amISeller: amISeller,
        lastMessage: lastMsg?['content'] as String?,
        lastMessageAt: lastMsg?['created_at'] != null
            ? DateTime.parse(lastMsg!['created_at'] as String).toLocal()
            : null,
        createdAt: DateTime.parse(c['created_at'] as String).toLocal(),
      ));
    }

    // 依最後活動時間排序
    result.sort((a, b) => b.sortTime.compareTo(a.sortTime));
    return result;
  }

  // ── Get or create conversation with explicit buyer/seller roles ──────────
  // 用於賣家主動聯絡買家（不能假設目前用戶就是買家）
  static Future<String> getOrCreateConversationFor({
    required String buyerId,
    required String sellerId,
    String? cardId,
    String? cardName,
    int? cardPrice,
    bool forceNew = false,
  }) async {
    // 每組 buyer+seller+card 一個對話（DB 有唯一約束）；先查現有
    if (cardId != null && cardId.isNotEmpty) {
      final existing = await _client
          .from('conversations')
          .select('id')
          .eq('buyer_id', buyerId)
          .eq('seller_id', sellerId)
          .eq('card_id', cardId)
          .limit(1)
          .maybeSingle();
      if (existing != null) return existing['id'] as String;
    }

    // 沒有才新增；若撞唯一約束（已存在/競態）改抓現有，避免 duplicate key 錯誤
    try {
      final res = await _client.from('conversations').insert({
        'buyer_id': buyerId,
        'seller_id': sellerId,
        'card_id': cardId ?? '',
        'card_name': cardName ?? '',
        'card_price': cardPrice ?? 0,
      }).select('id').single();
      return res['id'] as String;
    } catch (_) {
      final existing = await _client
          .from('conversations')
          .select('id')
          .eq('buyer_id', buyerId)
          .eq('seller_id', sellerId)
          .eq('card_id', cardId ?? '')
          .limit(1)
          .maybeSingle();
      if (existing != null) return existing['id'] as String;
      rethrow;
    }
  }

  // ── Load message history ──────────────────────────────────────────────────
  static Future<List<ChatMessage>> getMessages(String conversationId) async {
    final res = await _client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    return (res as List).map((r) => ChatMessage.fromRow(r)).toList();
  }

  // ── Send a message ────────────────────────────────────────────────────────
  static Future<void> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    final myId = AuthService.isLoggedIn
        ? AuthService.userId
        : await SupabaseService.getUserId();

    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': myId,
      'content': content,
    });

    await _notifyOtherParty(conversationId, myId,
        content.length > 40 ? '${content.substring(0, 40)}…' : content);
  }

  // ── Send an image message ─────────────────────────────────────────────────
  static Future<void> sendImageMessage({
    required String conversationId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final myId = AuthService.isLoggedIn
        ? AuthService.userId
        : await SupabaseService.getUserId();

    // 上傳到 storage（chat 分類）
    final path = 'chat/${conversationId}_${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _client.storage.from('card-images').uploadBinary(
      path, bytes,
      fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
    );
    final url = _client.storage.from('card-images').getPublicUrl(path);

    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': myId,
      'content': '📷 圖片', // 對話列表預覽用
      'image_url': url,
    });

    await _notifyOtherParty(conversationId, myId, '傳送了一張圖片 📷');
  }

  // 通知對話的另一方
  static Future<void> _notifyOtherParty(
      String conversationId, String myId, String preview) async {
    try {
      final conv = await _client
          .from('conversations')
          .select('buyer_id, seller_id, card_id, card_name')
          .eq('id', conversationId)
          .maybeSingle();
      if (conv != null) {
        final recipient = conv['buyer_id'] == myId
            ? conv['seller_id'] as String?
            : conv['buyer_id'] as String?;
        if (recipient != null && recipient.isNotEmpty) {
          final senderName = AuthService.isLoggedIn ? AuthService.displayName : '對方';
          await NotificationService.create(
            userId: recipient,
            type: 'message',
            title: '$senderName 傳來訊息 💬',
            body: preview,
            listingId: (conv['card_id'] as String?)?.isNotEmpty == true
                ? conv['card_id'] as String?
                : null,
          );
        }
      }
    } catch (_) {}
  }

  // ── Send system message (no notification, system sender) ─────────────────
  static Future<void> sendSystemMessage({
    required String conversationId,
    required String content,
  }) async {
    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': 'system',
      'content': content,
    });
  }

  // ── Subscribe to realtime messages ────────────────────────────────────────
  static void subscribe({
    required String conversationId,
    required void Function(ChatMessage) onMessage,
  }) {
    _channel?.unsubscribe();
    _channel = _client
        .channel('messages:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            final msg = ChatMessage.fromRow(payload.newRecord);
            onMessage(msg);
          },
        )
        .subscribe();
  }

  // ── Unsubscribe ───────────────────────────────────────────────────────────
  static void unsubscribe() {
    _channel?.unsubscribe();
    _channel = null;
  }

  // ── Get current user ID ───────────────────────────────────────────────────
  static Future<String> myId() async => AuthService.isLoggedIn
      ? AuthService.userId
      : await SupabaseService.getUserId();
}
