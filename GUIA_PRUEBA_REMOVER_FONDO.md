# Guía de Prueba: Remoción Automática de Fondo en Foto de Perfil

## 🎯 Objetivo
Verificar que la remoción automática de fondo funciona correctamente en las fotos de perfil.

---

## 📱 Cómo Probar

### Opción 1: Desde Mis Datos Personales

1. **Abrir la app**
2. **Ir a**: Menú → Perfil → Mis Datos Personales
3. **Tocar** el avatar/foto de perfil
4. **Seleccionar** "Tomar foto" o "Elegir de galería"
5. **Capturar/seleccionar** una foto con fondo visible
6. **Esperar** 2-3 segundos (procesamiento automático)
7. **Verificar** que la foto ahora tiene fondo gris claro

### Opción 2: Desde Mis Documentos

1. **Abrir la app**
2. **Ir a**: Menú → Perfil → Mis Documentos Personales
3. **Tocar** "Actualizar Foto de Perfil"
4. **Seleccionar** foto con fondo
5. **Verificar** resultado con fondo gris

### Opción 3: Durante Registro (Primera Vez)

1. **Registrar nuevo usuario**
2. **Llegar a** pantalla de Reconocimiento Facial
3. **Capturar** foto de rostro
4. **Verificar** que se aplica fondo gris automáticamente

---

## ✅ Resultados Esperados

### Antes del Procesamiento
```
📸 Foto original con:
- Fondo blanco/de pared
- Fondo de habitación
- Fondo de exterior
- Cualquier fondo visible
```

### Después del Procesamiento
```
✨ Foto procesada con:
- Fondo gris claro uniforme (#E0E0E0)
- Persona claramente visible
- Bordes limpios (o aceptables)
- Tamaño optimizado
```

---

## 🔍 Qué Observar

### Logs en Consola

**Inicio del proceso:**
```
🔄 Removiendo fondo de foto de perfil...
🔄 Procesando imagen localmente...
```

**Éxito:**
```
✅ Imagen procesada localmente: /path/to/output.png
✅ Fondo removido automáticamente con fondo gris claro
```

**Advertencia (no crítico):**
```
⚠️ No se pudo remover fondo, usando imagen original
```

### En la UI

1. **Loader/Indicador**: Debe aparecer brevemente durante procesamiento
2. **Foto Final**: Debe mostrarse con fondo gris claro
3. **Sin Errores**: No debe haber crashes ni mensajes de error

---

## 📊 Casos de Prueba

### ✅ Caso 1: Foto con Fondo Blanco
**Entrada**: Selfie con pared blanca de fondo  
**Esperado**: Fondo completamente gris claro  
**Dificultad**: Fácil ⭐

### ✅ Caso 2: Foto con Fondo de Color Sólido
**Entrada**: Foto con pared azul/verde/roja  
**Esperado**: Fondo gris claro, persona intacta  
**Dificultad**: Fácil ⭐

### ✅ Caso 3: Foto con Fondo de Habitación
**Entrada**: Selfie en habitación (muebles, ventanas)  
**Esperado**: Fondo mayormente gris, algunos detalles pueden quedar  
**Dificultad**: Media ⭐⭐

### ⚠️ Caso 4: Foto con Fondo Complejo
**Entrada**: Foto en exterior (árboles, edificios)  
**Esperado**: Fondo parcialmente gris, puede tener restos  
**Dificultad**: Difícil ⭐⭐⭐

### ✅ Caso 5: Foto de Baja Calidad
**Entrada**: Foto borrosa o con poca luz  
**Esperado**: Funciona pero bordes pueden ser irregulares  
**Dificultad**: Media ⭐⭐

---

## 🐛 Problemas Comunes y Soluciones

### Problema 1: No se Remueve el Fondo
**Síntoma**: Foto se guarda con fondo original

**Posibles Causas:**
- Parámetro `removerFondo: false` en algún lugar
- Error en procesamiento (ver logs)

**Solución:**
```dart
// Verificar en servicio_procesador_imagen_perfil.dart línea 28
removerFondo = true,  // Debe ser true
```

### Problema 2: Se Remueve Parte de la Persona
**Síntoma**: Bordes de la persona se ven cortados o grises

**Causa**: Umbral de brillo muy alto

**Solución:**
```dart
// En servicio_remover_fondo.dart línea ~130
if (brightness < 220) {  // Reducir de 240 a 220
```

### Problema 3: Queda Mucho Fondo Original
**Síntoma**: Fondo no se remueve completamente

**Causa**: Umbral de brillo muy bajo

**Solución:**
```dart
// En servicio_remover_fondo.dart línea ~130
if (brightness < 250) {  // Aumentar de 240 a 250
```

### Problema 4: Procesamiento Muy Lento
**Síntoma**: Tarda más de 5 segundos

