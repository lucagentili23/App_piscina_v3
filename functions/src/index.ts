import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import {
  onDocumentUpdated,
  onDocumentDeleted,
} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

export const toggleUserStatus = onCall(async (request) => {
  const uid = request.data.uid;

  if (!uid) {
    throw new HttpsError("invalid-argument", "L'UID è obbligatorio.");
  }

  try {
    const user = await admin.auth().getUser(uid);
    const disabled = user.disabled;
    await admin.auth().updateUser(uid, { disabled: !disabled });

    await db
      .collection("users")
      .doc(uid)
      .set({ isDisabled: !disabled }, { merge: true });

    return {
      success: true,
      message: `Utente ${disabled ? "disabilitato" : "abilitato"} correttamente.`,
    };
  } catch (error) {
    throw new HttpsError("internal", "Impossibile aggiornare lo stato.", error);
  }
});

export const deleteUserAccount = onCall(async (request) => {
  const uid = request.data.uid;
  if (!uid) {
    throw new HttpsError("invalid-argument", "L'UID è obbligatorio.");
  }

  try {
    const userRef = db.collection("users").doc(uid);
    await db.recursiveDelete(userRef);

    const attendeesSnapshot = await db
      .collectionGroup("attendees")
      .where("userId", "==", uid)
      .get();

    const batch = db.batch();

    attendeesSnapshot.docs.forEach((doc) => {
      // Elimina il documento attendee
      batch.delete(doc.ref);

      // Ottieni il riferimento al corso padre
      const courseRef = doc.ref.parent.parent;

      // Decrementa bookedSpots se il riferimento al corso esiste
      if (courseRef) {
        batch.update(courseRef, {
          bookedSpots: admin.firestore.FieldValue.increment(-1),
        });
      }
    });

    await batch.commit();

    await admin.auth().deleteUser(uid);
    return { success: true, message: "Account eliminato." };
  } catch (error) {
    throw new HttpsError("internal", "Errore eliminazione.", error);
  }
});

async function sendNotificationToUser(
  userId: string,
  title: string,
  body: string,
) {
  try {
    const userDoc = await db.collection("users").doc(userId).get();
    if (!userDoc.exists) return;
    const token = userDoc.data()?.fcmToken;

    await db.collection("users").doc(userId).collection("notifications").add({
      title,
      body,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      read: false,
    });

    if (token) {
      await admin.messaging().send({
        token,
        notification: { title, body },
        data: { click_action: "FLUTTER_NOTIFICATION_CLICK" },
      });
    }
  } catch (error) {
    console.error("Errore notifica:", error);
  }
}

export const onCourseUpdated = onDocumentUpdated(
  "courses/{courseId}",
  async (event) => {
    const newData = event.data?.after.data();
    const oldData = event.data?.before.data();
    if (!newData || !oldData) return;

    const newDate = newData.date.toDate();
    const oldDate = oldData.date.toDate();
    if (newDate.getTime() === oldDate.getTime()) return;

    const formattedOldDate = oldDate.toLocaleString("it-IT", {
      day: "2-digit",
      month: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
      timeZone: "Europe/Rome",
    });

    const formattedNewDate = newDate.toLocaleString("it-IT", {
      day: "2-digit",
      month: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
      timeZone: "Europe/Rome",
    });

    const attendeesSnapshot = await db
      .collection("courses")
      .doc(event.params.courseId)
      .collection("attendees")
      .get();

    const attendeeNotifications = attendeesSnapshot.docs.map((doc) => {
      const data = doc.data();
      return data.userId
        ? sendNotificationToUser(
            data.userId,
            "Variazione corso",
            `Il corso del ${formattedOldDate} è stato spostato al ${formattedNewDate}.`,
          )
        : null;
    });

    const adminsSnapshot = await db
      .collection("users")
      .where("role", "==", "admin")
      .get();

    const adminNotifications = adminsSnapshot.docs.map((doc) => {
      return sendNotificationToUser(
        doc.id,
        "Variazione corso",
        `Il corso del ${formattedOldDate} è stato spostato al ${formattedNewDate}.`,
      );
    });

    await Promise.all([...attendeeNotifications, ...adminNotifications]);
  },
);

