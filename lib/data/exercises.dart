import '../models/exercise.dart';
import '../services/remote_exercises.dart';

/// Katalog aller lokal gebündelten Übungen.
///
/// **Free** = 13 Basis-Übungen für die Gamer-Nacken-Grundversorgung
/// (Bahn/unterwegs, Büro, Zuhause).
///
/// **Pro** = Platzhalter-Beispiele. Die echten Pro-Übungen werden später aus
/// Firestore geladen (siehe TODO im Pro-Plan-Screen), damit du wöchentlich
/// Drops veröffentlichen kannst ohne App-Update.
///
/// Sobald dein Animator/Grafiker die Slide-Bilder liefert, kannst du sie unter
/// `assets/exercises/<id>_1.png` … droppen und beim Exercise über `imageSteps`
/// referenzieren. Für Lottie-JSONs analog `lottieAsset`.
const exercisesCatalog = <Exercise>[
  // ─── FREE · BAHN / UNTERWEGS ──────────────────────────────────────────────
  Exercise(
    id: 'transit_chin_tucks',
    title: 'Chin Tucks',
    subtitle: 'Doppelkinn machen — der Nacken dankt.',
    seconds: 30,
    context: ExerciseContext.transit,
    locations: [
      ExerciseContext.transit,
      ExerciseContext.office,
      ExerciseContext.home,
    ],
    bodyParts: [BodyPart.neck],
    type: ExerciseType.strength,
    intensity: ExerciseIntensity.easy,
    equipment: [Equipment.none],
    discreet: true,
    tags: ['gamer-neck', 'quick-fix'],
    benefit: 'Kräftigt die tiefen Halsbeuger und richtet den Kopf auf.',
    steps: [
      'Kopf gerade halten, Blick geradeaus.',
      'Kinn ohne Nicken nach hinten schieben (Doppelkinn).',
      '3 Sekunden halten, dann lösen.',
      '5× wiederholen, ruhig atmen.',
    ],
  ),
  Exercise(
    id: 'transit_neck_rolls',
    title: 'Neck Rolls',
    subtitle: 'Fällt unterwegs niemandem auf.',
    seconds: 30,
    context: ExerciseContext.transit,
    animationKey: 'neck_roll',
    steps: [
      'Kinn langsam auf die Brust senken.',
      'Kopf sanft nach rechts rollen, halten.',
      'Zurück durch die Mitte nach links.',
      '3 Runden, ruhig atmen.',
    ],
  ),
  Exercise(
    id: 'transit_ear_to_shoulder',
    title: 'Ohr-zu-Schulter Stretch',
    subtitle: 'Seitliche Nackenmuskulatur lockern.',
    seconds: 40,
    context: ExerciseContext.transit,
    steps: [
      'Aufrecht sitzen, Schultern locker.',
      'Rechtes Ohr Richtung rechte Schulter neigen.',
      '15 Sekunden halten, ohne Schulter zu heben.',
      'Seite wechseln.',
    ],
  ),
  Exercise(
    id: 'transit_look_up',
    title: 'Blick zur Decke Stretch',
    subtitle: 'Gegen die dauerhafte Vorwärtshaltung.',
    seconds: 20,
    context: ExerciseContext.transit,
    steps: [
      'Kopf langsam nach hinten neigen.',
      'Blick zur Decke, Mund entspannt.',
      '10 Sekunden halten.',
      '2× wiederholen.',
    ],
  ),
  Exercise(
    id: 'transit_shoulder_rolls',
    title: 'Shoulder Rolls (vor/rückwärts)',
    subtitle: 'Schultern kreisen — Blut in den Nacken.',
    seconds: 30,
    context: ExerciseContext.transit,
    steps: [
      'Arme locker hängen lassen.',
      '5× langsam rückwärts kreisen.',
      '5× langsam vorwärts kreisen.',
      'Ruhig atmen, kein Rucken.',
    ],
  ),
  Exercise(
    id: 'transit_shoulder_shrugs',
    title: 'Shoulder Shrugs',
    subtitle: 'Schultern hoch, halten, fallen lassen.',
    seconds: 25,
    context: ExerciseContext.transit,
    steps: [
      'Schultern kräftig Richtung Ohren ziehen.',
      '3 Sekunden halten.',
      'Komplett fallen lassen.',
      '5×.',
    ],
  ),

  // ─── FREE · BÜRO ──────────────────────────────────────────────────────────
  Exercise(
    id: 'office_wall_angels',
    title: 'Wall Angels',
    subtitle: 'Rücken an die Wand — Arme wie ein Schneeengel.',
    seconds: 45,
    context: ExerciseContext.office,
    locations: [ExerciseContext.office, ExerciseContext.home],
    bodyParts: [BodyPart.shoulders, BodyPart.upperBack],
    type: ExerciseType.mobility,
    intensity: ExerciseIntensity.medium,
    equipment: [Equipment.wall],
    discreet: false,
    tags: ['posture', 'gamer-neck'],
    benefit: 'Öffnet die Brust und mobilisiert die Schulterblätter.',
    animationKey: 'wall_angel',
    steps: [
      'Rücken flach an die Wand.',
      'Arme im 90° Winkel, Handrücken an Wand.',
      'Langsam nach oben, dann zurück.',
      '6 Wiederholungen.',
    ],
  ),
  Exercise(
    id: 'office_doorway_pec',
    title: 'Doorway Pec Stretch',
    subtitle: 'Brust öffnen, wenn du sie brauchst.',
    seconds: 40,
    context: ExerciseContext.office,
    steps: [
      'In einen Türrahmen stellen.',
      'Unterarme an den Rahmen, Ellbogen 90°.',
      'Ein Schritt vor, Brust nach vorne öffnen.',
      '20 Sekunden halten, dann wechseln.',
    ],
  ),
  Exercise(
    id: 'office_scapular_squeezes',
    title: 'Scapular Squeezes',
    subtitle: 'Schulterblätter zusammendrücken.',
    seconds: 30,
    context: ExerciseContext.office,
    steps: [
      'Aufrecht sitzen, Arme locker.',
      'Schulterblätter nach hinten & unten ziehen.',
      '5 Sekunden halten, dann lösen.',
      '8× wiederholen.',
    ],
  ),
  Exercise(
    id: 'office_levator_scapulae',
    title: 'Levator Scapulae Stretch',
    subtitle: 'Dieser eine Muskel, der immer verspannt ist.',
    seconds: 45,
    context: ExerciseContext.office,
    steps: [
      'Rechte Hand hinter den Rücken oder unter den Stuhl.',
      'Kopf zur linken Achsel neigen, leicht drehen.',
      'Mit linker Hand sanft Zug erhöhen.',
      '20 Sekunden halten, Seite wechseln.',
    ],
  ),

  // ─── FREE · ZUHAUSE ───────────────────────────────────────────────────────
  Exercise(
    id: 'home_cat_cow',
    title: 'Cat & Cow',
    subtitle: 'Auf allen Vieren — Rücken rund und hohl.',
    seconds: 60,
    context: ExerciseContext.home,
    animationKey: 'cat_cow',
    steps: [
      'In den Vierfüßlerstand.',
      'Einatmen: Rücken durchhängen, Blick hoch.',
      'Ausatmen: Rücken runden, Kinn zur Brust.',
      '8 Runden im Atemrhythmus.',
    ],
  ),
  Exercise(
    id: 'home_chest_opener',
    title: 'Chest Opener',
    subtitle: 'Hände hinter dem Kopf, Brust öffnen.',
    seconds: 30,
    context: ExerciseContext.home,
    steps: [
      'Hände hinter den Kopf verschränken.',
      'Ellbogen weit nach außen ziehen.',
      'Brustbein Richtung Decke schieben.',
      '20 Sekunden halten.',
    ],
  ),
  Exercise(
    id: 'home_prayer_stretch',
    title: 'Prayer Stretch (Handgelenk)',
    subtitle: 'Gamer-Handgelenke lockern.',
    seconds: 40,
    context: ExerciseContext.home,
    steps: [
      'Handflächen vor der Brust zusammenlegen.',
      'Ellbogen weit auseinander drücken.',
      'Hände langsam nach unten schieben.',
      'Bis Zug spürbar ist, 20 Sekunden halten.',
    ],
  ),

  // Pro-Übungen kommen ausschließlich aus Firestore
  // (siehe RemoteExerciseStore + combinedCatalog).
];

/// Kombinierter Zugriff auf lokal gebündelte + remote geladene Übungen.
/// Remote-Übungen mit identischer `id` überschreiben lokale (letzter gewinnt),
/// damit du Server-Fixes ohne App-Update ausrollen kannst.
List<Exercise> get combinedCatalog {
  final byId = <String, Exercise>{
    for (final e in exercisesCatalog) e.id: e,
  };
  // Remote store ist erst nach init() nutzbar; wenn nicht initialisiert
  // → still-fail und nur lokalen Katalog zurückgeben.
  try {
    for (final e in RemoteExerciseStore.instance.current) {
      byId[e.id] = e;
    }
  } catch (_) {}
  return byId.values.toList(growable: false);
}

List<Exercise> exercisesFor(ExerciseContext ctx, {required bool pro}) {
  return combinedCatalog
      .where((e) => e.context == ctx && (pro || !e.isPro))
      .toList();
}
