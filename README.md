# 💰 Moneyy App

**Un gestore di finanze personali moderno e completo, costruito con Flutter.**

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![SQLite](https://img.shields.io/badge/SQLite-003B57?style=for-the-badge&logo=sqlite&logoColor=white)

## ✨ Caratteristiche Principali

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
- **Glassmorphism UI** moderna e accattivante
- **Dark/Light Mode** automatico
- **Animazioni fluide** e transizioni
- **Responsive design** per tutti i dispositivi

---

## 🚀 **Novità v1.0.0+4 (Ottobre 2025)**

### ✅ **Bug Fixes Critici**
- **Risolto errore** spread operator syntax (`...[` invece di `..[`)
- **Corretto problema** null safety per XFile nella galleria
- **Eliminato overflow** "BOTTOM OVERFLOWED BY 7.0 PIXELS"
- **Sistemata posizione** FAB e dock per evitare sovrapposizioni

### 🎨 **Miglioramenti UI/UX**
- **Layout responsivo** migliorato con CustomScrollView
- **Spacing ottimizzato** per evitare conflitti con dock
- **Categorie veloci** ridisegnate con Wrap invece di GridView
- **Aspect ratio** migliorati per schermi compatti

### 📱 **Scansione Scontrini Potenziata**
- **Gestione permessi** robusta per fotocamera/galleria
- **Error handling** migliorato con messaggi informativi
- **Supporto multi-piattaforma** ottimizzato (iOS/Android/Desktop)
- **UI responsiva** con altezze dinamiche per immagini
- **Fallback robusti** per FilePicker su desktop

### ⚡ **Performance & Stabilità**
- **Memory leaks** risolti nella gestione immagini
- **Async operations** ottimizzate
- **Loading states** migliorati
- **Exception handling** più robusto

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

## 🏗️ **Architettura**

```
lib/
├── main.dart                 # Entry point dell'app
├── models.dart              # Modelli dati (MoneyTx, Goal, etc.)
├── providers.dart           # State management (MoneyModel)
├── theme_provider.dart      # Gestione temi
├── pages/
│   ├── home_page.dart       # Dashboard principale
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

## 📞 **Supporto**

Per bug report, richieste di funzionalità o domande:
- **Issues**: Apri un issue su GitHub
- **Discussions**: Partecipa alle discussioni della community
- **Email**: emanueleantonazzo2002@gmail.com

---

**Made with ❤️ and Flutter**