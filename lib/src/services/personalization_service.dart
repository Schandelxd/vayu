// lib/src/services/personalization_service.dart

class PersonalizationResult {
  final int riskScore; // 0–100
  final String riskLevel; // Low / Moderate / High / Very High
  final String shortMessage;
  final List<String> recommendations;

  PersonalizationResult({
    required this.riskScore,
    required this.riskLevel,
    required this.shortMessage,
    required this.recommendations,
  });

  Map<String, dynamic> toJson() => {
        'riskScore': riskScore,
        'riskLevel': riskLevel,
        'shortMessage': shortMessage,
        'recommendations': recommendations,
      };

  static PersonalizationResult fromJson(Map<String, dynamic> j) => PersonalizationResult(
        riskScore: (j['riskScore'] as num).toInt(),
        riskLevel: j['riskLevel'] as String,
        shortMessage: j['shortMessage'] as String,
        recommendations: List<String>.from(j['recommendations'] ?? []),
      );
}

class PersonalizationService {
  /// Deterministic (local/mock) logic to compute a risk and recommendations
  static PersonalizationResult generate({
    required int aqi,
    required int? age,
    required bool smoker,
    required bool asthma,
    required bool chronic,
  }) {
    int base;
    if (aqi <= 50) {
      base = 10;
    } else if (aqi <= 100) base = 30;
    else if (aqi <= 150) base = 55;
    else if (aqi <= 200) base = 72;
    else if (aqi <= 300) base = 85;
    else base = 95;

    int mod = 0;
    if (age != null && age < 12) mod += 12;
    if (age != null && age >= 65) mod += 10;
    if (smoker) mod += 15;
    if (asthma) mod += 20;
    if (chronic) mod += 12;

    final score = (base + mod).clamp(0, 100);

    String level;
    String summary;

    if (score < 25) {
      level = "Low";
      summary = "Air quality is good. Normal activities are safe.";
    } else if (score < 50) {
      level = "Moderate";
      summary = "Some people may experience mild effects outdoors.";
    } else if (score < 75) {
      level = "High";
      summary = "Air quality is poor. Reduce outdoor exposure.";
    } else {
      level = "Very High";
      summary = "Air is unhealthy. Stay indoors as much as possible.";
    }

    final recs = <String>[];

    // Base recommendations by level
    if (level == "Low") {
      recs.add("Outdoor exercise is safe.");
      recs.add("Keep monitoring AQI for sudden changes.");
    } else if (level == "Moderate") {
      recs.add("Sensitive individuals should avoid long outdoor exposure.");
      recs.add("Consider using a mask during exercise.");
    } else if (level == "High") {
      recs.add("Limit time outdoors and avoid heavy exercise.");
      recs.add("Consider an N95/FFP2 mask when outside.");
    } else {
      recs.add("Avoid outdoor exposure and keep windows closed.");
      recs.add("Use an air purifier if available.");
    }

    // Tailored suggestions
    if (smoker) recs.add("Avoid smoking and second-hand smoke to reduce respiratory stress.");
    if (asthma) recs.add("Carry your inhaler and follow your asthma action plan.");
    if (chronic) recs.add("Monitor symptoms closely due to increased vulnerability.");
    if (age != null && age < 12) recs.add("Children are more sensitive—limit outdoor play during high AQI.");
    if (age != null && age >= 65) recs.add("Older adults should avoid prolonged outdoor exposure.");

    recs.add("Seek medical help if you experience severe breathing difficulty.");

    return PersonalizationResult(
      riskScore: score,
      riskLevel: level,
      shortMessage: summary,
      recommendations: recs,
    );
  }
}
