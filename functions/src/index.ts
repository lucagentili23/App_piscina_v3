import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

/**
 * Funzione per disabilitare o abilitare un utente.
 * Parametri attesi: { uid: string, disabled: boolean }
 */
// Utilizziamo 'any' per data e context per evitare conflitti di tipizzazione TS rigorosi
export const toggleUserStatus = functions.https.onCall(async (data: any, context: any) => {
    // 1. Verifica autenticazione
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Devi essere loggato per eseguire questa operazione.');
    }

    const uid = data.uid;
    const disabled = data.disabled;

    if (!uid) {
        throw new functions.https.HttpsError('invalid-argument', 'L\'UID è obbligatorio.');
    }

    try {
        await admin.auth().updateUser(uid, {
            disabled: disabled === true,
        });
        return { success: true, message: `Utente ${disabled ? 'disabilitato' : 'abilitato'} correttamente.` };
    } catch (error) {
        console.error("Errore toggleUserStatus:", error);
        throw new functions.https.HttpsError('internal', 'Impossibile aggiornare lo stato dell\'utente.', error);
    }
});

/**
 * Funzione per eliminare definitivamente un utente e tutti i suoi dati.
 * Parametri attesi: { uid: string }
 */
export const deleteUserAccount = functions.https.onCall(async (data: any, context: any) => {
    // 1. Verifica autenticazione
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Devi essere loggato per eseguire questa operazione.');
    }

    const uid = data.uid;
    if (!uid) {
        throw new functions.https.HttpsError('invalid-argument', 'L\'UID è obbligatorio.');
    }

    const db = admin.firestore();

    try {
        // 2. Cancellazione Ricorsiva (Dati Utente + Sottocollezioni 'children')
        // Questo comando cancella il doc 'users/{uid}' E tutte le sottocollezioni al suo interno.
        const userRef = db.collection('users').doc(uid);
        await db.recursiveDelete(userRef);

        // 3. Elimina le prenotazioni (attendees) sparse
        // Le prenotazioni sono in una subcollection di 'courses', quindi recursiveDelete sopra non le tocca.
        // Dobbiamo cercarle tramite collectionGroup.
        const attendeesSnapshot = await db.collectionGroup('attendees').where('userId', '==', uid).get();
        
        // Cancellazione in batch
        const batch = db.batch();
        attendeesSnapshot.docs.forEach((doc) => {
            batch.delete(doc.ref);
        });
        await batch.commit();

        // 4. Elimina l'account da Firebase Authentication
        await admin.auth().deleteUser(uid);

        return { success: true, message: "Account eliminato definitivamente." };
    } catch (error) {
        console.error("Errore deleteUserAccount:", error);
        throw new functions.https.HttpsError('internal', 'Errore durante l\'eliminazione dell\'utente.', error);
    }
});