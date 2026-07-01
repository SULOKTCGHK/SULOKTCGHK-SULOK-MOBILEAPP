/// 系列分類選項（series_id → 顯示名稱），供 admin 新增/重新分類系列用。
/// 與 dex_screen 的 _seriesNames 對齊。
// 判定系列屬於哪個大分類：box(擴充盒) / deck(禮盒) / promo(特典卡)
// 與 dex_screen 的 _category 邏輯一致，供 storage 資料夾分類用。
final RegExp _kDeckPattern = RegExp(
    r'deck|starter|build.box|gift.box|trainer.box|special.set|special.deck|half.deck|kit|battle master|premium|construction|start decks|\bvs\b');

String setBranch(String id, String name) {
  final idL = id.toLowerCase();
  final nameL = name.toLowerCase();
  if (nameL.contains('promo') || idL.contains('-p-')) return 'promo';
  if (_kDeckPattern.hasMatch('$idL $nameL')) return 'deck';
  return 'box';
}

const Map<String, String> kSeriesOptions = {
  'm': 'Mega 系列',
  'sv': '朱＆紫系列',
  's': '劍＆盾系列',
  'sp': '劍盾特別系列',
  'sm': '太陽＆月亮系列',
  'xy': 'XY 系列',
  'cp': 'XY 概念包系列',
  'bw': '黑＆白系列',
  'dp': '鑽石＆珍珠系列',
  'pt': '白金系列',
  'l': 'LEGEND 系列',
  'adv': 'ADV（紅寶石）系列',
  'classic1': '初代系列',
  'neo': 'Neo（金銀）系列',
  'ecard': 'e卡系列',
  'pcg': 'PCG（EX）系列',
};
