# Guía de Integración - Sistema de Validación de Requisitos

## 📋 Descripción General

El sistema de validación de requisitos verifica automáticamente si un usuario tiene todos los documentos necesarios antes de permitir la inscripción a un programa de posgrado.

## 🎯 Características

- ✅ Validación automática de requisitos según el tipo de programa
- ✅ Interfaz visual moderna que muestra el progreso
- ✅ Redirección automática a documentos personales si faltan requisitos
- ✅ Soporte para 4 tipos de programas: Diplomado, Especialidad, Maestría, Doctorado
- ✅ Manejo de prórrogas para títulos académicos

## 📁 Archivos Creados

1. **Entidades**
   - `lib/features/sistema/domain/entities/requisito_inscripcion.dart`

2. **Servicios**
   - `lib/core/services/servicio_validacion_requisitos.dart`

3. **Pantallas**
   - `lib/features/sistema/screens/inscripcion/pantalla_validacion_requisitos.dart`

4. **Utilidades**
   - `lib/core/utils/helper_validacion_inscripcion.dart`

## 🚀 Uso Básico

### Opción 1: Validación Simple (Recomendada)

```dart
import 'package:refactor_template/core/utils/helper_validacion_inscripcion.dart';

// En tu botón de inscripción
ElevatedButton(
  onPressed: () async {
    final puedeInscribirse = await HelperValidacionInscripcion.validarYContinuar(
      context: context,
      tipoPrograma: 'DIPLOMADO', // o 'ESPECIALIDAD', 'MAESTRÍA', 'DOCTORADO'
      nombrePrograma: 'DIPLOMADO EN ADMINISTRACIÓN DE SERVIDORES GNU/LINUX',
      onRequisitosCompletos: () {
        // Este código se ejecuta cuando todos los requisitos están completos
        _continuarConInscripcion();
      },
    );
    
    if (puedeInscribirse) {
      // El usuario puede inscribirse
      print('Usuario puede inscribirse');
    } else {
      // Faltan requisitos - el usuario fue redirigido a completarlos
      print('Faltan requisitos');
    }
  },
  child: const Text('Inscribirse'),
)
```

### Opción 2: Mostrar Pantalla de Validación Directamente

```dart
import 'package:refactor_template/features/sistema/screens/inscripcion/pantalla_validacion_requisitos.dart';

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PantallaValidacionRequisitos(
      tipoPrograma: 'DIPLOMADO',
      nombrePrograma: 'DIPLOMADO EN ADMINISTRACIÓN DE SERVIDORES GNU/LINUX',
      onRequisitosCompletos: () {
        // Código cuando todos los requisitos están completos
        _continuarConInscripcion();
      },
    ),
  ),
);
```

### Opción 3: Validación Programática

```dart
import 'package:refactor_template/core/services/servicio_validacion_requisitos.dart';

final servicio = ServicioValidacionRequisitos();

// Verificar si puede inscribirse
final puedeInscribirse = await servicio.puedeInscribirse('DIPLOMADO');

if (puedeInscribirse) {
  // Continuar con inscripción
} else {
  // Obtener documentos faltantes
  final faltantes = await servicio.obtenerDocumentosFaltantes('DIPLOMADO');
  print('Documentos faltantes: $faltantes');
}
```

### Opción 4: Mostrar Diálogo de Documentos Faltantes

```dart
import 'package:refactor_template/core/utils/helper_validacion_inscripcion.dart';

// Mostrar un diálogo con los documentos faltantes
await HelperValidacionInscripcion.mostrarDocumentosFaltantes(
  context: context,
  tipoPrograma: 'DIPLOMADO',
);
```

## 📊 Requisitos por Tipo de Programa

### DIPLOMADO
1. ✅ Boletas de depósito bancario
2. ✅ Fotografías (4x4 y 2.5x2.5)
3. ✅ Formularios de inscripción
4. ✅ Fotocopia de CI
5. ✅ Título académico (o carta de prórroga)
6. ✅ Carta de solicitud de inscripción
7. ✅ Hoja de vida profesional

### ESPECIALIDAD, MAESTRÍA, DOCTORADO
- Los mismos requisitos del diplomado
- (Puedes agregar requisitos adicionales en el servicio)