**Causa**: Imagen muy grande

**Solución:**
```dart
// Reducir tamaño antes de procesar
targetSize: 512,  // Reducir de 600 a 512
```

---

## 🎨 Personalización del Fondo

### Cambiar Color de Fondo

**Ubicación**: `lib/core/services/servicio_remover_fondo.dart` línea ~115

**Opciones:**

```dart
// Gris claro (actual) - Recomendado
img.fill(result, color: img.ColorRgb8(224, 224, 224)); // #E0E0E0

// Blanco puro
img.fill(result, color: img.ColorRgb8(255, 255, 255)); // #FFFFFF

// Azul institucional
img.fill(result, color: img.ColorRgb8(0, 91, 172)); // #005BAC

// Gris oscuro
img.fill(result, color: img.ColorRgb8(128, 128, 128)); // #808080
```

---

## 📈 Métricas de Éxito

### Calidad Aceptable
- ✅ Fondo 90%+ gris claro
- ✅ Persona completamente visible
- ✅ Bordes razonablemente limpios
- ✅ Sin crashes ni errores

### Calidad Óptima
- ✅ Fondo 100% gris claro
- ✅ Bordes perfectamente limpios
- ✅ Procesamiento < 2 segundos
- ✅ Tamaño archivo < 500 KB

---

## 🔧 Ajustes Avanzados

### Mejorar Detección de Bordes

**Archivo**: `lib/core/services/servicio_remover_fondo.dart`

**Método**: `_aplicarFondoGris()` línea ~105

**Opciones:**

1. **Detección por brillo (actual)**
```dart
final brightness = (r + g + b) / 3;
if (brightness < 240) { /* mantener */ }
```

2. **Detección por saturación**
```dart
final max = [r, g, b].reduce((a, b) => a > b ? a : b);
final min = [r, g, b].reduce((a, b) => a < b ? a : b);
final saturation = max == 0 ? 0 : (max - min) / max;
if (saturation > 0.1) { /* mantener */ }
```

3. **Detección combinada**
```dart
if (brightness < 240 && saturation > 0.1) { /* mantener */ }
```

---

## 🚀 Activar Remove.bg API (Opcional)

Si la calidad local no es suficiente:

### Paso 1: Obtener API Key
1. Ir a https://remove.bg/api
2. Crear cuenta gratuita
3. Copiar API key

### Paso 2: Configurar
```dart
// En servicio_remover_fondo.dart línea 11
static const String _removeBgApiKey = 'tu_api_key_aqui';
```

### Paso 3: Activar
```dart
// En servicio_procesador_imagen_perfil.dart línea 38
useAPI: true,  // Cambiar de false a true
```

### Paso 4: Probar
- Plan gratuito: 50 imágenes/mes
- Calidad profesional
- Requiere internet

---

## 📝 Checklist de Prueba

### Funcionalidad Básica
- [ ] Foto se captura correctamente
- [ ] Procesamiento inicia automáticamente
- [ ] Loader/indicador aparece
- [ ] Foto se guarda con fondo gris
- [ ] No hay crashes

### Calidad Visual
- [ ] Fondo es gris claro uniforme
- [ ] Persona está completa
- [ ] Bordes son aceptables
- [ ] Colores de piel naturales

### Rendimiento
- [ ] Procesamiento < 5 segundos
- [ ] App no se congela
- [ ] Memoria se libera después
- [ ] Tamaño archivo razonable

### Casos Especiales
- [ ] Funciona con fondo blanco
- [ ] Funciona con fondo oscuro
- [ ] Funciona con fondo complejo
- [ ] Funciona con baja calidad

---

## 🎯 Criterios de Aceptación

### Mínimo Viable
✅ Fondo se reemplaza por gris claro en 80%+ de casos  
✅ No hay crashes ni errores críticos  
✅ Procesamiento < 5 segundos  

### Óptimo
✅ Fondo se reemplaza perfectamente en 95%+ de casos  
✅ Bordes limpios y profesionales  
✅ Procesamiento < 2 segundos  
✅ Usuarios satisfechos con resultado  

---

## 📞 Soporte

Si encuentras problemas:

1. **Revisar logs** en consola
2. **Verificar configuración** en archivos mencionados
3. **Ajustar parámetros** según tipo de fotos
4. **Considerar API** si calidad local no es suficiente

---

## ✨ Resultado Final Esperado

```
ANTES:                    DESPUÉS:
┌─────────────┐          ┌─────────────┐
│ 🏠 Fondo    │          │ ⬜ Gris     │
│    complejo │   →→→    │    claro    │
│             │          │             │
│    👤       │          │    👤       │
│   Persona   │          │   Persona   │
└─────────────┘          └─────────────┘
```

**¡Foto profesional con fondo uniforme institucional!** 🎉
