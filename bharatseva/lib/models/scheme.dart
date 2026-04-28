class SchemeFAQ {
  final String question;
  final String answer;

  SchemeFAQ({required this.question, required this.answer});

  factory SchemeFAQ.fromJson(Map<String, dynamic> json) {
    return SchemeFAQ(
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
    );
  }
}

class Scheme {
  final String id;
  final String name;
  final String shortTitle;
  final String level;
  final String state;
  final String ministry;
  final String department;
  final String beneficiaryType;
  final String benefitType;
  final List<String> categories;
  final List<String> tags;
  final String briefDescription;
  final String detailedDescription;
  final String benefits;
  final String eligibilityText;
  final List<String> eligibilitySentences;
  final String exclusions;
  final String applicationMode;
  final String applicationProcess;
  final String documentsRequired;
  final String references;
  final String applyUrl;
  final List<SchemeFAQ> faqs;

  Scheme({
    required this.id,
    required this.name,
    required this.shortTitle,
    required this.level,
    required this.state,
    required this.ministry,
    required this.department,
    required this.beneficiaryType,
    required this.benefitType,
    required this.categories,
    required this.tags,
    required this.briefDescription,
    required this.detailedDescription,
    required this.benefits,
    required this.eligibilityText,
    required this.eligibilitySentences,
    required this.exclusions,
    required this.applicationMode,
    required this.applicationProcess,
    required this.documentsRequired,
    required this.references,
    required this.applyUrl,
    required this.faqs,
  });

  factory Scheme.fromJson(Map<String, dynamic> json) {
    return Scheme(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      shortTitle: json['short_title'] ?? '',
      level: json['level'] ?? '',
      state: json['state'] ?? '',
      ministry: json['ministry'] ?? '',
      department: json['department'] ?? '',
      beneficiaryType: json['beneficiary_type'] ?? '',
      benefitType: json['benefit_type'] ?? '',
      categories: List<String>.from(json['categories'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      briefDescription: json['brief_description'] ?? '',
      detailedDescription: json['detailed_description'] ?? '',
      benefits: json['benefits'] ?? '',
      eligibilityText: json['eligibility_text'] ?? '',
      eligibilitySentences: List<String>.from(
        json['eligibility_sentences'] ?? [],
      ),
      exclusions: json['exclusions'] ?? '',
      applicationMode: json['application_mode'] ?? '',
      applicationProcess: json['application_process'] ?? '',
      documentsRequired: json['documents_required'] ?? '',
      references: json['references'] ?? '',
      applyUrl: json['apply_url'] ?? '',
      faqs:
          (json['faqs'] as List<dynamic>?)
              ?.map((f) => SchemeFAQ.fromJson(f))
              .toList() ??
          [],
    );
  }
}
