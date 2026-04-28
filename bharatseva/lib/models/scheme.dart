class Scheme {
  final String id;
  final String nameEn;
  final String nameHi;
  final String category;
  final String state;
  final String benefit;
  final String descriptionHi;
  final String applyUrl;

  Scheme({
    required this.id,
    required this.nameEn,
    required this.nameHi,
    required this.category,
    required this.state,
    required this.benefit,
    required this.descriptionHi,
    required this.applyUrl,
  });

  factory Scheme.fromJson(Map<String, dynamic> json) {
    return Scheme(
      id: json['id'] ?? '',
      nameEn: json['name_en'] ?? '',
      nameHi: json['name_hi'] ?? '',
      category: json['category'] ?? '',
      state: json['state'] ?? '',
      benefit: json['benefit'] ?? '',
      descriptionHi: json['description_hi'] ?? '',
      applyUrl: json['apply_url'] ?? '',
    );
  }
}
