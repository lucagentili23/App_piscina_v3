import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

// Funzione per disabilitare/abilitare un utente
export const toggleUserStatus = functions.https.onCall(async (data, context) => {
  // Verifica che chi chiama sia un admin (opzionale ma consigliato)
  if (!context.auth) {
     throw new functions.https.HttpsError('unauthenticated', 'Devi essere loggato.');
  }
  
  // Qui potresti controllare se context.auth.token.role === 'admin' se hai impostato i custom claims

  const uid = data.uid;
  const disabled = data.disabled; // true per disabilitare, false per abilitare

  try {
    await admin.auth().updateUser(uid, {
      disabled: disabled,
    });
    return { success: true, message: `Utente ${disabled ? 'disabilitato' : 'abilitato'} con successo.` };
  } catch (error) {
    throw new functions.https.HttpsError('internal', 'Errore aggiornamento utente', error);
  }
});

// Funzione per eliminare un utente e tutti i suoi dati
export const deleteUserAccount = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
     throw new functions.https.HttpsError('unauthenticated', 'Devi essere loggato.');
  }

  const uid = data.uid;

  try {
    // 1. Elimina le prenotazioni (attendees) fatte dall'utente
    // Usiamo collectionGroup per trovare tutti i documenti 'attendees' di questo utente
    const attendeesSnapshot = await db.collectionGroup('attendees').where('userId', '==', uid).get();
    const batch = db.batch();
    
    attendeesSnapshot.docs.forEach((doc) => {
        // Opzionale: Decrementare il contatore 'bookedSpots' nel corso padre
        // Questo richiederebbe una logica più complessa, per semplicità qui rimuoviamo solo la prenotazione
        batch.delete(doc.ref);
    });

    // 2. Elimina i figli (subcollection 'children' dentro l'utente)
    const childrenSnapshot = await db.collection('users').doc(uid).collection('children').get();
    childrenSnapshot.docs.forEach((doc) => {
        batch.delete(doc.ref);
    });

    // 3. Elimina il documento utente in Firestore
    batch.delete(db.collection('users').doc(uid));

    await batch.commit();

    // 4. Elimina l'account da Firebase Auth
    await admin.auth().deleteUser(uid);

    return { success: true };
  } catch (error) {
    throw new functions.https.HttpsError('internal', 'Errore eliminazione utente', error);
  }
});