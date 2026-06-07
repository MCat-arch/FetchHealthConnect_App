# AURA Health Monitor (Panic Attack Detector)

AURA is a comprehensive panic attack detector application built with Flutter, designed to continuously track user biometrics and contextual environment to detect and prevent panic attacks using deep learning.

## ✨ Key Features

- **Real-Time Biometric Monitoring**: Connects to Bluetooth Low Energy (BLE) wearables to capture Heart Rate (HR) and RR Intervals.
- **Advanced Health Metrics**: Automatically calculates Heart Rate Variability (HRV) and Resting Heart Rate (RHR).
- **Environmental Context**: Utilizes phone sensors to detect ambient noise levels and user activity states.
- **Machine Learning Panic Detection**: Analyzes combined biometric and environmental data by communicating with a **FastAPI endpoint deployed on Hugging Face**. The server utilizes an **LSTM (Long Short-Term Memory)** model to accurately predict the likelihood of panic attacks based on sequential data.
- **Continuous Background Execution**: Runs reliably in the background using foreground services to ensure 24/7 monitoring.
- **Intervention Tools**: Provides guided breathing exercises and audio therapy to help users calm down during an anxiety spike.
- **Data Analytics & Dashboard**: Visualizes health statistics and panic history with interactive charts.
- **Cloud Synchronization**: Securely syncs health data to Firebase Firestore for cross-device access and history tracking.

## 🏗️ System Architecture

1. **Data Ingestion**: `BLEService` and `PhoneSensorService` collect real-time data.
2. **Background Processing**: `ForegroundMonitorService` ensures uninterrupted data collection, while `WorkmanagerService` handles periodic background syncs.
3. **Intelligence Layer**: `MLPanicService` acts as a client that formats the collected time-series data and sends it to the remote Hugging Face FastAPI server. The LSTM model processes this sequence to return a prediction state, which the app uses to trigger necessary alerts.
4. **Storage Layer**: Local caching via `Hive` database and cloud synchronization via `Firebase Firestore`.

## 🛠️ Technology Stack

- **Framework**: Flutter 
- **State Management**: Provider
- **Local Storage**: Hive
- **Backend / BaaS**: Firebase (Auth, Firestore)
- **Machine Learning Backend**: FastAPI & LSTM (Hosted on Hugging Face Spaces)
- **Background Execution**: flutter_foreground_task, workmanager
- **Hardware Integration**: flutter_blue_plus (Bluetooth), sensors_plus, noise_meter, flutter_activity_recognition
- **Networking**: http
- **Routing**: go_router

## 📂 Project Structure

```text
lib/
├── database/        # Local database logic (Hive)
├── models/          # Data models and entities
├── providers/       # State management (ChangeNotifiers)
├── routes/          # Navigation and app routing (GoRouter)
├── services/        # Core business logic (BLE, FastAPI ML connection, Sensors, Firestore)
├── utils/           # Helper classes and formatting utilities
├── views/           # UI Screens and Pages
└── widgets/         # Reusable UI components
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK installed
- An active Firebase Project
- An Android/iOS device (Bluetooth features cannot be fully tested on an emulator)

### Installation
1. Clone the repository.
2. Run `flutter pub get` to install dependencies.
3. Ensure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are properly placed from your Firebase Console.
4. Run the code generator for Hive/JSON models if needed:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
5. Run the app:
   ```bash
   flutter run
   ```

## 🔒 Permissions Required
To function correctly, AURA requires the following permissions:
- **Bluetooth / Nearby Devices**: For connecting to the HR monitor.
- **Location**: Required for Bluetooth scanning on older Android versions.
- **Microphone**: For ambient noise level calculation.
- **Activity Recognition / Motion**: To determine user activity states.
- **Notifications**: To deliver panic alerts and background service indications.
- **Background Execution / Ignore Battery Optimizations**: Essential for continuous monitoring.
