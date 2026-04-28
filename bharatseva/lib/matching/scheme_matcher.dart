import '../models/scheme.dart';

class SchemeMatcher {
  final Map<String, String> profile;

  SchemeMatcher(this.profile);

  List<Scheme> matchSchemes(List<Scheme> allSchemes) {
    final matched = <Scheme>[];
    final userState = profile['State']?.toLowerCase() ?? '';
    final userGender = profile['Gender']?.toLowerCase() ?? '';
    final userAge =
        int.tryParse(profile['Age']?.replaceAll(RegExp(r'[^0-9]'), '') ?? '') ??
        0;
    final userIncome =
        double.tryParse(
          profile['Annual Family Income']?.replaceAll(RegExp(r'[^0-9]'), '') ??
              '',
        ) ??
        double.infinity;

    String getProfile(String key) => (profile[key] ?? '').toLowerCase();

    final userCategory = getProfile('Category');
    final isDisabled = getProfile('Person with Disability').contains('haan');
    final isBPL = getProfile('BPL Category').contains('haan');
    final residence = getProfile('Area of Residence');
    final isRural = residence.contains('gramin') || residence.contains('rural');
    final isStudent = getProfile('Student').contains('haan');

    for (var scheme in allSchemes) {
      int score = 0;
      int totalCriteria = 0;
      final lowerText = scheme.eligibilityText.toLowerCase();

      // 1. State filter
      if (scheme.level == 'State/ UT' && scheme.state.isNotEmpty) {
        totalCriteria++;
        if (scheme.state.toLowerCase() == userState || scheme.state == 'All') {
          score++;
        } else {
          continue;
        }
      }

      // 2. Gender check
      totalCriteria++;
      if (userGender.contains('mahila') || userGender.contains('female')) {
        if (lowerText.contains('woman') ||
            lowerText.contains('girl') ||
            scheme.tags.any((t) => t.toLowerCase() == 'women')) {
          score++;
        } else {
          score++; // No explicit restriction, still include
        }
      } else if (userGender.contains('purush') || userGender.contains('male')) {
        if (lowerText.contains('male') || lowerText.contains('men')) {
          score++;
        } else {
          score++;
        }
      } else {
        score++;
      }

      // 3. Age
      totalCriteria++;
      final ageMatch = RegExp(
        r'(\d+)\s*(?:to|-)\s*(\d+)\s*years?|above\s*(\d+)|below\s*(\d+)',
      ).firstMatch(lowerText);
      if (ageMatch != null) {
        if (ageMatch.group(1) != null && ageMatch.group(2) != null) {
          int minAge = int.parse(ageMatch.group(1)!);
          int maxAge = int.parse(ageMatch.group(2)!);
          if (userAge >= minAge && userAge <= maxAge) score++;
        } else if (ageMatch.group(3) != null) {
          int minAge = int.parse(ageMatch.group(3)!);
          if (userAge >= minAge) score++;
        } else if (ageMatch.group(4) != null) {
          int maxAge = int.parse(ageMatch.group(4)!);
          if (userAge <= maxAge) score++;
        }
      } else {
        score++;
      }

      // 4. Income / BPL
      totalCriteria++;
      if (isBPL) {
        if (lowerText.contains('bpl') || lowerText.contains('below poverty'))
          score++;
        else
          score++;
      } else if (userIncome > 0) {
        final incomeRegex = RegExp(
          r'income[^.]*?(?:up to|max|not exceed|less than|below)\s*[₹rs.]*\s*([\d,]+)',
        );
        final incMatch = incomeRegex.firstMatch(lowerText);
        if (incMatch != null) {
          double limit =
              double.tryParse(incMatch.group(1)!.replaceAll(',', '')) ??
              double.infinity;
          if (userIncome <= limit) score++;
        } else {
          score++;
        }
      } else {
        score++;
      }

      // 5. Category / Caste
      totalCriteria++;
      if (userCategory.isNotEmpty && userCategory != 'general') {
        if (lowerText.contains(userCategory) ||
            scheme.tags.any((t) => t.toLowerCase() == userCategory)) {
          score++;
        } else {
          continue;
        }
      } else {
        score++;
      }

      // 6. Disability
      totalCriteria++;
      if (isDisabled) {
        if (lowerText.contains('disability') ||
            lowerText.contains('handicapped'))
          score++;
      } else {
        if (lowerText.contains('disabled only') ||
            lowerText.contains('person with disability only'))
          continue;
        score++;
      }

      // 7. Student status
      totalCriteria++;
      if (isStudent &&
          (lowerText.contains('student') ||
              lowerText.contains('education') ||
              lowerText.contains('scholarship'))) {
        score++;
      } else if (!isStudent && lowerText.contains('only for students')) {
        continue;
      } else {
        score++;
      }

      // 8. Rural/Urban
      totalCriteria++;
      if (isRural && lowerText.contains('rural'))
        score++;
      else if (!isRural && lowerText.contains('rural only'))
        continue;
      else if (!isRural && lowerText.contains('urban only')) {
        if (profile['Area of Residence']?.toLowerCase()?.contains('shahri') ==
            true)
          score++;
      } else {
        score++;
      }

      if (totalCriteria > 0) {
        double matchPercent = score / totalCriteria;
        if (matchPercent >= 0.7) {
          matched.add(scheme);
        }
      }
    }

    matched.sort((a, b) => b.tags.length.compareTo(a.tags.length));
    return matched;
  }
}
