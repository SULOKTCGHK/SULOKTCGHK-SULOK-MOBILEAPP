import 'package:flutter/material.dart';

/// 法律文件顯示頁（隱私政策 / 使用條款）
class LegalScreen extends StatelessWidget {
  final String title;
  final String effectiveDate;
  final List<LegalSection> sections;

  const LegalScreen({
    super.key,
    required this.title,
    required this.effectiveDate,
    required this.sections,
  });

  factory LegalScreen.privacy() => const LegalScreen(
        title: '隱私政策',
        effectiveDate: '2026 年 6 月 20 日',
        sections: _privacySections,
      );

  factory LegalScreen.terms() => const LegalScreen(
        title: '使用條款',
        effectiveDate: '2026 年 6 月 20 日',
        sections: _termsSections,
      );

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
        title: Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF111827))),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Text(title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 4),
          Text('生效日期：$effectiveDate',
              style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
          const SizedBox(height: 20),
          for (final s in sections) ...[
            Text(s.heading,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            const SizedBox(height: 6),
            Text(s.body,
                style: const TextStyle(fontSize: 13.5, height: 1.7, color: Color(0xFF374151))),
            const SizedBox(height: 18),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              '如對本文件有任何疑問，請透過 PokeBid 內的客服管道或電子郵件與我們聯絡。',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class LegalSection {
  final String heading;
  final String body;
  const LegalSection(this.heading, this.body);
}

// ── 隱私政策 ──────────────────────────────────────────────────────────────────
const List<LegalSection> _privacySections = [
  LegalSection('1. 前言',
      'PokeBid（以下稱「本平台」）是一個寶可夢卡牌交易與收藏的社群平台。我們重視您的隱私，本政策說明我們蒐集哪些資料、如何使用，以及您擁有的權利。使用本平台即表示您同意本政策。'),
  LegalSection('2. 我們蒐集的資料',
      '• 帳號資料：當您以 Google 帳號登入時，我們會取得您的名稱、電子郵件與頭像。\n'
      '• 交易與內容資料：您建立的掛售商品、出價、聊天訊息、評價、收藏與願望清單。\n'
      '• 上傳內容：您上傳的卡牌圖片。\n'
      '• 使用資料：裝置類型、操作紀錄等技術資訊，用於改善服務與排除問題。'),
  LegalSection('3. 我們如何使用資料',
      '我們使用您的資料以：提供與維護交易、聊天、通知等核心功能；顯示賣家評價與信用；發送與您交易相關的通知；維護平台安全、防止詐騙與濫用；並依法令要求進行必要處理。'),
  LegalSection('4. 第三方服務',
      '本平台使用下列第三方服務協助運作：\n'
      '• Google 登入（身分驗證）\n'
      '• Supabase（資料儲存與後端服務）\n'
      '• 卡牌價格參考來源（如 TCGplayer / eBay / JustTCG 等）僅用於顯示市場行情，不會傳送您的個人資料給這些服務。\n'
      '這些服務有其各自的隱私政策，建議您一併參閱。'),
  LegalSection('5. 資料分享',
      '我們不會販售您的個人資料。部分資訊（如您的顯示名稱、掛售內容、評價）會在平台上公開顯示，供其他使用者瀏覽。除法律要求或為保護平台與使用者安全外，我們不會將您的個人資料提供給第三方。'),
  LegalSection('6. 資料保存與刪除',
      '我們會在提供服務所需期間保存您的資料。您可要求刪除帳號與相關個人資料；部分交易紀錄可能因法律或紛爭處理需要而保留一段時間。'),
  LegalSection('7. 您的權利',
      '您有權查詢、更正或刪除您的個人資料，並可隨時撤回同意。如需行使上述權利，請透過平台內客服管道與我們聯絡。'),
  LegalSection('8. 兒童隱私',
      '本平台不針對未滿法定年齡之兒童提供服務。若您未達所在地區可獨立締約之年齡，請在法定代理人同意與監督下使用。'),
  LegalSection('9. 政策變更',
      '我們可能不時更新本政策。重大變更將於平台內公告。變更後您繼續使用本平台，即視為同意更新後的政策。'),
  LegalSection('10. 聯絡我們',
      '若您對本隱私政策有任何疑問，請透過 PokeBid 平台內的客服管道或電子郵件與我們聯絡。'),
];

// ── 使用條款 ──────────────────────────────────────────────────────────────────
const List<LegalSection> _termsSections = [
  LegalSection('1. 條款的接受',
      '歡迎使用 PokeBid。當您註冊、登入或使用本平台任何功能時，即表示您已閱讀、理解並同意本使用條款。若您不同意，請勿使用本平台。'),
  LegalSection('2. 服務說明',
      'PokeBid 提供寶可夢卡牌的掛售、出價、聊天、收藏管理、圖鑑查詢與市場行情參考等功能。本平台為使用者之間的交易媒合場所，交易由買賣雙方自行協商與完成。'),
  LegalSection('3. 帳號與資格',
      '您須提供真實、正確的資料，並對帳號下的所有活動負責。您須達到所在地區可獨立締結契約之年齡。請妥善保管登入憑證，不得將帳號轉讓或出借他人。'),
  LegalSection('4. 交易規則',
      '• 賣家須對所刊登卡牌的真實性、狀況描述與所有權負責。\n'
      '• 禁止刊登仿冒品、贓物、侵權品或任何違法物品。\n'
      '• 平台顯示的市場行情僅供參考，不構成價格保證或投資建議。\n'
      '• 交易款項與寄送由買賣雙方自行約定並完成，本平台不介入金流，亦不對交易結果負擔保責任。'),
  LegalSection('5. 使用者行為規範',
      '您同意不從事下列行為：發布虛假、詐騙或誤導性資訊；騷擾、辱罵或威脅其他使用者；發布違法、色情、仇恨或侵權內容；利用程式自動化大量操作；規避平台機制或破壞系統安全。'),
  LegalSection('6. 評價機制',
      '評價應基於真實交易體驗。禁止刷評、惡意攻擊或不實評價。本平台保留移除違規評價的權利。'),
  LegalSection('7. 智慧財產權',
      '「寶可夢」及相關名稱、圖樣之權利屬其各自權利人所有，本平台與其無隸屬或代言關係。您上傳的內容仍屬您所有，但您授權本平台在提供服務範圍內使用、顯示該等內容。'),
  LegalSection('8. 免責聲明',
      '本平台依「現狀」提供服務，不保證服務不中斷、無錯誤或完全符合您的需求。對於使用者之間的交易爭議、卡牌真偽、款項糾紛等，本平台不負擔保或賠償責任，但會在合理範圍內協助處理。'),
  LegalSection('9. 責任限制',
      '在法律允許的最大範圍內，本平台對於因使用或無法使用本服務所生之任何間接、附帶、衍生性損害，不負賠償責任。'),
  LegalSection('10. 帳號終止',
      '若您違反本條款，本平台得限制、暫停或終止您的帳號使用權，且無需事先通知。'),
  LegalSection('11. 條款變更',
      '本平台得不時修訂本條款，並於平台內公告。修訂後您繼續使用本平台，即視為同意修訂後的條款。'),
  LegalSection('12. 準據法',
      '本條款之解釋與適用，以及因本條款所生之爭議，均依中華民國（台灣）法律處理。'),
];
