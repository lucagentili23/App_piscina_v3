import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

export const toggleUserStatus = functions.https.onCall(async (data: any) => {
  const uid = data.data.uid;

  if (!uid) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "L'UID è obbligatorio."
    );
  }

  try {
    const user = await admin.auth().getUser(uid);

    const disabled = user.disabled;
    await admin.auth().updateUser(uid, {
      disabled: !disabled,
    });

    const db = admin.firestore();

    await db
      .collection("users")
      .doc(uid)
      .set({ isDisabled: !disabled }, { merge: true });

    return {
      success: true,
      message: `Utente ${
        disabled ? "disabilitato" : "abilitato"
      } correttamente.`,
    };
  } catch (error) {
    console.error("Errore toggleUserStatus:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Impossibile aggiornare lo stato dell'utente.",
      error
    );
  }
});

export const deleteUserAccount = functions.https.onCall(async (data: any) => {
  const uid = data.data.uid;
  if (!uid) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "L'UID è obbligatorio."
    );
  }

  const db = admin.firestore();

  try {
    const userRef = db.collection("users").doc(uid);
    await db.recursiveDelete(userRef);

    const attendeesSnapshot = await db
      .collectionGroup("attendees")
      .where("userId", "==", uid)
      .get();

    const batch = db.batch();
    attendeesSnapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });
    await batch.commit();

    await admin.auth().deleteUser(uid);

    return { success: true, message: "Account eliminato definitivamente." };
  } catch (error) {
    console.error("Errore deleteUserAccount:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Errore durante l'eliminazione dell'utente.",
      error
    );
  }
});
