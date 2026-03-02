# 🔄 Mejora: Loader Transparente en Escaneo de CI

## 📋 Problema Identificado

Cuando el usuario escanea el anverso o reverso del CI y presiona "Continuar", la app procesa el OCR pero no muestra ningún indicador visual, dando la impresión de que la app se ha colgado o congelado. Además, el usuario podía intentar interactuar con la pantalla durante el procesamiento.

## ✅ Solución Implementada

Se agregó un overlay transparente con loader animado que cubre toda la pantalla mientras se procesa el OCR (tanto anverso como reverso), proporcionando feedback visual claro al usuario y bloqueando cualquier interacción hasta que termine el procesamiento.

## 🔧 Cambios Realizados

### Archivo Modificado
**`lib/features/login/presentation/pages/pantalla_subida_identidad.dart`**

### 1. Estructura del Stack

Se envolvió el `SingleChildScrollView` en un `Stack` para poder superponer el overlay:

```dart
body: Stack(
  children: [
    // Contenido principal
    SingleChildScrollView(...),
    
    // Overlay transparente (visible durante cualquier procesamiento)
    if (_isProcessing || _isMlKitOcrProcessing || _isScanbotProcessing)
      Positioned.fill(
        child: Container(
          color: Colors.black.withOpacity(0.7),
          child: Center(...),
        ),
      ),
  ],
),
```

### 2. Variables de Estado Monitoreadas

El overlay se muestra cuando cualquiera de estas variables es `true`:

- **`_isProcessing`**: Procesamiento general del OCR
- **`_isMlKitOcrProcessing`**: Procesamiento con Google ML Kit OCR (anverso + reverso)
- **`_isScanbotProcessing`**: Procesamiento con Scanbot SDK

Esto asegura que el overlay se muestre en todos los escenarios de procesamiento.

### 2. Componentes del Overlay

El overlay incluye:

#### a) Fondo Transparente
```dart
Container(
  color: Colors.black.withOpacity(0.7), // 70% de opacidad
  ...
)
```

#### b) Loader Circular
```dart
SizedBox(
  width: 80,
  height: 80,
  child: CircularProgressIndicator(
    strokeWidth: 5,
    valueColor: AlwaysStoppedAnimation<Color>(
      Color(0xFF305BA4), // Azul institucional
    ),
    backgroundColor: Colors.white24,
  ),
)
```

#### c) Texto de Estado Dinámico
```dart
Text(
  _getCurrentProcessingStep() ?? 'Procesando...',
  style: const TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  ),
)
```

#### d) Subtítulo
```dart
Text(
  'Por favor espera',
  style: TextStyle(
    color: Colors.white.withOpacity(0.8),
    fontSize: 14,
  ),
)
```

## 🎨 Diseño Visual

### Colores
- **Fondo overlay**: Negro con 70% opacidad (`Colors.black.withOpacity(0.7)`)
- **Loader**: Azul institucional (`#305BA4`)
- **Fondo del loader**: Blanco con 24% opacidad
- **Texto principal**: Blanco
- **Texto secundario**: Blanco con 80% opacidad
- **Contenedor de texto**: Blanco con 10% opacidad

### Dimensiones
- **Loader**: 80x80px
- **Grosor del loader**: 5px
- **Padding del contenedor**: 24px horizontal, 12px vertical
- **Border radius**: 12px

### Espaciado
- **Entre loader y texto**: 24px
- **Entre texto principal y secundario**: 8px

## 📊 Estados del Procesamiento

El método `_getCurrentProcessingStep()` retorna diferentes mensajes según el progreso:

| Progreso | Mensaje |
|----------|---------|
| < 0.2 | "Inicializando escaneo..." |
| < 0.4 | "Analizando documento..." |
| < 0.6 | "Extrayendo datos..." |
| < 0.8 | "Validando información..." |
| >= 0.8 | "Finalizando..." |

## 🔄 Flujo de Usuario

### Antes (Sin Loader):
```
1. Usuario escanea anverso/reverso
2. Presiona "Continuar"
3. Pantalla se congela (sin feedback)
4. Usuario no sabe si está procesando o colgado
5. Puede presionar múltiples veces
6. Puede intentar interactuar con la pantalla
```

### Después (Con Loader):
```
1. Usuario escanea anverso/reverso
2. Presiona "Continuar"
3. Overlay transparente aparece inmediatamente
4. Loader circular animado visible
5. Mensaje de estado actualizado dinámicamente
6. Usuario sabe que está procesando
7. No puede interactuar hasta que termine
8. Pantalla bloqueada para evitar acciones accidentales
```

## 🎯 Beneficios

### Experiencia de Usuario
- ✅ **Feedback visual claro**: Usuario sabe que la app está trabajando
- ✅ **Previene múltiples toques**: Overlay bloquea interacción
- ✅ **Reduce ansiedad**: Mensajes de estado tranquilizan al usuario
- ✅ **Profesional**: Apariencia moderna y pulida
- ✅ **Consistente**: Mismo comportamiento para anverso y reverso
- ✅ **Fluidez**: Transición suave entre estados

