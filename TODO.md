OBBLIGATORI

- [x] Oridna lista clienti in ordine alfabetico per admin
- [x] Controlla i try e catch e che gestiscano correttamente gli errori
- [x] Coerenza di testi, font ecc
- [x] Verifica che i testi siano allineati centralmente dove necessario (textAlign: TextAlign.center)
- [x] Quando un utente viene disabilitato o eliminato deve venire fatto il logout
- [x] Overflow pulsanti schermata clienti
- [x] Controlla dimensioni pulsanti e altri widgets (rendile uguali)
- [x] Aggiorna le pagine dopo ogni operazione che necessita di aggiornamento
- [x] Rendi pagine aggiornabili dove necessario
- [x] Verifica che durante i caricamenti non si possano effettuare altre operazioni
- [x] Controlla che ci siano i dispose dove ci sono campi di inserimeto testo o simili
- [x] controlla se vale la pena mantenere gli stream dove creati
- [x] Cerca di otimizzare le chiamate al db (usa batch dove necessario)
- [x] Le operazioni devono essere eseguite in parallelo (se la connessione cade tra due operazioni sul db è un problema)
- [x] Controlla se nelle schermate ci sono operazioni che potrebbero essere eseguite in parallelo (ad esempio quando carica i dati)
- [x] Centra tutti i titoli nelle appbar (su andorid non sono centrati)
- [x] Cambia grafica schermata clienti
- [x] Metti super.initstate() come prima funzione chiamata
- [x] Rimuovi stream da courses se necessario
- [ ] Crea funzione che elimina corsi vecchi più di due settimane
- [ ] Crea funzione che elimina notifiche vecchie più di due settimane
- [x] Quando cliente diventa admin, rimuovilo dai corsi e rimuovigli i figli e le noitfiche

FACOLTATIVI

- [ ] Controlla se ci sono metodi helper nelle schermate da trasformare in classi
- [ ] Controlla se ci sono metodi helper o aree di codice unificabili o riutilizzabili
- [x] Sistema colore icona corso tra sezione corsi e user home (in user home è più scuro)
- [ ] Contorlla e sistema eventuali problemi di oerflow nelle schermate
- [ ] Se non c'è rete notifica opportunamente con gli errori
- [ ] Aggiungi scorrimento con caricamento per liste troppo lunghe come ad esempio notifiche (meglio se metti tutto max 10 elementi poi si aggiungono altri)
