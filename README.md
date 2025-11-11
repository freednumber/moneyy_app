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
- **Preprocessing immagine** per migliore accuratezza
- **UI Glass** per camera, preview e risultati
- **Supporto multi-piattaforma** (mobile e desktop)

### 🎯 **Gestione Obiettivi**
- **Obiettivi di risparmio** personalizzabili con glass cards
- **Tracking del progresso** in tempo reale
- **Dialogs glass** per add/edit/delete
- **Visualizzazioni grafiche** accattivanti

### 🔄 **Transazioni Ricorrenti**
- **Automatizzazione** di stipendi, bollette, abbonamenti
- **Gestione flessibile** delle frequenze
- **UI Glass** uniforme

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
- **Dock animato** con highlight glass

---

## 🚀 **Novità v1.0.0+5 (Novembre 2025)**

### 🫧 **Glass UI Completo**
- ✅ **home_page.dart** - Logo, saldo, stats, quick add, transactions TUTTE glass
- ✅ **goals_page.dart** - AppBar, cards, dialogs TUTTE glass
- ✅ **settings_page.dart** - Cards, footer, reset dialog TUTTE glass
- ✅ **main.dart** - Navigation, FAB, quick add modal glass
- ✅ **liquid_glass_dock.dart** - Dock animato con glass perfetto
- ✅ **GlassUIHelper** - Utility class per pattern riutilizzabili

### 🔧 **UX Migliorata**
- **FAB posizionato** sopra il dock (no sovrapposizioni)
- **Quick add modal** glass con Entrata/Uscita/Scansione
- **Scroll controller** integrato per animazioni dock
- **Dialog glass uniformi** su tutte le pagine
- **Nessun freeze o crash**

### 📚 **Documentazione**
- **LIQUID_GLASS_GUIDE.md** - Guida dettagliata liquid glass
- **GLASS_UI_MIGRATION_GUIDE.md** - Come applicare glass a tutte le pagine
- **NOVITA.md** - Changelog completo
- **Esempi pratici** e snippet pronti all'uso

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

### Configurazione Permessi

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSCameraUsageDescription</key>
<string>Per scansionare scontrini e aggiungere transazioni automaticamente</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Per selezionare immagini degli scontrini dalla galleria</string>
```

---

## 🏛️ **Architettura**

```
lib/
├── main.dart                    # Entry point con navigation glass
├── models.dart                  # Modelli dati (MoneyTx, Goal, etc.)
├── providers.dart               # State management (MoneyModel)
├── theme_provider.dart          # Gestione temi dark/light
├── widgets/
│   ├── liquid_glass_card.dart   # Widget Liquid Glass riutilizzabili
│   ├── liquid_glass_dock.dart   # Dock animato glass
│   └── entry_actions_sheet.dart # Bottom sheet glass azioni
├── pages/
│   ├── home_page.dart           # ✅ Dashboard glass completa
│   ├── home_page_liquid_glass.dart # Esempio avanzato glass
│   ├── moneyy_glass_home.dart   # Alternative glass home
│   ├── scan_receipt_page.dart   # Scansione AI scontrini
│   ├── goals_page.dart          # ✅ Gestione obiettivi glass
│   ├── reports_page.dart        # Analytics e grafici
│   ├── recurring_page.dart      # Transazioni ricorrenti
│   ├── settings_page.dart       # ✅ Impostazioni glass
│   └── add_tx_page.dart         # Aggiungi transazione
├── services/
│   ├── ai_service.dart          # Integrazione Google AI
│   ├── receipt_service.dart     # Elaborazione scontrini OCR
│   └── storage_service.dart     # Database SQLite
└── utils/
    ├── glass_ui_helper.dart     # ✅ Utility glass pattern riutilizzabili
    └── permission_helper.dart   # Gestione permessi
```

---

## 🎓 **Guida Rapida Liquid Glass**

### Pattern Base

```dart
import 'dart:ui';

BackdropFilter(
  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
  child: Container(
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
      ),
    ),
    child: // Il tuo contenuto
  ),
)
```

### Uso Helper

```dart
import 'package:moneyy/utils/glass_ui_helper.dart';

// AppBar Glass
appBar: GlassUIHelper.buildGlassAppBar(
  title: 'Titolo',
  isDark: isDark,
),

// Card Glass
GlassUIHelper.buildGlassCard(
  isDark: isDark,
  child: YourWidget(),
),

// Button Glass
GlassUIHelper.buildGlassButton(
  label: 'Salva',
  icon: Icons.save,
  color: Color(0xFF6366F1),
  onTap: () {},
  isDark: isDark,
),
```

### Widget Personalizzati

```dart
import 'package:moneyy/widgets/liquid_glass_card.dart';

// Card semplice
LiquidGlassCard(
  borderRadius: 30,
  child: Text('Hello!'),
)

