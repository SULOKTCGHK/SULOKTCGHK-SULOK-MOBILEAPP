import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/supabase_service.dart';
import '../services/api_service.dart';
import 'dex_card_detail_screen.dart';
import '../i18n/strings.dart';

// 世代定義：name、id 範圍
const List<Map<String, dynamic>> _kGens = [
  {'label': '全部',  'min': 1,   'max': 9999},
  {'label': 'Gen 1 🔴', 'min': 1,   'max': 151},
  {'label': 'Gen 2 🌿', 'min': 152, 'max': 251},
  {'label': 'Gen 3 💎', 'min': 252, 'max': 386},
  {'label': 'Gen 4 💠', 'min': 387, 'max': 493},
  {'label': 'Gen 5 ⚡', 'min': 494, 'max': 649},
  {'label': 'Gen 6 🌸', 'min': 650, 'max': 721},
  {'label': 'Gen 7 🌺', 'min': 722, 'max': 809},
  {'label': 'Gen 8 ⚔️', 'min': 810, 'max': 905},
  {'label': 'Gen 9 🌙', 'min': 906, 'max': 9999},
];

// 精靈基本資料（編號、英文名、中文名）
const List<Map<String, dynamic>> _kPokemonList = [
  {'id': 1, 'en': 'Bulbasaur', 'zh': '妙蛙種子'},
  {'id': 2, 'en': 'Ivysaur', 'zh': '妙蛙草'},
  {'id': 3, 'en': 'Venusaur', 'zh': '妙蛙花'},
  {'id': 4, 'en': 'Charmander', 'zh': '小火龍'},
  {'id': 5, 'en': 'Charmeleon', 'zh': '火恐龍'},
  {'id': 6, 'en': 'Charizard', 'zh': '噴火龍'},
  {'id': 7, 'en': 'Squirtle', 'zh': '傑尼龜'},
  {'id': 8, 'en': 'Wartortle', 'zh': '卡咪龜'},
  {'id': 9, 'en': 'Blastoise', 'zh': '水箭龜'},
  {'id': 10, 'en': 'Caterpie', 'zh': '綠毛蟲'},
  {'id': 11, 'en': 'Metapod', 'zh': '鐵甲蛹'},
  {'id': 12, 'en': 'Butterfree', 'zh': '巴大蝴'},
  {'id': 13, 'en': 'Weedle', 'zh': '獨角蟲'},
  {'id': 14, 'en': 'Kakuna', 'zh': '蜂巢蟲'},
  {'id': 15, 'en': 'Beedrill', 'zh': '大針蜂'},
  {'id': 16, 'en': 'Pidgey', 'zh': '波波'},
  {'id': 17, 'en': 'Pidgeotto', 'zh': '比比鳥'},
  {'id': 18, 'en': 'Pidgeot', 'zh': '大比鳥'},
  {'id': 19, 'en': 'Rattata', 'zh': '小拉達'},
  {'id': 20, 'en': 'Raticate', 'zh': '拉達'},
  {'id': 21, 'en': 'Spearow', 'zh': '烈雀'},
  {'id': 22, 'en': 'Fearow', 'zh': '大嘴雀'},
  {'id': 23, 'en': 'Ekans', 'zh': '阿柏蛇'},
  {'id': 24, 'en': 'Arbok', 'zh': '阿柏怪'},
  {'id': 25, 'en': 'Pikachu', 'zh': '比卡超'},
  {'id': 26, 'en': 'Raichu', 'zh': '雷丘'},
  {'id': 27, 'en': 'Sandshrew', 'zh': '穿山鼠'},
  {'id': 28, 'en': 'Sandslash', 'zh': '穿山王'},
  {'id': 29, 'en': 'Nidoran♀', 'zh': '尼多蘭'},
  {'id': 30, 'en': 'Nidorina', 'zh': '尼多娜'},
  {'id': 31, 'en': 'Nidoqueen', 'zh': '尼多后'},
  {'id': 32, 'en': 'Nidoran♂', 'zh': '尼多朗'},
  {'id': 33, 'en': 'Nidorino', 'zh': '尼多力諾'},
  {'id': 34, 'en': 'Nidoking', 'zh': '尼多王'},
  {'id': 35, 'en': 'Clefairy', 'zh': '皮皮'},
  {'id': 36, 'en': 'Clefable', 'zh': '皮可西'},
  {'id': 37, 'en': 'Vulpix', 'zh': '六尾'},
  {'id': 38, 'en': 'Ninetales', 'zh': '九尾'},
  {'id': 39, 'en': 'Jigglypuff', 'zh': '胖丁'},
  {'id': 40, 'en': 'Wigglytuff', 'zh': '胖可丁'},
  {'id': 41, 'en': 'Zubat', 'zh': '超音蝠'},
  {'id': 42, 'en': 'Golbat', 'zh': '大嘴蝠'},
  {'id': 43, 'en': 'Oddish', 'zh': '走路草'},
  {'id': 44, 'en': 'Gloom', 'zh': '臭臭花'},
  {'id': 45, 'en': 'Vileplume', 'zh': '霸王花'},
  {'id': 46, 'en': 'Paras', 'zh': '派拉斯'},
  {'id': 47, 'en': 'Parasect', 'zh': '派拉斯特'},
  {'id': 48, 'en': 'Venonat', 'zh': '毛球'},
  {'id': 49, 'en': 'Venomoth', 'zh': '摩魯蛾'},
  {'id': 50, 'en': 'Diglett', 'zh': '地鼠'},
  {'id': 51, 'en': 'Dugtrio', 'zh': '三地鼠'},
  {'id': 52, 'en': 'Meowth', 'zh': '喵喵'},
  {'id': 53, 'en': 'Persian', 'zh': '貓老大'},
  {'id': 54, 'en': 'Psyduck', 'zh': '可達鴨'},
  {'id': 55, 'en': 'Golduck', 'zh': '哥達鴨'},
  {'id': 56, 'en': 'Mankey', 'zh': '猴怪'},
  {'id': 57, 'en': 'Primeape', 'zh': '火爆猴'},
  {'id': 58, 'en': 'Growlithe', 'zh': '卡蒂狗'},
  {'id': 59, 'en': 'Arcanine', 'zh': '風速狗'},
  {'id': 60, 'en': 'Poliwag', 'zh': '蚊香蝌蚪'},
  {'id': 61, 'en': 'Poliwhirl', 'zh': '蚊香君'},
  {'id': 62, 'en': 'Poliwrath', 'zh': '蚊香泳士'},
  {'id': 63, 'en': 'Abra', 'zh': '凱西'},
  {'id': 64, 'en': 'Kadabra', 'zh': '勇基拉'},
  {'id': 65, 'en': 'Alakazam', 'zh': '胡地'},
  {'id': 66, 'en': 'Machop', 'zh': '腕力'},
  {'id': 67, 'en': 'Machoke', 'zh': '豪力'},
  {'id': 68, 'en': 'Machamp', 'zh': '怪力'},
  {'id': 69, 'en': 'Bellsprout', 'zh': '喇叭芽'},
  {'id': 70, 'en': 'Weepinbell', 'zh': '口呆花'},
  {'id': 71, 'en': 'Victreebel', 'zh': '大食花'},
  {'id': 72, 'en': 'Tentacool', 'zh': '蚊香海星'},
  {'id': 73, 'en': 'Tentacruel', 'zh': '毒刺水母'},
  {'id': 74, 'en': 'Geodude', 'zh': '小拳石'},
  {'id': 75, 'en': 'Graveler', 'zh': '隆隆石'},
  {'id': 76, 'en': 'Golem', 'zh': '隆隆岩'},
  {'id': 77, 'en': 'Ponyta', 'zh': '小火馬'},
  {'id': 78, 'en': 'Rapidash', 'zh': '烈焰馬'},
  {'id': 79, 'en': 'Slowpoke', 'zh': '呆呆獸'},
  {'id': 80, 'en': 'Slowbro', 'zh': '呆殼獸'},
  {'id': 81, 'en': 'Magnemite', 'zh': '小磁怪'},
  {'id': 82, 'en': 'Magneton', 'zh': '三合磁怪'},
  {'id': 83, 'en': 'Farfetch\'d', 'zh': '大蔥鴨'},
  {'id': 84, 'en': 'Doduo', 'zh': '嘟嘟'},
  {'id': 85, 'en': 'Dodrio', 'zh': '嘟嘟利'},
  {'id': 86, 'en': 'Seel', 'zh': '小海獅'},
  {'id': 87, 'en': 'Dewgong', 'zh': '白海獅'},
  {'id': 88, 'en': 'Grimer', 'zh': '臭泥'},
  {'id': 89, 'en': 'Muk', 'zh': '臭臭泥'},
  {'id': 90, 'en': 'Shellder', 'zh': '大舌貝'},
  {'id': 91, 'en': 'Cloyster', 'zh': '刺甲貝'},
  {'id': 92, 'en': 'Gastly', 'zh': '鬼斯'},
  {'id': 93, 'en': 'Haunter', 'zh': '鬼斯通'},
  {'id': 94, 'en': 'Gengar', 'zh': '耿鬼'},
  {'id': 95, 'en': 'Onix', 'zh': '大岩蛇'},
  {'id': 96, 'en': 'Drowzee', 'zh': '催眠貘'},
  {'id': 97, 'en': 'Hypno', 'zh': '引夢貘人'},
  {'id': 98, 'en': 'Krabby', 'zh': '大鉗蟹'},
  {'id': 99, 'en': 'Kingler', 'zh': '鉗蟹王'},
  {'id': 100, 'en': 'Voltorb', 'zh': '霹靂球'},
  {'id': 101, 'en': 'Electrode', 'zh': '頑皮雷彈'},
  {'id': 102, 'en': 'Exeggcute', 'zh': '蛋蛋'},
  {'id': 103, 'en': 'Exeggutor', 'zh': '椰蛋樹'},
  {'id': 104, 'en': 'Cubone', 'zh': '卡拉卡拉'},
  {'id': 105, 'en': 'Marowak', 'zh': '嘎啦嘎啦'},
  {'id': 106, 'en': 'Hitmonlee', 'zh': '飛腿郎'},
  {'id': 107, 'en': 'Hitmonchan', 'zh': '快拳郎'},
  {'id': 108, 'en': 'Lickitung', 'zh': '大舌頭'},
  {'id': 109, 'en': 'Koffing', 'zh': '瓦斯彈'},
  {'id': 110, 'en': 'Weezing', 'zh': '雙彈瓦斯'},
  {'id': 111, 'en': 'Rhyhorn', 'zh': '獨角犀牛'},
  {'id': 112, 'en': 'Rhydon', 'zh': '頑皮熊貓'},
  {'id': 113, 'en': 'Chansey', 'zh': '幸福蛋'},
  {'id': 114, 'en': 'Tangela', 'zh': '蔓藤怪'},
  {'id': 115, 'en': 'Kangaskhan', 'zh': '袋龍'},
  {'id': 116, 'en': 'Horsea', 'zh': '墨海馬'},
  {'id': 117, 'en': 'Seadra', 'zh': '海刺龍'},
  {'id': 118, 'en': 'Goldeen', 'zh': '角金魚'},
  {'id': 119, 'en': 'Seaking', 'zh': '金魚王'},
  {'id': 120, 'en': 'Staryu', 'zh': '海星星'},
  {'id': 121, 'en': 'Starmie', 'zh': '寶石海星'},
  {'id': 122, 'en': 'Mr. Mime', 'zh': '魔牆人偶'},
  {'id': 123, 'en': 'Scyther', 'zh': '飛天螳螂'},
  {'id': 124, 'en': 'Jynx', 'zh': '迷唇姐'},
  {'id': 125, 'en': 'Electabuzz', 'zh': '電擊獸'},
  {'id': 126, 'en': 'Magmar', 'zh': '鴨嘴火獸'},
  {'id': 127, 'en': 'Pinsir', 'zh': '凱羅斯'},
  {'id': 128, 'en': 'Tauros', 'zh': '肯泰羅'},
  {'id': 129, 'en': 'Magikarp', 'zh': '鯉魚王'},
  {'id': 130, 'en': 'Gyarados', 'zh': '暴鯉龍'},
  {'id': 131, 'en': 'Lapras', 'zh': '拉普拉斯'},
  {'id': 132, 'en': 'Ditto', 'zh': '百變怪'},
  {'id': 133, 'en': 'Eevee', 'zh': '伊布'},
  {'id': 134, 'en': 'Vaporeon', 'zh': '水伊布'},
  {'id': 135, 'en': 'Jolteon', 'zh': '雷伊布'},
  {'id': 136, 'en': 'Flareon', 'zh': '火伊布'},
  {'id': 137, 'en': 'Porygon', 'zh': '多邊獸'},
  {'id': 138, 'en': 'Omanyte', 'zh': '菊石獸'},
  {'id': 139, 'en': 'Omastar', 'zh': '多刺菊石獸'},
  {'id': 140, 'en': 'Kabuto', 'zh': '化石盔'},
  {'id': 141, 'en': 'Kabutops', 'zh': '鐮刀盔'},
  {'id': 142, 'en': 'Aerodactyl', 'zh': '化石翼龍'},
  {'id': 143, 'en': 'Snorlax', 'zh': '卡比獸'},
  {'id': 144, 'en': 'Articuno', 'zh': '急凍鳥'},
  {'id': 145, 'en': 'Zapdos', 'zh': '閃電鳥'},
  {'id': 146, 'en': 'Moltres', 'zh': '火焰鳥'},
  {'id': 147, 'en': 'Dratini', 'zh': '迷你龍'},
  {'id': 148, 'en': 'Dragonair', 'zh': '哈克龍'},
  {'id': 149, 'en': 'Dragonite', 'zh': '快龍'},
  {'id': 150, 'en': 'Mewtwo', 'zh': '超夢'},
  {'id': 151, 'en': 'Mew', 'zh': '夢幻'},
  // Gen 2
  {'id': 152, 'en': 'Chikorita', 'zh': '菊草葉'},
  {'id': 153, 'en': 'Bayleef', 'zh': '月桂葉'},
  {'id': 154, 'en': 'Meganium', 'zh': '大花園'},
  {'id': 155, 'en': 'Cyndaquil', 'zh': '火球鼠'},
  {'id': 156, 'en': 'Quilava', 'zh': '火岩鼠'},
  {'id': 157, 'en': 'Typhlosion', 'zh': '火爆獸'},
  {'id': 158, 'en': 'Totodile', 'zh': '湯姆士'},
  {'id': 159, 'en': 'Croconaw', 'zh': '藍鱷'},
  {'id': 160, 'en': 'Feraligatr', 'zh': '大力鱷'},
  {'id': 175, 'en': 'Togepi', 'zh': '波克比'},
  {'id': 176, 'en': 'Togetic', 'zh': '波克基古'},
  {'id': 179, 'en': 'Mareep', 'zh': '咩利羊'},
  {'id': 181, 'en': 'Ampharos', 'zh': '電龍'},
  {'id': 183, 'en': 'Marill', 'zh': '瑪力露'},
  {'id': 196, 'en': 'Espeon', 'zh': '太陽伊布'},
  {'id': 197, 'en': 'Umbreon', 'zh': '月亮伊布'},
  {'id': 203, 'en': 'Girafarig', 'zh': '麒麟奇'},
  {'id': 212, 'en': 'Scizor', 'zh': '剪刀蟲'},
  {'id': 214, 'en': 'Heracross', 'zh': '赫拉克羅斯'},
  {'id': 215, 'en': 'Sneasel', 'zh': '狃拉'},
  {'id': 216, 'en': 'Teddiursa', 'zh': '熊寶寶'},
  {'id': 217, 'en': 'Ursaring', 'zh': '圈圈熊'},
  {'id': 220, 'en': 'Swinub', 'zh': '小山豬'},
  {'id': 225, 'en': 'Delibird', 'zh': '送禮鳥'},
  {'id': 228, 'en': 'Houndour', 'zh': '戴魯比'},
  {'id': 229, 'en': 'Houndoom', 'zh': '黑魯加'},
  {'id': 234, 'en': 'Stantler', 'zh': '驚角鹿'},
  {'id': 238, 'en': 'Smoochum', 'zh': '迷唇寶'},
  {'id': 239, 'en': 'Elekid', 'zh': '電擊怪'},
  {'id': 240, 'en': 'Magby', 'zh': '鴨嘴寶寶'},
  {'id': 241, 'en': 'Miltank', 'zh': '大奶罐'},
  {'id': 242, 'en': 'Blissey', 'zh': '幸福蛋進化'},
  {'id': 243, 'en': 'Raikou', 'zh': '雷公'},
  {'id': 244, 'en': 'Entei', 'zh': '炎帝'},
  {'id': 245, 'en': 'Suicune', 'zh': '水君'},
  {'id': 246, 'en': 'Larvitar', 'zh': '幼基拉斯'},
  {'id': 247, 'en': 'Pupitar', 'zh': '沙基拉斯'},
  {'id': 248, 'en': 'Tyranitar', 'zh': '班基拉斯'},
  {'id': 249, 'en': 'Lugia', 'zh': '航母拉希'},
  {'id': 250, 'en': 'Ho-Oh', 'zh': '鳳王'},
  {'id': 251, 'en': 'Celebi', 'zh': '鬢蜻蜓'},
  // Gen 3
  {'id': 252, 'en': 'Treecko', 'zh': '木守宮'},
  {'id': 255, 'en': 'Torchic', 'zh': '火稚雞'},
  {'id': 258, 'en': 'Mudkip', 'zh': '泥泥鰻'},
  {'id': 261, 'en': 'Poochyena', 'zh': '土狼犬'},
  {'id': 270, 'en': 'Lotad', 'zh': '湖湖草'},
  {'id': 280, 'en': 'Ralts', 'zh': '拉鲁拉斯'},
  {'id': 281, 'en': 'Kirlia', 'zh': '奇魯莉安'},
  {'id': 282, 'en': 'Gardevoir', 'zh': '沙奈朵'},
  {'id': 302, 'en': 'Sableye', 'zh': '煤炭鬼'},
  {'id': 303, 'en': 'Mawile', 'zh': '大嘴娃'},
  {'id': 304, 'en': 'Aron', 'zh': '可可多拉'},
  {'id': 306, 'en': 'Aggron', 'zh': '波士可多拉'},
  {'id': 310, 'en': 'Manectric', 'zh': '雷電犬'},
  {'id': 316, 'en': 'Gulpin', 'zh': '溶食獸'},
  {'id': 319, 'en': 'Sharpedo', 'zh': '巨牙鯊'},
  {'id': 320, 'en': 'Wailmer', 'zh': '吼吼鯨'},
  {'id': 321, 'en': 'Wailord', 'zh': '吼鯨王'},
  {'id': 323, 'en': 'Camerupt', 'zh': '熔岩蟲'},
  {'id': 330, 'en': 'Flygon', 'zh': '沙漠蜻蜓'},
  {'id': 334, 'en': 'Altaria', 'zh': '七夕青鳥'},
  {'id': 350, 'en': 'Milotic', 'zh': '美納斯'},
  {'id': 354, 'en': 'Banette', 'zh': '詛咒娃娃'},
  {'id': 358, 'en': 'Chimecho', 'zh': '風鈴鈴'},
  {'id': 359, 'en': 'Absol', 'zh': '阿勃梭魯'},
  {'id': 362, 'en': 'Glalie', 'zh': '冰鬼護'},
  {'id': 371, 'en': 'Bagon', 'zh': '哈克龍 Jr.'},
  {'id': 374, 'en': 'Beldum', 'zh': '鋼塊小子'},
  {'id': 375, 'en': 'Metang', 'zh': '金屬怪'},
  {'id': 376, 'en': 'Metagross', 'zh': '巨金怪'},
  {'id': 377, 'en': 'Regirock', 'zh': '雷吉洛克'},
  {'id': 378, 'en': 'Regice', 'zh': '雷吉艾斯'},
  {'id': 379, 'en': 'Registeel', 'zh': '雷吉斯奇魯'},
  {'id': 380, 'en': 'Latias', 'zh': '拉帝亞斯'},
  {'id': 381, 'en': 'Latios', 'zh': '拉帝歐斯'},
  {'id': 382, 'en': 'Kyogre', 'zh': '蓋歐卡'},
  {'id': 383, 'en': 'Groudon', 'zh': '固拉多'},
  {'id': 384, 'en': 'Rayquaza', 'zh': '烈空坐'},
  {'id': 385, 'en': 'Jirachi', 'zh': '基拉祈'},
  {'id': 386, 'en': 'Deoxys', 'zh': '代歐奇希斯'},
  // Gen 4
  {'id': 387, 'en': 'Turtwig', 'zh': '草苗龜'},
  {'id': 390, 'en': 'Chimchar', 'zh': '小猴火'},
  {'id': 393, 'en': 'Piplup', 'zh': '波加曼'},
  {'id': 396, 'en': 'Starly', 'zh': '姆克兒'},
  {'id': 403, 'en': 'Shinx', 'zh': '小獅雄'},
  {'id': 408, 'en': 'Cranidos', 'zh': '頭冠龍'},
  {'id': 412, 'en': 'Burmy', 'zh': '結草兒'},
  {'id': 417, 'en': 'Pachirisu', 'zh': '帕奇利茲'},
  {'id': 418, 'en': 'Buizel', 'zh': '浮潛小獺'},
  {'id': 425, 'en': 'Drifloon', 'zh': '飄飄球'},
  {'id': 427, 'en': 'Buneary', 'zh': '卷卷耳'},
  {'id': 431, 'en': 'Glameow', 'zh': '魅力喵'},
  {'id': 437, 'en': 'Bronzong', 'zh': '青銅鈴鐺'},
  {'id': 442, 'en': 'Spiritomb', 'zh': '奇幻守門員'},
  {'id': 443, 'en': 'Gible', 'zh': '鯉魚龍'},
  {'id': 444, 'en': 'Gabite', 'zh': '嗡蝠龍'},
  {'id': 445, 'en': 'Garchomp', 'zh': '烈咬陸鯊'},
  {'id': 447, 'en': 'Riolu', 'zh': '利歐路'},
  {'id': 448, 'en': 'Lucario', 'zh': '路卡利歐'},
  {'id': 453, 'en': 'Croagunk', 'zh': '毒蛙小子'},
  {'id': 459, 'en': 'Snover', 'zh': '雪笠怪'},
  {'id': 460, 'en': 'Abomasnow', 'zh': '暴雪王'},
  {'id': 461, 'en': 'Weavile', 'zh': '暴雪貂'},
  {'id': 462, 'en': 'Magnezone', 'zh': '磁力怪'},
  {'id': 464, 'en': 'Rhyperior', 'zh': '超甲狂犀'},
  {'id': 466, 'en': 'Electivire', 'zh': '電擊魔獸'},
  {'id': 467, 'en': 'Magmortar', 'zh': '鴨嘴炎獸'},
  {'id': 468, 'en': 'Togekiss', 'zh': '波克基斯'},
  {'id': 470, 'en': 'Leafeon', 'zh': '葉伊布'},
  {'id': 471, 'en': 'Glaceon', 'zh': '冰伊布'},
  {'id': 472, 'en': 'Gliscor', 'zh': '天蠍王'},
  {'id': 475, 'en': 'Gallade', 'zh': '艾路雷朵'},
  {'id': 479, 'en': 'Rotom', 'zh': '洛托姆'},
  {'id': 480, 'en': 'Uxie', 'zh': '由克希'},
  {'id': 481, 'en': 'Mesprit', 'zh': '艾姆利多'},
  {'id': 482, 'en': 'Azelf', 'zh': '阿古諾姆'},
  {'id': 483, 'en': 'Dialga', 'zh': '帝牙盧卡'},
  {'id': 484, 'en': 'Palkia', 'zh': '帕路奇亞'},
  {'id': 485, 'en': 'Heatran', 'zh': '席多藍恩'},
  {'id': 486, 'en': 'Regigigas', 'zh': '雷吉奇卡斯'},
  {'id': 487, 'en': 'Giratina', 'zh': '騎拉帝納'},
  {'id': 488, 'en': 'Cresselia', 'zh': '克雷色利亞'},
  {'id': 490, 'en': 'Manaphy', 'zh': '瑪納霏'},
  {'id': 491, 'en': 'Darkrai', 'zh': '達克萊伊'},
  {'id': 492, 'en': 'Shaymin', 'zh': '謝米'},
  {'id': 493, 'en': 'Arceus', 'zh': '阿爾宙斯'},
  // Gen 5
  {'id': 494, 'en': 'Victini', 'zh': '比克提尼'},
  {'id': 495, 'en': 'Snivy', 'zh': '藤藤蛇'},
  {'id': 498, 'en': 'Tepig', 'zh': '暖暖豬'},
  {'id': 501, 'en': 'Oshawott', 'zh': '水水獺'},
  {'id': 504, 'en': 'Patrat', 'zh': '直盯土撥鼠'},
  {'id': 506, 'en': 'Lillipup', 'zh': '小約克'},
  {'id': 509, 'en': 'Purrloin', 'zh': '淘氣貓'},
  {'id': 519, 'en': 'Pidove', 'zh': '豆鴿'},
  {'id': 524, 'en': 'Roggenrola', 'zh': '石丸子'},
  {'id': 529, 'en': 'Drilbur', 'zh': '螺絲鑽'},
  {'id': 532, 'en': 'Timburr', 'zh': '木木梟'},
  {'id': 540, 'en': 'Sewaddle', 'zh': '蟲蟲棉斗蓬'},
  {'id': 546, 'en': 'Cottonee', 'zh': '棉棉豆'},
  {'id': 548, 'en': 'Petilil', 'zh': '花小姐'},
  {'id': 555, 'en': 'Darmanitan', 'zh': '達摩狒狒'},
  {'id': 562, 'en': 'Yamask', 'zh': '行道面具'},
  {'id': 570, 'en': 'Zorua', 'zh': '索羅亞'},
  {'id': 571, 'en': 'Zoroark', 'zh': '索羅亞克'},
  {'id': 572, 'en': 'Minccino', 'zh': '泡泡鼠'},
  {'id': 577, 'en': 'Solosis', 'zh': '核子小體'},
  {'id': 580, 'en': 'Ducklett', 'zh': '泳圈鴨'},
  {'id': 590, 'en': 'Foongus', 'zh': '迷貝蘑菇'},
  {'id': 595, 'en': 'Joltik', 'zh': '電電蜘蛛'},
  {'id': 599, 'en': 'Klink', 'zh': '齒輪兒'},
  {'id': 610, 'en': 'Axew', 'zh': '牙牙'},
  {'id': 612, 'en': 'Haxorus', 'zh': '双斧戰龍'},
  {'id': 613, 'en': 'Cubchoo', 'zh': '一鼻子'},
  {'id': 614, 'en': 'Beartic', 'zh': '凍熊徒'},
  {'id': 619, 'en': 'Mienfoo', 'zh': '功夫鼬'},
  {'id': 621, 'en': 'Druddigon', 'zh': '赤面龍'},
  {'id': 624, 'en': 'Pawniard', 'zh': '刀片小兵'},
  {'id': 625, 'en': 'Bisharp', 'zh': '切割郎'},
  {'id': 628, 'en': 'Braviary', 'zh': '勇士雄鷹'},
  {'id': 631, 'en': 'Heatmor', 'zh': '食蟻獸'},
  {'id': 633, 'en': 'Deino', 'zh': '索龍丁'},
  {'id': 634, 'en': 'Zweilous', 'zh': '雙索龍'},
  {'id': 635, 'en': 'Hydreigon', 'zh': '三首暴龍'},
  {'id': 638, 'en': 'Cobalion', 'zh': '鋼鐵武神'},
  {'id': 639, 'en': 'Terrakion', 'zh': '岩石武神'},
  {'id': 640, 'en': 'Virizion', 'zh': '草原武神'},
  {'id': 641, 'en': 'Tornadus', 'zh': '龍捲雲'},
  {'id': 642, 'en': 'Thundurus', 'zh': '雷電雲'},
  {'id': 643, 'en': 'Reshiram', 'zh': '萊希拉姆'},
  {'id': 644, 'en': 'Zekrom', 'zh': '捷克羅姆'},
  {'id': 645, 'en': 'Landorus', 'zh': '土地雲'},
  {'id': 646, 'en': 'Kyurem', 'zh': '酋雷姆'},
  {'id': 647, 'en': 'Keldeo', 'zh': '凱路迪歐'},
  {'id': 648, 'en': 'Meloetta', 'zh': '美洛耶塔'},
  {'id': 649, 'en': 'Genesect', 'zh': '蓋諾賽克特'},
  // Gen 6
  {'id': 650, 'en': 'Chespin', 'zh': '哈利栗'},
  {'id': 653, 'en': 'Fennekin', 'zh': '火狐狸'},
  {'id': 656, 'en': 'Froakie', 'zh': '呱呱泡蛙'},
  {'id': 659, 'en': 'Bunnelby', 'zh': '掘兔'},
  {'id': 661, 'en': 'Fletchling', 'zh': '小箭雀'},
  {'id': 664, 'en': 'Scatterbug', 'zh': '粉蝶蟲'},
  {'id': 667, 'en': 'Litleo', 'zh': '小火獅'},
  {'id': 669, 'en': 'Flabébé', 'zh': '花蓓蓓'},
  {'id': 672, 'en': 'Skiddo', 'zh': '小山羊'},
  {'id': 674, 'en': 'Pancham', 'zh': '頑皮熊貓'},
  {'id': 677, 'en': 'Espurr', 'zh': '妙喵'},
  {'id': 678, 'en': 'Meowstic', 'zh': '超能妙喵'},
  {'id': 679, 'en': 'Honedge', 'zh': '獨劍鞘'},
  {'id': 680, 'en': 'Doublade', 'zh': '雙劍鞘'},
  {'id': 681, 'en': 'Aegislash', 'zh': '坚盾剑怪'},
  {'id': 682, 'en': 'Spritzee', 'zh': '香香球'},
  {'id': 684, 'en': 'Swirlix', 'zh': '棉花糖'},
  {'id': 686, 'en': 'Inkay', 'zh': '好啦魚'},
  {'id': 688, 'en': 'Binacle', 'zh': '兩面帽'},
  {'id': 690, 'en': 'Skrelp', 'zh': '哈哈海馬'},
  {'id': 692, 'en': 'Clauncher', 'zh': '蜇蝦'},
  {'id': 694, 'en': 'Helioptile', 'zh': '太陽蜥蜴'},
  {'id': 696, 'en': 'Tyrunt', 'zh': '提洛龍'},
  {'id': 698, 'en': 'Amaura', 'zh': '冰雪龍'},
  {'id': 700, 'en': 'Sylveon', 'zh': '仙子伊布'},
  {'id': 701, 'en': 'Hawlucha', 'zh': '摔角鷹人'},
  {'id': 702, 'en': 'Dedenne', 'zh': '天線美'},
  {'id': 703, 'en': 'Carbink', 'zh': '小鑽石'},
  {'id': 704, 'en': 'Goomy', 'zh': '軟泥龍'},
  {'id': 705, 'en': 'Sliggoo', 'zh': '黏液龍'},
  {'id': 706, 'en': 'Goodra', 'zh': '黏美龍'},
  {'id': 707, 'en': 'Klefki', 'zh': '鑰圈兒'},
  {'id': 708, 'en': 'Phantump', 'zh': '幽幽樹'},
  {'id': 710, 'en': 'Pumpkaboo', 'zh': '南瓜精'},
  {'id': 712, 'en': 'Bergmite', 'zh': '小冰駝'},
  {'id': 714, 'en': 'Noibat', 'zh': '噪音翼獸'},
  {'id': 715, 'en': 'Noivern', 'zh': '音波龍'},
  {'id': 716, 'en': 'Xerneas', 'zh': '哲爾尼亞斯'},
  {'id': 717, 'en': 'Yveltal', 'zh': '伊裴爾塔爾'},
  {'id': 718, 'en': 'Zygarde', 'zh': '基格爾德'},
  {'id': 719, 'en': 'Diancie', 'zh': '黛安希'},
  {'id': 720, 'en': 'Hoopa', 'zh': '胡帕'},
  {'id': 721, 'en': 'Volcanion', 'zh': '波爾凱尼恩'},
  // Gen 7
  {'id': 722, 'en': 'Rowlet', 'zh': '木木梟'},
  {'id': 725, 'en': 'Litten', 'zh': '火斑喵'},
  {'id': 728, 'en': 'Popplio', 'zh': '球球海獅'},
  {'id': 745, 'en': 'Lycanroc', 'zh': '小狼犬'},
  {'id': 753, 'en': 'Fomantis', 'zh': '假蜻蜓'},
  {'id': 758, 'en': 'Salazzle', 'zh': '焰后蜥'},
  {'id': 764, 'en': 'Comfey', 'zh': '花環椰蛋'},
  {'id': 765, 'en': 'Oranguru', 'zh': '智揮猩'},
  {'id': 766, 'en': 'Passimian', 'zh': '投擲猴'},
  {'id': 772, 'en': 'Type: Null', 'zh': '屬性：空'},
  {'id': 773, 'en': 'Silvally', 'zh': '銀伴戰獸'},
  {'id': 778, 'en': 'Mimikyu', 'zh': '謎擬 Q'},
  {'id': 785, 'en': 'Tapu Koko', 'zh': '卡璞・鸣鸣'},
  {'id': 786, 'en': 'Tapu Lele', 'zh': '卡璞・蝶蝶'},
  {'id': 787, 'en': 'Tapu Bulu', 'zh': '卡璞・哞哞'},
  {'id': 788, 'en': 'Tapu Fini', 'zh': '卡璞・鳍鳍'},
  {'id': 789, 'en': 'Cosmog', 'zh': '科斯莫古'},
  {'id': 790, 'en': 'Cosmoem', 'zh': '科斯莫姆'},
  {'id': 791, 'en': 'Solgaleo', 'zh': '索爾迦雷奧'},
  {'id': 792, 'en': 'Lunala', 'zh': '露奈雅拉'},
  {'id': 793, 'en': 'Nihilego', 'zh': '虛吾伊德'},
  {'id': 800, 'en': 'Necrozma', 'zh': '奈克洛茲瑪'},
  {'id': 801, 'en': 'Magearna', 'zh': '瑪機雅娜'},
  {'id': 802, 'en': 'Marshadow', 'zh': '瑪夏多'},
  {'id': 807, 'en': 'Zeraora', 'zh': '捷拉奧拉'},
  // Gen 8
  {'id': 808, 'en': 'Meltan', 'zh': '美錄坦'},
  {'id': 809, 'en': 'Melmetal', 'zh': '美錄梅塔爾'},
  {'id': 810, 'en': 'Grookey', 'zh': '敲音猴'},
  {'id': 813, 'en': 'Scorbunny', 'zh': '炎兔兒'},
  {'id': 816, 'en': 'Sobble', 'zh': '淚眼蜥'},
  {'id': 819, 'en': 'Skwovet', 'zh': '倉倉鼠'},
  {'id': 821, 'en': 'Rookidee', 'zh': '高傲雀'},
  {'id': 827, 'en': 'Nickit', 'zh': '小偷狐'},
  {'id': 835, 'en': 'Yamper', 'zh': '電電犬'},
  {'id': 840, 'en': 'Applin', 'zh': '蟲蟲蘋果'},
  {'id': 843, 'en': 'Silicobra', 'zh': '沙蛇'},
  {'id': 845, 'en': 'Cramorant', 'zh': '大嘴吞鳥'},
  {'id': 848, 'en': 'Toxel', 'zh': '小毒菠'},
  {'id': 854, 'en': 'Sinistea', 'zh': '茶毒壺'},
  {'id': 856, 'en': 'Hatenna', 'zh': '感應娃'},
  {'id': 859, 'en': 'Impidimp', 'zh': '小嗡嗡'},
  {'id': 862, 'en': 'Obstagoon', 'zh': '遮面取'},
  {'id': 863, 'en': 'Perrserker', 'zh': '呆毛喵'},
  {'id': 864, 'en': 'Cursola', 'zh': '死亡珊瑚'},
  {'id': 868, 'en': 'Milcery', 'zh': '奶霜仙子'},
  {'id': 869, 'en': 'Alcremie', 'zh': '奶霜蛋糕'},
  {'id': 870, 'en': 'Falinks', 'zh': '六面搖滾'},
  {'id': 873, 'en': 'Frosmoth', 'zh': '雪絨飛蛾'},
  {'id': 874, 'en': 'Stonjourner', 'zh': '巨石達夫'},
  {'id': 875, 'en': 'Eiscue', 'zh': '雪頭企鵝'},
  {'id': 876, 'en': 'Indeedee', 'zh': '的確小精靈'},
  {'id': 877, 'en': 'Morpeko', 'zh': '莫魯貝可'},
  {'id': 878, 'en': 'Cufant', 'zh': '小象斯'},
  {'id': 879, 'en': 'Copperajah', 'zh': '大象斯'},
  {'id': 880, 'en': 'Dracozolt', 'zh': '化石雷龍'},
  {'id': 884, 'en': 'Duraludon', 'zh': '鋁鋼龍'},
  {'id': 885, 'en': 'Dreepy', 'zh': '幽靈龍'},
  {'id': 886, 'en': 'Drakloak', 'zh': '幽靈騎龍'},
  {'id': 887, 'en': 'Dragapult', 'zh': '幽靈彈射龍'},
  {'id': 888, 'en': 'Zacian', 'zh': '薩熙'},
  {'id': 889, 'en': 'Zamazenta', 'zh': '薩馬曾達'},
  {'id': 890, 'en': 'Eternatus', 'zh': '無極汰那'},
  {'id': 891, 'en': 'Kubfu', 'zh': '熊徒弟'},
  {'id': 892, 'en': 'Urshifu', 'zh': '武道熊師'},
  {'id': 893, 'en': 'Zarude', 'zh': '薩露德'},
  {'id': 894, 'en': 'Regieleki', 'zh': '雷吉艾勒奇'},
  {'id': 895, 'en': 'Regidrago', 'zh': '雷吉龍'},
  {'id': 896, 'en': 'Glastrier', 'zh': '冰帝'},
  {'id': 897, 'en': 'Spectrier', 'zh': '幽帝'},
  {'id': 898, 'en': 'Calyrex', 'zh': '蕾冠王'},
  // Gen 9
  {'id': 906, 'en': 'Sprigatito', 'zh': '小草苗'},
  {'id': 909, 'en': 'Fuecoco', 'zh': '呆呆鱷'},
  {'id': 912, 'en': 'Quaxly', 'zh': '澄清鴨'},
  {'id': 915, 'en': 'Lechonk', 'zh': '炸豬排'},
  {'id': 917, 'en': 'Tarountula', 'zh': '毛毛蟲'},
  {'id': 919, 'en': 'Flittle', 'zh': '小蝶'},
  {'id': 921, 'en': 'Pawmi', 'zh': '小掌球'},
  {'id': 924, 'en': 'Tandemaus', 'zh': '田鼠二人'},
  {'id': 926, 'en': 'Fidough', 'zh': '可頌狗'},
  {'id': 928, 'en': 'Smoliv', 'zh': '小橄欖'},
  {'id': 931, 'en': 'Squawkabilly', 'zh': '鸚鵡'},
  {'id': 935, 'en': 'Maschiff', 'zh': '哈奇獸'},
  {'id': 937, 'en': 'Shroodle', 'zh': '毒鼩鼱'},
  {'id': 939, 'en': 'Bombirdier', 'zh': '炸彈鳥'},
  {'id': 941, 'en': 'Scovillain', 'zh': '辣椒鬼'},
  {'id': 943, 'en': 'Rellor', 'zh': '滾滾球'},
  {'id': 945, 'en': 'Flittle', 'zh': '小蝶'},
  {'id': 947, 'en': 'Tinkatink', 'zh': '叮叮錘'},
  {'id': 948, 'en': 'Tinkatuff', 'zh': '叮叮鑄'},
  {'id': 949, 'en': 'Tinkaton', 'zh': '叮叮大師'},
  {'id': 950, 'en': 'Wiglett', 'zh': '冰山地鼠'},
  {'id': 951, 'en': 'Wugtrio', 'zh': '三冰山'},
  {'id': 952, 'en': 'Bombirdier', 'zh': '炸彈鳥'},
  {'id': 953, 'en': 'Finizen', 'zh': '海豚'},
  {'id': 954, 'en': 'Palafin', 'zh': '超級海豚'},
  {'id': 955, 'en': 'Varoom', 'zh': '引擎怪'},
  {'id': 956, 'en': 'Revavroom', 'zh': '大引擎怪'},
  {'id': 957, 'en': 'Cyclizar', 'zh': '摩托蜥蜴'},
  {'id': 958, 'en': 'Orthworm', 'zh': '鐵頭蠕蟲'},
  {'id': 959, 'en': 'Glimmet', 'zh': '毒晶球'},
  {'id': 960, 'en': 'Glimmora', 'zh': '毒晶石'},
  {'id': 961, 'en': 'Greavard', 'zh': '幽靈犬'},
  {'id': 962, 'en': 'Houndstone', 'zh': '墓碑犬'},
  {'id': 963, 'en': 'Flamigo', 'zh': '火烈鳥'},
  {'id': 964, 'en': 'Cetoddle', 'zh': '鯨鯨'},
  {'id': 965, 'en': 'Cetitan', 'zh': '大鯨鯨'},
  {'id': 966, 'en': 'Veluza', 'zh': '斬鮫'},
  {'id': 967, 'en': 'Dondozo', 'zh': '鬍鬚鯰'},
  {'id': 968, 'en': 'Tatsugiri', 'zh': '大奴命'},
  {'id': 969, 'en': 'Annihilape', 'zh': '暴怒猴'},
  {'id': 970, 'en': 'Clodsire', 'zh': '毒地蟾蜍'},
  {'id': 971, 'en': 'Farigiraf', 'zh': '長頸龍'},
  {'id': 972, 'en': 'Dudunsparce', 'zh': '大師咩花'},
  {'id': 973, 'en': 'Kingambit', 'zh': '大師切割郎'},
  {'id': 974, 'en': 'Great Tusk', 'zh': '初代象牙'},
  {'id': 975, 'en': 'Scream Tail', 'zh': '初代粉蝶蟲'},
  {'id': 976, 'en': 'Brute Bonnet', 'zh': '初代蘑菇'},
  {'id': 977, 'en': 'Flutter Mane', 'zh': '初代皮皮'},
  {'id': 978, 'en': 'Slither Wing', 'zh': '初代巴大蝴'},
  {'id': 979, 'en': 'Sandy Shocks', 'zh': '初代三合磁怪'},
  {'id': 980, 'en': 'Iron Treads', 'zh': '未來版土地雲'},
  {'id': 981, 'en': 'Iron Bundle', 'zh': '未來版送禮鳥'},
  {'id': 982, 'en': 'Iron Hands', 'zh': '未來版怪力'},
  {'id': 983, 'en': 'Iron Jugulis', 'zh': '未來版三首暴龍'},
  {'id': 984, 'en': 'Iron Moth', 'zh': '未來版摩魯蛾'},
  {'id': 985, 'en': 'Iron Thorns', 'zh': '未來版三合磁怪(刺)'},
  {'id': 986, 'en': 'Frigibax', 'zh': '冰絨龍'},
  {'id': 987, 'en': 'Arctibax', 'zh': '寒冰龍'},
  {'id': 988, 'en': 'Baxcalibur', 'zh': '極寒龍'},
  {'id': 989, 'en': 'Gimmighoul', 'zh': '寶箱龍'},
  {'id': 990, 'en': 'Gholdengo', 'zh': '寶箱龍(金)'},
  {'id': 991, 'en': 'Wo-Chien', 'zh': '古蔓禍'},
  {'id': 992, 'en': 'Chien-Pao', 'zh': '古劍禍'},
  {'id': 993, 'en': 'Ting-Lu', 'zh': '古鼎禍'},
  {'id': 994, 'en': 'Chi-Yu', 'zh': '古璧禍'},
  {'id': 995, 'en': 'Roaring Moon', 'zh': '未來月亮'},
  {'id': 996, 'en': 'Iron Valiant', 'zh': '未來版沙奈朵'},
  {'id': 997, 'en': 'Koraidon', 'zh': '故勒頓'},
  {'id': 998, 'en': 'Miraidon', 'zh': '未來頓'},
  {'id': 999, 'en': 'Munkidori', 'zh': '毒猴'},
  {'id': 1000, 'en': 'Fezandipiti', 'zh': '雉雞'},
  {'id': 1001, 'en': 'Okidogi', 'zh': '毒犬'},
  {'id': 1002, 'en': 'Ogerpon', 'zh': '面具鬼'},
  {'id': 1003, 'en': 'Gouging Fire', 'zh': '未來版噴火龍'},
  {'id': 1004, 'en': 'Raging Bolt', 'zh': '未來版雷丘'},
  {'id': 1005, 'en': 'Iron Boulder', 'zh': '未來版超夢'},
  {'id': 1006, 'en': 'Iron Crown', 'zh': '未來版路卡利歐'},
  {'id': 1007, 'en': 'Terapagos', 'zh': '太樂巴戈斯'},
  {'id': 1008, 'en': 'Pecharunt', 'zh': '毒桃'},
];

