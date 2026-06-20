import '../services/api_service.dart';

/// 日版 PROMO 卡系列靜態資料（TCGdex 不提供，由平台自行維護）
final List<ApiSet> kJaPromoSets = [
  ApiSet(
    id: 'SV-P',
    name: 'スカーレット＆バイオレット プロモカード',
    series: 'スカーレット＆バイオレット',
    seriesId: 'sv',
    releaseDate: '2022-12-02',
    total: 0,
  ),
  ApiSet(
    id: 'S-P',
    name: 'ソード＆シールド プロモカード',
    series: 'ソード＆シールド',
    seriesId: 'ss',
    releaseDate: '2020-01-10',
    total: 0,
  ),
  ApiSet(
    id: 'SM-P',
    name: 'サン＆ムーン プロモカード',
    series: 'サン＆ムーン',
    seriesId: 'sm',
    releaseDate: '2016-12-09',
    total: 0,
  ),
  ApiSet(
    id: 'XY-P',
    name: 'XY プロモカード',
    series: 'XY',
    seriesId: 'xy',
    releaseDate: '2013-10-11',
    total: 0,
  ),
  ApiSet(
    id: 'BW-P',
    name: 'ブラック＆ホワイト プロモカード',
    series: 'ブラック＆ホワイト',
    seriesId: 'bw',
    releaseDate: '2010-09-18',
    total: 0,
  ),
  ApiSet(
    id: 'DP-P',
    name: 'ダイヤモンド＆パール プロモカード',
    series: 'ダイヤモンド＆パール',
    seriesId: 'dp',
    releaseDate: '2006-09-28',
    total: 0,
  ),
];

/// PROMO 系列繁中顯示名稱
const Map<String, String> kPromoSetNameZh = {
  'sv-p': '朱紫 PROMO',
  's-p': '劍盾 PROMO',
  'sm-p': '太陽月亮 PROMO',
  'xy-p': 'XY PROMO',
  'bw-p': '黑白 PROMO',
  'dp-p': '鑽石珍珠 PROMO',
};
