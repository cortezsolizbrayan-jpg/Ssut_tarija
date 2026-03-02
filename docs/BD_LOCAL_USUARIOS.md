# Base de Datos Local - Usuarios de Ejemplo

La aplicación ahora incluye una **base de datos local** con usuarios de ejemplo precargados para facilitar el desarrollo y testing sin depender de la API externa.

## 📋 Usuarios Precargados

### Usuario 1: Ficticio – Directo al menú (sin verificación)
```
CI: 12865214
Contraseña: payaso123
Nombre: Participante Registrado
Email: participante@example.com
Programas inscritos: 0 (ninguno)
```

**Características:**
- ✅ **Usuario ficticio solo para pruebas**
- ✅ **Va directo al menú principal** (sin verificación de identidad)
- ✅ Si en pantalla de registro ingresas este CI, te redirige al login
- ✅ Contraseña: payaso123

**Nota:** El usuario con CI 12865213 es **real** y debe pasar por verificación de identidad; no está en la BD local.

### Usuario 2: Con Programas
```
CI: 87654321
Contraseña: test123
Nombre: María José Mamani Quispe
Email: maria@example.com
Programas inscritos: 2
```

## 🚀 Cómo Funciona

### 1. Inicialización Automática

La base de datos local se inicializa automáticamente al arrancar la app (`main.dart`):

```dart
await LocalDatabaseService.initializeDatabase();
```

### 2. Proceso de Login

Al hacer login, el sistema sigue esta estrategia de **fallback**:

```
1. ¿Usuario existe en BD local? → Login local ✅
2. Si no → Intentar login con API externa ☁️
3. Si API falla → Error ❌
```

**Ventajas:**
- Desarrollo sin conexión a internet
- Testing rápido sin depender del backend
- Usuarios de ejemplo siempre disponibles

### 3. Estado Vacío en "Mis Programas"

Cuando un usuario **no tiene programas inscritos** (como el usuario ficticio `12865214`):

**Características visuales:**
- 🏅 Medallas en plomo (gris) mostrando que no hay logros
- 💬 Mensaje: *"¡Aún no tienes programas!"*
- 📝 Descripción motivacional
- 🔘 Botón **"Explorar Programas"** → navega a `/sistema/programas-vigentes`
- 🎨 Diseño limpio y motivador (no intimidante)

## 🧪 Cómo Probar

### Prueba 1: Usuario ficticio sin programas
```
1. Abrir la app
2. Login con CI: 12865214 / password: payaso123 (usuario ficticio)
3. Ir a "Mis Programas" (ícono de medalla en bottom bar)
4. Observar: 
   - Estado vacío con todas las medallas en plomo
   - Invitación a explorar programas
5. Tocar "Explorar Programas"
6. Inscribirse en un programa
7. Volver a "Mis Programas" → Ahora debería aparecer el programa
```

### Prueba 2: Usuario 12865214 – Directo al menú (sin verificación de identidad)
```
1. Pantalla de bienvenida → "Registrarse"
2. Ingresar CI: 12865214
3. Observar: "Ya estás registrado. Redirigiendo al inicio de sesión..." → va a /login
4. En login: CI 12865214 / contraseña: payaso123
5. Observar: Entra directo al menú principal (no verificación de identidad)
```

### Prueba 3: Usuario con programas
```
1. Login con CI: 87654321 / password: test123
2. Ir a "Mis Programas"
3. Observar: Lista de programas inscritos con detalles
```

## 🛠️ Servicios Disponibles

### `LocalDatabaseService`

**Métodos principales:**

```dart
// Autenticar usuario
LocalDatabaseService.authenticateUser(ci, password)

// Obtener usuario por CI
LocalDatabaseService.getUserByCi(ci)

// Registrar nuevo usuario
LocalDatabaseService.registerUser(userData)

// Obtener programas inscritos
LocalDatabaseService.getUserEnrolledPrograms(ci)

// Inscribir en programa
LocalDatabaseService.enrollUserInProgram(ci, programId)

// Desinscribir de programa
LocalDatabaseService.unenrollUserFromProgram(ci, programId)

// Reiniciar BD a valores por defecto
LocalDatabaseService.resetDatabase()
```

## 📦 Ubicación de los Archivos

```
lib/
├── core/
│   └── services/
│       └── local_database_service.dart  ← Servicio de BD local
├── features/
│   ├── login/
│   │   └── infrastructure/
│   │       └── datasources/
│   │           └── login_datasource_impl.dart  ← Login con fallback
│   └── sistema/
│       └── screens/
│           └── home/
│               └── mis_programas_screen.dart  ← Estado vacío
└── main.dart  ← Inicialización de BD
```

## 💾 Almacenamiento

La BD local utiliza **SharedPreferences** para persistir los datos:

- **Key:** `local_users_db`
- **Formato:** JSON serializado
- **Persistencia:** Los datos sobreviven entre sesiones de la app

## 🔄 Reiniciar la BD

Si necesitas resetear la BD a los valores por defecto:

```dart
await LocalDatabaseService.resetDatabase();
```

## ⚡ Ventajas del Sistema

1. **Desarrollo sin API**: Puedes desarrollar sin conexión
2. **Testing rápido**: No dependes de la disponibilidad del backend
3. **Datos consistentes**: Los usuarios de ejemplo siempre están disponibles
4. **Fallback automático**: Si la API falla, intenta con BD local
5. **UX mejorado**: Estado vacío bonito y motivador

## 🎨 Diseño del Estado Vacío

El estado vacío de "Mis Programas" sigue estos principios de UX:

✅ **Lo que SÍ hace:**
- Muestra claramente que no hay programas
- Motiva al usuario a inscribirse
- Proporciona acción directa (botón "Explorar Programas")
- Usa metáfora visual (medallas en plomo = sin logros aún)
- Diseño limpio y profesional

❌ **Lo que NO hace:**
- Mostrar error (no es un error, es un estado válido)
- Dejar al usuario sin opciones
- Diseño intimidante o confuso
- Mensaje negativo

## 📱 Screenshots (Descripción)

### Estado Vacío:
```
┌─────────────────────────┐
│                         │
│    🏅 (Medalla gris)    │
│                         │
│ ¡Aún no tienes         │
│    programas!           │
│                         │
│ Todas tus medallas      │
│ están en plomo...       │
│                         │
│  🥉  🥈  🥇            │
│ (Todas en gris)         │
│                         │
│ [Explorar Programas]    │
│                         │
│ Descubre maestrías,     │
│ especialidades...       │
└─────────────────────────┘
```

## 🐛 Troubleshooting

### Problema: "Usuario no encontrado"
**Solución:** Verifica que estés usando el CI correcto (`12865213` o `87654321`)

### Problema: "BD no inicializada"
**Solución:** La BD se inicializa automáticamente en `main()`. Si hay error, revisa los logs.

### Problema: "Estado vacío no aparece"
**Solución:** Asegúrate de que el usuario no tenga programas inscritos. Usa el usuario `12865213`.

## 📚 Referencias

- **Servicio principal:** `lib/core/services/local_database_service.dart`
- **Login:** `lib/features/login/infrastructure/datasources/login_datasource_impl.dart`
- **Estado vacío:** `lib/features/sistema/screens/home/mis_programas_screen.dart` (método `_buildEmptyState`)

---

**Última actualización:** Enero 2026  
**Versión:** 1.0.0
