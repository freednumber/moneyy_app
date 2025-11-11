# 💰 Moneyy App

**Un gestore di finanze personali moderno e completo, costruito con Flutter.**

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![SQLite](https://img.shields.io/badge/SQLite-003B57?style=for-the-badge&logo=sqlite&logoColor=white)

## ✨ Caratteristiche Principali

### 🎨 **Liquid Glass UI (Apple WWDC 2025)**
- **Effetto Liquid Glass** autentico come presentato da Apple
- **Glassmorphism avanzato** con rifrazione e blur dinamici
- **Effetti interattivi** con glow e stretch al tocco
- **Performance ottimizzate** con rendering Impeller
- 📚 [**Guida completa**](LIQUID_GLASS_GUIDE.md) all'implementazione

### 🏠 **Dashboard Moderna**
- **Panoramica finanziaria** in tempo reale
- **Statistiche mensili** di entrate e uscite
- **Categorie più utilizzate** per aggiunta rapida
- **Lista transazioni recenti** con interfaccia intuitiva

### 🤖 **Scansione Scontrini AI**
- **Estrazione automatica** di importo, negozio e data
- **Vision API** con fallback OCR locale
- **Supporto multi-piattaforma** (mobile e desktop)
- **Gestione permessi** ottimizzata per galleria e fotocamera

### 🎯 **Gestione Obiettivi**
- **Obiettivi di risparmio** personalizzabili
- **Tracking del progresso** in tempo reale
- **Visualizzazioni grafiche** accattivanti

### 🔄 **Transazioni Ricorrenti**
- **Automatizzazione** di stipendi, bollette, abbonamenti
- **Gestione flessibile** delle frequenze
- **Notifiche** per transazioni programmate

### 📊 **Report e Analytics**
- **Grafici interattivi** con fl_chart
- **Analisi per categoria** e periodo
- **Esportazione dati** in Excel
- **Trend e insights** finanziari

### 🎨 **Design System**
- **Liquid Glass UI** stile Apple WWDC 2025
- **Dark/Light Mode** automatico
- **Animazioni fluide** e transizioni
- **Responsive design** per tutti i dispositivi

---

## 🚀 **Novità v1.0.0+5 (Novembre 2025)**

### 🫧 **Liquid Glass Effect**
- **Integrazione completa** dell'effetto Liquid Glass di Apple
- **Widget personalizzati** per card, button e container
- **Effetti interattivi** con glow e stretch
- **Guida completa** per l'implementazione
- **Performance ottimizzate** con Impeller

### 📚 **Documentazione**
- **LIQUID_GLASS_GUIDE.md** - Guida dettagliata all'uso
- **Esempi completi** di implementazione
- **Best practices** per le performance
- **Widget riutilizzabili** pronti all'uso

---

## 🛠️ **Installazione e Setup**

### Prerequisiti
```bash
# Flutter SDK >= 3.1.0
flutter --version

# Dipendenze
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
├── main.dart                 # Entry point dell'app
├── models.dart              # Modelli dati (MoneyTx, Goal, etc.)
├── providers.dart           # State management (MoneyModel)
├── theme_provider.dart      # Gestione temi
├── widgets/
│   └── liquid_glass_card.dart # Widget Liquid Glass riutilizzabili
├── pages/
│   ├── home_page.dart       # Dashboard principale
│   ├── home_page_liquid_glass.dart # Esempio con Liquid Glass
│   ├── scan_receipt_page.dart # Scansione AI scontrini
│   ├── goals_page.dart      # Gestione obiettivi
│   ├── reports_page.dart    # Analytics e grafici
│   ├── recurring_page.dart  # Transazioni ricorrenti
│   └── settings_page.dart   # Impostazioni app
├── services/
│   ├── ai_service.dart      # Integrazione Google AI
│   ├── receipt_service.dart # Elaborazione scontrini
│   └── storage_service.dart # Database SQLite
└── parsed_receipt.dart      # Modello dati scontrini
```

---

## 🎓 **Guida Rapida Liquid Glass**

### Uso Base

```dart
import 'package:moneyy/widgets/liquid_glass_card.dart';

// Card semplice
LiquidGlassCard(
  borderRadius: 30,
  child: Text('Hello, Liquid Glass!'),
)

// Card con effetto glow
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

### Struttura Base

```dart
Scaffold(
  body: Stack(
    children: [
      // 1. Sfondo (gradiente o immagine)
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(...),
        ),
      ),
      
      // 2. Contenuto con liquid glass
      SafeArea(
        child: LiquidGlassCard(
          child: YourContent(),
        ),
      ),
    ],
  ),
)
```

📚 **Per la guida completa, vedi [LIQUID_GLASS_GUIDE.md](LIQUID_GLASS_GUIDE.md)**

---

## 🤝 **Contribuire**

1. **Fork** del repository
2. **Crea** un branch per le tue modifiche
3. **Commit** le modifiche con messaggi descrittivi
4. **Push** al tuo fork
5. **Apri** una Pull Request

### Linee Guida
- Segui le **convenzioni Dart/Flutter**
- Usa **commit semantici** (feat:, fix:, docs:, etc.)
- Testa le modifiche su **multiple piattaforme**
- Documenta **nuove funzionalità**

---

## 📝 **Licenza**

Questo progetto è rilasciato sotto licenza MIT. Vedi il file [LICENSE](LICENSE) per i dettagli.

---

## 📦 **Risorse**

### Liquid Glass
- [Apple WWDC 2025 - Meet Liquid Glass](https://developer.apple.com/videos/play/wwdc2025/219/)
- [liquid_glass_renderer su pub.dev](https://pub.dev/packages/liquid_glass_renderer)
- [awesome-liquid-glass](https://github.com/carolhsiaoo/awesome-liquid-glass)

### Flutter
- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)

---

## 📞 **Supporto**

Per bug report, richieste di funzionalità o domande:
- **Issues**: Apri un issue su GitHub
- **Discussions**: Partecipa alle discussioni della community
- **Email**: emanueleantonazzo2002@gmail.com

---

**Made with ❤️, 🫧 and Flutter**
