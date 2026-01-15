---
description: Repository Information Overview
alwaysApply: true
---

# UPEA Postgraduate Management System - Complete Repository Guide

## Summary

Flutter-based cross-platform application for UPEA (Universidad de El Alto) postgraduate student management. Features advanced facial recognition authentication, intelligent OCR-based identity verification, biometric login, real-time student dashboards, program enrollment management, payment tracking, document processing, and comprehensive profile management. Supports Android, iOS, Web, Linux, macOS, and Windows with Spanish-first localization.

## Project Overview

**Type**: Flutter Multi-Platform Application  
**Architecture Pattern**: Clean Architecture (3-layer: Domain → Infrastructure → Presentation)  
**State Management**: Riverpod (FutureProvider, Provider, AsyncNotifier)  
**Routing**: GoRouter with protected routes and session-based access control  
**API Client**: Dio with custom error handling  
**Local Storage**: SharedPreferences + file system  
**ML/Vision**: Google ML Kit (face detection, OCR)  
**Authentication**: Local biometric + cloud-based login

## Directory Structure

```
lib/
├── config/                    # Application configuration
│   ├── constants/             # App-wide constants and environment variables
│   ├── menu/                  # Navigation menu definitions and Rive models
│   └── router/                # GoRouter configuration with route guards
├── core/                      # Shared services and utilities
│   ├── animations/            # Custom page transitions and animations
│   ├── services/              # Business logic services
│   │   ├── *_ocr_*.dart       # OCR and document processing services
│   │   ├── biometric_service.dart        # Fingerprint/face auth
│   │   ├── profile_image_processor_service.dart  # Image processing
│   │   ├── local_storage_service.dart    # SharedPreferences wrapper
│   │   └── *_letter_*.dart    # Document composition services
│   ├── utils/                 # Helper utilities (Rive, etc.)
│   └── dio_error_handler.dart # Global HTTP error handling
├── features/                  # Feature modules (Clean Architecture)
│   ├── login/                 # Authentication feature
│   │   ├── domain/            # Business logic layer
│   │   │   ├── entities/      # Core data models (Login, Data)
│   │   │   ├── repositories/  # Abstract repository interfaces
│   │   │   └── errors/        # Custom exceptions
│   │   ├── infrastructure/    # Data layer
│   │   │   ├── datasources/   # API calls and data fetching
│   │   │   ├── models/        # JSON serialization models
│   │   │   └── repositories/  # Repository implementations
│   │   ├── presentation/      # UI layer
│   │   │   ├── pages/         # Full-screen pages
│   │   │   ├── providers/     # Riverpod state management
│   │   │   ├── widgets/       # Reusable UI components
│   │   │   └── mixins/        # OCR integration mixins
│   │   ├── onboding/          # Onboarding screens
│   │   └── widgets/           # Shared login widgets
│   └── sistema/               # Main system feature (dashboard, profiles, programs)
│       ├── domain/            # Business logic (ProgramaPosgrado entities)
│       ├── infrastructure/    # Data layer (datasources, models, repositories)
│       ├── presentation/      # Screens and providers
│       ├── screens/           # Feature-specific screens
│       │   ├── entryPoint/    # Main app shell with navigation
│       │   ├── inicio/        # Dashboard/home
│       │   ├── diplomados/    # Program management
│       │   ├── perfil/        # User profile and documents
│       │   ├── configuracion/ # Settings
│       │   ├── pagos/         # Payment management
│       │   ├── curriculum/    # Curriculum management
│       │   ├── notificaciones/# Notifications
│       │   └── mapa/          # University map
│       ├── widgets/           # Shared cards and components
│       └── providers/         # State management (Riverpod)
└── main.dart                  # App initialization and theme setup

assets/
├── Fonts/           # Intel, Poppins, Parisienne (Spanish)
├── images/          # General images
├── icons/           # Icon assets
├── svg/             # Vector graphics
├── avaters/         # User avatars
├── Backgrounds/     # UI backgrounds
└── RiveAssets/      # Animation assets
```

## Architecture Pattern - Clean Architecture

### Layer Breakdown

**Domain Layer** (`domain/`)
- Pure Dart, no Flutter dependencies
- Defines entities, repositories (interfaces), and use cases
- Contains business logic and validation rules
- Example: `Login` entity with `token`, `nombreUsuario`, `grupos`

**Infrastructure Layer** (`infrastructure/`)
- Implements domain repositories
- Handles API communication via Dio
- Manages data serialization/deserialization (JSON models)
- Implements local persistence
- Example: `LoginDatasourceImpl` → `LoginRepositoryImpl`

