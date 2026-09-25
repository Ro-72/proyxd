# PROYXD - Sistema de Control de Laptops

# El codigo del ESP32 se encuentra en el archivo CodigoESP32.txt

## Descripción

Aplicación móvil desarrollada en Flutter para gestionar el control de préstamo de laptops en laboratorios universitarios. Permite visualizar registros de salida de laptops con filtro por fecha.

## Tecnología

| Componente | Versión |
|------------|---------|
| Flutter | 3.35.5 |
| Dart | 3.9.2 |
| Firebase Auth | 5.7.0 |
| Firebase Realtime Database | 11.3.10 |

## Características

- Autenticación de usuarios (login/registro)
- Visualización de registros de laptops
- Filtro por fecha con calendario
- Información detallada de cada préstamo
- Estados de registro (Activo, Inactivo, Pendiente)

## Requisitos

- Flutter SDK 3.35.5+
- Android Studio / Xcode
- Cuenta Firebase configurada

## Instalación

```bash
cd proyxd
flutter pub get
flutter run
```

## Estructura del Proyecto

```
proyxd/
├── lib/
│   ├── main.dart                 # Entry point, AuthWrapper
│   ├── firebase_options.dart     # Configuración Firebase
│   ├── screens/
│   │   ├── login_screen.dart     # Login con email/password
│   │   ├── sign_up_screen.dart   # Registro de usuarios
│   │   ├── home_screen.dart      # Dashboard principal
│   │   └── laptop_records_screen.dart  # Lista de registros
│   ├── models/
│   │   ├── laptop.dart           # Modelo Laptop
│   │   └── laptop_record.dart    # Modelo Registro
│   ├── services/
│   │   └── laptop_service.dart   # Lógica de negocio
│   └── widgets/
│       └── laptop_record_card.dart  # Card de registro
├── assets/
│   └── laptops.json              # Catálogo de laptops (prueba)
└── pubspec.yaml                  # Dependencias
```

## Navegación

```
App Start
    │
    ▼
AuthWrapper ───────────────────────┐
    │                              │
    ▼ (no session)        ▼ (session active)
LoginScreen ────────────► SignUpScreen
    │                              │
    └──────────────────────────────┘
                   │
                   ▼
              HomeScreen
                   │
                   ▼
          LaptopRecordsScreen
```

## Screens

| Screen | Descripción |
|--------|-------------|
| `LoginScreen` | Inicio de sesión con email/password |
| `SignUpScreen` | Registro de nueva cuenta |
| `HomeScreen` | Dashboard con info de usuario y acceso a registros |
| `LaptopRecordsScreen` | Vista de registros con calendario |

## Firebase

**Proyecto:** waos-4535f

- **Auth:** Firebase Authentication (email/password)
- **Database:** Firebase Realtime Database
- **Ruta de registros:** `usersTest`

## Estado

En desarrollo activo.

## Comandos Útiles

```bash
flutter analyze    # Analizar código
flutter pub get     # Instalar dependencias
flutter run         # Ejecutar en dispositivo
```
