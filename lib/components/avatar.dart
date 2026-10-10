import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../utils/api_db/api_service.dart';

/// Round avatar: the profile photo when there is one, otherwise initials on
/// a colour derived from the name (stable across runs).
class Avatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final double size;

  const Avatar({super.key, required this.name, this.photoUrl, this.size = 40});

  static const _palette = [
    Color(0xFF8A5A44),
    Color(0xFF4F6F52),
    Color(0xFF5B5F97),
    Color(0xFF9B6A2F),
    Color(0xFF3D6E8F),
    Color(0xFF7A4F6D),
    Color(0xFF6B6B3A),
    Color(0xFF2E6F76),
  ];

  static String initials(String name) {
    // "KlaraSmitkova" or "Klára Smitková" -> "KS"; "NikolGrover_sms" -> "NG"
    final words = name
        .replaceAll(RegExp(r'_.*$'), '')
        .replaceAllMapped(
            RegExp(
                r'(?<=[a-záäčďéěíľĺňóôöřŕšťúůüýž])(?=[A-ZÁÄČĎÉĚÍĽĹŇÓÔÖŘŔŠŤÚŮÜÝŽ])'),
            (_) => ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    final first = words.first.characters.first;
    return words.length == 1
        ? first.toUpperCase()
        : (first + words.last.characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final color = _palette[name.hashCode.abs() % _palette.length];
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        initials(name),
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.36,
          fontWeight: FontWeight.w600,
          fontVariations: const [FontVariation.weight(600)],
        ),
      ),
    );
    final url = photoUrl;
    if (url == null) return fallback;
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        httpHeaders: ApiService.headersFor(url),
        width: size,
        height: size,
        memCacheWidth: (size * 3).round(),
        fit: BoxFit.cover,
        placeholder: (_, __) => fallback,
        errorWidget: (_, __, ___) => fallback,
      ),
    );
  }
}
