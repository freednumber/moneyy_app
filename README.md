# 💰 Moneyy App

**Un gestore di finanze personali moderno e completo, costruito con Flutter e Glass UI.**

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![SQLite](https://img.shields.io/badge/SQLite-003B57?style=for-the-badge&logo=sqlite&logoColor=white)

## ✨ Caratteristiche Principali

### 🫧 **Liquid Glass UI (Apple WWDC 2025)**
- **Effetto Liquid Glass** autentico come presentato da Apple
- **Glassmorphism avanzato** con rifrazione e blur dinamici
- **BackdropFilter pattern** applicato a TUTTE le pagine
- **Effetti interattivi** con glow e animazioni fluide
- **Performance ottimizzate** con rendering Impeller
- 📚 [**Guida completa**](LIQUID_GLASS_GUIDE.md) all'implementazione
- 📋 [**Guida migrazione**](GLASS_UI_MIGRATION_GUIDE.md) per aggiornare tutte le pagine

### 🏠 **Dashboard Moderna**
- **Panoramica finanziaria** in tempo reale con glass cards
- **Statistiche mensili** di entrate e uscite
- **Categorie più utilizzate** per aggiunta rapida (glass chips)
- **Lista transazioni recenti** con interfaccia glass intuitiva
- **Scroll controller** integrato per animazioni dock

### 🤖 **Scansione Scontrini AI**
- **Estrazione automatica** di importo, negozio e data
- **OCR.space API** per riconoscimento testo affidabile
- **Accessibile da modal "Più"** con bottone Home
- **Preprocessing immagine** per migliore accuratezza
- **UI Glass** per camera, preview e risultati

### 📅 **Pianificazione Finanziaria** 🆕
- **Pagina unificata** per Obiettivi e Transazioni Ricorrenti
- **Tab switcher animato** stile glass
- **Gestione obiettivi** con tracking progresso
- **Transazioni ricorrenti** automatizzate
- **FAB contestuale** per aggiungere in base al tab attivo

### 📊 **Report e Analytics**
- **Grafici interattivi** con fl_chart
- **Analisi per categoria** e periodo (giorno/settimana/mese/anno)
- **Esportazione dati** in Excel
- **Cards glass** per tutte le statistiche

### 🎨 **Design System Uniforme**
- **Liquid Glass UI** stile Apple WWDC 2025 su TUTTE le pagine
- **Dark/Light Mode** perfettamente supportato
- **Animazioni fluide** e transizioni (300ms uniformi)
- **Responsive design** per tutti i dispositivi
- **Dock animato** con 3 tab principali + impostazioni

---

## 🚀 **Novità v1.1.0 (Novembre 2025)**

### 🆕 **Pagina Pianificazione Unificata**
- ✅ **planning_page.dart** - Combina Obiettivi + Transazioni Ricorrenti
- ✅ **Tab switcher glass** animato per cambiare sezione
- ✅ **FAB contestuale** che si adatta al tab attivo
- ✅ **Glass UI** uniforme su tutta la pagina
- ✅ **Empty states** informativi per entrambe le sezioni

### 🧹 **Navigation Semplificata (3 Tab)**
- ✅ **Dock ridotto** da 6 a 4 tab (3 principali + impostazioni)
- ✅ **Home** - Dashboard transazioni
- ✅ **Pianificazione** - Obiettivi + Ricorrenti
- ✅ **Report** - Analytics e grafici
- ✅ **Impostazioni** - Configurazione app

### 📱 **Scanner Riprogettato**
- ✅ **Rimosso dal dock** (meno usato)
- ✅ **Accessibile da modal "Più"** sulla home
- ✅ **Bottone Home** per tornare alla dashboard
- ✅ **AppBar glass** con navigation

### 🫧 **Glass UI Completo**
- ✅ **home_page.dart** - Logo, saldo, stats, quick add, transactions
- ✅ **planning_page.dart** - Tab switcher, cards, dialogs
- ✅ **goals_page.dart** - AppBar, cards, dialogs (fix sintassi)
- ✅ **settings_page.dart** - Cards, footer, reset dialog
- ✅ **main.dart** - Navigation, FAB, modal
- ✅ **liquid_glass_dock.dart** - Dock con 3-4 tab dinamici
- ✅ **GlassUIHelper** - Utility class riutilizzabile

### 🐛 **Bug Fix**
- ✅ **goals_page.dart** - Corretti errori sintassi spread operator
- ✅ **Navigation index** - Aggiornati per 3-tab structure
- ✅ **Modal scanner** - Gestione corretta del back button

### 📚 **Documentazione**
- **LIQUID_GLASS_GUIDE.md** - Guida dettagliata liquid glass
- **GLASS_UI_MIGRATION_GUIDE.md** - Come applicare glass
- **CHANGELOG_NOV_2025.md** - Changelog completo refactoring
- **NOVITA.md** - Feature list aggiornata

---

## 🛠️ **Installazione e Setup**

### Prerequisiti
```bash
# Flutter SDK >= 3.1.0
flutter --version

# Clone repository
git clone https://github.com/freednumber/moneyy_app.git
cd moneyy_app

# Installa dipendenze
flutter pub get
```

### Compilazione
```bash
# Debug
flutter run

# Release Android
flutter build apk --release

# Release iOS
flutter build ios --release

# Release macOS
flutter build macos --release
```

### Requisiti per Liquid Glass

⚠️ **IMPORTANTE**: Il Liquid Glass funziona **SOLO con Impeller**.

- ✅ **Supportato**: iOS, Android, macOS
- ❌ **NON Supportato**: Web, Windows, Linux (per ora)

```bash
# iOS/macOS: Impeller è attivo di default
# Android: verifica che sia abilitato nelle build settings
```

---

## 🏛️ **Architettura**

```
lib/
├── main.dart                    # ✅ Entry point - 3-tab navigation glass
├── models.dart                  # Modelli dati
├── providers.dart               # State management
├── theme_provider.dart          # Gestione temi
├── widgets/
│   ├── liquid_glass_card.dart   # Widget glass riutilizzabili
│   └── liquid_glass_dock.dart   # ✅ Dock glass dinamico (3-4 tab)
├── pages/
│   ├── home_page.dart           # ✅ Dashboard glass
│   ├── planning_page.dart       # ✅ NEW: Obiettivi + Ricorrenti
│   ├── reports_page.dart        # Analytics e grafici
│   ├── settings_page.dart       # ✅ Impostazioni glass
│   ├── scan_receipt_page.dart   # Scanner AI (via modal)
│   ├── add_tx_page.dart         # Aggiungi transazione
│   ├── goals_page.dart          # ⚠️ DEPRECATED
│   └── recurring_page.dart      # ⚠️ DEPRECATED
├── services/
│   ├── ai_service.dart          # Google AI
│   ├── receipt_service.dart     # OCR processing
│   └── storage_service.dart     # SQLite database
└── utils/
    ├── glass_ui_helper.dart     # ✅ Utility glass pattern
    └── permission_helper.dart   # Gestione permessi
```

---

## 🏃 **Quick Start**

```bash
# Setup
git clone https://github.com/freednumber/moneyy_app.git
cd moneyy_app
flutter pub get

# Run
flutter run

# Build
flutter build apk --release  # Android
flutter build ios --release  # iOS
```

---

## 🤝 **Contribuire**

1. Fork del repository
2. Crea branch (`git checkout -b feature/AmazingFeature`)
3. Commit (`git commit -m 'Add AmazingFeature'`)
4. Push (`git push origin feature/AmazingFeature`)
5. Apri Pull Request

---

## 📚 **Documentazione**

- **[LIQUID_GLASS_GUIDE.md](LIQUID_GLASS_GUIDE.md)** - Tutorial glass UI
- **[GLASS_UI_MIGRATION_GUIDE.md](GLASS_UI_MIGRATION_GUIDE.md)** - Migrazione glass
- **[CHANGELOG_NOV_2025.md](CHANGELOG_NOV_2025.md)** - Refactoring novembre 2025
- **[NOVITA.md](NOVITA.md)** - Feature list

---

## 🎯 **Roadmap**

### Q4 2025
- [x] Unified Planning page
- [x] 3-tab navigation
- [x] Glass UI completo
- [ ] Reports glass UI
- [ ] Testing completo

### Q1 2026
- [ ] AI Budget Assistant
- [ ] Cloud sync
- [ ] Widget iOS/Android
- [ ] Notifiche smart

---

## 📧 **Supporto**

- **Issues**: [GitHub Issues](https://github.com/freednumber/moneyy_app/issues)
- **Email**: emanueleantonazzo2002@gmail.com
- **Discussions**: [GitHub Discussions](https://github.com/freednumber/moneyy_app/discussions)

---

## 🏆 **Credits**

**Developed by** [@freednumber](https://github.com/freednumber)

**Inspired by**:
- Apple Liquid Glass (WWDC 2025)
- Material Design 3
- iOS Human Interface Guidelines

---

**Made with ❤️, 🫧 and Flutter**

---

**⭐ Star this repo if you like it!**
