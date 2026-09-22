# Customer App 📱

A modern, highly responsive, and robust Flutter mobile application designed for customers within the **Service Booking & Management System**. Built using clean architecture patterns, state-of-the-art UI elements, and reactive state management, this app enables customers to discover local services, book professional providers, track jobs in real-time, and chat directly with experts.

---

## 🚀 Key Features

*   **Service Discovery & Booking**: Browse, search, and book various services with an intuitive interface.
*   **Job & Order Tracking**: Track the lifecycle of service requests (Jobs) in real-time.
*   **Real-time Communication**: Integrated in-app chat with service providers and customer support.
*   **Authentication & Security**: Secure login/registration, token storage, and session management.
*   **Multi-language Support**: Locale/language switcher with full translation readiness.
*   **Offline/Online Awareness**: Real-time network connectivity monitoring.
*   **Responsive UI**: Optimized for all screen sizes and aspect ratios using `flutter_screenutil` (430x932 base resolution).

---

## 🏗️ Architecture Design

The project strictly follows **Clean Architecture** combined with the BLoC pattern to ensure a separation of concerns, ease of testing, and high maintainability.

```
lib/
├── config/             # Global configurations (theme, router, etc.)
├── core/               # Shared constants, errors, network services, and utilities
└── src/                # Feature-driven codebase
    ├── data/           # Models, repositories implementation, and data sources (local/remote)
    ├── domain/         # Entities, repository interfaces, and use cases
    └── presentation/   # UI layer: Screens, widgets, blocs, and cubits
```

### Clean Architecture Layers:
1.  **Data Layer**: Responsible for communicating with external APIs (via `Dio`) and local storage. Handles data mapping (JSON to Models).
2.  **Domain Layer**: Contains the core business logic (Entities, Use Cases) and defines Repository interfaces. Completely independent of any external libraries or UI components.
3.  **Presentation Layer**: Responsible for UI display. Uses **BLoC/Cubit** for reactive state management, updating UI states based on user interactions.

---

## 🛠️ Tech Stack & Key Libraries

| Category | Technology / Library | Description |
| :--- | :--- | :--- |
| **Framework** | [Flutter (SDK ^3.12.1)](https://flutter.dev) | Cross-platform UI toolkit |
| **State Management** | BLoC / Cubits | Predictable and reactive state container |
| **Routing** | `go_router` | Declarative routing system |
| **Networking** | `dio` | Powerful HTTP client with interceptors |
| **Local Storage** | `flutter_secure_storage` | Keychain/Keystore-backed secure storage |
| **Responsiveness** | `flutter_screenutil` | Dynamic adaptation for varying screen sizes |
| **UI Typography** | `google_fonts` | Modern, beautiful typefaces |
| **Internationalization**| `flutter_localizations` & `country_flags` | Multi-language & locale management |
| **Utilities** | `equatable`, `intl`, `share_plus` | Value equality, formatting, and native sharing |

---

## 📋 Prerequisites & Setup

Ensure you have the following installed on your local machine:
*   [Flutter SDK](https://docs.flutter.dev/get-started/install) (compatible version `^3.12.1`)
*   Dart SDK
*   Android Studio / Xcode (for emulation/simulation)

### Getting Started Steps:

1.  **Clone the repository:**
    ```bash
    git clone <repository_url>
    cd customer_app
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Setup Environment Variables:**
    Create a `.env` file in the root directory (if required) based on the configurations:
    ```env
    API_BASE_URL=https://api.yourdomain.com
    API_TIMEOUT=5000
    ```

4.  **Run the application:**
    ```bash
    # Run in development mode
    flutter run
    ```

5.  **Build production releases:**
    ```bash
    # For Android (APK / App Bundle)
    flutter build apk --release
    flutter build appbundle --release

    # For iOS
    flutter build ipa --release
    ```

---

## 🧹 Code Quality & Standards

*   **Linter Rules**: Strictly adheres to the rules defined in [analysis_options.yaml](file:///home/pasindu/projects/personal/service-management/customer_app/analysis_options.yaml). Run `flutter analyze` before committing.
*   **Formatting**: Keep the code clean and formatted by running `flutter format .`.
*   **Architecture Integrity**: Do not import `presentation` or `data` layer components directly into the `domain` layer. Keep layers decoupled!

