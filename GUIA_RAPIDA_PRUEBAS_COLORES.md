# Guía Rápida de Pruebas - Colores Institucionales

## 🎯 Objetivo
Verificar que los colores institucionales (#005BAC) se apliquen correctamente en las pantallas modificadas.

## 🚀 Inicio Rápido

### 1. Ejecutar la App
```bash
flutter run -d <device_id>
```

### 2. Hot Restart (si es necesario)
```
Presionar R (mayúscula) en la terminal
```

## ✅ Checklist de Pruebas

### Pantalla: Detalle de Programa
**Ruta**: Inicio → Mis Programas → Seleccionar un programa

| Elemento | Color Esperado | ✓ |
|----------|----------------|---|
| Header (gradiente) | #005BAC → #0F7BD7 | ☐ |
| Fondo | #EEF1F8 | ☐ |
| Badge tipo programa | #005BAC | ☐ |
| Tarjeta progreso (seleccionada) | #005BAC | ☐ |
| Botón "Ver Historial" | #005BAC | ☐ |
| Botones "Pagar" | #005BAC | ☐ |
| Botones "Factura" (borde) | #005BAC | ☐ |
| Icono descarga | #005BAC | ☐ |
| Icono configuración (gradiente) | #005BAC → #0F7BD7 | ☐ |

### Pantalla: Mis Datos Personales
**Ruta**: Inicio → Perfil → Mis Datos Personales

| Elemento | Color Esperado | ✓ |
|----------|----------------|---|
| AppBar | #005BAC | ☐ |
| Fondo | #EEF1F8 | ☐ |
| Avatar (gradiente) | #005BAC → #0F7BD7 | ☐ |
| Botón cámara | #005BAC (icono blanco) | ☐ |
| Barra progreso | #005BAC | ☐ |
| Campos formulario (enfocados) | Borde #005BAC | ☐ |
| Iconos campos | #005BAC (50% opacidad) | ☐ |
| Labels campos | #005BAC (90% opacidad) | ☐ |
| Texto campos | #005BAC | ☐ |
| Dropdowns (icono) | #005BAC | ☐ |
| Botón "Guardar Datos" | Fondo #005BAC, texto blanco | ☐ |
| Loader guardando | Blanco | ☐ |
| Botón "GESTIONAR DOCUMENTOS" | #005BAC | ☐ |

## 🔍 Verificación Visual Rápida

### Colores que NO deberías ver:
- ❌ Naranja (#FF9800)
- ❌ Amarillo (#FFC900)
- ❌ Azul oscuro antiguo (#1A3A5C)
- ❌ Gris oscuro (#1E293B)

### Colores que SÍ deberías ver:
- ✅ Azul institucional (#005BAC)
- ✅ Azul brillante (#0F7BD7) en gradientes
- ✅ Fondo gris claro (#EEF1F8)
- ✅ Blanco en texto de botones
- ✅ Verde (#4CAF50) solo en estados de éxito

## 🎨 Comparación Visual

### Antes
- Botones naranjas y amarillos
- Múltiples tonos de azul inconsistentes
- Texto oscuro en botones amarillos

### Después
- Todos los botones en azul institucional
- Un solo tono de azul (#005BAC)
- Texto blanco en botones azules (mejor contraste)

## 🐛 Problemas Comunes

### Si los colores no cambian:
1. Hacer hot restart (R mayúscula)
2. Si persiste, detener y volver a ejecutar `flutter run`
3. Limpiar build: `flutter clean && flutter pub get`

### Si hay errores de compilación:
1. Verificar que no haya errores de sintaxis
2. Ejecutar `flutter pub get`
3. Revisar que todos los imports estén correctos

## 📱 Capturas Recomendadas

Para documentar los cambios, tomar capturas de:
1. Header de detalle de programa
2. Tarjetas de progreso seleccionadas
3. Botones de pago
4. AppBar de mis datos personales
5. Botón "Guardar Datos"
6. Campos de formulario enfocados

## ✨ Puntos Clave a Verificar

### Contraste
- ✅ Texto blanco sobre azul institucional debe ser legible
- ✅ Iconos azules sobre fondo claro deben ser visibles
- ✅ Bordes azules deben destacar al enfocar campos

### Consistencia
- ✅ Mismo tono de azul en toda la app
- ✅ Gradientes coherentes
- ✅ Fondo uniforme (#EEF1F8)

### Interactividad
- ✅ Botones responden al toque
- ✅ Campos muestran borde azul al enfocar
- ✅ Animaciones funcionan correctamente

## 📊 Resultado Esperado

Al completar todas las pruebas, deberías ver:
- ✅ 100% de elementos con colores institucionales
- ✅ 0 colores antiguos visibles
- ✅ Interfaz coherente y profesional
- ✅ Mejor contraste y legibilidad

## 🎉 Éxito

Si todos los checkboxes están marcados, ¡la implementación fue exitosa!

---

**Tiempo estimado de pruebas**: 5-10 minutos  
**Dificultad**: Baja  
**Requiere**: Dispositivo/emulador con la app instalada
