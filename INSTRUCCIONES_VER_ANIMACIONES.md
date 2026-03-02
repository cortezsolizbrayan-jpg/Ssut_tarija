# 🎮 Instrucciones para Ver las Animaciones Mágicas

## ⚠️ IMPORTANTE: Necesitas HOT RESTART

Las animaciones que acabamos de implementar requieren un **HOT RESTART** completo, no solo un hot reload.

## 📱 Cómo Hacer Hot Restart

### Opción 1: Desde la Terminal
Si tienes Flutter corriendo en la terminal:
1. Presiona la tecla `R` (mayúscula) en la terminal donde corre Flutter
2. Verás: "Performing hot restart..."
3. Espera a que termine

### Opción 2: Desde VS Code/Android Studio
1. Haz clic en el botón de "Hot Restart" (icono de flecha circular con rayo)
2. O usa el atajo: `Ctrl + Shift + F5` (Windows) / `Cmd + Shift + F5` (Mac)

### Opción 3: Detener y Volver a Correr
```bash
# Detener la app
Ctrl + C

# Volver a correr
flutter run
```

## 🎯 Qué Deberías Ver Después del Restart

### 1. Pantalla de Autenticación (Minimalista)
- Fondo con gradiente azul institucional
- Icono de candado con pulso sutil
- Título "Bienvenido" simple
- Teclado numérico sin bordes (minimalista)
- Puntos del PIN pequeños y discretos

### 2. Pantalla de Inicio (Con Animaciones Mágicas)

#### Secuencia de Entrada:
```
0.0s  → Header baja desde arriba
0.3s  → Tabs de programas aparecen
0.4s  → Medallas entran desde la izquierda
0.5s  → Grid de programas sube
0.6s  → Primera tarjeta aparece
0.7s  → Segunda tarjeta aparece
0.8s  → Tercera tarjeta aparece
0.9s  → Redes sociales suben
1.0s  → Iconos hacen zoom
```

#### Medallas Mágicas (Efecto Continuo):
- ✨ **Brillo pulsante** que nunca para
- ⚡ **3 partículas brillantes** rotando alrededor
- 🌟 **Anillo de luz** exterior que respira
- 💫 **Sombras dinámicas** que cambian de intensidad
- 🎨 **Colores vibrantes**: Oro, Plata, Bronce, Púrpura, Azul

#### Al Tocar una Medalla:
- 🔄 Rotación completa con rebote elástico (600ms)
- 📈 Efecto de escala (la medalla "late")
- ✨ Las partículas siguen brillando

## 🔍 Cómo Verificar que Funciona

### Checklist Visual:
- [ ] El header baja suavemente desde arriba
- [ ] Las medallas tienen un brillo continuo
- [ ] Ves 3 puntitos brillantes rotando alrededor de cada medalla
- [ ] Las tarjetas de programas suben desde abajo una por una
- [ ] Al tocar una medalla, gira con efecto de rebote
- [ ] Los colores son vibrantes (oro brillante, plata, bronce, etc.)

### Si NO Ves las Animaciones:
1. Verifica que hiciste HOT RESTART (no hot reload)
2. Cierra completamente la app y vuelve a correr
3. Verifica que estás en la pantalla de "Inicio" (primera tab del menú)
4. Toca una medalla para ver la rotación

## 🎮 Interactividad

### Medallas:
- **Tap**: Rotación completa con rebote + escala
- **Efecto continuo**: Brillo y partículas siempre activas
- **Scroll horizontal**: Desliza para ver todas las medallas

### Tarjetas de Programas:
- Aparecen secuencialmente desde abajo
- Cada una con delay de 100ms

### Redes Sociales:
- Container sube desde abajo
- Cada icono hace zoom secuencialmente

## 🐛 Troubleshooting

### Problema: No veo las animaciones de entrada
**Solución**: Las animaciones solo se ejecutan la primera vez que se carga la pantalla. Si ya estabas en la pantalla de inicio:
1. Navega a otra pantalla (ej: Perfil)
2. Vuelve a la pantalla de Inicio
3. Verás las animaciones de entrada

### Problema: Las medallas no brillan
**Solución**: 
1. Haz HOT RESTART completo (tecla `R` mayúscula)
2. Si persiste, cierra la app y vuelve a correr

### Problema: Las partículas no rotan
**Solución**:
1. Verifica que hiciste `flutter pub get`
2. Haz HOT RESTART completo
3. Verifica que el import de `dart:math` está presente

### Problema: La app crashea
**Solución**:
1. Verifica los logs en la terminal
2. Ejecuta: `flutter clean`
3. Ejecuta: `flutter pub get`
4. Vuelve a correr: `flutter run`

## 📊 Performance

Las animaciones están optimizadas para:
- **60 FPS** estables
- **Bajo consumo** de batería
- **Memoria eficiente** (solo controllers)

Si notas lag:
1. Verifica que estás en modo Release: `flutter run --release`
2. Cierra otras apps en el dispositivo
3. Reinicia el dispositivo

## 🎨 Colores de las Medallas

Para verificar que los colores son correctos:
- **Maestría**: Oro brillante (#FFD700)
- **Diplomado**: Plata (#C0C0C0)
- **Doctorado**: Bronce (#CD7F32)
- **Posdoctorado**: Púrpura mágico (#9C27B0)
- **Cursos**: Azul eléctrico (#2196F3)

## 🎬 Video de Referencia

Si quieres ver cómo debería verse, busca videos de:
- "League of Legends Hextech Crafting" (efecto de brillo)
- "LOL Champion Select" (animaciones de entrada)
- "LOL Mastery Badges" (colores y brillos)

---

**Nota**: Si después de hacer HOT RESTART completo aún no ves las animaciones, comparte un screenshot de la pantalla de inicio y te ayudo a diagnosticar el problema.
