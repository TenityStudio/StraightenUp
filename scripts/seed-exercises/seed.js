// ─── Firestore Exercise Seeder ──────────────────────────────────────────────
//
// Läd Übungen aus `exercises.json` in die Firestore-Collection `exercises`.
//
// SETUP (nur einmal):
// 1. In diesem Ordner: `npm init -y && npm install firebase-admin`
// 2. Firebase Console → Project Settings → Service Accounts →
//    "Generate new private key" → speichern als `serviceAccount.json`
//    NEBEN dieser Datei. WICHTIG: .gitignore die Datei!
//
// AUFRUFEN:
//   node seed.js                → alle Docs aus exercises.json anlegen/updaten
//   node seed.js --dry          → nur anzeigen was hochgeladen würde
//   node seed.js --file foo.json → andere JSON-Datei nehmen
//   node seed.js --delete       → alle Pro-Docs (isPro:true) LÖSCHEN
//
// ────────────────────────────────────────────────────────────────────────────

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const args = process.argv.slice(2);
const dry = args.includes('--dry');
const del = args.includes('--delete');
const fileIdx = args.indexOf('--file');
const file = fileIdx >= 0 ? args[fileIdx + 1] : 'exercises.json';

// ─── Init Admin SDK ─────────────────────────────────────────────────────────

const keyPath = path.join(__dirname, 'serviceAccount.json');
if (!fs.existsSync(keyPath)) {
  console.error('❌ serviceAccount.json fehlt neben seed.js.');
  console.error('   Firebase Console → Project Settings → Service Accounts');
  console.error('   → "Generate new private key" → hier speichern.');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(require(keyPath)),
});
const db = admin.firestore();
const col = db.collection('exercises');

// ─── DELETE MODE ────────────────────────────────────────────────────────────

if (del) {
  (async () => {
    console.log('🗑  Suche Pro-Docs (isPro:true)...');
    const snap = await col.where('isPro', '==', true).get();
    console.log(`   ${snap.size} Docs gefunden.`);
    if (dry) {
      snap.forEach((d) => console.log(`   [dry] würde löschen: ${d.id}`));
      return;
    }
    const batch = db.batch();
    snap.forEach((d) => batch.delete(d.ref));
    await batch.commit();
    console.log(`✅ ${snap.size} Pro-Docs gelöscht.`);
  })().catch((e) => {
    console.error('❌', e);
    process.exit(1);
  });
} else {
  // ─── SEED MODE ────────────────────────────────────────────────────────────

  const jsonPath = path.join(__dirname, file);
  if (!fs.existsSync(jsonPath)) {
    console.error(`❌ Datei nicht gefunden: ${jsonPath}`);
    process.exit(1);
  }

  const raw = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
  const items = Array.isArray(raw) ? raw : [raw];

  const errors = [];
  const REQUIRED = ['id', 'title', 'subtitle', 'steps', 'seconds', 'context'];
  const CTX_VALUES = ['transit', 'office', 'home'];
  const TYPE_VALUES = [
    'stretch', 'strength', 'mobility',
    'breathing', 'relaxation', 'balance', 'eyes',
  ];
  const INTENSITY_VALUES = ['easy', 'medium', 'hard'];

  items.forEach((it, i) => {
    for (const k of REQUIRED) {
      if (it[k] === undefined || it[k] === null) {
        errors.push(`#${i} (${it.id ?? '?'}): fehlt "${k}"`);
      }
    }
    if (it.context && !CTX_VALUES.includes(it.context)) {
      errors.push(`#${i} (${it.id}): context "${it.context}" ungültig`);
    }
    if (it.type && !TYPE_VALUES.includes(it.type)) {
      errors.push(`#${i} (${it.id}): type "${it.type}" ungültig`);
    }
    if (it.intensity && !INTENSITY_VALUES.includes(it.intensity)) {
      errors.push(`#${i} (${it.id}): intensity "${it.intensity}" ungültig`);
    }
    if (!Array.isArray(it.steps) || it.steps.length === 0) {
      errors.push(`#${i} (${it.id}): steps muss ein nicht-leeres Array sein`);
    }
  });

  if (errors.length) {
    console.error('❌ Validation fehlgeschlagen:');
    errors.forEach((e) => console.error('  ' + e));
    process.exit(1);
  }

  (async () => {
    console.log(`📦 ${items.length} Übungen aus ${file} bereit.`);

    if (dry) {
      items.forEach((it) => {
        console.log(`  [dry] ${it.id}  (${it.context}, isPro:${!!it.isPro})`);
      });
      return;
    }

    const batch = db.batch();
    items.forEach((it) => {
      const { id, ...data } = it;
      // updatedAt automatisch mitschreiben (praktisch fürs Debugging).
      data.updatedAt = admin.firestore.FieldValue.serverTimestamp();
      batch.set(col.doc(id), data, { merge: true });
    });
    await batch.commit();
    console.log(`✅ ${items.length} Docs hochgeladen (merge).`);
  })().catch((e) => {
    console.error('❌', e);
    process.exit(1);
  });
}
