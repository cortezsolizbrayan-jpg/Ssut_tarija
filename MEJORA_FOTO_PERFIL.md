# Mejora: Actualización Automática de Foto de Perfil

## Problema Identificado
La foto capturada en el reconocimiento facial no se reflejaba automáticamente en la pantalla "Mis Datos Personales" de la app. El usuario tenía que cerrar y volver a abrir la pantalla para ver la foto actualizada.

## Solución Implementada

### 1. Mejora en `MisDatosPersonalesScreen`
**Archivo**: `lib/features/sistema/screens/perfil/mis_datos_personales_screen.dart`

#### Cambios realizados:
- **Agregado `didChangeDependencies()`**: Este método del ciclo de vida se ejecuta cuando la pantalla vuelve a estar activa, permitiendo recargar la imagen automáticamente.

```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  // Recargar imagen cuando se vuelve a la pantalla
  _refreshProfileImageIfNeeded();
}
```

- **Mejorado `_refreshProfileImageIfNeeded()`**: Ahora verifica múltiples condiciones para determinar si debe actualizar la imagen:
  - Compara paths de archivos
  - Verifica timestamps de modificación
  - Actualiza solo cuando hay cambios reales

```dart
Future<void> _refreshProfileImageIfNeeded() async {
  final imageFile = await LocalStorageService.getProfileImageFile();
  if (!mounted) return;
  
  // Verificar si el archivo existe y si cambió
  bool shouldUpdate = false;
  if (nextPath.isNotEmpty && nextPath != currentPath) {
    shouldUpdate = true;
  } else if (nextPath.isNotEmpty && currentPath.isNotEmpty) {
    // Verificar si el archivo fue modificado (por timestamp)
    try {
      final currentFile = File(currentPath);
      final nextFile = File(nextPath);
      if (await currentFile.exists() && await nextFile.exists()) {
        final currentModified = await currentFile.lastModified();
        final nextModified = await nextFile.lastModified();
        if (nextModified.isAfter(currentModified)) {
          shouldUpdate = true;
        }
      }
    } catch (e) {
      debugPrint('Error verificando timestamp de imagen: $e');
    }
  }
  
  if (shouldUpdate || _profileImage == null && imageFile != null) {
    setState(() {
      _profileImage = imageFile;
    });
    debugPrint('✅ Foto de perfil actualizada en Mis Datos Personales');
  }
}
```

- **Eliminado `addPostFrameCallback` redundante**: Ya no es necesario porque `didChangeDependencies()` maneja la recarga de forma más eficiente.

### 2. Mejora en `ProfileAvatarWidget`
**Archivo**: `lib/features/sistema/widgets/profile_avatar_widget.dart`

#### Cambios realizados:
- **Agregado tracking de path**: Ahora el widget mantiene registro del último path cargado para evitar recargas innecesarias.

```dart
class _ProfileAvatarWidgetState extends State<ProfileAvatarWidget> with RouteAware {
  File? _profileImage;
  String? _lastLoadedPath;  // NUEVO: tracking de path
```

- **Mejorado `didChangeDependencies()`**: Ahora usa un método separado para verificar y recargar solo cuando es necesario.

```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  // Recargar imagen cuando se vuelve a la pantalla o cambian las dependencias
  _checkAndReloadImage();
}

Future<void> _checkAndReloadImage() async {
  final imageFile = await LocalStorageService.getProfileImageFile();
  if (!mounted) return;
  
  // Solo actualizar si cambió el path o si no teníamos imagen antes
  final newPath = imageFile?.path;
  if (newPath != _lastLoadedPath || (_profileImage == null && imageFile != null)) {
    setState(() {
      _profileImage = imageFile;
      _lastLoadedPath = newPath;
    });
  }
}
```

### 3. Flujo de Guardado (Ya Existente)
**Archivo**: `lib/features/login/presentation/pages/pantalla_reconocimiento_facial.dart`

El método `_processAndStoreProfilePhoto()` ya guardaba correctamente la foto en ambas ubicaciones:
- SharedPreferences (`profile_image_path`)
- Documentos del participante (`profile_photo_path`)

```dart
final savedPath = await LocalStorageService.saveProfileImage(toSave);
if (savedPath == null) return;

final current = await LocalStorageService.getParticipantDocumentsData() ?? <String, dynamic>{};
current['profile_photo_path'] = savedPath;
await LocalStorageService.saveParticipantDocumentsData(current);
```

## Beneficios de la Solución

1. **Actualización Automática**: La foto se actualiza inmediatamente al volver a la pantalla "Mis Datos Personales"
2. **Eficiencia**: Solo recarga cuando hay cambios reales (evita recargas innecesarias)
3. **Consistencia**: La foto se muestra igual en toda la app (avatar, perfil, requisitos)
4. **Mejor UX**: El usuario ve los cambios sin necesidad de reiniciar la app

## Flujo Completo

1. Usuario captura foto en reconocimiento facial
2. Foto se procesa con fondo plomo (4x4)
3. Foto se guarda en:
   - `LocalStorageService.saveProfileImage()` → SharedPreferences
   - `participant_documents['profile_photo_path']` → Para requisitos
4. Usuario navega a "Mis Datos Personales"
5. `didChangeDependencies()` detecta que volvió a la pantalla
6. `_refreshProfileImageIfNeeded()` verifica si hay nueva foto
7. Si hay cambios, actualiza `_profileImage` con `setState()`
8. La UI se redibuja mostrando la nueva foto

## Archivos Modificados

1. `lib/features/sistema/screens/perfil/mis_datos_personales_screen.dart`
   - Agregado `didChangeDependencies()`
   - Mejorado `_refreshProfileImageIfNeeded()`
   - Eliminado `addPostFrameCallback` redundante

2. `lib/features/sistema/widgets/profile_avatar_widget.dart`
   - Agregado tracking de path (`_lastLoadedPath`)
   - Mejorado `didChangeDependencies()`
   - Agregado `_checkAndReloadImage()`

## Testing Recomendado

1. Capturar foto en reconocimiento facial
2. Navegar a "Mis Datos Personales"
3. Verificar que la foto se muestra correctamente
4. Cambiar la foto desde "Mis Datos Personales" (botón cámara)
5. Verificar que se actualiza en el avatar del AppBar
6. Ir a "Requisitos de Inscripción" → "Fotografías"
7. Verificar que muestra la misma foto

## Notas Técnicas

- Se usa `didChangeDependencies()` en lugar de `initState()` porque se ejecuta cada vez que la pantalla vuelve a estar activa
- Se verifica el timestamp de modificación del archivo para detectar cambios incluso si el path es el mismo
- Se mantiene compatibilidad con el flujo existente de guardado de fotos
- No se requieren cambios en otros archivos del proyecto
