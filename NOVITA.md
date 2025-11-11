# 🆕 Novità Moneyy App - Novembre 2025

## Liquid Glass Update

- Completamente aggiornata l'interfaccia con stile liquid glass Apple WWDC 2025
- Floating Action Button (FAB) posizionato sopra il dock, con menu rapido glass: Entrata/Uscita/Scansiona
- Dock animato con effetto vetro liquido e highlight mobile responsive
- BottomSheet, modal, e card principali ora glass coerenti
- Passaggio centralizzato del ScrollController per animazioni dock

## UX Migliorata

- Nessuna sovrapposizione tra dock/FAB, sempre accessibile
- Navigazione tra pagine senza freeze o bug
- Quick add sempre accessibile e dismissabile
- Versioni doppie dei file Dart rimosse

## Bugfix

- Corretto impallamento app causato da controller/duplicati
- Funzioni di dispose/init centralizzate, nessun crash all'avvio
- Aggiornata la gestione dei modali per evitare freeze e sovrapposizioni

## Best Practice

- Usa i widget personalizzati glass per tutte le card, modali, dock
- Versioni aggiornate dei file su GitHub: main.dart e widgets/liquid_glass_dock.dart

## Link utili
- [main.dart](https://github.com/freednumber/moneyy_app/blob/main/main.dart)
- [widgets/liquid_glass_dock.dart](https://github.com/freednumber/moneyy_app/blob/main/widgets/liquid_glass_dock.dart)

---
Vuoi guide dettagliate su come integrare la glass UI su pages come Report, Goals o Recurring? Scrivimi!