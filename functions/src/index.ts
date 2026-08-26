/**
 * Cloud Functions für The Straight Guys.
 *
 * - onLobbyEventCreated: sobald ein Client ein Event-Doc in einer Lobby
 *   anlegt (z.B. per Summon), fanout via FCM an alle Lobby-Mitglieder.
 * - finalizeExpiredEvents: alle 60s, markiert abgelaufene Events als
 *   `finalized: true` und trägt "missed" für alle Mitglieder ohne Response ein.
 */

import {
  onDocumentCreated,
  onDocumentDeleted,
} from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { setGlobalOptions } from "firebase-functions/v2";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { logger } from "firebase-functions/v2";

initializeApp();

setGlobalOptions({
  region: "europe-west1",
  maxInstances: 10,
});

const db = () => getFirestore();

// ─── FCM Fanout bei neuem Event ────────────────────────────────────────────

export const onLobbyEventCreated = onDocumentCreated(
  "lobbies/{code}/events/{eventId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const data = snap.data();
    const code = event.params.code as string;
    const eventId = event.params.eventId as string;
    const windowSeconds = (data.windowSeconds as number | undefined) ?? 10;
    const summonerUid = (data.summonerUid as string | undefined) ?? "";

    const membersSnap = await db()
      .collection(`lobbies/${code}/members`)
      .get();
    const memberUids = membersSnap.docs.map((d) => d.id);

    if (memberUids.length === 0) return;

    const userDocs = await db().getAll(
      ...memberUids.map((uid) => db().doc(`users/${uid}`))
    );
    const tokens: string[] = [];
    for (const doc of userDocs) {
      const t = doc.data()?.fcmToken;
      if (t && typeof t === "string") tokens.push(t);
    }
    if (tokens.length === 0) {
      logger.info(`No FCM tokens for lobby ${code}`);
      return;
    }

    const result = await getMessaging().sendEachForMulticast({
      tokens,
      data: {
        type: "call",
        lobbyCode: code,
        eventId,
        windowSeconds: String(windowSeconds),
        summonerUid,
      },
      android: {
        priority: "high",
      },
    });
    logger.info(
      `Fanout lobby=${code} event=${eventId} success=${result.successCount} fail=${result.failureCount}`
    );
  }
);

// ─── Aufräumen bei Lobby-Delete (Host schließt Lobby) ─────────────────────

export const onLobbyDeleted = onDocumentDeleted(
  "lobbies/{code}",
  async (event) => {
    const code = event.params.code as string;
    const db = getFirestore();
    logger.info(`Cleanup lobby ${code}`);

    // 1. Alle Mitglieder-Dokumente einsammeln (brauchen wir für
    //    activeLobbyCode-Cleanup) und löschen.
    const membersSnap = await db.collection(`lobbies/${code}/members`).get();
    const memberUids = membersSnap.docs.map((d) => d.id);

    // 2. activeLobbyCode bei jedem User zurücksetzen (falls er noch drauf zeigt).
    await Promise.all(
      memberUids.map(async (uid) => {
        try {
          const userRef = db.doc(`users/${uid}`);
          const userSnap = await userRef.get();
          if (userSnap.data()?.activeLobbyCode === code) {
            await userRef.update({
              activeLobbyCode: FieldValue.delete(),
            });
          }
        } catch (e) {
          logger.warn(`user cleanup failed for ${uid}: ${e}`);
        }
      })
    );

    // 3. Events + deren Responses löschen.
    const eventsSnap = await db.collection(`lobbies/${code}/events`).get();
    for (const ev of eventsSnap.docs) {
      const respSnap = await ev.ref.collection("responses").get();
      const batch = db.batch();
      for (const r of respSnap.docs) batch.delete(r.ref);
      batch.delete(ev.ref);
      await batch.commit();
    }

    // 4. Members-Docs löschen.
    if (memberUids.length > 0) {
      const batch = db.batch();
      for (const m of membersSnap.docs) batch.delete(m.ref);
      await batch.commit();
    }
    logger.info(`Cleanup done for ${code}`);
  }
);

// ─── Alle 60s: abgelaufene Events finalisieren + Missed eintragen ─────────

export const finalizeExpiredEvents = onSchedule(
  "every 1 minutes",
  async () => {
    const nowMs = Date.now();
    // Wir picken alles wo `finalized=false` — die Query braucht keinen
    // startedAt-Filter (klein bleiben), wir filtern das im Code.
    const snap = await db()
      .collectionGroup("events")
      .where("finalized", "==", false)
      .limit(50)
      .get();
    for (const evDoc of snap.docs) {
      const data = evDoc.data();
      const windowSeconds = (data.windowSeconds as number | undefined) ?? 10;
      const startedAt = (data.startedAt as Timestamp | undefined)?.toDate();
      if (!startedAt) continue;
      if (nowMs - startedAt.getTime() < (windowSeconds + 1) * 1000) continue;

      const parts = evDoc.ref.path.split("/");
      const code = parts[1];

      const [membersSnap, responsesSnap] = await Promise.all([
        db().collection(`lobbies/${code}/members`).get(),
        evDoc.ref.collection("responses").get(),
      ]);
      const responded = new Set(responsesSnap.docs.map((d) => d.id));
      const batch = db().batch();
      for (const m of membersSnap.docs) {
        if (responded.has(m.id)) continue;
        batch.set(evDoc.ref.collection("responses").doc(m.id), {
          displayName: m.data().displayName ?? "Anon",
          responseSeconds: null,
          answeredAt: FieldValue.serverTimestamp(),
        });
      }
      batch.update(evDoc.ref, { finalized: true });
      await batch.commit();
      logger.info(`Finalized event ${evDoc.id} in lobby ${code}`);
    }
  }
);
