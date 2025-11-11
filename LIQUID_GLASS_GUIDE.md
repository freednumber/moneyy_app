# 🫧 Guida Liquid Glass per Moneyy App

**Liquid Glass Effect** - Lo stile di design presentato da Apple al WWDC 2025

Questa guida ti aiuterà ad implementare il Liquid Glass effect in tutta l'interfaccia di Moneyy App.

---

## 📋 Indice

1. [Setup Iniziale](#setup-iniziale)
2. [Widget Disponibili](#widget-disponibili)
3. [Come Implementare](#come-implementare)
4. [Best Practices](#best-practices)
5. [Performance](#performance)
6. [Esempi](#esempi)

---

## 🚀 Setup Iniziale

### 1. Installazione Dipendenze

La dipendenza `liquid_glass_renderer` è già stata aggiunta al `pubspec.yaml`.

Esegui:
```bash
flutter pub get
```

### 2. Import Necessari

In ogni file dove vuoi usare il liquid glass:

```dart
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import '../widgets/liquid_glass_card.dart'; // Widget personalizzati
```

### 3. Requisiti di Sistema

⚠️ **IMPORTANTE**: Il Liquid Glass funziona **SOLO con Impeller** (il nuovo rendering engine di Flutter).

- ✅ **Supportato**: iOS, Android, macOS
- ❌ **NON Supportato**: Web, Windows, Linux (per ora)

Per verificare che Impeller sia attivo:
```bash
# iOS/macOS: Impeller è attivo di default
# Android: verifica che sia abilitato nelle build settings
```

---

## 🎨 Widget Disponibili

### 1. **LiquidGlassCard**

Card base con effetto liquid glass.

```dart
LiquidGlassCard(
  borderRadius: 30,
  padding: const EdgeInsets.all(16),
  thickness: 15,
  blur: 10,
  child: Text('Hello, Liquid Glass!'),
)
```

**Parametri:**
- `child`: Widget figlio
- `borderRadius`: Raggio dei bordi (default: 30)
- `padding`: Padding interno
- `glassColor`: Colore tinta del vetro
- `thickness`: Intensità della rifrazione (default: 15)
- `blur`: Intensità della sfocatura (default: 10)
- `onTap`: Callback per il tap
- `width`, `height`: Dimensioni opzionali

### 2. **LiquidGlassCardWithGlow**

Card con effetto glow interattivo al tocco.

```dart
LiquidGlassCardWithGlow(
  borderRadius: 30,
  thickness: 15,
  blur: 10,
  glowColor: Colors.white24,
  child: YourWidget(),
)
```

**Caratteristiche:**
- Effetto glow che segue il tocco
- Animazione stretch interattiva
- Perfetto per elementi cliccabili

### 3. **LiquidGlassContainer**

Container generico con liquid glass.

```dart
LiquidGlassContainer(
  borderRadius: 25,
  margin: const EdgeInsets.all(16),
  padding: const EdgeInsets.all(20),
  child: YourContent(),
)
```

### 4. **LiquidGlassButton**

Button interattivo con liquid glass.

```dart
LiquidGlassButton(
  borderRadius: 25,
  onPressed: () {
    // Action
  },
  child: Text('Tap Me'),
)
```

**Caratteristiche:**
- Effetto glow al tocco
- Animazione stretch
- Design premium

---

## 🎯 Come Implementare

### Struttura Base

Il liquid glass richiede uno **sfondo** per funzionare. Usa sempre un `Stack`:

```dart
Scaffold(
  body: Stack(
    children: [
      // 1. Sfondo (gradiente, immagine, etc.)
      _buildBackground(),
      
      // 2. Contenuto con liquid glass
      SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              LiquidGlassCard(
                child: YourContent(),
              ),
              // Altri widget...
            ],
          ),
        ),
      ),
    ],
  ),
)
```

### Esempio: Sfondo Gradiente

```dart
Widget _buildBackground() {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF1a1a2e),
          const Color(0xFF16213e),
          const Color(0xFF0f3460),
        ],
      ),
    ),
  );
}
```

### Esempio: Sfondo Immagine

```dart
Widget _buildBackground() {
  return Positioned.fill(
    child: Image.network(
      'https://picsum.photos/800/800',
      fit: BoxFit.cover,
    ),
  );
}
```

---

## ✨ Best Practices

### 1. **Ottimizza le Performance**

❌ **NON FARE:**
```dart
// Troppi layer separati
LiquidGlass.withOwnLayer(child: Widget1()),
LiquidGlass.withOwnLayer(child: Widget2()),
LiquidGlass.withOwnLayer(child: Widget3()),
```

✅ **FAI:**
```dart
// Usa un singolo layer per forme vicine
LiquidGlassLayer(
  settings: LiquidGlassSettings(...),
  child: Column(
    children: [
      LiquidGlass(child: Widget1()),
      LiquidGlass(child: Widget2()),
      LiquidGlass(child: Widget3()),
    ],
  ),
)
```

### 2. **Usa FakeGlass per Liste Lunghe**

Per liste con molti elementi, usa `FakeGlass` per migliorare le performance:

```dart
ListView.builder(
  itemBuilder: (context, index) {
    return FakeGlass(
      shape: LiquidRoundedSuperellipse(borderRadius: 20),
      settings: LiquidGlassSettings(
        blur: 10,
        glassColor: Color(0x33FFFFFF),
      ),
      child: ListTile(...),
    );
  },
)
```

### 3. **Blend per Forme Sovrapposte**

Quando hai forme che si sovrappongono:

```dart
LiquidGlassLayer(
  child: LiquidGlassBlendGroup(
    blend: 20.0, // Controlla quanto si fondono
    child: Stack(
      children: [
        LiquidGlass.grouped(
          shape: LiquidRoundedSuperellipse(borderRadius: 40),
          child: Widget1(),
        ),
        LiquidGlass.grouped(
          shape: LiquidRoundedSuperellipse(borderRadius: 40),
          child: Widget2(),
        ),
      ],
    ),
  ),
)
```

### 4. **Colori Ottimali**

```dart
// Dark Mode
glassColor: Color(0x1AFFFFFF)  // Bianco trasparente

// Light Mode
glassColor: Color(0x33FFFFFF)  // Bianco semi-trasparente

// Colorato (effetto Apple)
glassColor: Color(0x33FF6B9D)  // Rosa trasparente
saturation: 1.4  // Aumenta saturazione
```

### 5. **Parametri Bilanciati**

```dart
// Per card grandi
thickness: 20
blur: 12

// Per button/elementi piccoli
thickness: 10-12
blur: 6-8

// Per container/dialog
thickness: 15
blur: 10
```

---

## ⚡ Performance

### Limitazioni Conosciute

⚠️ **Memory Spike durante Animazioni**
- Dovuto a un [bug di Flutter](https://github.com/flutter/flutter/issues/138627)
- Le texture non vengono rilasciate immediatamente
- **Soluzione**: Limita le animazioni continue

⚠️ **Massimo 16 forme in BlendGroup**
- Oltre 16 forme, le performance degradano
- **Soluzione**: Dividi in più gruppi o usa `FakeGlass`

⚠️ **Blur introduce artifacts**
- Il blur può creare artefatti visivi in alcune situazioni
- **Soluzione**: Riduci il valore del blur o usa `FakeGlass`

### Consigli per Performance Ottimali

1. **Minimizza l'area coperta da `LiquidGlassLayer`**
   - Più piccola è l'area, meglio è
   - Usa layer separati per forme distanti

2. **Limita le animazioni**
   - Il glass è "gratis" quando è statico
   - Ogni movimento richiede re-rendering

3. **Usa `FakeGlass` strategicamente**
   - Per elementi off-screen
   - Per elementi meno importanti
   - Per liste lunghe

4. **Test su dispositivi reali**
   - Testa su dispositivi low-end e mid-range
   - Monitora memoria e framerate

---

## 📚 Esempi

### Esempio 1: Dashboard Card

```dart
LiquidGlassCardWithGlow(
  borderRadius: 35,
  padding: const EdgeInsets.all(24),
  thickness: 20,
  blur: 12,
  child: Column(
    children: [
      Text(
        'Saldo Totale',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 12),
      Text(
        '€1,234.56',
        style: TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ],
  ),
)
```

### Esempio 2: Button Interattivo

```dart
LiquidGlassButton(
  borderRadius: 25,
  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  thickness: 12,
  blur: 8,
  onPressed: () {
    // Action
  },
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.add, color: Colors.white),
      SizedBox(width: 8),
      Text(
        'Aggiungi Transazione',
        style: TextStyle(color: Colors.white),
      ),
    ],
  ),
)
```

### Esempio 3: Lista con FakeGlass

```dart
ListView.builder(
  padding: EdgeInsets.all(16),
  itemCount: items.length,
  itemBuilder: (context, index) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: FakeGlass(
        shape: LiquidRoundedSuperellipse(borderRadius: 20),
        settings: LiquidGlassSettings(
          blur: 8,
          glassColor: Color(0x22FFFFFF),
        ),
        child: ListTile(
          leading: Icon(Icons.receipt, color: Colors.white70),
          title: Text(
            items[index].title,
            style: TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            items[index].date,
            style: TextStyle(color: Colors.white60),
          ),
          trailing: Text(
            items[index].amount,
            style: TextStyle(
              color: Colors.greenAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  },
)
```

### Esempio 4: Dialog Glass

```dart
showDialog(
  context: context,
  builder: (context) => Dialog(
    backgroundColor: Colors.transparent,
    child: Stack(
      children: [
        // Sfondo sfocato
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        // Dialog content
        LiquidGlassContainer(
          borderRadius: 30,
          padding: EdgeInsets.all(24),
          thickness: 18,
          blur: 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Conferma',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Vuoi continuare?',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: LiquidGlassButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Annulla'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: LiquidGlassButton(
                      onPressed: () {
                        // Conferma
                        Navigator.pop(context);
                      },
                      glassColor: Color(0x44FF6B9D),
                      child: Text('Conferma'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  ),
);
```

---

## 🎓 Risorse Aggiuntive

### Documentazione Ufficiale
- [Apple WWDC 2025 - Meet Liquid Glass](https://developer.apple.com/videos/play/wwdc2025/219/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines)
- [liquid_glass_renderer su pub.dev](https://pub.dev/packages/liquid_glass_renderer)

### Repository di Riferimento
- [awesome-liquid-glass](https://github.com/carolhsiaoo/awesome-liquid-glass)
- [flutter_liquid_glass](https://github.com/whynotmake-it/flutter_liquid_glass)

### Esempi Live
Vedi `lib/pages/home_page_liquid_glass.dart` per un esempio completo di implementazione.

---

## 🐛 Troubleshooting

### Problema: L'effetto non è visibile

**Soluzione:**
1. Assicurati di avere uno sfondo (gradiente o immagine) nello Stack
2. Verifica che Impeller sia attivo
3. Controlla che i valori di `thickness` e `blur` non siano 0

### Problema: Performance scarse

**Soluzione:**
1. Riduci il numero di layer separati
2. Usa `FakeGlass` per liste lunghe
3. Minimizza le animazioni
4. Riduci l'area coperta dai layer

### Problema: Memory spike

**Soluzione:**
1. È un problema noto di Flutter ([issue](https://github.com/flutter/flutter/issues/138627))
2. Limita le animazioni continue
3. Usa `FakeGlass` dove possibile

---

## 📞 Supporto

Per domande o problemi:
- **Email**: emanueleantonazzo2002@gmail.com
- **GitHub Issues**: Apri un issue nel repository

---

**Made with 🫧 and Flutter**
