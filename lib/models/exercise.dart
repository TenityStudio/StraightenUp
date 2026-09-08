enum ExerciseContext {
  transit('BAHN / UNTERWEGS', '🚆'),
  office('BÜRO', '💼'),
  home('ZUHAUSE', '🏠');

  final String label;
  final String emoji;
  const ExerciseContext(this.label, this.emoji);
}

/// Grober Typ der Übung — hilft beim Kategorisieren & Filtern.
enum ExerciseType {
  stretch('Stretch', '🤸'),
  strength('Kräftigung', '💪'),
  mobility('Mobilität', '🌀'),
  breathing('Atmung', '🌬️'),
  relaxation('Entspannung', '🧘'),
  balance('Gleichgewicht', '⚖️'),
  eyes('Augen', '👀');

  final String label;
  final String emoji;
  const ExerciseType(this.label, this.emoji);
}

enum ExerciseIntensity {
  easy('Leicht', '🟢'),
  medium('Mittel', '🟡'),
  hard('Fordernd', '🔴');

  final String label;
  final String emoji;
  const ExerciseIntensity(this.label, this.emoji);
}

/// Kanonische Body-Part-Slugs — nur als Konstanten, du kannst in Firestore
/// aber freie Strings hinterlegen falls du zusätzliche brauchst.
class BodyPart {
  static const neck = 'neck';
  static const shoulders = 'shoulders';
  static const upperBack = 'upper_back';
  static const lowerBack = 'lower_back';
  static const chest = 'chest';
  static const spine = 'spine';
  static const wrists = 'wrists';
  static const forearms = 'forearms';
  static const hips = 'hips';
  static const hamstrings = 'hamstrings';
  static const eyes = 'eyes';
  static const core = 'core';
}

/// Equipment-Slugs — Firestore darf ergänzen.
class Equipment {
  static const none = 'none';
  static const wall = 'wall';
  static const chair = 'chair';
  static const floor = 'floor';
  static const doorway = 'doorway';
  static const band = 'band';
  static const foamRoller = 'foam_roller';
  static const tennisBall = 'tennis_ball';
  static const towel = 'towel';
  static const mat = 'mat';
}

class Exercise {
  final String id;
  final String title;
  final String subtitle;
  final List<String> steps;
  final int seconds;

  /// Primärer Kontext — bestimmt, wo die Übung im Choice-Screen einsortiert
  /// wird (BAHN / BÜRO / ZUHAUSE).
  final ExerciseContext context;

  /// Alle Locations wo die Übung sinnvoll ist. Wenn leer → wird als
  /// `[context]` interpretiert. Beispiel: Chin Tucks → [transit, office, home]
  final List<ExerciseContext> locations;

  /// Zielmuskeln/Körperbereiche — siehe `BodyPart`-Konstanten.
  final List<String> bodyParts;

  final ExerciseType? type;
  final ExerciseIntensity? intensity;

  /// Was du brauchst — siehe `Equipment`-Konstanten. Leer/`['none']` = nix.
  final List<String> equipment;

  /// Kann diskret in der Öffentlichkeit gemacht werden (kein Aufsehen)?
  final bool discreet;

  /// Freie Tags — z.B. 'morning', 'gamer-neck', 'quick-fix'.
  final List<String> tags;

  /// Was bringt die Übung — kurze Nutzer-Zeile, z.B. "Löst Verspannung im
  /// oberen Trapezmuskel."
  final String? benefit;

  final bool isPro;
  final String? lottieAsset;
  final String? animationKey;

  const Exercise({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.steps,
    required this.seconds,
    required this.context,
    this.locations = const [],
    this.bodyParts = const [],
    this.type,
    this.intensity,
    this.equipment = const [Equipment.none],
    this.discreet = false,
    this.tags = const [],
    this.benefit,
    this.isPro = false,
    this.lottieAsset,
    this.animationKey,
  });

  /// Effektive Locations — falls `locations` leer, fällt auf `[context]` zurück.
  List<ExerciseContext> get effectiveLocations =>
      locations.isEmpty ? [context] : locations;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'steps': steps,
        'seconds': seconds,
        'context': context.name,
        'locations': locations.map((c) => c.name).toList(),
        'bodyParts': bodyParts,
        if (type != null) 'type': type!.name,
        if (intensity != null) 'intensity': intensity!.name,
        'equipment': equipment,
        'discreet': discreet,
        'tags': tags,
        if (benefit != null) 'benefit': benefit,
        'isPro': isPro,
        if (lottieAsset != null) 'lottieAsset': lottieAsset,
        if (animationKey != null) 'animationKey': animationKey,
      };

  static Exercise? fromJson(Map<String, dynamic> j) {
    final ctxName = j['context'] as String?;
    final ctx = ExerciseContext.values.where((c) => c.name == ctxName).firstOrNull;
    final id = j['id'] as String?;
    final title = j['title'] as String?;
    final subtitle = j['subtitle'] as String?;
    final seconds = j['seconds'];
    final rawSteps = j['steps'];
    if (id == null || title == null || subtitle == null || ctx == null ||
        seconds is! num || rawSteps is! List) {
      return null;
    }
    List<ExerciseContext> locations = const [];
    final rawLocations = j['locations'];
    if (rawLocations is List) {
      locations = rawLocations
          .map((e) => e.toString())
          .map((n) => ExerciseContext.values
              .where((c) => c.name == n)
              .firstOrNull)
          .whereType<ExerciseContext>()
          .toList();
    }
    ExerciseType? type;
    final rawType = j['type'];
    if (rawType is String) {
      type = ExerciseType.values.where((t) => t.name == rawType).firstOrNull;
    }
    ExerciseIntensity? intensity;
    final rawIntensity = j['intensity'];
    if (rawIntensity is String) {
      intensity = ExerciseIntensity.values
          .where((t) => t.name == rawIntensity)
          .firstOrNull;
    }
    return Exercise(
      id: id,
      title: title,
      subtitle: subtitle,
      steps: rawSteps.map((e) => e.toString()).toList(),
      seconds: seconds.toInt(),
      context: ctx,
      locations: locations,
      bodyParts: (j['bodyParts'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      type: type,
      intensity: intensity,
      equipment: (j['equipment'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [Equipment.none],
      discreet: (j['discreet'] as bool?) ?? false,
      tags: (j['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      benefit: j['benefit'] as String?,
      isPro: (j['isPro'] as bool?) ?? true,
      lottieAsset: j['lottieAsset'] as String?,
      animationKey: j['animationKey'] as String?,
    );
  }
}