class PokemonDexScreen extends StatefulWidget {
  final bool embedded;
  const PokemonDexScreen({super.key, this.embedded = false});

  @override
  State<PokemonDexScreen> createState() => _PokemonDexScreenState();
}

class _PokemonDexScreenState extends State<PokemonDexScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  int _genIndex = 0; // 0 = 全部
  String? _selectedPokemon;
  bool _cardLoading = false;
  List<ApiCard> _cards = [];

  List<Map<String, dynamic>> get _filtered {
    final gen = _kGens[_genIndex];
    final min = gen['min'] as int;
    final max = gen['max'] as int;
    var list = _kPokemonList.where((p) {
      final id = p['id'] as int;
      return id >= min && id <= max;
    }).toList();
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((p) =>
        p['en'].toString().toLowerCase().contains(q) ||
        p['zh'].toString().toLowerCase().contains(q) ||
        p['id'].toString() == q).toList();
    }
    return list;
  }

  ApiCard _rowToCard(Map<String, dynamic> r) => ApiCard(
    id: r['id'] as String, name: r['name'] as String,
    imageSmall: r['image_small'] as String?, imageLarge: r['image_large'] as String?,
    rarity: r['rarity'] as String?, setName: r['set_name'] as String?,
    setId: r['set_id'] as String?, number: r['number'] as String?,
    supertype: r['supertype'] as String?,
    types: (r['types'] as String?)?.split(',').where((s) => s.isNotEmpty).toList() ?? [],
    variant: r['variant'] as String?,
  );

  Future<void> _loadCards(String pokemonName) async {
    setState(() { _selectedPokemon = pokemonName; _cardLoading = true; _cards = []; });
    // 用開頭搜尋抓最齊全的結果（Charizard → Charizard V, Charizard ex...）
    final rows = await SupabaseService.searchCardsByPokemon(pokemonName);
    if (mounted) setState(() {
      _cards = rows.map(_rowToCard).toList();
      _cardLoading = false;
    });
  }

  String _spriteUrl(int id) =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png';

  String _fmt(int p) => p.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      // 內嵌模式：無 Scaffold，直接返回內容（含精靈選中後的返回列）
      return Column(children: [
        if (_selectedPokemon != null)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
            child: Row(children: [
              GestureDetector(
                onTap: () => setState(() { _selectedPokemon = null; _cards = []; }),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.chevron_left, size: 20, color: Color(0xFFE8A52A)),
                  Text(L.pokemonBack, style: const TextStyle(fontSize: 13, color: Color(0xFFE8A52A))),
                ]),
              ),
              const SizedBox(width: 8),
              Text(_selectedPokemon!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ]),
          ),
        Expanded(child: _selectedPokemon != null ? _buildCards() : _buildPokemonGrid()),
      ]);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0.5,
        foregroundColor: const Color(0xFF111827),
        title: _selectedPokemon == null
            ? Text(L.pokemonDexTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))
            : Row(children: [
                GestureDetector(
                  onTap: () => setState(() { _selectedPokemon = null; _cards = []; }),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.chevron_left, size: 20, color: Color(0xFFE8A52A)),
                    Text('精靈', style: TextStyle(fontSize: 13, color: Color(0xFFE8A52A))),
                  ]),
                ),
                const SizedBox(width: 8),
                Text(_selectedPokemon!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ]),
        leading: _selectedPokemon != null ? const SizedBox.shrink() : null,
        automaticallyImplyLeading: _selectedPokemon == null,
      ),
      body: _selectedPokemon != null ? _buildCards() : _buildPokemonGrid(),
    );
  }

  Widget _buildPokemonGrid() {
    final list = _filtered;
    return Column(children: [
      // 搜尋欄
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _query = v),
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: L.searchPokemonHint,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 20),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Color(0xFF9CA3AF)),
                    onPressed: () { _searchCtrl.clear(); setState(() => _query = ''); })
                : null,
            filled: true, fillColor: const Color(0xFFF3F4F6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
      // 世代 Tab 橫向滾動
      Container(
        color: Colors.white,
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
          itemCount: _kGens.length,
          itemBuilder: (_, i) {
            final active = _genIndex == i;
            return GestureDetector(
              onTap: () => setState(() { _genIndex = i; }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFFE8A52A) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(i == 0 ? L.all : _kGens[i]['label'] as String,
                    style: TextStyle(
                      fontSize: 11.5, fontWeight: FontWeight.w600,
                      color: active ? Colors.white : const Color(0xFF6B7280))),
              ),
            );
          },
        ),
      ),
      // 精靈數量提示
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Row(children: [
          Text(L.pokemonCount(list.length),
              style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
        ]),
      ),
      // 精靈格
      Expanded(
        child: list.isEmpty
            ? Center(child: Text(L.noPokemon, style: const TextStyle(color: Color(0xFF9CA3AF))))
            : GridView.builder(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8,
                  childAspectRatio: 0.78),
                itemCount: list.length,
                itemBuilder: (_, i) => _pokemonTile(list[i]),
              ),
      ),
    ]);
  }

  Widget _pokemonTile(Map<String, dynamic> p) {
    return GestureDetector(
      onTap: () => _loadCards(p['en'] as String),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEDEFF2), width: 0.5)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CachedNetworkImage(
            imageUrl: _spriteUrl(p['id'] as int),
            height: 56, width: 56, fit: BoxFit.contain,
            errorWidget: (_, __, ___) => const Icon(Icons.catching_pokemon,
                size: 32, color: Color(0xFFE8A52A)),
          ),
          const SizedBox(height: 2),
          Text('#${(p['id'] as int).toString().padLeft(3, '0')}',
              style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(L.pokemonName(p),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                    color: Color(0xFF374151)),
                maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
          ),
        ]),
      ),
    );
  }

  Widget _buildCards() {
    if (_cardLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFE8A52A), strokeWidth: 2));
    }
    if (_cards.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.style_outlined, size: 48, color: Color(0xFFD1D5DB)),
        const SizedBox(height: 12),
        Text(L.noCardsForPokemon(_selectedPokemon ?? ''),
            style: const TextStyle(color: Color(0xFF9CA3AF))),
        const SizedBox(height: 6),
        Text(L.pokemonNotInDb,
            style: const TextStyle(fontSize: 12, color: Color(0xFFD1D5DB))),
      ]));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.66),
      itemCount: _cards.length,
      itemBuilder: (_, i) {
        final card = _cards[i];
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => DexCardDetailScreen(
              card: card, isCollected: false,
              onToggleCollect: (_) {},
              formatPrice: _fmt,
            ),
          )),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEDEFF2), width: 0.5)),
            clipBehavior: Clip.antiAlias,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(
                child: (card.imageSmall != null && card.imageSmall!.isNotEmpty)
                    ? CachedNetworkImage(
                        imageUrl: card.imageSmall!,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const Center(
                            child: SizedBox(width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFFD1D5DB)))),
                        errorWidget: (_, __, ___) => const Center(
                            child: Icon(Icons.image_not_supported_outlined,
                                size: 28, color: Color(0xFFD1D5DB))),
                      )
                    : const Center(child: Icon(Icons.image_not_supported_outlined,
                        size: 28, color: Color(0xFFD1D5DB))),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(5, 3, 5, 4),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(card.name,
                      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (card.setName != null)
                    Text(card.setName!,
                        style: const TextStyle(fontSize: 8, color: Color(0xFF9CA3AF)),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
            ]),
          ),
        );
      },
    );
  }
}
