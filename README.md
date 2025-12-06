# 📱 Firebase Chat App

A **real-time mobile chat application** built using **Flutter** and **Firebase**.

The app supports user authentication, live chatting, typing indicators, and presence (online/offline status).

[📄 **Full Project Report (Detailed PDF)**](https://drive.google.com/file/d/1WqTXE8eDPL0r6H4guVA651feWu0ilEXk/view?usp=sharing)

---

## 🚀 Features

- **Firebase Authentication** (Email/Password)
- **Cloud Firestore** for:
  - User profiles
  - Storing chat messages
- **Realtime Database** for:
  - Online / Offline status
  - Typing indicator
- One-to-one chat rooms
- Clean UI with **dark theme**
- Live message updates
- Auto-scrolling message list

---

## 🛠️ Tech Stack

- **Flutter** (Dart)
- **Firebase Authentication**
- **Firebase Cloud Firestore**
- **Firebase Realtime Database**
- **Provider** state management
- **Intl** for timestamp formatting

---

## 📁 Project Structure

```
lib/
├── main.dart
├── firebase_options.dart
├── screens/
│     ├── auth/
│     │     ├── login_screen.dart
│     │     └── register_screen.dart
│     ├── home_screen.dart
│     └── chat_screen.dart
├── services/
│     ├── auth_service.dart
│     └── chat_service.dart
└── models/
      └── message.dart
```

---

## ⚙️ How to Run the Project

1.  **Clone the repository**
    ```bash
    git clone <https://github.com/MSTFA7/Chatting-Project-With-Firebase>
    cd Chatting-Project-With-Firebase
    ```
2.  **Install dependencies**
    ```bash
    flutter pub get
    ```
3.  **Run the app**
    ```bash
    flutter run
    ```

**Note:** `firebase_options.dart` is already included. Make sure **Firebase Authentication**, **Firestore**, and **Realtime Database** are enabled in your Firebase console.

---


## 📌 Notes

- If you use a different Firebase project, regenerate `firebase_options.dart` via FlutterFire CLI.
- Ensure **Realtime Database rules** allow authenticated read/write.
- Presence (online status) requires **Realtime DB** to be enabled.

---

## 📚 Full Documentation

For the complete in-depth project report:

[👉 **Full PDF Report**](https://drive.google.com/file/d/1WqTXE8eDPL0r6H4guVA651feWu0ilEXk/view?usp=sharing)
