# PROYXD - Documentación Técnica Completa

## Índice

1. [Descripción General](#1-descripción-general)
2. [Arquitectura del Proyecto](#2-arquitectura-del-proyecto)
3. [Autenticación Firebase](#3-autenticación-firebase)
4. [Modelos de Datos](#4-modelos-de-datos)
5. [Servicios](#5-servicios)
6. [Pantallas (Screens)](#6-pantallas-screens)
7. [Widgets](#7-widgets)
8. [Firebase](#8-firebase)
9. [Assets](#9-assets)
10. [Dependencias](#10-dependencias)

---

## 1. Descripción General

**PROYXD** es un sistema de control de préstamos de laptops para laboratorios universitarios. Permite a los usuarios autenticarse y visualizar registros de salida de equipos con filtros por fecha.

**Funcionalidades:**
- Login/Registro de usuarios con Firebase Auth
- Visualización de registros de laptops desde Firebase Realtime Database
- Filtro de registros por fecha usando TableCalendar
- Visualización de detalles expandibles por registro
- Estados de préstamo (Activo, Inactivo, Pendiente)

---

## 2. Arquitectura del Proyecto

### Estructura de Carpetas

```
lib/
├── main.dart                    # Entry point + MyApp + AuthWrapper
├── firebase_options.dart        # Configuración Firebase por plataforma
├── screens/                     # Pantallas de la app
│   ├── login_screen.dart
│   ├── sign_up_screen.dart
│   ├── home_screen.dart
│   └── laptop_records_screen.dart
├── models/                      # Modelos de datos
│   ├── laptop.dart
│   └── laptop_record.dart
├── services/                    # Lógica de negocio
│   └── laptop_service.dart
└── widgets/                     # Widgets reutilizables
    └── laptop_record_card.dart
```

### Flujo de Navegación

```
main.dart
    │
    ▼
MyApp (MaterialApp con tema blue)
    │
    ▼
AuthWrapper (StreamBuilder que escucha authStateChanges)
    │
    ├──► No hay usuario ──► LoginScreen
    │                            │
    │                            └──► SignUpScreen
    │
    └──► Hay usuario ──► HomeScreen
                              │
                              └──► LaptopRecordsScreen
```

### Tema Visual

- **Primary Color:** Blue (#1976D2 / blue[700])
- **ColorScheme:** Seed color blue, brightness light
- **Material Design:** 3 (useMaterial3: true)
- **AppBar:** Centrado, sin elevación, fondo blue[700]

---

## 3. Autenticación Firebase

### main.dart - AuthWrapper

```dart
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Escucha cambios en el estado de autenticación
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Usuario autenticado
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        }

        // No autenticado
        return const LoginScreen();
      },
    );
  }
}
```

**Propósito:** Este widget envuelve toda la app y determina qué screen mostrar basándose en el estado de sesión de Firebase.

---

### LoginScreen

```dart
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
```

**Elementos del Formulario:**
- Email (TextFormField con validación)
- Contraseña (TextFormField con toggle visibility)
- Botón de submit

**Método `_login()`:**
```dart
Future<void> _login() async {
  // Valida formulario
  if (!_formKey.currentState!.validate()) return;

  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    // Firebase Auth: sign in con email/password
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    // Navega a Home
    if (mounted) {
      Navigator.pushReplacement(context, ...);
    }
  } on FirebaseAuthException catch (e) {
    // Maneja errores específicos
    setState(() => _errorMessage = _getErrorMessage(e.code));
  }
}
```

**Errores manejados:**
- `user-not-found` → "No existe una cuenta con este correo."
- `wrong-password` → "Contraseña incorrecta."
- `invalid-email` → "El correo electrónico no es válido."
- `user-disabled` → "Esta cuenta ha sido deshabilitada."
- `too-many-requests` → "Demasiados intentos."

---

### SignUpScreen

```dart
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
```

**Diferencias con Login:**
- 4 campos: Nombre, Email, Contraseña, Confirmar contraseña
- Validación de confirmación de contraseña
- `updateDisplayName()` para guardar nombre en Firebase User

**Método `_signUp()`:**
```dart
UserCredential credential = await FirebaseAuth.instance
    .createUserWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

// Actualiza el perfil con el nombre
await credential.user!.updateDisplayName(_nameController.text.trim());
```

**Errores manejados:**
- `email-already-in-use` → "Ya existe una cuenta con este correo."
- `weak-password` → "La contraseña es muy débil."

---

### HomeScreen

```dart
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    // Muestra avatar, nombre, email del usuario
    // Botón para ir a LaptopRecordsScreen
    // Botón de logout en AppBar
  }
}
```

**Funcionalidades:**
- Muestra información del usuario autenticado
- Avatar con inicial del nombre/email
- Botón "Ir a Registros" → LaptopRecordsScreen
- Botón logout en AppBar → FirebaseAuth.instance.signOut()

---

## 4. Modelos de Datos

### Laptop

```dart
class Laptop {
  final String id;
  final String nombre;
  final String laboratorio;

  Laptop({
    required this.id,
    required this.nombre,
    required this.laboratorio,
  });

  factory Laptop.fromJson(String id, Map<String, dynamic> json) {
    return Laptop(
      id: id,
      nombre: json['nombre'] ?? '',
      laboratorio: json['laboratorio'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {...};
}
```

**Propósito:** Representa una laptop del catálogo local (cargado desde laptops.json).

---

### LaptopRecord

```dart
class LaptopRecord {
  final String id;
  final String instanceId;    // Número aleatorio único del préstamo
  final String uid;           // ID de la laptop (FK)
  final String fecha;         // Fecha DD/MM/YYYY
  final String status;        // Estado: Activo, Inactivo, Pendiente
  final String timestamp;     // Hora HH:MM
  final String? usuario;      // Usuario que retiró (opcional)
  final String? observaciones; // Notas (opcional)
```

**Métodos auxiliares:**
- `getParsedDate()` → Convierte string "DD/MM/YYYY" a DateTime
- `getFormattedDate()` → Retorna la fecha formateada
- `getFormattedTime()` → Retorna la hora
- `isFromDate(DateTime date)` → Compara si el registro es de cierta fecha
- `getDateTime()` → Combina fecha y hora para ordenamiento

---

## 5. Servicios

### LaptopService

```dart
class LaptopService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  Map<String, Laptop> _laptops = {};

  Future<void> loadLaptops() async {
    // Carga laptops desde assets/laptops.json
    final String response = await rootBundle.loadString('assets/laptops.json');
    final data = await json.decode(response);
    _laptops = {};
    (data['laptops'] as Map<String, dynamic>).forEach((key, value) {
      _laptops[key] = Laptop.fromJson(key, value);
    });
  }

  Laptop? getLaptopById(String id) => _laptops[id];
```

**Métodos principales:**

```dart
// Stream reactivo para todos los registros
Stream<List<LaptopRecord>> getRecordsStream() {
  return _database.child('usersTest').onValue.map((event) {
    final List<LaptopRecord> records = [];
    if (event.snapshot.value != null) {
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      data.forEach((instanceId, recordData) {
        if (recordData is Map) {
          // Convierte y añade a la lista
          records.add(LaptopRecord.fromJson(instanceId.toString(), instanceId.toString(), Map<String, dynamic>.from(recordData)));
        }
      });
    }
    // Ordena por fecha/hora descendente
    records.sort((a, b) => b.getDateTime()?.compareTo(a.getDateTime() ?? DateTime(0)) ?? 0);
    return records;
  });
}

// Consulta por fecha específica
Future<List<LaptopRecord>> getRecordsByDate(DateTime date) async {
  final snapshot = await _database.child('usersTest').get();
  // Filtra registros donde isFromDate(date) sea true
  // Ordena por fecha/hora descendente
  return records;
}
```

**Propósito:** Abstrae el acceso a Firebase Realtime Database y al catálogo local de laptops.

---

## 6. Pantallas (Screens)

### LaptopRecordsScreen

```dart
class LaptopRecordsScreen extends StatefulWidget {
  const LaptopRecordsScreen({super.key});
  @override
  State<LaptopRecordsScreen> createState() => _LaptopRecordsScreenState();
}

class _LaptopRecordsScreenState extends State<LaptopRecordsScreen> {
  final LaptopService _laptopService = LaptopService();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _showAll = true;
  bool _isLoading = true;
  CalendarFormat _calendarFormat = CalendarFormat.month;
```

**Widgets principales:**
- `TableCalendar` → Selector de fechas
- `ElevatedButton` → "Mostrar Todos los Registros"
- `StreamBuilder` / `FutureBuilder` → Lista de registros

**Flujo:**
1. `initState()` → Carga laptops con `loadLaptops()`
2. `TableCalendar` → Al seleccionar día, cambia `_showAll = false` y filtra
3. Botón "Mostrar Todos" → Restaura `_showAll = true`
4. Lista usa `StreamBuilder` para modo "todos" o `FutureBuilder` para filtro por fecha

---

## 7. Widgets

### LaptopRecordCard

```dart
class LaptopRecordCard extends StatefulWidget {
  final LaptopRecord record;
  final Laptop? laptop;
  // laptop puede ser null si no se encuentra en el catálogo local
```

**Estructura visual:**
```
┌─────────────────────────────────┐
│ [Avatar] Título          [▾]  │  <- expand_less/expand_more
├─────────────────────────────────┤
│  DD/MM/YYYY - HH:MM            │
└─────────────────────────────────┘
     ↓ expand_more pulsado
┌─────────────────────────────────┐
│ [Avatar] Título          [▴]  │
├─────────────────────────────────┤
│ 📱 ID Instancia: 6831          │
│ 🏷 Código Laptop: LAP003        │
│ 💻 Nombre: Lenovo ThinkPad     │
│ 📍 Laboratorio: Lab A          │
│ 📅 Fecha: DD/MM/YYYY           │
│ ⏰ Hora: HH:MM                 │
│ ✅ Estado: [Activo]             │
│ 👤 Usuario: Juan Pérez         │
│ 📝 Observaciones: ...          │
└─────────────────────────────────┘
```

**_buildStatusRow():**
- Verde (#4CAF50): "Activo", "Active", "En uso"
- Gris (#9E9E9E): "Inactivo", "Inactive", "Devuelto"
- Naranja (#FF9800): "Pendiente", "Pending"

---

## 8. Firebase

### Configuración (firebase_options.dart)

Generado automáticamente por `flutterfire configure`.

```dart
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android: return android;
      case TargetPlatform.iOS: return ios;
      // ...
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAV-...',
    appId: '1:75630856613:android:...',
    messagingSenderId: '75630856613',
    projectId: 'waos-4535f',
    databaseURL: 'https://waos-4535f-default-rtdb.firebaseio.com',
    storageBucket: 'waos-4535f.firebasestorage.app',
  );
}
```

### Realtime Database - Estructura

```json
{
  "usersTest": {
    "6831": {
      "uid": "LAP003",
      "fecha": "25/03/2026",
      "timestamp": "14:30",
      "status": "Activo",
      "usuario": "Juan Pérez",
      "observaciones": "Préstamo para práctica"
    },
    "6832": {
      "uid": "LAP005",
      "fecha": "25/03/2026",
      "timestamp": "15:45",
      "status": "Pendiente"
    }
  }
}
```

**Nota:** `usersTest` es la colección principal de registros. Cada clave (ej: "6831") es un ID de instancia generado aleatoriamente.

### Firebase Authentication

**Métodos habilitados:**
- Email/Password

**Rutas de autenticación:**
- `createUserWithEmailAndPassword()` → Registro
- `signInWithEmailAndPassword()` → Login
- `signOut()` → Logout
- `authStateChanges()` → Escuchar cambios de sesión
- `currentUser` → Usuario actual
- `updateDisplayName()` → Actualizar nombre de perfil

---

## 9. Assets

### laptops.json

```json
{
  "laptops": {
    "03EE82A5": {
      "nombre": "Dell Latitude 5420",
      "laboratorio": "Laboratorio A - Ingeniería"
    },
    "LAP003": {
      "nombre": "Lenovo ThinkPad T14",
      "laboratorio": "Laboratorio A - Ingeniería"
    }
  }
}
```

**Propósito:** Catálogo local de laptops para mostrar nombre y laboratorio en lugar de solo el código UID.

**Nota:** Este archivo sirve como datos de prueba/muestra. En producción podría cargarse desde Firebase Storage o Firestore.

---

## 10. Dependencias

### pubspec.yaml - Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Firebase
  firebase_core: ^3.10.0
  firebase_auth: ^5.1.1
  firebase_database: ^11.1.7
  cloud_firestore: ^5.1.0
  firebase_app_check: ^0.3.2+6

  # UI
  cupertino_icons: ^1.0.8
  table_calendar: ^3.1.2

  # Utils
  http: ^1.4.0
  path_provider: ^2.1.1
  intl: ^0.19.0
  web: ^1.1.1
```

### Paquetes principales

| Paquete | Propósito |
|---------|-----------|
| `firebase_core` | Inicialización Firebase |
| `firebase_auth` | Autenticación usuarios |
| `firebase_database` | Realtime Database |
| `cloud_firestore` | Firestore (no usado actualmente) |
| `firebase_app_check` | Seguridad de App Check |
| `table_calendar` | Widget de calendario |
| `intl` | Formateo de fechas |
| `path_provider` | Acceso al sistema de archivos |
| `http` | Requests HTTP |

---

## Notas de Implementación

### Material Design 3

La app usa `useMaterial3: true` con seed color `Colors.blue`, lo que genera automáticamente un ColorScheme con tonos de azul.

### Estados de Error

Los widgets de formulario manejan estados de:
- Loading (CircularProgressIndicator)
- Error (Container con mensaje rojo)
- Empty (Icono de inbox/calendar con mensaje)

### Ordenamiento

Los registros se ordenan por fecha y hora descendente (más reciente primero) usando `sort()` con `getDateTime()`.
