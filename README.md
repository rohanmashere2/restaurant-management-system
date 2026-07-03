<div align="center">
<h1>🍽️ Restro-Manager</h1>
 
<h3>A Flutter + Firebase powered restaurant operations suite for Managers, Waiters & the Kitchen</h3>
 
**Author: Rohan Mashere**
<br>
<i>B.Tech (AI & Data Science) · Dr. D. Y. Patil Vidyapeeth, Pune</i>
 
[![Flutter](https://img.shields.io/badge/Flutter-3.9-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore%20%7C%20RTDB-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Riverpod](https://img.shields.io/badge/State%20Management-Riverpod-3E63DD)](https://riverpod.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](#license)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey)](#)
 
**[📲 Download the Android APK](https://drive.google.com/file/d/1qJo7oLJ86iS36D3dBD9ABCtBkMowYxkR/view)**
 
</div>
---
 
## 📑 Table of Contents
 
- [About the Project](#-about-the-project)
- [Features](#-features)
- [Tech Stack](#️-tech-stack)
- [Screenshots](#-screenshots)
- [Project Structure](#️-project-structure)
- [Getting Started](#-getting-started)
- [Security Notes](#-security-notes)
- [Roadmap](#️-roadmap)
- [Download](#-download)
- [Contributing](#-contributing)
- [License](#-license)
- [Contact](#-contact)
---
 
## 📖 About the Project
 
**Restro-Manager** is a cross-platform Flutter application built to digitize the day-to-day operations of a restaurant — from taking orders to billing to kitchen coordination. It supports two distinct user roles with dedicated flows:
 
- 👔 **Manager** — owns the restaurant account, configures tables, menu, and waiter staff, monitors live orders, tracks bills, and runs the kitchen display.
- 🧑‍🍳 **Waiter** — logs in on a registered device, takes table orders against the live menu, and manages checkout for assigned tables.
The app is backed entirely by **Firebase** (Authentication, Cloud Firestore, and a legacy Realtime Database layer for historical bills), giving every manager account real-time, multi-device synchronization across their staff.
 
---
 
## ✨ Features
 
### 👔 Manager
- **Secure authentication** — Email/Password sign-up with email verification, Google Sign-In, and password reset.
- **Restaurant profile** — manage restaurant name, owner details, contact info, and address.
- **Table management** — add/remove tables, view them live.
- **Menu management** — add items under Veg/Non-Veg categories and sub-categories (Starters, Main Menu, Rice & Biryani, Roti, Cold Drinks), toggle item availability (86'd items stay visible to the manager but hidden from waiters).
- **Waiter management** — onboard waiters with auto-generated credentials sent via SMS, activate/deactivate accounts, and review individual waiter activity.
- **Kitchen Display System (KDS)** — a live, cross-table ticket board showing every open order line with a **Queued → Preparing → Ready → Done** lifecycle, one tap to advance status.
- **Bill history** — dual-tab view of Cloud (Firestore) bills and Legacy (Realtime Database) bills, with per-invoice breakdowns and timestamps.
- **Navigation drawer** — quick access to Profile, Menu, Tables, Waiters, History, Kitchen Display, and Logout.
### 🧑‍🍳 Waiter
- **Device-bound login** — credentials are tied to a device ID; once logged in on a device, the app auto-recognizes the waiter on next launch (no repeated logins needed).
- **Live table menu** — browse the manager's live menu, respecting item availability.
- **Order checkout** — items grouped by category, live kitchen status chips per line, quantity control, and running bill total.
- **Waiter profile** — edit personal details and securely log out (which also frees the device lock).
### ☁️ Backend & Infrastructure
- **Cloud Firestore** as the primary real-time data store (users, tables, menu, waiters, orders, bills).
- **Realtime Database** retained for legacy historical bill records.
- **Offline persistence** enabled so waiters can keep working through brief connectivity gaps.
- **Google Sign-In** integration for managers.
- **Device registry service** for fast, secure waiter device recognition.
---
 
## 🛠️ Tech Stack
 
| Layer | Technology |
|---|---|
| Framework | Flutter (Dart SDK ^3.9.2) |
| State Management | flutter_riverpod |
| Auth | firebase_auth, google_sign_in |
| Database | cloud_firestore, firebase_database (legacy) |
| Backend Core | firebase_core, firebase_messaging |
| Fonts/UI | google_fonts |
| Utilities | device_info_plus, url_launcher |
| PDF/Print | pdf, printing |
 
---
 
## 📸 Screenshots
 
<div align="center">
<table>
<tr>
<td><img src="assets/screenshots/WhatsApp%20Image%202026-07-03%20at%208.09.45%20PM.jpeg" width="200"/></td>
<td><img src="assets/screenshots/WhatsApp%20Image%202026-07-03%20at%208.09.46%20PM.jpeg" width="200"/></td>
<td><img src="assets/screenshots/WhatsApp%20Image%202026-07-03%20at%208.09.47%20PM.jpeg" width="200"/></td>
<td><img src="assets/screenshots/WhatsApp%20Image%202026-07-03%20at%208.09.48%20PM.jpeg" width="200"/></td>
</tr>
<tr>
<td><img src="assets/screenshots/WhatsApp%20Image%202026-07-03%20at%208.09.48%20PM%20(1).jpeg" width="200"/></td>
<td><img src="assets/screenshots/WhatsApp%20Image%202026-07-03%20at%208.09.49%20PM.jpeg" width="200"/></td>
<td><img src="assets/screenshots/WhatsApp%20Image%202026-07-03%20at%208.09.49%20PM%20(1).jpeg" width="200"/></td>
<td><img src="assets/screenshots/WhatsApp%20Image%202026-07-03%20at%208.09.50%20PM.jpeg" width="200"/></td>
</tr>
<tr>
<td><img src="assets/screenshots/WhatsApp%20Image%202026-07-03%20at%208.09.50%20PM%20(1).jpeg" width="200"/></td>
<td><img src="assets/screenshots/WhatsApp%20Image%202026-07-03%20at%208.09.51%20PM.jpeg" width="200"/></td>
<td><img src="assets/screenshots/WhatsApp%20Image%202026-07-03%20at%208.09.51%20PM%20(1).jpeg" width="200"/></td>
<td><img src="assets/screenshots/WhatsApp%20Image%202026-07-03%20at%208.09.52%20PM.jpeg" width="200"/></td>
</tr>
</table>
</div>
> Filenames are the raw WhatsApp exports currently in `assets/screenshots/`. Feel free to rename them to something descriptive (e.g. `manager_home.jpeg`, `kitchen_display.jpeg`) and swap the `src` paths above to match — captions can also be added under each image with a plain line of text in the `<td>`.
 
---
 
## 🗂️ Project Structure
 
```
lib/
├── main.dart                     # App entry point, Firebase init, theming
├── firebase_options.dart         # FlutterFire-generated platform config
├── models/
│   ├── menu.dart                 # MenuItem model
│   ├── table.dart                # AppTable model
│   ├── waiter.dart                # Waiter model
│   └── order_line_status.dart     # Kitchen order lifecycle (queued/preparing/ready/done)
├── services/
│   └── waiter_device_registry.dart  # Device-based waiter auto-login registry
├── widgets/
│   └── main_drawer.dart          # Manager navigation drawer
└── screens/
    ├── selection_screen.dart          # Manager / Waiter role selection
    ├── manager_login_screen.dart
    ├── manager_register_screen.dart
    ├── manager_home_screen.dart
    ├── manager_profile_screen.dart
    ├── manager_table_screen.dart
    ├── table_add_screen.dart
    ├── manager_menu_screen.dart
    ├── menu_add_screen.dart
    ├── manager_waiter_screen.dart
    ├── manager_waiter_view.dart
    ├── waiter_add_screen.dart
    ├── manager_checkout_screen.dart
    ├── kitchen_display_screen.dart
    ├── bill_history_screen.dart
    ├── reset_password_screen.dart
    ├── waiter_login_screen.dart
    ├── waiter_home_screen.dart
    ├── waiter_menu_screen.dart
    ├── waiter_checkout_screen.dart
    └── waiter_profile_screen.dart
```
 
---
 
## 🚀 Getting Started
 
### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.9.x or newer)
- A [Firebase project](https://console.firebase.google.com/) with **Authentication** (Email/Password + Google), **Cloud Firestore**, and **Realtime Database** enabled
- Android Studio / Xcode for platform builds
### Installation
 
```bash
# Clone the repository
git clone https://github.com/<your-username>/Restro-Manager.git
cd Restro-Manager
 
# Install dependencies
flutter pub get
 
# Configure Firebase (generates firebase_options.dart)
flutterfire configure
 
# Run the app
flutter run
```
 
### Firebase Data Model (high level)
 
Each manager account is a document under `users/{uid}` containing:
 
```
users/{uid}
├── Restaurant Name, Owner Name, Email, Mobile No, Address
├── tables: [ "Table 1", "Table 2", ... ]
├── waiters: [ { name, username, password, mobile no, active, deviceCode } ]
├── menu: { Veg: { Starters: [...], ... }, Non-Veg: { ... } }
├── add_menu: { "Table 1": [ { name, price, quantity, note, kitchenStatus, lineId } ] }
├── total_bill: { "Table 1": 450.0 }
└── bill_records/ (Firestore subcollection — cloud bill history)
```
 
---
 
## 🔒 Security Notes
 
- `firebase_options.dart` contains **client-side Firebase config keys** (API keys, App IDs). These are safe to expose publicly by design — real protection comes from **Firebase Security Rules**, not from hiding this file.
- Before going to production, lock down Firestore/Realtime Database rules so that:
  - A manager can only read/write their own `users/{uid}` document.
  - Waiter documents are only mutable by their owning manager account.
- Waiter passwords are currently stored as plain fields inside the `waiters` array — consider hashing them or migrating waiters to Firebase Auth custom tokens for a production release.
- Restrict the Google Sign-In OAuth client and enable App Check if you plan to publish this publicly.
---
 
## 🗺️ Roadmap
 
- [ ] Move waiter authentication to Firebase Auth (custom tokens) instead of plaintext password matching
- [ ] Add printable/PDF invoice generation on checkout (packages already included: `pdf`, `printing`)
- [ ] Push notifications for kitchen ticket updates (`firebase_messaging` already wired in dependencies)
- [ ] Analytics dashboard for daily/weekly sales
- [ ] Multi-language support
- [ ] iOS release build & App Store listing
---
 
## 📥 Download
 
Grab the latest signed Android APK here:
 
**➡️ [Restro-Manager — APK](https://drive.google.com/file/d/1qJo7oLJ86iS36D3dBD9ABCtBkMowYxkR/view)**
 
---
 
## 🤝 Contributing
 
Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](../../issues) or open a pull request.
 
---
 
## 📄 License
 
This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
 
 
<div align="center">
Made with ❤️ using Flutter & Firebase
 
</div>