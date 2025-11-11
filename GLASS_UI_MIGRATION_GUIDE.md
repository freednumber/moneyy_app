# 🫧 Guida Migrazione Glass UI - Moneyy App

## Aggiornamento Novembre 2025

Tutte le pagine dell'app sono state aggiornate con il pattern **Liquid Glass** di Apple (WWDC 2025).

---

## ✅ Pagine già aggiornate con Glass UI

### 1. **home_page.dart** ✅
- Logo con glass effect
- Card saldo netto glass
- Statistiche entrate/uscite glass
- Quick add categories glass
- Transaction cards glass
- Dialog aggiungi veloce glass
- Scroll controller integrato

[Vedi file](https://github.com/freednumber/moneyy_app/blob/main/lib/pages/home_page.dart)

### 2. **goals_page.dart** ✅
- AppBar glass
- Goal cards glass
- Progress bars glass
- Dialogs (add/edit/delete) glass
- Empty state glass

[Vedi file](https://github.com/freednumber/moneyy_app/blob/main/lib/pages/goals_page.dart)

### 3. **settings_page.dart** ✅
- AppBar glass
- Settings cards glass
- Footer glass
- Reset dialog glass completo
- Switch/toggle con glass

[Vedi file](https://github.com/freednumber/moneyy_app/blob/main/lib/pages/settings_page.dart)

### 4. **main.dart** ✅
- Navigation glass
- FAB glass posizionato sopra dock
- Quick add modal glass (Entrata/Uscita/Scansione)
- Glass buttons per tutte le azioni

[Vedi file](https://github.com/freednumber/moneyy_app/blob/main/main.dart)

### 5. **liquid_glass_dock.dart** ✅
- Dock animato glass
- Highlight animato glass
- Scroll responsive glass

[Vedi file](https://github.com/freednumber/moneyy_app/blob/main/widgets/liquid_glass_dock.dart)

---

## 🔧 Pagine da completare

### **reports_page.dart**
- AppBar: Usa `GlassUIHelper.buildGlassAppBar()`
- Chart card: Usa `GlassUIHelper.buildGlassCard()`
- Period selector: Applica BackdropFilter
- Transaction list: Ogni card con glass

### **scan_receipt_page.dart**
- Camera/Gallery buttons: Usa helper `GlassReceiptHelper.buildGlassButton()`
- Preview image: Container glass
- Result form: Card glass con `GlassUIHelper.buildGlassCard()`
- Process button: Glass gradient button

### **add_tx_page.dart**
- Form container: Usa `GlassAddTxHelper.buildGlassFormCard()`
- Category chips: Usa `GlassAddTxHelper.buildGlassCategoryChip()`
- Date/Amount fields: Wrappa in glass container
- Save button: Glass effect

### **recurring_page.dart**
- AppBar glass
- Recurring transaction cards glass
- Add/edit dialogs glass

---

## 📐 Pattern Base Glass

### Standard BackdropFilter Pattern

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

### Uso GlassUIHelper

```dart
import '../utils/glass_ui_helper.dart';

// AppBar
appBar: GlassUIHelper.buildGlassAppBar(
  title: 'Titolo Pagina',
  isDark: isDark,
),

// Card
GlassUIHelper.buildGlassCard(
  isDark: isDark,
  child: Column(
    children: [
      // Contenuto card
    ],
  ),
),

// Button
GlassUIHelper.buildGlassButton(
  label: 'Salva',
  icon: Icons.save,
  color: Color(0xFF6366F1),
  onTap: () {},
  isDark: isDark,
),

// Dialog
GlassUIHelper.showGlassDialog(
  context: context,
  title: 'Conferma',
  icon: Icons.warning,
  content: Text('Sei sicuro?'),
  actions: [
    TextButton(...),
    ElevatedButton(...),
  ],
);
```

---

## 🎨 Parametri Glass Consigliati

### Blur
- **AppBar**: 15px
- **Cards**: 12px
- **Buttons**: 10px
- **Dialogs**: 15px
- **Dock**: 20px

### Opacity (Dark Mode)
- **AppBar**: 0.08
- **Cards**: 0.08
- **Buttons**: 0.15
- **Containers**: 0.06

### Opacity (Light Mode)
- **AppBar**: 0.85
- **Cards**: 0.85
- **Buttons**: 0.10
- **Containers**: 0.70-0.80

### Border
- **Dark**: `Colors.white.withOpacity(0.15)`, width: 1.2
- **Light**: `Colors.white`, width: 1.2

### Border Radius
- **Cards principali**: 20-24
- **Buttons**: 16
- **Chips**: 16-18
- **Small elements**: 12-14

---

## 📦 File Helper Disponibili

1. **lib/utils/glass_ui_helper.dart** - Utility generale glass
2. **lib/widgets/liquid_glass_card.dart** - Widget card glass personalizzati
3. **lib/widgets/entry_actions_sheet.dart** - Bottom sheet glass azioni
4. **lib/pages/scan_receipt_page_glass.dart** - Helper scan glass
5. **lib/pages/add_tx_page_glass.dart** - Helper add transaction glass

---

## 🚀 Come applicare Glass a una pagina esistente

### Step 1: Import
```dart
import 'dart:ui';
import '../utils/glass_ui_helper.dart';
```

### Step 2: Background
```dart
Scaffold(
  backgroundColor: isDark ? Color(0xFF0F172A) : Color(0xFFF8FAFC),
  // ...
)
```

### Step 3: AppBar
```dart
appBar: GlassUIHelper.buildGlassAppBar(
  title: 'Nome Pagina',
  isDark: isDark,
),
```

### Step 4: Sostituisci Card/Container
Cerca tutti i `Card`, `Container` principali e wrappali con:
```dart
GlassUIHelper.buildGlassCard(
  isDark: isDark,
  child: // contenuto originale
)
```

### Step 5: Dialogs
Sostituisci `showDialog` con `GlassUIHelper.showGlassDialog`

### Step 6: Bottoni
Sostituisci bottoni custom con `GlassUIHelper.buildGlassButton`

---

## 🎯 Checklist per ogni pagina

- [ ] Import `dart:ui` e helper
- [ ] Background color aggiornato
- [ ] AppBar glass
- [ ] Tutte le card wrappate con glass
- [ ] Tutti i dialog con glass
- [ ] Bottoni principali con glass
- [ ] Chip/tags con glass (se presenti)
- [ ] Empty states con glass
- [ ] Test su light e dark mode
- [ ] Verifica scroll e performance

---

## 📱 Test

Dopo ogni modifica, testa:
1. **Build**: `flutter clean && flutter pub get && flutter run`
2. **Light/Dark mode**: Switch tema e verifica uniformità
3. **Scroll**: Verifica che dock si anima correttamente
4. **Dialogs**: Apri e chiudi tutti i dialog
5. **Performance**: Verifica fluidità su device reale

---

## 💡 Best Practices

1. **Usa sempre gli helper** invece di duplicare codice
2. **Mantieni parametri uniformi** (blur, opacity, border)
3. **Testa sempre dark e light mode**
4. **Non esagerare con blur** (max 20px)
5. **Performance**: Su liste lunghe usa `FakeGlass` al posto di BackdropFilter

---

## 🔗 Risorse

- [LIQUID_GLASS_GUIDE.md](https://github.com/freednumber/moneyy_app/blob/main/LIQUID_GLASS_GUIDE.md) - Guida completa liquid glass
- [NOVITA.md](https://github.com/freednumber/moneyy_app/blob/main/NOVITA.md) - Changelog aggiornato
- [liquid_glass_renderer package](https://pub.dev/packages/liquid_glass_renderer)

---

## 🎉 Risultato

Dopo aver applicato glass a tutte le pagine:
- ✅ UI uniforme e moderna
- ✅ Stile Apple WWDC 2025
- ✅ Performance ottimali con Impeller
- ✅ Dark/Light mode perfettamente supportati
- ✅ Animazioni fluide e coerenti

---

**Sviluppato da freednumber** 🚀
