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
        title: '私隱政策',
        effectiveDate: '2026 年 6 月 22 日',
        sections: _privacySections,
      );

  factory LegalScreen.terms() => const LegalScreen(
        title: '服務條款',
        effectiveDate: '2026 年 6 月 22 日',
        sections: _termsSections,
      );

  factory LegalScreen.safety() => const LegalScreen(
        title: '安全交易提示',
        effectiveDate: '2026 年 6 月 22 日',
        sections: _safetySections,
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

// ── 私隱政策（香港 PDPO）──────────────────────────────────────────────────────
const List<LegalSection> _privacySections = [
  LegalSection('1. 前言',
      'PokeBid（以下稱「本平台」）是一個寶可夢卡牌交易與收藏的社群平台。本平台依據香港《個人資料（私隱）條例》（香港法例第 486 章，下稱「PDPO」）處理您的個人資料。本政策說明我們蒐集哪些資料、如何使用以及您擁有的權利。使用本平台即表示您同意本政策。'),
  LegalSection('2. 我們蒐集的資料',
      '• 帳戶資料：當您以 Google 帳戶登入時，我們會取得您的名稱、電子郵件與頭像。\n'
      '• 交易與內容資料：您建立的掛售商品、出價、聊天訊息、評價、收藏與願望清單。\n'
      '• 上傳內容：您上傳的卡牌圖片。\n'
      '• 使用資料：裝置類型、操作紀錄等技術資訊，用於改善服務與排除問題。'),
  LegalSection('3. 蒐集目的與使用',
      '我們僅為下列目的使用您的個人資料：提供及維護交易、聊天、通知等核心功能；顯示賣家評價與信用；發送與您交易相關的通知；維護平台安全、防止詐騙與濫用；以及遵循適用法律的要求。我們不會在未取得您同意下，將資料用於原蒐集目的以外的用途。'),
  LegalSection('4. 第三方服務',
      '本平台使用下列第三方服務協助運作：\n'
      '• Google 登入（身分驗證）\n'
      '• Supabase（資料儲存與後端服務）\n'
      '• 卡牌價格參考來源（如 TCGplayer、JustTCG、SNKRDUNK 等）僅用於顯示市場行情，不會傳送您的個人資料給這些服務。\n'
      '這些服務有其各自的私隱政策，建議您一併參閱。'),
  LegalSection('5. 資料轉移與披露',
      '我們不會出售您的個人資料。部分資訊（如顯示名稱、掛售內容、評價）會在平台上公開顯示，供其他使用者瀏覽。除法律要求、執法機關合法要求，或為保護平台與使用者安全所必需外，我們不會向第三方披露您的個人資料。'),
  LegalSection('6. 資料保安',
      '我們採取合理可行的保安措施保護您的個人資料，防止未經授權或意外的查閱、處理、刪除或使用。資料主要儲存於受存取控制保護的後端服務。'),
  LegalSection('7. 資料保存',
      '我們僅在達成蒐集目的所需期間保存您的個人資料。您可要求刪除帳戶及相關個人資料；惟部分交易或溝通紀錄可能因法律或處理糾紛需要而保留一段合理期間。'),
  LegalSection('8. 您的權利（查閱及更正）',
      '根據 PDPO，您有權查閱及更正本平台持有關於您的個人資料，亦可隨時撤回先前給予的同意。如需行使查閱、更正或刪除權利，請透過平台內客服管道與我們聯絡。我們會在條例規定的時間內回覆。'),
  LegalSection('9. 直接促銷',
      '除非取得您的同意，本平台不會將您的個人資料用於直接促銷。若日後提供促銷訊息，您可隨時免費選擇停止接收。'),
  LegalSection('10. 未成年人士',
      '本平台不針對未達可獨立締約年齡的人士提供服務。若您未達該年齡，請在家長或監護人同意及監督下使用。'),
  LegalSection('11. 政策變更',
      '我們可能不時更新本政策，重大變更將於平台內公告。變更後您繼續使用本平台，即視為同意更新後的政策。'),
  LegalSection('12. 聯絡我們',
      '若您對本私隱政策或個人資料處理有任何疑問或要求，請透過 PokeBid 平台內的客服管道或電子郵件與我們聯絡。'),
];

// ── 服務條款（香港，C2C 媒合平台）────────────────────────────────────────────
const List<LegalSection> _termsSections = [
  LegalSection('1. 條款的接受',
      '歡迎使用 PokeBid。當您註冊、登入或使用本平台任何功能時，即表示您已閱讀、理解並同意本服務條款。若您不同意，請勿使用本平台。'),
  LegalSection('2. 服務說明',
      'PokeBid 提供寶可夢卡牌的掛售、出價、聊天、收藏管理、圖鑑查詢與市場行情參考等功能。本平台為使用者之間（C2C）的交易媒合場所，所有交易由買賣雙方自行協商與完成。'),
  LegalSection('3. 平台角色與交易免責（重要）',
      'PokeBid 僅為買賣雙方提供刊登與聯絡的媒合服務，並非任何交易的一方。本平台：\n'
      '• 不經手任何款項，亦不參與議價；\n'
      '• 不負責驗證卡牌的真偽、品相或所有權；\n'
      '• 不處理寄送、交付、退款或退換。\n'
      '所有付款、交付及相關安排均由買賣雙方自行協商並自行承擔風險。因交易所生之任何糾紛、損失、詐騙、卡牌真偽或品相問題，概由買賣雙方自行負責，本平台不承擔任何責任。我們強烈建議您在交易前查閱對方評價並採取安全交易措施（見「安全交易提示」）。'),
  LegalSection('4. 帳戶與資格',
      '您須提供真實、正確的資料，並對帳戶下的所有活動負責。您須達到香港法律下可獨立締結合約的年齡。請妥善保管登入憑證，不得將帳戶轉讓或出借他人。'),
  LegalSection('5. 刊登與交易規則',
      '• 賣家須對所刊登卡牌的真實性、狀況描述與所有權負責。\n'
      '• 禁止刊登仿冒品、贓物、侵權品或任何違法物品。\n'
      '• 平台顯示的市場行情（包括 PSA 等級成交價）僅供參考，不構成價格保證或投資建議。\n'
      '• 幣值以港幣（HK\$）顯示；日本市場成交價會按參考匯率換算，僅供參考。'),
  LegalSection('6. 使用者行為規範',
      '您同意不從事下列行為：發布虛假、詐騙或誤導性資訊；騷擾、辱罵或威脅其他使用者；發布違法、色情、仇恨或侵權內容；利用程式自動化大量操作；規避平台機制或破壞系統保安。'),
  LegalSection('7. 評價機制',
      '評價應基於真實交易體驗。禁止刷評、惡意攻擊或不實評價。本平台保留移除違規評價的權利。'),
  LegalSection('8. 知識產權',
      '「寶可夢」（Pokémon）及相關名稱、標誌、圖樣之權利屬其各自權利人（包括任天堂／株式會社 Pokémon 等）所有，本平台與其並無任何隸屬、贊助或代言關係。卡牌圖片與市場資料來自第三方來源，僅供識別與參考。您上傳的內容仍屬您所有，但您授權本平台在提供服務範圍內使用及顯示該等內容。'),
  LegalSection('9. 免責聲明',
      '本平台依「現狀」及「現有」基礎提供服務，不就服務不中斷、無錯誤、行情準確性或完全符合您的需求作任何明示或默示保證。'),
  LegalSection('10. 責任限制',
      '在香港法律允許的最大範圍內，本平台對於因使用或無法使用本服務、或因使用者之間交易所生之任何直接、間接、附帶或衍生性損害，均不負賠償責任。'),
  LegalSection('11. 帳戶終止',
      '若您違反本條款，本平台得在無須事先通知下，限制、暫停或終止您的帳戶使用權。'),
  LegalSection('12. 條款變更',
      '本平台得不時修訂本條款，並於平台內公告。修訂後您繼續使用本平台，即視為同意修訂後的條款。'),
  LegalSection('13. 準據法及管轄',
      '本條款受香港特別行政區法律管轄並據其詮釋。因本條款或您使用本平台所生之任何爭議，雙方同意交由香港特別行政區法院處理。'),
];

// ── 安全交易提示 ──────────────────────────────────────────────────────────────
const List<LegalSection> _safetySections = [
  LegalSection('PokeBid 不經手金流',
      '本平台只負責媒合買賣雙方，不參與付款或寄送。所有交易由你和對方自行完成，請務必採取以下措施保障自己。'),
  LegalSection('交易前',
      '• 先查看對方的評價與交易紀錄，信用低或全新帳戶要特別小心。\n'
      '• 要求賣家提供卡片的清晰實拍照片（含正反面、邊角、評級標籤）。\n'
      '• 高價卡建議要求 PSA／鑑定資料或影片驗證。'),
  LegalSection('面交（最推薦）',
      '• 約在人多、有閉路電視的公眾場所（如商場、港鐵站）。\n'
      '• 當面驗卡、確認無誤後才付款。\n'
      '• 高價交易可結伴前往。'),
  LegalSection('郵寄/付款',
      '• 使用有追蹤編號的寄件方式，並保留單據。\n'
      '• 盡量使用有買家保障或可追溯的付款方式。\n'
      '• 避免在驗證對方前就全額預付到不明帳戶。'),
  LegalSection('詐騙警號 🚩',
      '• 催促你「馬上轉帳」、要求離開平台私下交易。\n'
      '• 價格遠低於市價、聽起來好得不真實。\n'
      '• 收款後失聯、拒絕視訊或實拍驗卡。\n'
      '• 要求你先付「訂金／運費／關稅」到私人帳戶。'),
  LegalSection('遇到問題',
      '保留聊天紀錄、付款證明與單據。如懷疑受騙，請向香港警方求助；本平台可在合理範圍內協助提供相關紀錄，惟不承擔交易結果的責任。'),
];
