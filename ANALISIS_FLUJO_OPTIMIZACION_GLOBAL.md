# Análisis y Optimización Global del Flujo de Trabajo

## Fecha
24 de febrero de 2026

## Flujo de Trabajo Identificado

### 1. Flujo de Autenticación
```
Splash Screen
    ↓
Onboarding Screen (primera vez)
    ↓
Login / Register Screen
    ↓
ID Upload Screen (OCR)
    ↓
Face Recognition Screen
    ↓
Registration Form Screen
    ↓
Password Setup Screen
    ↓
Biometric Setup Screen
    ↓
Entry Point (Sistema Principal)
```

### 2. Flujo de Inscripción (CRÍTICO)
```
Entry Point → Inicio Screen
    ↓
Programas Vigentes Screen
    ↓
Detalle Programa Screen
    ↓
[Botón Inscribirse]
    ↓
Pantalla Validación Requisitos
    ↓
[Completar documentos faltantes]
    ↓
Mis Datos Personales Screen
Mis Documentos Personales Screen
    ↓
[Volver a validación]
    ↓
Confirmación Inscripción Screen ✅ (OPTIMIZADA)
```

### 3. Flujo de Gestión de Perfil
```
Entry Point → Perfil Screen
    ↓
Mis Datos Personales Screen
Mis Documentos Personales Screen
Mi Curriculum Screen
```

### 4. Flujo de Pagos
```
Entry Point → Diplomados Screen
    ↓
Detalle Programa Screen
    ↓
Depósito Matrícula Screen
Program Payments Screen
```

## Pantallas Críticas para Optimización

### Prioridad ALTA (Uso frecuente + Complejidad)

#### 1. Programas Vigentes Screen ⚠️
**Problemas identificados:**
- Múltiples `AnimatedBuilder` y `TweenAnimationBuilder`
- Scroll controller + Search controller + Filtros
- Carga de imágenes de red sin caché
- Rebuilds frecuentes por filtros
- Animaciones en cada tarjeta de programa

**Optimizaciones recomendadas:**
- ✅ Implementar `AutomaticKeepAliveClientMixin` para mantener estado
- ✅ Usar `CachedNetworkImage` para imágenes
- ✅ Debounce en búsqueda (300ms)
- ✅ Lazy loading con `ListView.builder`
- ✅ Reducir animaciones de tarjetas
- ✅ Memoizar filtros con `useMemo` o similar

#### 2. Pantalla Validación Requisitos ⚠️
**Problemas identificados:**
- Validación completa en cada `didChangeDependencies`
- Múltiples lecturas de `LocalStorageService`
- Generación de PDFs en UI thread
- Animaciones complejas en cada requisito
- Diálogos con animaciones pesadas

**Optimizaciones recomendadas:**
- ✅ Caché de resultados de validación
- ✅ Validación incremental (solo lo que cambió)
- ✅ Generación de PDFs en `compute()` (isolate)
- ✅ Simplificar animaciones de requisitos
- ✅ Lazy loading de documentos

#### 3. Detalle Programa Screen ⚠️
**Problemas identificados:**
- Animaciones Rive pesadas
- Múltiples gráficos de progreso
- Carga de datos sin caché
- Rebuilds innecesarios

**Optimizaciones recomendadas:**
- ✅ Caché de datos del programa
- ✅ Simplificar animaciones Rive
- ✅ Usar `RepaintBoundary` en gráficos
- ✅ Implementar `const` widgets donde sea posible

#### 4. Mis Documentos Personales Screen ⚠️
**Problemas identificados:**
- Carga de múltiples imágenes grandes
- Sin compresión de imágenes
- Validación de documentos en cada rebuild
- Animaciones en cada tarjeta de documento

**Optimizaciones recomendadas:**
- ✅ Compresión de imágenes antes de guardar
- ✅ Thumbnails para preview
- ✅ Lazy loading de imágenes
- ✅ Caché de validaciones
- ✅ Simplificar animaciones

