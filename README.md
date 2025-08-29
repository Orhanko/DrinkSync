# DrinkSync ☕🍹

DrinkSync je **Flutter aplikacija** za digitalno upravljanje inventarom i menijem kafića.  
Korisnici (menadžeri i osoblje) imaju pregled dostupnih artikala i mogućnost praćenja količina u realnom vremenu putem **Firebase Firestore** baze podataka.  

---

## ✨ Funkcionalnosti (trenutne i planirane)

- ✅ Firebase Authentication (email/password login)  
- ✅ Dohvat korisničkog `activeCafeId` i prikaz menija kafića  
- ✅ Live sinhronizacija sa Firestore (StreamBuilder)  
- 🔄 State management sa **BLoC patternom** (u toku implementacija)  
- 🔮 Arhitektura aplikacije prati **BLoC + Clean arhitekturu** (skalabilna, jednostavna za održavanje)  
- 🔜 Administracija menija (dodavanje, izmjena, brisanje artikala)  
- 🔜 Upravljanje korisnicima i ulogama  

---

## 📂 Firestore struktura

Firestore je organizovan po **kolekcijama i podkolekcijama**:

```
/users/{uid}
  ├── displayName: string
  ├── activeCafeId: string (npr. "caffe_bordeaux")

/cafes/{cafeId}
  ├── name: string
  ├── members/{uid} → dokumenti korisnika članova
  └── drinks/{drinkId}
        ├── name: string
        ├── quantity: number
```

- Svaki korisnik ima **`activeCafeId`** → određuje u kojem kafiću trenutno radi.  
- Svaki kafić (`cafes`) ima listu članova (`members`) i artikle (`drinks`).  

---

## 🚀 Pokretanje projekta lokalno

1. Kloniraj repozitorij:
   ```bash
   git clone https://github.com/USERNAME/DrinkSync.git
   cd DrinkSync
   ```

2. Instaliraj zavisnosti:
   ```bash
   flutter pub get
   ```

3. Dodaj Firebase konfiguracione fajlove:
   - `ios/Runner/GoogleService-Info.plist`
   - `android/app/google-services.json`

   ⚠️ Ovi fajlovi nisu u repozitoriju jer je projekt **javan**.  
   Potrebno je generisati svoje Firebase fajlove u [Firebase Console](https://console.firebase.google.com/).

4. iOS (ako buildaš na macOS-u):
   ```bash
   cd ios
   pod install
   cd ..
   ```

5. Pokreni aplikaciju:
   ```bash
   flutter run
   ```

---

## 🏗️ Arhitektura

- **State Management**: [flutter_bloc](https://pub.dev/packages/flutter_bloc)  
- **Arhitektura**: BLoC pattern + modularna podjela po feature-ima  
  - `lib/blocs/` – BLoC-ovi i eventi  
  - `lib/models/` – podaci iz Firestore-a  
  - `lib/repositories/` – apstrakcija pristupa Firebase servisima  
  - `lib/screens/` – UI sloj  
  - `lib/widgets/` – zajednički widgeti  

---

## 🛠️ Tehnologije

- [Flutter](https://flutter.dev/) (Dart)  
- [Firebase Authentication](https://firebase.google.com/docs/auth)  
- [Cloud Firestore](https://firebase.google.com/docs/firestore)  
- [flutter_bloc](https://pub.dev/packages/flutter_bloc)  

---

## 📌 Status projekta

Ovo je **aktivno razvijajući projekt** i trenutno se radi na:  
- BLoC arhitekturi  
- Dodavanju CRUD operacija za artikle  
- Podešavanju roles & permissions sistema  

---

## 📜 Licenca

MIT License © 2025 Orhan Pojskic
