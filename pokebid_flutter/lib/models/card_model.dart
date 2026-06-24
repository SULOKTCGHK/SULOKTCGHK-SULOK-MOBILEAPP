import 'package:flutter/material.dart';

class Seller {
  final String name;
  final double rating;
  final int sales;
  final String? id;

  const Seller({required this.name, required this.rating, required this.sales, this.id});
}

enum CardType { fire, water, grass, electric, psychic, dragon, normal, dark, fairy, rock }

enum ListingType { auction, fixedPrice }

class PokemonCard {
  final int id;
  final String name;
  final String grade;
  final CardType type;
  int price;
  final String condition;
  final Seller seller;
  final ListingType listingType;
  int bids;
  final String timeInfo;
  final String? supabaseId;
  final List<String> imageUrls;
  final bool isSold;
  final String? setId;      // 系列 ID，如 sv8a
  final String? cardNumber; // 卡號，如 217
  final String? psaCert;    // PSA cert number（用戶上架時輸入）
  final String? psaSpecId;  // PSA SpecID（cert 查到 / admin 設定）
  final List<String> meetupLocations; // 優先面交地點

  PokemonCard({
    required this.id,
    required this.name,
    required this.grade,
    required this.type,
    required this.price,
    required this.condition,
    required this.seller,
    required this.listingType,
    this.bids = 0,
    required this.timeInfo,
    this.supabaseId,
    this.imageUrls = const [],
    this.isSold = false,
    this.setId,
    this.cardNumber,
    this.psaCert,
    this.psaSpecId,
    this.meetupLocations = const [],
  });
}

extension CardTypeExtension on CardType {
  String get label {
    switch (this) {
      case CardType.fire: return 'Fire';
      case CardType.water: return 'Water';
      case CardType.grass: return 'Grass';
      case CardType.electric: return 'Electric';
      case CardType.psychic: return 'Psychic';
      case CardType.dragon: return 'Dragon';
      case CardType.normal: return 'Normal';
      case CardType.dark: return 'Dark';
      case CardType.fairy: return 'Fairy';
      case CardType.rock: return 'Rock';
    }
  }

  String get emoji {
    switch (this) {
      case CardType.fire: return '🔥';
      case CardType.water: return '💧';
      case CardType.grass: return '🌿';
      case CardType.electric: return '⚡';
      case CardType.psychic: return '🔮';
      case CardType.dragon: return '💎';
      case CardType.normal: return '○';
      case CardType.dark: return '🌙';
      case CardType.fairy: return '✦';
      case CardType.rock: return '◈';
    }
  }

  Color get color {
    switch (this) {
      case CardType.fire: return const Color(0xFFE74C3C);
      case CardType.water: return const Color(0xFF2980B9);
      case CardType.grass: return const Color(0xFF27AE60);
      case CardType.electric: return const Color(0xFFD4A017);
      case CardType.psychic: return const Color(0xFF8E44AD);
      case CardType.dragon: return const Color(0xFF1A6FA8);
      case CardType.normal: return const Color(0xFF6B7280);
      case CardType.dark: return const Color(0xFF374151);
      case CardType.fairy: return const Color(0xFFC0397A);
      case CardType.rock: return const Color(0xFF7C6045);
    }
  }

  Color get bgColor {
    switch (this) {
      case CardType.fire: return const Color(0xFFFEF2F2);
      case CardType.water: return const Color(0xFFEFF6FF);
      case CardType.grass: return const Color(0xFFF0FDF4);
      case CardType.electric: return const Color(0xFFFEFCE8);
      case CardType.psychic: return const Color(0xFFFDF4FF);
      case CardType.dragon: return const Color(0xFFEFF6FF);
      case CardType.normal: return const Color(0xFFF9FAFB);
      case CardType.dark: return const Color(0xFFF3F4F6);
      case CardType.fairy: return const Color(0xFFFDF2F8);
      case CardType.rock: return const Color(0xFFFAF5EB);
    }
  }
}
