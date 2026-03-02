# Subida de Identidad – Guía rápida

## Qué hace esta carpeta

Sirve para **subir y leer datos del carnet** (CI, nombres, fechas, etc.) usando OCR.  
La pantalla principal está en `../pantalla_subida_identidad.dart` y usa lo que hay aquí.

---

## Estructura (qué hace cada cosa)

```
pantalla_subida_identidad/
│
├── mixins/
│   ├── identity_ocr_extraction_mixin.dart   # Lee CI, nombres, apellidos y fechas del texto OCR
│   └── mixins.dart                           # Solo exporta el mixin
│
├── scanners/                                  # Módulos por tipo de escaneo
│   ├── blinkid_scanner.dart                  # BlinkID: tips → scanWithUi → finalize
│   ├── scanbot_scanner.dart                  # Scanbot: captura páginas → front/back File
│   └── scanners.dart                         # Barrel
│
├── models/
│   └── identity_document_data.dart         # Modelo con los datos del documento (CI, nombres, fechas…)
│----escandaloso 
d s un 
├── utils/
│   ├── date_helpers.dart                   # Normaliza y parsea fechas en texto (DD/MM/YYYY, etc.)
│   ├── text_extraction_helpers.dart       # Palabras válidas, quitar profesiones, saber si es nombre/lugar
│   └── image_preprocessing_helpers.dart    # Preparar imagen para OCR (recorte, contraste, nitidez)
│
└── widgets/
    ├── upload_card.dart                    # Tarjeta “toca para subir foto” (frontal/reverso)
    ├── scan_options_widget.dart            # Botones de opciones de escaneo (BlinkID, Scanbot, etc.)
    ├── scan_progress_widget.dart           # Indicador de progreso mientras corre el OCR
    └── scan_tips_dialog.dart               # Diálogo con consejos para escanear bien
```

---

## Flujo en una frase

El usuario sube **fotos del carnet** → se preprocesan imágenes → se llama **BlinkID/ML Kit/Scanbot** → el **mixin** extrae CI, nombres y fechas del texto → se navega a **reconocimiento facial** con esos datos.

---

## Dónde está la pantalla principal

- **Archivo:** `lib/features/login/presentation/pages/pantalla_subida_identidad.dart`
- **Widget:** `IDUploadScreen`
- Usa `IdentityOcrExtractionMixin` para la extracción y los widgets de esta carpeta para la UI.
