import { onCall, HttpsError } from "firebase-functions/v2/https";
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
    attendeesSnapshot.docs.forEach((doc) => batch.delete(doc.ref));
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
