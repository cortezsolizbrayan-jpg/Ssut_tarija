# Implementación API de Inscripción

## Fecha
23 de febrero de 2026

## Endpoint Configurado
```
POST http://dev-api-preinscripcion.posgradoupea.edu.bo/api/v1/inscripcion
Content-Type: multipart/form-data
```

## Archivos Creados

### 1. `lib/features/sistema/infrastructure/datasources/inscripcion_datasource.dart`
Interfaz abstracta del datasource de inscripción.

### 2. `lib/features/sistema/infrastructure/datasources/inscripcion_datasource_impl.dart`
Implementación del datasource que maneja la comunicación HTTP con el servidor.

**Características**:
- Usa Dio para peticiones HTTP
- Maneja multipart/form-data para envío de archivos
- Timeout de 30 segundos
- Manejo robusto de errores
- Logging detallado en modo debug

### 3. `lib/core/services/servicio_inscripcion.dart`
Servicio de alto nivel que:
- Recopila todos los datos del usuario desde LocalStorage
- Valida que los datos estén completos
- Formatea los datos según el formato esperado por la API
- Envía la inscripción completa

### 4. Métodos agregados a `LocalStorageService`
```dart
saveFacturacionData(Map<String, dynamic> data)
getFacturacionData()
```

## Estructura de Datos Enviados

### Campos del Body (multipart/form-data)

#### Campos Simples
```dart
idPersona: int
idPrograma: int
```

#### personaExterna[campo]
```dart
personaExterna[ci]: String              // Número de CI
personaExterna[expedido]: String        // Lugar de expedición (LP, CB, SC, etc.)
personaExterna[nombre]: String          // Nombre
personaExterna[paterno]: String         // Apellido paterno
personaExterna[materno]: String         // Apellido materno (opcional)
personaExterna[genero]: String          // M o F
personaExterna[fechaNacimiento]: String // Formato: YYYY-MM-DD
personaExterna[celular]: String         // Número de celular
personaExterna[correo]: String          // Email
personaExterna[direccion]: String       // Dirección
personaExterna[ciudad]: String          // Ciudad
```

#### facturacion[campo]
```dart
facturacion[idTributario]: String       // NIT o CI
facturacion[tipoTributario]: String     // Tipo (1, 2, etc.)
facturacion[tipoDocumento]: String      // Tipo de documento (5, etc.)
facturacion[pais]: String               // Código de país (22 = Bolivia)
facturacion[nroDocumento]: String       // Número de documento
facturacion[complemento]: String        // Complemento (opcional)
facturacion[razonSocial]: String        // Razón social o nombre completo
facturacion[celular]: String            // Celular
facturacion[correo]: String             // Email
```

#### Archivos
```dart
respaldoCi[anverso]: File (image/jpeg)  // Foto del anverso del CI
respaldoCi[reverso]: File (image/jpeg)  // Foto del reverso del CI
```

## Uso del Servicio

### Ejemplo Básico

```dart
import 'package:refactor_template/core/services/servicio_inscripcion.dart';

// En tu widget o provider
final servicioInscripcion = ServicioInscripcion();

// Verificar si tiene datos completos
final tieneD atos = await servicioInscripcion.tieneDatosCompletos();

if (!tieneDatos) {
  // Mostrar mensaje pidiendo completar perfil
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Por favor completa tu perfil antes de inscribirte'),
    ),
  );
  return;
}

// Enviar inscripción
try {
  final resultado = await servicioInscripcion.enviarInscripcionCompleta(
    idPrograma: 2172, // ID del programa seleccionado
  );

  if (resultado['success'] == true) {
    // Inscripción exitosa
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Inscripción enviada exitosamente!'),
        backgroundColor: Colors.green,
      ),
    );
    
    // Navegar a pantalla de confirmación
    context.go('/inscripcion-exitosa');
  }
} catch (e) {
  // Error en la inscripción
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Error: $e'),
      backgroundColor: Colors.red,
    ),
  );
}
```

### Ejemplo con Resumen Previo

```dart
// Obtener resumen antes de enviar
final resumen = await servicioInscripcion.obtenerResumenInscripcion(
  idPrograma: 2172,
);

// Mostrar dialog de confirmación
showDialog(
  context: context,
  builder: (ctx) => AlertDialog(
    title: const Text('Confirmar Inscripción'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nombre: ${resumen['nombreCompleto']}'),
        Text('CI: ${resumen['ci']}'),
        Text('Correo: ${resumen['correo']}'),
        Text('Celular: ${resumen['celular']}'),
        const SizedBox(height: 16),
        Text('Razón Social: ${resumen['razonSocial']}'),
        Text('NIT: ${resumen['nit']}'),
        const SizedBox(height: 16),
        Text('CI Anverso: ${resumen['tieneCiAnverso'] ? '✅' : '❌'}'),
        Text('CI Reverso: ${resumen['tieneCiReverso'] ? '✅' : '❌'}'),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(ctx),
        child: const Text('Cancelar'),
      ),
      ElevatedButton(
        onPressed: () async {
          Navigator.pop(ctx);
          // Enviar inscripción
          await _enviarInscripcion();
        },
        child: const Text('Confirmar'),
      ),
    ],
  ),
);
```

### Ejemplo con Loading

```dart
Future<void> _enviarInscripcion() async {
  // Mostrar loading
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const Center(
      child: CircularProgressIndicator(),
    ),
  );

  try {
    final servicioInscripcion = ServicioInscripcion();
    
    final resultado = await servicioInscripcion.enviarInscripcionCompleta(
      idPrograma: widget.idPrograma,
    );

    // Cerrar loading
    if (mounted) Navigator.pop(context);

    if (resultado['success'] == true) {
      // Éxito
      _mostrarExito();
    }
  } catch (e) {
    // Cerrar loading
    if (mounted) Navigator.pop(context);
    
    // Mostrar error
    _mostrarError(e.toString());
  }
}
```