**Presentation Layer** (`presentation/`)
- Flutter UI components and screens
- Riverpod providers for state management
- Handles user interactions and navigation
- Example: `PaginaLogin` screen → `AsyncLoginNotifier` provider

### Data Flow
```
UI (Presentation) 
  → Provider/State 
  → Repository Interface (Domain) 
  → Repository Implementation (Infrastructure) 
  → DataSource (API/Local Storage)
```

## Authentication & Login Flow

### 1. Initial Entry
- `SplashScreen` → 2-second delay for app initialization
- Check session data in SharedPreferences (`session_data` key)
- Redirect to `/login` or `/sistema/pantalla_principal` based on session

### 2. Registration Flow
```
StartScreen 
  → RegisterScreen (email/phone entry)
  → VerificationScreen (OTP verification)
  → IDUploadScreen (identity document scan)
  → FaceRecognitionScreen (facial capture)
  → RegistrationFormScreen (pre-filled from OCR)
  → PasswordSetupScreen (credentials)
  → TermsConditionsScreen
  → Automatic login & entry to dashboard
```

### 3. Login Flow
```
PaginaLogin 
  → AsyncLoginNotifier (calls LoginDatasourceImpl)
  → API: POST /auth/login {nombre_usuario, clave_usuario}
  → Save session data to SharedPreferences
  → Navigate to PantallaPrincipal
```

### Session Management
- Session data stored with key `session_data` (JSON format)
- Contains authentication token, expiration, and user info
- Route guard in GoRouter checks for session on protected routes
- Public routes: `/splash`, `/start-screen`, `/register`, `/login`, etc.

## Main Features & User Workflows

### 1. Facial Recognition Authentication
**File**: `lib/features/login/presentation/pages/pantalla_reconocimiento_facial.dart`

- **Technology**: Google ML Kit Face Detection + Camera
- **Flow**: Center face → Hold still → Auto-capture when detected
- **Validation**:
  - Single face detection (reject multiple/no faces)
  - Distance check (no acercarse/alejarse feedback)
  - Face rotation boundaries
  - Centering in circular guide
- **Animations**:
  - Pulse border while detecting
  - Success confetti animation (Rive)
  - Head rotation indicator
  - Flash effect on capture
- **Photo Capture**: Stores multiple XFiles, processes best match
- **Error Handling**: Camera permissions, device compatibility, ML Kit errors

### 2. Identity Document OCR
**Files**: `lib/features/login/presentation/pages/pantalla_subida_identidad.dart`

- **Service**: Advanced AI-powered OCR (`servicio_ocr_ia_avanzado.dart`)
- **Supported Documents**:
  - Cédula de Identidad (primary)
  - Título Académico
  - Certificado de Nacimiento
  - Certificado de Estudios
  - Carta de Prórroga
- **Extraction**:
  - Nombres, Apellidos
  - Cédula CI number
  - Fecha Emisión, Fecha Expiración
  - Confidence scoring (0.0-1.0)
  - Field-level location tracking
- **Features**:
  - Document type auto-detection
  - Validation warnings and suggestions
  - Metadata extraction
  - Image quality assessment
- **Output**: Pre-fills `RegistrationFormScreen` with extracted data

### 3. Student Dashboard
**File**: `lib/features/sistema/screens/inicio/inicio_screen.dart`

- Welcome message with student name
- Program cards (DIPLOMADO, ESPECIALIDAD, MAESTRÍA tabs)
- Quick action buttons
- Notifications badge
- Program filtering by type and area

### 4. Program Management
**File**: `lib/features/sistema/screens/diplomados/`

- **DiplomadosScreen**: Enrolled programs with details
- **ProgramasDisponiblesScreen**: Browse and enroll in new programs
- **DetalleProgramaScreen**: Comprehensive program info
  - Curriculum outline
  - Duration and schedule
  - Requirements and prerequisites
  - Instructor information
  - Enrollment and payment status
- **Data Source**: API calls with program filters (area, type)

### 5. Profile Management
**File**: `lib/features/sistema/screens/perfil/`

- **perfil_screen.dart**: Main profile with avatar and user info
- **mis_datos_personales_screen.dart**: Personal data editing
- **mis_documentos_personales_screen.dart**: Document upload and management
- **pantalla_escaneo_inteligente.dart**: Smart document scanning with preview
- Profile image: Stored in app documents directory via `ProfileImageProcessorService`

