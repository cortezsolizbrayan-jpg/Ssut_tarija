# Plan de Optimización: Perfil Screen

## Fecha
24 de febrero de 2026

## Problema Actual

**Archivo:** `lib/features/sistema/screens/perfil/perfil_screen.dart`

### Controllers Actuales (15+)
```dart
// ❌ PROBLEMA: Demasiados controllers
final List<AnimationController> _medalControllers = []; // 5 controllers
final List<AnimationController> _medalEntryControllers = []; // 5 controllers
late final AnimationController _mascotController; // 1 controller
late final AnimationController _rotationController; // 1 controller
late final AnimationController _pulseController; // 1 controller
late final AnimationController _e