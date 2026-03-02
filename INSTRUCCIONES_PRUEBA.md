# 🧪 Instrucciones de Prueba - Nuevas Funcionalidades

## 📋 Checklist de Pruebas

### ✅ Preparación
- [ ] Verificar que `.env` tiene `GOOGLE_GEMINI_API_KEY` configurada
- [ ] Ejecutar `flutter clean`
- [ ] Ejecutar `flutter pub get`
- [ ] Verificar conexión a internet

---

## 🎖️ Prueba 1: Animación de Medallas

### Objetivo
Verificar que las medallas aparecen secuencialmente con animación 3D

### Pasos
1. Ejecutar la app: `flutter run`
2. Hacer hot restart: Presionar `R` en la terminal
3. Iniciar sesión en la app
4. Navegar a la pantalla de perfil (Home)

### Resultado Esperado
✅ **Animación Secuencial**:
- Medalla 1 (dorada) aparece primero
- Cada medalla siguiente aparece con 200ms de delay
- Cada medalla:
  - Hace fade in (de transparente a visible)
  - Crece desde pequeña (scale 0.5 → 1.0)
  - Gira 360° en su eje vertical (efecto 3D)
  - Produce vibración sutil al aparecer

✅ **Timing Total**: ~1.8 segundos para todas las medallas

### Problemas Comunes
❌ **Las medallas aparecen todas juntas**:
- Solución: Hacer hot restart (R), no hot reload (r)

❌ **No hay animación**:
- Verificar que `_startSequentialMedalAnimation()` se llama en `initState()`

---

## 🤖 Prueba 2: Validación Facial con Gemini

### Objetivo
Verificar que Gemini valida correctamente la calidad de la foto facial

### Preparación
- Tener buena iluminación
- Preparar fondo gris/plomo (pared, cartulina, etc.)
- Tener cámara frontal disponible

### Escenario 1: Foto Válida ✅

**Pasos**:
1. Ir al flujo de registro
2. Llegar a "Reconocimiento Facial"
3. Posicionar rostro de frente
4. Asegurar fondo plomo/gris
5. Esperar a que capture automáticamente

**Resultado Esperado**:
- ✅ Foto se acepta sin diálogo
- ✅ Continúa al siguiente paso
- ✅ Mensaje en logs: "✅ Foto validada por Gemini AI"

### Escenario 2: Foto de Perfil ❌

**Pasos**:
1. Llegar a "Reconocimiento Facial"
2. Girar la cabeza hacia un lado (perfil)
3. Esperar captura

**Resultado Esperado**:
- ❌ Aparece diálogo "Foto no válida"
- ❌ Muestra: "Rostro debe estar de frente"
- ✅ Botón "Tomar otra foto" disponible
- ✅ Al presionar, reinicia captura

### Escenario 3: Fondo Incorrecto ❌

**Pasos**:
1. Llegar a "Reconocimiento Facial"
2. Posicionar con fondo colorido o con patrones
3. Esperar captura

**Resultado Esperado**:
- ❌ Aparece diálogo "Foto no válida"
- ❌ Muestra: "Fondo debe ser gris/plomo uniforme"
- ✅ Opción de retomar

### Escenario 4: Foto Borrosa ❌

**Pasos**:
1. Llegar a "Reconocimiento Facial"
2. Mover la cámara mientras captura
3. O usar poca iluminación

**Resultado Esperado**:
- ❌ Aparece diálogo "Foto no válida"
- ❌ Muestra: "Imagen debe ser nítida"
- ✅ Opción de retomar

### Escenario 5: Múltiples Personas ❌

**Pasos**:
1. Llegar a "Reconocimiento Facial"
2. Tener otra persona visible en el fondo
3. Esperar captura

**Resultado Esperado**:
- ❌ Aparece diálogo "Foto no válida"
- ❌ Muestra: "Solo debe aparecer una persona"
- ✅ Opción de retomar

### Logs de Debug

Buscar en la consola:
```
🤖 Validando foto con Gemini AI...
→ Validando foto facial con Gemini (model: gemini-1.5-flash)
✔ Respuesta de Gemini recibida (model: gemini-1.5-flash)
✅ Validación facial completada: VÁLIDA/INVÁLIDA
   - De frente: true/false
   - Fondo plomo: true/false
   - Nítida: true/false
   - Solo una persona: true/false
```

### Problemas Comunes