### 6. Payment & Enrollment
**Files**: `lib/features/sistema/screens/pagos/deposito_matricula_screen.dart`

- Enrollment and deposit tracking
- Payment status display
- Deposit details with enrollment number and amount
- Integration with banking system (UI placeholder)

### 7. Notifications
**File**: `lib/features/sistema/screens/notificaciones/notificaciones_screen.dart`

- Notification list with timestamps
- Provider: `notificaciones_provider.dart`
- Notification badge count on home screen

## State Management - Riverpod

### Pattern: Repository-Driven Providers

```dart
// Data Source Provider
final programaPosgradoDatasourceProvider = Provider<ProgramaPosgradoDatasource>(
  (ref) => ProgramaPosgradoDatasourceImpl(),
);

// Repository Provider
final programaPosgradoRepositoryProvider = Provider<ProgramaPosgradoRepository>(
  (ref) => ProgramaPosgradoRepositoryImpl(
    ref.watch(programaPosgradoDatasourceProvider),
  ),
);

// Async Data Provider (FutureProvider with filters)
final programasPosgradoProvider = FutureProvider.family<List<ProgramaPosgrado>, Map<String, String?>>(
  (ref, filters) => ref.watch(programaPosgradoRepositoryProvider)
    .obtenerProgramas(area: filters['area'], tipo: filters['tipo']),
);

// Single Item Provider (by ID)
final programaPorIdProvider = FutureProvider.family<ProgramaPosgrado?, String>(
  (ref, id) => ref.watch(programaPosgradoRepositoryProvider)
    .obtenerProgramaPorId(id),
);
```

### Login Async Notifier
```dart
@riverpod
class AsyncLoginNotifier extends _$AsyncLoginNotifier {
  @override
  FutureOr<Login> build(String nombreUsuario, String claveUsuario) async {
    final datasource = LoginDatasourceImpl();
    return await datasource.login(
      nombreUsuario: nombreUsuario,
      claveUsuario: claveUsuario,
    );
  }
}
```

## Core Services

### OCR & Document Processing
- **`servicio_ocr_ia_avanzado.dart`** (1074 lines): Advanced ML-based OCR
  - Document type detection (6 types)
  - Field confidence scoring
  - Warnings and suggestions system
  - Metadata collection
  - Rect-based field locations
  
- **`servicio_ocr_inteligente_identidad.dart`**: Identity-focused OCR
  - Optimized for CI documents
  - Validation rules specific to Bolivia
  
- **`identity_smart_ocr_service.dart`**: Enhanced identity recognition
  - Landmark detection
  - Advanced validation

### Biometric Authentication
- **`biometric_service.dart`**: Local Auth integration
  - Fingerprint authentication
  - Face ID on iOS
  - Fallback to PIN if biometric unavailable
  - Error handling for unsupported devices

### Image & Profile Processing
- **`profile_image_processor_service.dart`**: Image manipulation
  - Crop, resize, compress
  - File system storage
  - Conversion formats

### Document Composition
- **`servicio_compositor_cartas_ci.dart`**: Letter generation
- **`ci_letter_composer_service.dart`**: Identity letter templates

### Local Storage
- **`local_storage_service.dart`**: Unified storage wrapper
  - SharedPreferences for small data
  - File system for images and documents
  - JSON serialization for complex objects
  - Keys: `personal_data`, `curriculum_data`, `session_data`, `profile_image_path`

## API Communication

### Base Configuration
**File**: `lib/features/login/infrastructure/datasources/login_datasource_impl.dart`

```dart
Dio(
  BaseOptions(
    baseUrl: Environment.apiUrlPsg,  // From .env: https://dev-repositorio-backend.posgradoupea.edu.bo/api/v1
    connectTimeout: Duration(seconds: 30),
    receiveTimeout: Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ),
)
```

### Error Handling
**File**: `lib/core/dio_error_handler.dart`

- Maps DioException types to user-friendly messages
- Handles: timeout, bad response, connection errors, bad certificate
- Status codes: 401 (wrong credentials), 404 (not found), 500+ (server errors)
- Special handling for web CORS issues

### Endpoints
- **Login**: `POST /auth/login` → Returns token, expiration, user info
- **Programs**: `GET /programas?area=...&tipo=...` → List programs with filters
- **Program Detail**: `GET /programa/{id}` → Detailed program information

## Data Models & Entities

### Login Entity
```dart
class Login {
  String status;              // "success", "error"
  Data data;                  // Token and user info
  String message;             // User-friendly message
}

class Data {
  String token;               // JWT or session token
  int expiresIn;              // Seconds until expiration
  String nombreUsuario;       // Username
  List<String> grupos;        // User groups/roles
}
```