// Card con glow
LiquidGlassCardWithGlow(
  borderRadius: 30,
  child: YourWidget(),
)

// Button interattivo
LiquidGlassButton(
  onPressed: () {},
  child: Text('Tap Me'),
)
```

📚 **Guide complete**:
- [LIQUID_GLASS_GUIDE.md](LIQUID_GLASS_GUIDE.md) - Tutorial dettagliato
- [GLASS_UI_MIGRATION_GUIDE.md](GLASS_UI_MIGRATION_GUIDE.md) - Come applicare glass

---

## 🎯 **Roadmap**

### In Sviluppo
- [ ] Completare glass su reports_page.dart
- [ ] Completare glass su scan_receipt_page.dart
- [ ] Completare glass su add_tx_page.dart
- [ ] Completare glass su recurring_page.dart

### Prossime Feature
- [ ] **AI Budget Assistant** - Consigli intelligenti
- [ ] **Categorizzazione automatica** transazioni
- [ ] **Widget iOS/Android** per home screen
- [ ] **Notifiche smart** per obiettivi e budget
- [ ] **Sync cloud** multi-device

### Miglioramenti UI
- [ ] **Animazioni avanzate** con Hero transitions
- [ ] **Gesture personalizzate** per navigazione
- [ ] **Temi personalizzati** oltre dark/light
- [ ] **Accessibility** migliorato

---

## 🤝 **Contribuire**

1. **Fork** del repository
2. **Crea** un branch per le tue modifiche (`git checkout -b feature/AmazingFeature`)
3. **Commit** le modifiche (`git commit -m 'Add some AmazingFeature'`)
4. **Push** al branch (`git push origin feature/AmazingFeature`)
5. **Apri** una Pull Request

### Linee Guida
- Segui le **convenzioni Dart/Flutter**
- Usa **commit semantici** (feat:, fix:, docs:, style:, refactor:)
- Testa le modifiche su **multiple piattaforme**
- Documenta **nuove funzionalità**
- Applica **pattern glass** per coerenza UI

---

## 📝 **Licenza**

Questo progetto è rilasciato sotto licenza MIT. Vedi il file [LICENSE](LICENSE) per i dettagli.

---

## 📦 **Risorse Utili**

### Liquid Glass & Design
- [Apple WWDC 2025 - Meet Liquid Glass](https://developer.apple.com/videos/play/wwdc2025/219/)
- [liquid_glass_renderer su pub.dev](https://pub.dev/packages/liquid_glass_renderer)
- [awesome-liquid-glass](https://github.com/carolhsiaoo/awesome-liquid-glass)
- [Material Design 3](https://m3.material.io/)

### Flutter & Dart
- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Provider State Management](https://pub.dev/packages/provider)
- [FL Chart Documentation](https://pub.dev/packages/fl_chart)

### OCR & AI
- [OCR.space API](https://ocr.space/ocrapi)
- [Google AI Studio](https://ai.google.dev/)

---

## 📚 **Documentazione Completa**

- **[LIQUID_GLASS_GUIDE.md](LIQUID_GLASS_GUIDE.md)** - Tutorial dettagliato Liquid Glass
- **[GLASS_UI_MIGRATION_GUIDE.md](GLASS_UI_MIGRATION_GUIDE.md)** - Come applicare glass a tutte le pagine
- **[NOVITA.md](NOVITA.md)** - Changelog novembre 2025

---

## 📞 **Supporto e Contatti**

Per bug report, richieste di funzionalità o domande:
- **Issues**: [Apri un issue su GitHub](https://github.com/freednumber/moneyy_app/issues)
- **Discussions**: [Partecipa alle discussioni](https://github.com/freednumber/moneyy_app/discussions)
- **Email**: emanueleantonazzo2002@gmail.com

---

## 🏆 **Credits**

**Sviluppato da** [freednumber](https://github.com/freednumber)

**Design inspirato da**:
- Apple Liquid Glass (WWDC 2025)
- Material Design 3
- iOS Human Interface Guidelines

---

**Made with ❤️, 🫧 and Flutter**

---

## 🌟 **Screenshots**

### Home con Liquid Glass
![Home Glass](screenshots/home_glass.png)

### Obiettivi Glass
![Goals Glass](screenshots/goals_glass.png)

### Scanner Scontrini
![Scanner](screenshots/scanner.png)

### Report Analytics
![Reports](screenshots/reports.png)

---

## 🎯 **Quick Start**

```bash
# Clone e setup
git clone https://github.com/freednumber/moneyy_app.git
cd moneyy_app
flutter pub get

# Run
flutter run

# Build release
flutter build apk --release  # Android
flutter build ios --release  # iOS
flutter build macos --release # macOS
```

---

## 🧪 **Testing**

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Integration tests
flutter drive --target=test_driver/app.dart
```

---

**⭐ Se ti piace il progetto, lascia una stella su GitHub!**