export const onCourseDeleted = onDocumentDeleted(
  "courses/{courseId}",
  async (event) => {
    const courseData = event.data?.data();
    if (!courseData) return;

    const date = courseData.date.toDate();
    const now = new Date();

    if (date < now) {
      console.log("Corso passato eliminato, nessuna notifica inviata.");
      const attendeesSnapshot = await db
        .collection("courses")
        .doc(event.params.courseId)
        .collection("attendees")
        .get();

      const batchDelete = db.batch();
      attendeesSnapshot.docs.forEach((doc) => batchDelete.delete(doc.ref));
      await batchDelete.commit();
      return;
    }

    const formattedDate = date.toLocaleString("it-IT", {
      day: "2-digit",
      month: "2-digit",
      timeZone: "Europe/Rome",
    });

    const attendeesSnapshot = await db
      .collection("courses")
      .doc(event.params.courseId)
      .collection("attendees")
      .get();
    const batchDelete = db.batch();

    const attendeeNotifications = attendeesSnapshot.docs.map((doc) => {
      const data = doc.data();
      batchDelete.delete(doc.ref);
      return data.userId
        ? sendNotificationToUser(
            data.userId,
            "Corso Cancellato",
            `Il corso del ${formattedDate} è stato cancellato.`,
          )
        : null;
    });

    const adminsSnapshot = await db
      .collection("users")
      .where("role", "==", "admin")
      .get();

    const adminNotifications = adminsSnapshot.docs.map((doc) => {
      return sendNotificationToUser(
        doc.id,
        "Corso Cancellato",
        `Il corso del ${formattedDate} è stato cancellato.`,
      );
    });

    await Promise.all([...attendeeNotifications, ...adminNotifications]);
    await batchDelete.commit();
  },
);

export const onAttendeeRemoved = onDocumentDeleted(
  "courses/{courseId}/attendees/{attendeeId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const courseDoc = await db
      .collection("courses")
      .doc(event.params.courseId)
      .get();
    if (!courseDoc.exists) return; // Se il corso è stato cancellato, gestisce onCourseDeleted

    if (data.userId) {
      const courseDate = courseDoc.data()?.date.toDate();
      const dateStr = courseDate
        ? courseDate.toLocaleString("it-IT", {
            day: "2-digit",
            month: "2-digit",
            timeZone: "Europe/Rome",
          })
        : "";
      await sendNotificationToUser(
        data.userId,
        "Prenotazione Cancellata",
        `Un amministratore ha rimosso ${data.displayedName} dal corso del ${dateStr}.`,
      );
    }
  },
);

// Esegue ogni giorno a mezzanotte
export const cleanupOldData = onSchedule("every day 00:00", async (event) => {
  const now = new Date();
  const twoWeeksAgo = new Date(now.getTime() - 14 * 24 * 60 * 60 * 1000); // 14 giorni fa

  try {
    // --- 1. PULIZIA CORSI VECCHI ---
    // Query per i corsi con data < 2 settimane fa
    const oldCoursesSnapshot = await db
      .collection("courses")
      .where("date", "<", admin.firestore.Timestamp.fromDate(twoWeeksAgo))
      .get();

    console.log(
      `Trovati ${oldCoursesSnapshot.size} corsi vecchi da eliminare.`,
    );

    // Usiamo un loop per eliminare ricorsivamente (Corso + Sottocollezione attendees)
    const deleteCoursePromises = oldCoursesSnapshot.docs.map(async (doc) => {
      // recursiveDelete è fondamentale perché i corsi hanno la sottocollezione 'attendees'
      await db.recursiveDelete(doc.ref);
    });

    await Promise.all(deleteCoursePromises);

    // --- 2. PULIZIA NOTIFICHE VECCHIE ---
    // Usiamo collectionGroup per cercare in TUTTE le sottocollezioni 'notifications' di tutti gli utenti
    const oldNotificationsSnapshot = await db
      .collectionGroup("notifications")
      .where("createdAt", "<", admin.firestore.Timestamp.fromDate(twoWeeksAgo))
      .get();

    console.log(
      `Trovate ${oldNotificationsSnapshot.size} notifiche vecchie da eliminare.`,
    );

    // Le eliminazioni in batch supportano max 500 operazioni
    const batchSize = 500;
    const batches = [];
    let batch = db.batch();
    let operationCounter = 0;

    oldNotificationsSnapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
      operationCounter++;

      if (operationCounter === batchSize) {
        batches.push(batch.commit());
        batch = db.batch();
        operationCounter = 0;
      }
    });

    // Committa le rimanenti
    if (operationCounter > 0) {
      batches.push(batch.commit());
    }

    await Promise.all(batches);

    console.log("Pulizia completata.");
  } catch (error) {
    console.error("Errore durante la pulizia automatica:", error);
  }
});
