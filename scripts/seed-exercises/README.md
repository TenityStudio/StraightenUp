# Firestore Exercise Seeder

Kleines Node.js-Skript um Übungen aus `exercises.json` direkt in Firestore
hochzuladen — kein Feld-für-Feld-Klicken in der Firebase Console mehr.

## Einmalige Einrichtung

1. **Node.js installiert?** Prüfen mit `node -v`. Falls nicht: [nodejs.org](https://nodejs.org).

2. **Dependencies installieren** (in diesem Ordner):
   ```
   npm init -y
   npm install firebase-admin
   ```

3. **Service Account Key besorgen:**
   - Firebase Console → ⚙️ Project Settings → Service Accounts
   - "Generate new private key" → JSON-Datei downloaden
   - Speichern als `serviceAccount.json` **neben** `seed.js`
   - ⚠️ Diese Datei ist geheim — nicht committen! (`.gitignore` ist schon gesetzt)

## Benutzung

**JSON-Datei mit Übungen befüllen** (`exercises.json`):

Nutz den Prompt aus dem Chat um sie mit Claude/GPT zu generieren, oder schreib
sie von Hand. Ein Beispiel liegt schon drin.

**Hochladen:**

```
node seed.js
```

Alle Docs werden mit `merge: true` gesetzt — existierende Docs mit gleicher
`id` werden überschrieben, andere Felder bleiben. `updatedAt` wird automatisch
gesetzt.

**Nur anschauen was hochgeladen würde (Dry-Run):**

```
node seed.js --dry
```

**Andere JSON-Datei:**

```
node seed.js --file weekly-drop-2026-09.json
```

**Alle Pro-Docs löschen (Reset):**

```
node seed.js --delete       # löscht alle isPro:true Docs
node seed.js --delete --dry # zeigt nur was gelöscht würde
```

## Wöchentliche Drops

Empfohlener Workflow für "neue Pro-Übungen jede Woche":

1. Jede Woche eine neue JSON: `weekly-drop-YYYY-MM-DD.json`
2. `week: <N>` in jedem Doc setzen (fortlaufend)
3. `node seed.js --file weekly-drop-2026-09.json`
4. App-User bekommen die neuen Übungen automatisch (max. 6h Cache-Delay)
