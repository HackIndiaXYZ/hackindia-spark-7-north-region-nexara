import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/scheme.dart';

class SchemeService {
  List<Scheme>? _cachedSchemes;

  Future<List<Scheme>> getAllSchemes() async {
    if (_cachedSchemes != null) return _cachedSchemes!;

    final data = await rootBundle.loadString('lib/assets/schemes_data.json');
    final List<dynamic> jsonList = json.decode(data);
    _cachedSchemes = jsonList.map((e) => Scheme.fromJson(e)).toList();
    return _cachedSchemes!;
  }

  /// Simple search across scheme name, tags, and description (case‑insensitive).
  List<Scheme> search(String query) {
    if (_cachedSchemes == null || query.trim().isEmpty) {
      return _cachedSchemes ?? [];
    }

    final lowerQuery = query.toLowerCase();
    return _cachedSchemes!
        .where(
          (s) =>
              s.name.toLowerCase().contains(lowerQuery) ||
              s.briefDescription.toLowerCase().contains(lowerQuery) ||
              s.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)),
        )
        .toList();
  }
}