### Programa Posgrado Entity
```dart
class ProgramaPosgrado {
  String id;
  String titulo;
  String tipo;                // DIPLOMADO, ESPECIALIDAD, MAESTRÍA
  String area;                // Academic area
  String descripcion;
  int duracion;               // In months
  double costo;
  List<String>? modulos;      // Curriculum modules
  String? instructor;
  DateTime? fechaInicio;
}
```

### Navigation Routes

| Path | Name | Purpose |
|------|------|---------|
| `/splash` | SplashScreen | Loading animation |
| `/start-screen` | StartScreen | Welcome/onboarding |
| `/register` | RegisterScreen | Initial registration |
| `/verification` | VerificationScreen | OTP/email verification |
| `/upload-ci` | IDUploadScreen | Identity document capture |
| `/face-recognition` | FaceRecognitionScreen | Facial authentication |
| `/registration-form` | RegistrationFormScreen | User data form (OCR pre-filled) |
| `/password-setup` | PasswordSetupScreen | Password creation |
| `/terms-conditions` | TermsConditionsScreen | T&C acceptance |
| `/login` | PaginaLogin | Login page |
| `/sistema/pantalla_principal` | PantallaPrincipal | Main dashboard |
| `/diplomados` | DiplomadosScreen | Enrolled programs |
| `/programas-disponibles` | ProgramasDisponiblesScreen | Available programs |
| `/detalle-programa` | DetalleProgramaScreen | Program details |
| `/mis-datos-personales` | MisDatosPersonalesScreen | Personal info |
| `/mis-documentos-personales` | MisDocumentosPersonalesScreen | Document management |
| `/configuracion` | ConfiguracionScreen | Settings |
| `/notificaciones` | NotificacionesScreen | Notification center |

### Route Guards
- Public routes: No session required
- Protected routes: Redirect to login if no session
- Session check: Stored in SharedPreferences (`session_data` key)

## UI/UX Framework

### Animations & Transitions
**Files**: `lib/core/animations/`

- **CustomAnimations**: Pre-built animation compositions
- **PageTransitions**: Custom route transitions (fade, slide, scale)
- **Rive Integration**: Vector animations for:
  - Loading states
  - Success/completion feedback
  - Character animations (mascot)
  - Confetti effects

### Theme Configuration
**File**: `lib/main.dart`

```dart
ThemeData(
  scaffoldBackgroundColor: Color(0xFFEEF1F8),  // Light blue
  fontFamily: "Intel",
  primarySwatch: Colors.blue,
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      borderSide: BorderSide(color: Color(0xFFDEE3F2), width: 1),
    ),
  ),
)
```

### Custom Widgets
- **LoginTopBackground**: Blue curved header
- **FondoAzulCurvoWidget**: Curved background component
- **ProgramCard**: Program display card
- **MatriculaDetailCard**: Enrollment details
- **ProfileAvatarWidget**: User profile picture with badge
- **NotificationIconWidget**: Notification bell with count

### Fonts
- **Intel**: Primary font for UI (Regular, SemiBold)
- **Poppins**: Bold headings
- **Parisienne**: Decorative (Spanish motto)

## Build & Installation

### Prerequisites
```bash
# Required versions
Flutter SDK: Latest (requires Dart ^3.10.0)
Android SDK: API 21+ (targetSdkVersion 34+)
iOS: 11.0+ (deployment target)
```

### Setup Commands
```bash
# Get dependencies
flutter pub get

# Code generation (Riverpod)
dart run build_runner build

# Run dev app
flutter run -d android                # Android device
flutter run -d ios                    # iOS simulator
flutter run -d chrome                 # Web (may need CORS fix)
flutter run -d linux                  # Linux
flutter run -d windows                # Windows
flutter run -d macos                  # macOS

# Build releases
flutter build apk --release           # Android APK
flutter build appbundle --release     # Android App Bundle
flutter build ios --release           # iOS IPA (use Xcode)
flutter build web --release           # Web deployment
flutter build linux --release         # Linux binary
flutter build windows --release       # Windows executable
```

### Environment Setup
```bash
# Create .env file from template
cp .env.template .env

# Content:
THE_API_PSG=https://dev-repositorio-backend.posgradoupea.edu.bo/api/v1

# Load via:
# lib/config/constants/environment.dart
```

### Platform-Specific Setup