## Flujo Completo de Inscripción

### 1. Usuario Completa su Perfil
```dart
// En MisDatosPersonalesScreen
await LocalStorageService.savePersonalData({
  'numeroCI': '84615167',
  'expedidoEn': 'LP',
  'nombre': 'Juan',
  'apPaterno': 'Pérez',
  'apMaterno': '',
  'genero': 'M',
  'fechaNacimiento': '2004-11-19',
  'celular': '77263023',
  'correo': 'juan@mail.com',
  'direccion': 'Calle 1 # 234',
  'ciudad': 'LA PAZ - EL ALTO',
});
```

### 2. Usuario Completa Datos de Facturación
```dart
// En pantalla de facturación (crear si no existe)
await LocalStorageService.saveFacturacionData({
  'nit': '8372500',
  'tipoTributario': '1',
  'tipoDocumento': '5',
  'pais': '22',
  'nroDocumento': '8372500',
  'complemento': '1A',
  'razonSocial': 'Quispe',
  'celular': '78917623',
  'correo': 'cpacoquispe@gmail.com',
});
```

### 3. Usuario Sube Documentos
```dart
// Ya implementado en MisDocumentosPersonalesScreen
// Los archivos se guardan automáticamente en participant_documents
```

### 4. Usuario Se Inscribe a un Programa
```dart
// En ProgramasVigentesScreen o detalle del programa
final servicioInscripcion = ServicioInscripcion();

// Verificar datos completos
if (!await servicioInscripcion.tieneDatosCompletos()) {
  // Redirigir a completar perfil
  context.go('/mi-perfil');
  return;
}

// Enviar inscripción
await servicioInscripcion.enviarInscripcionCompleta(
  idPrograma: programaSeleccionado.id,
);
```

## Validaciones Implementadas

### Datos Requeridos
El servicio valida automáticamente que estén presentes:
- ✅ Número de CI
- ✅ Nombre
- ✅ Apellido paterno
- ✅ Celular
- ✅ Correo electrónico
- ✅ Razón social (facturación)
- ✅ Número de documento (facturación)

### Archivos Opcionales
- CI Anverso (recomendado)
- CI Reverso (recomendado)

## Manejo de Errores

### Errores Comunes

#### 400 - Bad Request
```
Datos inválidos: Verifica la información
```
**Solución**: Revisar que todos los campos requeridos estén completos y en el formato correcto.

#### 404 - Not Found
```
Endpoint no encontrado
```
**Solución**: Verificar que la URL base esté correcta en Environment.

#### 500 - Internal Server Error
```
Error en el servidor
```
**Solución**: Contactar al equipo de backend.

#### Connection Timeout
```
Tiempo de conexión agotado
```
**Solución**: Verificar conexión a internet.

#### Connection Error
```
Error de conexión. Verifica tu internet
```
**Solución**: Verificar que el dispositivo tenga internet.

## Logging en Modo Debug

El servicio imprime información detallada en modo debug:

```
📤 Enviando inscripción a: http://dev-api-preinscripcion.posgradoupea.edu.bo/api/v1/inscripcion
📋 Datos: idPersona=16548, idPrograma=2172
📋 Preparando inscripción:
   idPersona: 16548
   idPrograma: 2172
   CI: 84615167
   Nombre: juan perez
   Correo: juan@mail.com
   Facturación: Quispe
   CI Anverso: Sí
   CI Reverso: Sí
✅ Inscripción enviada exitosamente
📥 Respuesta: {success: true, message: "Inscripción registrada"}
```

## Próximos Pasos

### 1. Crear Pantalla de Facturación
Crear una pantalla donde el usuario pueda ingresar sus datos de facturación:
- NIT o CI
- Razón social
- Correo
- Celular

### 2. Agregar Botón de Inscripción
En la pantalla de detalle del programa o en programas vigentes, agregar un botón "Inscribirse" que:
1. Verifique datos completos
2. Muestre resumen
3. Confirme inscripción
4. Envíe al servidor

### 3. Pantalla de Confirmación
Crear una pantalla que se muestre después de inscribirse exitosamente con:
- Mensaje de éxito
- Número de inscripción (si lo devuelve el servidor)
- Próximos pasos
- Botón para ver mis inscripciones

### 4. Historial de Inscripciones
Guardar localmente las inscripciones exitosas para que el usuario pueda verlas.

## Testing

### Test Manual
1. Completar perfil personal
2. Completar datos de facturación
3. Subir fotos del CI
4. Intentar inscribirse a un programa
5. Verificar que se envíe correctamente

### Test de Errores
1. Intentar inscribirse sin completar perfil
2. Intentar inscribirse sin internet
3. Verificar mensajes de error claros

## Notas Importantes

- ⚠️ El `idPersona` se obtiene de la sesión del usuario (login)
- ⚠️ Los archivos del CI son opcionales pero recomendados
- ⚠️ La fecha de nacimiento debe estar en formato YYYY-MM-DD
- ⚠️ El servicio valida automáticamente los datos antes de enviar
- ⚠️ Todos los errores se propagan con mensajes claros en español

## Estado
✅ **IMPLEMENTADO Y LISTO PARA USAR**

---
**Desarrollador**: Kiro AI Assistant
**Fecha**: 23 de febrero de 2026
**API Base**: http://dev-api-preinscripcion.posgradoupea.edu.bo/api/v1
**Endpoint**: POST /inscripcion