❌ **Error: API Key no configurada**:
```
❌ API Key de Gemini no configurada
```
- Solución: Agregar `GOOGLE_GEMINI_API_KEY` en `.env`

❌ **Error: Sin conexión a internet**:
```
❌ Error general en validación facial: SocketException
```
- Solución: Verificar conexión a internet

❌ **Validación siempre acepta**:
- Verificar que el método `_processAndStoreProfilePhoto()` llama a `ServicioValidacionFacialGemini.validarFotoFacial()`

---

## 📊 Prueba 3: Performance

### Objetivo
Verificar que las animaciones no afectan el rendimiento

### Pasos
1. Abrir DevTools de Flutter
2. Ir a la pestaña "Performance"
3. Navegar a la pantalla de perfil
4. Observar el gráfico de FPS

### Resultado Esperado
- ✅ FPS constante en 60
- ✅ No hay drops significativos
- ✅ Uso de memoria estable

### Métricas Aceptables
- **FPS**: 55-60 (constante)
- **Frame Time**: <16ms
- **Memoria**: Incremento <10MB durante animaciones

---

## 🔍 Prueba 4: Casos Edge

### Caso 1: Sin API Key de Gemini

**Pasos**:
1. Comentar `GOOGLE_GEMINI_API_KEY` en `.env`
2. Reiniciar app
3. Intentar capturar foto facial

**Resultado Esperado**:
- ⚠️ Log: "❌ API Key de Gemini no configurada"
- ✅ Foto se acepta sin validación (fallback)
- ✅ App no crashea

### Caso 2: Sin Conexión a Internet

**Pasos**:
1. Activar modo avión
2. Intentar capturar foto facial

**Resultado Esperado**:
- ⚠️ Log: "❌ Error general en validación facial"
- ✅ Foto se acepta sin validación (fallback)
- ✅ App no crashea

### Caso 3: Timeout de Gemini

**Pasos**:
1. Usar conexión muy lenta
2. Capturar foto

**Resultado Esperado**:
- ⚠️ Timeout después de 15-20 segundos
- ✅ Foto se acepta sin validación (fallback)
- ✅ App no crashea

---

## 📱 Prueba 5: Compatibilidad

### Android
- [ ] Probar en Android 8+
- [ ] Verificar permisos de cámara
- [ ] Verificar animaciones fluidas

### iOS
- [ ] Probar en iOS 12+
- [ ] Verificar permisos de cámara
- [ ] Verificar animaciones fluidas

### Web (Opcional)
- [ ] Probar en Chrome/Firefox
- [ ] Verificar acceso a cámara web
- [ ] Verificar animaciones (pueden ser más lentas)

---

## 🐛 Reporte de Bugs

Si encuentras un bug, reportar con:

1. **Descripción**: ¿Qué pasó?
2. **Pasos para Reproducir**: ¿Cómo llegaste ahí?
3. **Resultado Esperado**: ¿Qué debería pasar?
4. **Resultado Actual**: ¿Qué pasó realmente?
5. **Logs**: Copiar logs relevantes de la consola
6. **Dispositivo**: Modelo, OS, versión
7. **Screenshots**: Si es posible

### Ejemplo de Reporte
```
BUG: Medallas no aparecen

Pasos:
1. Abrir app
2. Ir a perfil
3. Las medallas no se ven

Esperado: Medallas aparecen con animación
Actual: Pantalla en blanco

Logs:
[ERROR] Exception: _medalEntryControllers is empty

Dispositivo: Samsung Galaxy S21, Android 12
```

---

## ✅ Checklist Final

Antes de marcar como completo, verificar:

- [ ] Animación de medallas funciona correctamente
- [ ] Validación facial rechaza fotos de perfil
- [ ] Validación facial rechaza fondos incorrectos
- [ ] Validación facial acepta fotos válidas
- [ ] Opción "Tomar otra foto" funciona
- [ ] No hay crashes ni errores en logs
- [ ] Performance es aceptable (60fps)
- [ ] Funciona sin API Key (fallback)
- [ ] Funciona sin internet (fallback)

---

## 📞 Contacto

Si tienes dudas o problemas:
1. Revisar logs de Flutter
2. Verificar configuración de `.env`
3. Consultar `RESUMEN_IMPLEMENTACION.md`
4. Revisar `MEJORAS_SESION_ACTUAL.md`

---

**¡Buena suerte con las pruebas! 🚀**