### Técnico
- ✅ **No bloquea UI thread**: Overlay se muestra mientras procesa
- ✅ **Reutilizable**: Variable `_isProcessing` ya existía
- ✅ **Ligero**: Solo se renderiza cuando es necesario
- ✅ **Responsive**: Se adapta a cualquier tamaño de pantalla

## 🎨 Siguiendo el Design System

### Colores
- ✅ Primary Blue: `#305BA4` (loader)
- ✅ Overlay: Negro con opacidad (estándar Material Design)

### Animaciones
- ✅ Loader circular: Animación continua suave
- ✅ Aparición: Instantánea (no distrae)

### Typography
- ✅ Texto principal: 16px, weight 600
- ✅ Texto secundario: 14px, weight 400

### Spacing
- ✅ Large: 24px (entre loader y texto)
- ✅ Small: 8px (entre textos)

### Border Radius
- ✅ Medium: 12px (contenedor de texto)

## 🧪 Testing Recomendado

### Escenarios Cubiertos

El overlay se muestra en los siguientes escenarios:

1. **Procesamiento con ML Kit OCR**:
   - Escaneo de anverso
   - Escaneo de reverso
   - Análisis de ambas imágenes

2. **Procesamiento con Scanbot SDK**:
   - Escaneo automático de documento
   - Procesamiento de imágenes capturadas

3. **Procesamiento General**:
   - Extracción de datos con OCR
   - Validación de información
   - Combinación de resultados

### Casos de Prueba
1. ✅ Escanear anverso con ML Kit → Presionar continuar → Overlay aparece
2. ✅ Escanear reverso con ML Kit → Presionar continuar → Overlay aparece
3. ✅ Durante procesamiento → Intentar tocar pantalla → No responde
4. ✅ Observar mensajes → Cambian según progreso
5. ✅ Procesamiento completa → Overlay desaparece
6. ✅ Error en procesamiento → Overlay desaparece, muestra error
7. ✅ Usar Scanbot → Overlay aparece durante procesamiento
8. ✅ Procesamiento largo → Mensajes mantienen al usuario informado

### Escenarios
- **Procesamiento rápido** (< 2 segundos): Overlay visible brevemente
- **Procesamiento lento** (> 5 segundos): Mensajes de estado ayudan
- **Error de red**: Overlay desaparece, muestra mensaje de error
- **Usuario cancela**: Overlay desaparece al volver atrás

## 📱 Responsive Design

El overlay se adapta automáticamente:
- **Positioned.fill**: Cubre toda la pantalla
- **Center**: Contenido centrado vertical y horizontalmente
- **Padding responsive**: Se ajusta al tamaño de pantalla

## 🔒 Prevención de Interacción

Mientras `_isProcessing` es `true`:
- ❌ No se puede tocar el contenido debajo
- ❌ No se puede presionar botones
- ❌ No se puede hacer scroll
- ✅ Solo se puede ver el progreso

## 🎭 Variantes Consideradas

### Opción 1: Dialog (Descartada)
```dart
showDialog(
  barrierDismissible: false,
  builder: (context) => AlertDialog(...)
);
```
**Problema**: Más intrusivo, menos moderno

### Opción 2: SnackBar (Descartada)
```dart
ScaffoldMessenger.of(context).showSnackBar(...)
```
**Problema**: No bloquea interacción, puede ser ignorado

### Opción 3: Overlay Transparente (Elegida) ✅
```dart
if (_isProcessing)
  Positioned.fill(
    child: Container(...)
  )
```
**Ventajas**: Moderno, no intrusivo, bloquea interacción

## 🚀 Resultado Final

La pantalla de escaneo de CI ahora:
- ✅ Muestra feedback visual claro durante procesamiento
- ✅ Previene interacción accidental
- ✅ Informa al usuario del progreso
- ✅ Reduce la percepción de que la app está congelada
- ✅ Proporciona una experiencia más profesional

## 📝 Código Completo del Overlay

```dart
// En el método build, dentro del Stack:
if (_isProcessing || _isMlKitOcrProcessing || _isScanbotProcessing)
  Positioned.fill(
    child: Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Loader circular
            const SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                strokeWidth: 5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(0xFF305BA4),
                ),
                backgroundColor: Colors.white24,
              ),
            ),
            const SizedBox(height: 24),
            // Texto de estado
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    _getCurrentProcessingStep() ?? 'Procesando...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Por favor espera',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ),
```

### Variables de Estado Monitoreadas

```dart
// En la clase State:
bool _isProcessing = false;           // Procesamiento general
bool _isMlKitOcrProcessing = false;   // ML Kit OCR (anverso + reverso)
bool _isScanbotProcessing = false;    // Scanbot SDK
```

El overlay se muestra cuando **cualquiera** de estas variables es `true`, asegurando cobertura completa de todos los escenarios de procesamiento.

---

**Fecha de Implementación**: 23 de febrero de 2026
**Estado**: ✅ COMPLETADO
**Impacto**: Mejora significativa en UX durante procesamiento OCR
