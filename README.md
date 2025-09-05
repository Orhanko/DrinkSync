# DrinkSync ☕🍹

DrinkSync je **Flutter aplikacija** za digitalno upravljanje inventarom i smjenama u kafićima.\
Korisnici (menadžeri i osoblje) imaju pregled dostupnih artikala, mogućnost praćenja količina u realnom vremenu te vođenje i zatvaranje smjena putem **Firebase Firestore** baze podataka.

---

## ✨ Funkcionalnosti

- ✅ Firebase Authentication (email/password login)
- ✅ Dohvat korisničkog `activeCafeId` i prikaz menija kafića
- ✅ Live sinhronizacija sa Firestore (BLoC + StreamBuilder)
- ✅ State management sa **BLoC patternom**
- ✅ Administracija količina artikala tokom smjene
- ✅ Logovi izmjena dostupni menadžeru
- ✅ Otvaranje i zatvaranje smjene sa:
  - Početnim novcem (zaduženje konobara)
  - Evidencijom rashoda
  - Automatskim proračunom prihoda, manjka i viška
- 🔜 Administracija menija (dodavanje, izmjena, brisanje artikala)
- 🔜 Upravljanje korisnicima i ulogama

---

## 📂 Firestore struktura

Firestore je organizovan po **kolekcijama i podkolekcijama**:

```
/users/{uid}
  ├── displayName: string
  ├── activeCafeId: string

/cafes/{cafeId}
  ├── name: string
  ├── members/{uid} → dokumenti korisnika članova
  ├── drinks/{drinkId}
  │     ├── name: string
  │     ├── quantity: number
  │     ├── price: number (feninga)
  ├── logs/{logId}
  └── handoverSessions/{sessionId}
        ├── status: "open" | "closed"
        ├── openedBy, openedByName, openedAt
        ├── openingCashCents
        ├── openingSnapshot: map(drinkId → qty/price)
        ├── closingSnapshot: map(drinkId → qty/price)
        ├── cashCount, expenses
        ├── settlement { revenue, lhs, rhs, deltaCents, status }
```

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

   ⚠️ Ovi fajlovi nisu u repozitoriju jer je projekt **javan**.\
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

- **State Management**: [flutter\_bloc](https://pub.dev/packages/flutter_bloc)
- **Arhitektura**: BLoC pattern + modularna podjela po feature-ima
  - `features/menu/` – artikli i logovi
  - `features/handover/` – otvaranje/zatvaranje smjene
  - `features/auth/` – autentifikacija
  - `widgets/` – zajednički widgeti

---

## 🛠️ Tehnologije

- [Flutter](https://flutter.dev/) (Dart)
- [Firebase Authentication](https://firebase.google.com/docs/auth)
- [Cloud Firestore](https://firebase.google.com/docs/firestore)
- [flutter\_bloc](https://pub.dev/packages/flutter_bloc)

---

## 📌 Status projekta

Ovo je **aktivno razvijajući projekt** i trenutno se radi na:

- Poboljšanju logova i filtera
- Dodavanju CRUD operacija za artikle
- Podešavanju roles & permissions sistema
- UI/UX poboljšanjima

---

## 📜 Licenca

MIT License © 2025 Orhan Pojskic