#### 5. Inicio Screen ⚠️
**Problemas identificados:**
- Múltiples animaciones simultáneas
- Carga de datos de múltiples fuentes
- Notificaciones en tiempo real
- Carrusel de imágenes sin optimizar

**Optimizaciones recomendadas:**
- ✅ Usar `inicio_screen_optimized.dart` (ya existe)
- ✅ Lazy loading de secciones
- ✅ Caché de datos del dashboard
- ✅ Optimizar carrusel

### Prioridad MEDIA

#### 6. ID Upload Screen (OCR)
**Optimizaciones:**
- ✅ Procesamiento OCR en isolate
- ✅ Compresión de imágenes capturadas
- ✅ Caché de resultados OCR

#### 7. Face Recognition Screen
**Optimizaciones:**
- ✅ Reducir resolución de cámara
- ✅ Throttle de detección facial
- ✅ Liberar recursos de cámara rápidamente

#### 8. Perfil Screen
**Optimizaciones:**
- ✅ Caché de avatar
- ✅ Lazy loading de secciones
- ✅ Simplificar animaciones

### Prioridad BAJA

#### 9. Splash Screen
- Ya es simple y rápida

#### 10. Onboarding Screen
- Se ve una sola vez

## Optimizaciones Globales Recomendadas

### 1. Gestión de Imágenes
```dart
// Implementar en toda la app
class OptimizedImageWidget extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  
  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
      placeholder: (context, url) => const SkeletonLoader(),
      errorWidget: (context, url, error) => const Icon(Icons.error),
      fadeInDuration: const Duration(milliseconds: 200),
    );
  }
}
```

### 2. Caché Global
```dart
// Implementar sistema de caché centralizado
class AppCache {
  static final _programasCache = <String, ProgramaPosgrado>{};
  static final _validacionesCache = <String, ResultadoValidacionInscripcion>{};
  static final _documentosCache = <String, Map<String, dynamic>>{};
  
  static const _cacheDuration = Duration(minutes: 5);
  static final _cacheTimestamps = <String, DateTime>{};
  
  static T? get<T>(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return null;
    
    if (DateTime.now().difference(timestamp) > _cacheDuration) {
      invalidate(key);
      return null;
    }
    
    // Retornar del caché apropiado
    return null; // Implementar lógica
  }
  
  static void set<T>(String key, T value) {
    _cacheTimestamps[key] = DateTime.now();
    // Guardar en caché apropiado
  }
  
  static void invalidate(String key) {
    _cacheTimestamps.remove(key);
    // Limpiar de cachés
  }
}
```

### 3. Debounce para Búsquedas
```dart
class Debouncer {
  final Duration delay;
  Timer? _timer;
  
  Debouncer({this.delay = const Duration(milliseconds: 300)});
  
  void call(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }
  
  void dispose() {
    _timer?.cancel();
  }
}

// Uso en búsqueda
final _searchDebouncer = Debouncer();

void _onSearchChanged(String query) {
  _searchDebouncer(() {
    setState(() {
      _searchQuery = query;
    });
  });
}
```

### 4. Lazy Loading Pattern
```dart
class LazyLoadingList<T> extends StatefulWidget {
  final Future<List<T>> Function(int page, int pageSize) loadItems;
  final Widget Function(BuildContext, T) itemBuilder;
  
  @override
  State<LazyLoadingList<T>> createState() => _LazyLoadingListState<T>();
}

class _LazyLoadingListState<T> extends State<LazyLoadingList<T>> {
  final _items = <T>[];
  int _currentPage = 0;
  bool _loading = false;
  bool _hasMore = true;
  
  @override
  void initState() {
    super.initState();
    _loadMore();
  }
  
  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    
    setState(() => _loading = true);
    
    final newItems = await widget.loadItems(_currentPage, 20);
    
    setState(() {
      _items.addAll(newItems);
      _currentPage++;
      _hasMore = newItems.length == 20;
      _loading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _items.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _items.length) {
          _loadMore();
          return const Center(child: CircularProgressIndicator());
        }
        return widget.itemBuilder(context, _items[index]);
      },
    );
  }
}
```