**Android**:
- Gradle 8.1+ configured in `android/build.gradle.kts`
- Permissions (camera, storage, biometric) in `AndroidManifest.xml`
- Camera ML Kit models auto-downloaded on first use

**iOS**:
- Xcode 14+ required
- Pod dependencies installed via CocoaPods
- Permissions in `Info.plist`
- Face/Touch ID configuration

**Web**:
- Chrome/Firefox/Safari support
- CORS handling: May need `--disable-web-security` flag for local development
- ML Kit models loaded from CDN

## Testing

**Framework**: Flutter Test (unit and widget tests)  
**Test Location**: No test directory found in repository  
**Run Tests**:
```bash
flutter test
```

Note: Project currently has test infrastructure but no tests implemented. Consider adding:
- Unit tests for services and repositories
- Widget tests for screens
- Integration tests for critical flows (login, enrollment)

## Dependencies Summary

| Category | Package | Version | Purpose |
|----------|---------|---------|---------|
| **State Management** | flutter_riverpod | ^3.0.3 | Reactive state |
| | riverpod_annotation | ^4.0.0 | Code generation |
| **Routing** | go_router | ^17.0.0 | Navigation |
| **API** | dio | ^5.9.0 | HTTP client |
| **Storage** | shared_preferences | ^2.5.3 | Local data |
| | path_provider | ^2.1.5 | File paths |
| **ML/Vision** | google_mlkit_face_detection | ^0.13.1 | Face detection |
| | google_mlkit_text_recognition | ^0.15.0 | OCR |
| | camera | ^0.11.0 | Camera access |
| **Auth** | local_auth | ^3.0.0 | Biometric |
| | permission_handler | ^12.0.1 | Permissions |
| **Animations** | rive | ^0.13.0 | Vector animations |
| | animate_do | ^4.2.0 | Pre-built animations |
| **UI/UX** | flutter_svg | ^2.0.9 | SVG rendering |
| | font_awesome_flutter | ^10.12.0 | Icons |
| **Localization** | flutter_localizations | SDK | Spanish locale |
| **Utilities** | flutter_dotenv | ^6.0.0 | .env files |
| | url_launcher | ^6.2.5 | Open URLs |
| | image_picker | ^1.1.2 | Photo selection |
| | file_picker | ^10.3.8 | File selection |
| | share_plus | ^10.1.4 | Share content |
| | image | ^4.1.7 | Image processing |
| | open_filex | ^4.5.0 | Open files |

## Development Workflow

### Code Generation
```bash
# Generate Riverpod providers and other code
dart run build_runner build

# Watch for changes (incremental)
dart run build_runner watch
```

### Linting & Analysis
```bash
# Check code quality
flutter analyze

# Fix issues automatically
dart fix --apply
```

### Debugging Tips
1. **Web Development**: Run Chrome with `--disable-web-security` for local CORS
2. **Camera Issues**: Check permissions and ML Kit model download
3. **API Errors**: Check `dio_error_handler.dart` for detailed error messages
4. **Face Recognition**: Ensure good lighting, clear face, in-frame positioning
5. **OCR**: Best results with well-lit identity documents, minimal skew

## Key Files Reference

| File | Purpose |
|------|---------|
| `lib/main.dart` | App initialization, theme, router setup |
| `lib/config/router/app_router.dart` | All routes and navigation guards |
| `lib/core/services/local_storage_service.dart` | Storage abstraction layer |
| `lib/features/login/presentation/pages/pantalla_reconocimiento_facial.dart` | Face recognition implementation |
| `lib/features/login/infrastructure/datasources/login_datasource_impl.dart` | Login API integration |
| `lib/features/sistema/presentation/providers/programa_posgrado_provider.dart` | Program data providers |
| `pubspec.yaml` | Dependencies and asset configuration |
| `.env.template` | Environment variable template |
| `analysis_options.yaml` | Linting configuration |

## Performance Optimization Notes

1. **Camera**: Set to `ResolutionPreset.low` on Android for stability
2. **Face Detection**: Fast mode vs accurate mode trade-off
3. **OCR**: Heavy processing—cache results when possible
4. **Images**: Compress with `profile_image_processor_service` before storage
5. **Network**: 30-second timeout for API calls, proper error recovery

## Localization

**Supported Locales**:
- Spanish (es) - Primary
- Spanish (Spain) - es-ES
- Spanish (Bolivia) - es-BO
- English (en) - Fallback

**Locale Setup**: Configured in `main.dart` with `flutter_localizations`

This is a comprehensive, production-ready postgraduate management system with enterprise-grade features for identity verification and secure authentication.