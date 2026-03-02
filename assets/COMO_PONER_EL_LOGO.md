# Dónde poner el logo de la app (Posgrado UPEA)

## 1. Logo **dentro de la app** (pantallas, login, splash, cabecera)

- **Carpeta:** `assets/images/`
- Ya tienes: `logoposgrado.jpg`, `logposgrado.png`
- Para un logo nuevo: guarda tu imagen aquí, por ejemplo:
  - `assets/images/logo_upea.jpg` o `logo_upea.png`
- En el código lo usas así:
  ```dart
  Image.asset('assets/images/logoposgrado.jpg')
  ```

Si prefieres que sea un **icono** (SVG o PNG pequeño para botones/menú):

- **Carpeta:** `assets/icons/`
- Ejemplo: `assets/icons/logo_upea.svg` o `logo_upea.png`
- En código: `Image.asset('assets/icons/logo_upea.png')`

---

## 2. **Icono de la app** (el que se ve en el escritorio del móvil)

Ese es el icono del launcher, no va en `assets/images` ni `assets/icons`. Va en:

### Android
- Carpeta: `android/app/src/main/res/`
- Archivos a reemplazar en cada subcarpeta:
  - `mipmap-mdpi/ic_launcher.png`     → 48×48 px
  - `mipmap-hdpi/ic_launcher.png`    → 72×72 px
  - `mipmap-xhdpi/ic_launcher.png`   → 96×96 px
  - `mipmap-xxhdpi/ic_launcher.png`  → 144×144 px
  - `mipmap-xxxhdpi/ic_launcher.png` → 192×192 px

Sustituye cada `ic_launcher.png` por tu logo en ese tamaño (o usa la herramienta abajo para generarlos todos).

### iOS
- Carpeta: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- Ahí hay varios PNG con nombres fijos, por ejemplo:
  - `Icon-App-1024x1024@1x.png` (1024×1024, para App Store)
  - `Icon-App-60x60@2x.png` (120×120)
  - etc.
- Sustituye cada archivo por tu logo en el tamaño que indica el nombre.

---

## Opción fácil: generar todos los iconos desde una sola imagen

Ya está configurado en el proyecto con `flutter_launcher_icons`:

1. Pon **una sola imagen** del logo (1024×1024 px recomendado) en:
   - `assets/images/logoposgrado.jpg` (o usa otro archivo y cambia `image_path` en `pubspec.yaml`).
2. Ejecuta en la raíz del proyecto:
   ```bash
   dart run flutter_launcher_icons
   ```
3. Se generan y reemplazan solos todos los iconos en Android e iOS.

Resumen:
- **Dentro de la app** → `assets/images/` (o `assets/icons/` para iconos).
- **Icono del launcher** → carpetas `res/mipmap-*` (Android) y `AppIcon.appiconset` (iOS), o una sola imagen en `assets/images/` + `flutter_launcher_icons`.