## 🔧 Campos de Documentos en SharedPreferences

El sistema valida los siguientes campos:

- `profilePhoto` - Fotografía de perfil
- `ciLetterPath` - Fotocopia de CI (generada automáticamente)
- `tituloPath` - Título académico
- `prorrogaPath` - Carta de prórroga (si aplica)
- `deferDocuments` - Boolean que indica si se solicitó prórroga
- `cartaInscripcionPath` - Carta de inscripción
- `hojaVidaPath` - Hoja de vida profesional

## 💡 Ejemplo Completo de Integración

```dart
import 'package:flutter/material.dart';
import 'package:refactor_template/core/utils/helper_validacion_inscripcion.dart';

class PantallaProgramaDetalle extends StatelessWidget {
  final String tipoPrograma = 'DIPLOMADO';
  final String nombrePrograma = 'DIPLOMADO EN ADMINISTRACIÓN DE SERVIDORES GNU/LINUX';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(nombrePrograma)),
      body: Column(
        children: [
          // Información del programa
          Text('Información del programa...'),
          
          const Spacer(),
          
          // Botón de inscripción
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => _iniciarInscripcion(context),
                child: const Text('Inscribirse Ahora'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _iniciarInscripcion(BuildContext context) async {
    // Validar requisitos antes de continuar
    final puedeInscribirse = await HelperValidacionInscripcion.validarYContinuar(
      context: context,
      tipoPrograma: tipoPrograma,
      nombrePrograma: nombrePrograma,
      onRequisitosCompletos: () {
        // Todos los requisitos están completos
        _procesarInscripcion(context);
      },
    );

    if (!puedeInscribirse) {
      // El usuario fue redirigido a completar documentos
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete los requisitos faltantes para continuar'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _procesarInscripcion(BuildContext context) {
    // Aquí va tu lógica de inscripción
    print('Procesando inscripción...');
    
    // Ejemplo: Navegar a pantalla de confirmación
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PantallaConfirmacionInscripcion(),
      ),
    );
  }
}
```

## 🎨 Personalización

### Agregar Nuevos Requisitos

Edita `lib/core/services/servicio_validacion_requisitos.dart`:

```dart
static List<RequisitoInscripcion> get requisitosDiplomado => [
  // ... requisitos existentes ...
  
  // Agregar nuevo requisito
  const RequisitoInscripcion(
    id: 'certificado_medico',
    descripcion: 'Certificado médico vigente',
    esObligatorio: true,
    tipo: TipoRequisito.otro,
    campoDocumento: 'certificadoMedicoPath',
  ),
];
```

### Modificar Validación de un Requisito

En el método `_validarRequisito`, agrega tu lógica:

```dart
case 'certificado_medico':
  return _validarCertificadoMedico(requisito, prefs);
```

## 📱 Flujo de Usuario

1. Usuario hace clic en "Inscribirse"
2. Sistema valida requisitos automáticamente
3. **Si todos están completos**: Continúa con inscripción
4. **Si faltan requisitos**: 
   - Muestra pantalla de validación
   - Usuario puede ir a "Documentos Personales"
   - Completa documentos faltantes
   - Regresa y actualiza estado
   - Continúa con inscripción

## ✅ Ventajas

- ✨ **UX Mejorada**: El usuario sabe exactamente qué le falta
- 🚀 **Automatización**: No necesita verificación manual
- 📊 **Visual**: Progreso claro con porcentajes
- 🔄 **Actualización en tiempo real**: Revalida al volver de documentos
- 🎯 **Específico por programa**: Diferentes requisitos según el tipo

## 🐛 Solución de Problemas

### Error: "No se pudo cargar la información"
- Verifica que SharedPreferences esté inicializado
- Asegúrate de que los campos de documento existan

### Los requisitos no se actualizan
- Llama a `_validarRequisitos()` después de completar documentos
- Verifica que los paths se guarden correctamente en SharedPreferences

### Requisitos siempre aparecen como pendientes
- Verifica los nombres de los campos en SharedPreferences
- Asegúrate de que los documentos se guarden con los keys correctos

## 📞 Soporte

Para más información, revisa los archivos de código fuente con comentarios detallados.