### 5. Optimización de Animaciones Globales
```dart
// Configuración global de animaciones
class AnimationConfig {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 400);
  
  static const Curve defaultCurve = Curves.easeOut;
  static const Curve bounceCurve = Curves.easeOutBack;
  
  // Detectar capacidad del dispositivo
  static bool get isLowEndDevice {
    // Implementar detección basada en memoria, CPU, etc.
    return false;
  }
  
  static Duration getDuration(Duration standard) {
    return isLowEndDevice ? standard * 0.7 : standard;
  }
}
```

### 6. RepaintBoundary Strategy
```dart
// Usar en widgets que no cambian frecuentemente
class OptimizedCard extends StatelessWidget {
  final Widget child;
  
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Card(
        child: child,
      ),
    );
  }
}
```

### 7. Const Widgets
```dart
// Maximizar uso de const
class ProgramCard extends StatelessWidget {
  final ProgramaPosgrado programa;
  
  const ProgramCard({super.key, required this.programa});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // Usar const donde sea posible
          const SizedBox(height: 16),
          const Icon(Icons.school, size: 24),
          const SizedBox(height: 8),
          Text(programa.titulo), // No puede ser const
        ],
      ),
    );
  }
}
```

## Plan de Implementación

### Fase 1: Optimizaciones Críticas (Semana 1)
1. ✅ Confirmación Inscripción Screen (COMPLETADO)
2. ⏳ Programas Vigentes Screen
3. ⏳ Pantalla Validación Requisitos
4. ⏳ Mis Documentos Personales Screen

### Fase 2: Optimizaciones Medias (Semana 2)
5. ⏳ Detalle Programa Screen
6. ⏳ Inicio Screen (usar optimized)
7. ⏳ ID Upload Screen
8. ⏳ Face Recognition Screen

### Fase 3: Infraestructura Global (Semana 3)
9. ⏳ Sistema de caché centralizado
10. ⏳ Optimización de imágenes global
11. ⏳ Debounce y throttle utilities
12. ⏳ Lazy loading components

### Fase 4: Refinamiento (Semana 4)
13. ⏳ Profiling con DevTools
14. ⏳ Ajustes finos de rendimiento
15. ⏳ Testing en dispositivos reales
16. ⏳ Documentación de mejores prácticas

## Métricas de Éxito

### Objetivos de Rendimiento
- **FPS:** 60 constantes en gama baja
- **Tiempo de carga inicial:** < 2 segundos
- **Tiempo de navegación:** < 300ms entre pantallas
- **Uso de memoria:** < 150 MB en gama baja
- **Uso de CPU:** < 25% promedio
- **Tamaño de APK:** < 50 MB

### Objetivos de UX
- **Animaciones fluidas:** Sin drops de frames
- **Respuesta inmediata:** < 100ms a toques
- **Feedback visual:** Siempre presente
- **Sin bloqueos:** UI nunca congelada
- **Carga progresiva:** Contenido aparece gradualmente

## Herramientas de Monitoreo

### Durante Desarrollo
```dart
// Performance overlay
void main() {
  runApp(
    MaterialApp(
      showPerformanceOverlay: kDebugMode,
      home: MyApp(),
    ),
  );
}
```

### En Producción
```dart
// Firebase Performance Monitoring
final trace = FirebasePerformance.instance.newTrace('screen_load');
await trace.start();
// ... cargar pantalla
await trace.stop();
```

### DevTools
- Timeline para identificar jank
- Memory para detectar leaks
- CPU profiler para hotspots
- Network para optimizar requests

## Conclusión

El flujo de inscripción es el más crítico y requiere optimización inmediata. Las pantallas identificadas tienen múltiples oportunidades de mejora:

1. **Reducir controllers de animación**
2. **Implementar caché efectivo**
3. **Optimizar carga de imágenes**
4. **Lazy loading de contenido**
5. **Simplificar animaciones**
6. **Usar const widgets**
7. **RepaintBoundary estratégico**

Con estas optimizaciones, la app será significativamente más rápida y fluida en todos los dispositivos.
