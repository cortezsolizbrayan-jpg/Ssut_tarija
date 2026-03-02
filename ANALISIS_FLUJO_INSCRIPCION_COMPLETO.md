# Análisis Completo del Flujo de Inscripción

## Fecha
24 de febrero de 2026

## Estado Actual

### ✅ Implementado
1. **API de Inscripción** - Completamente funcional
   - Endpoint: `POST /inscripcion`
   - Servicio: `ServicioInscripcion`
   - Datasource: `InscripcionDatasourceImpl`
   - Validaciones automáticas
   - Manejo robusto de errores

2. **Almacenamiento Local**
   - Datos personales
   - Datos de facturación
   - Documentos del participante
   - Sesión del usuario

3. **Pantallas Existentes**
   - Mis Datos Personales
   - Mis Documentos Personales
   - Validación de Requisitos
   - Confirmación de Inscripción
   - Programas Vigentes

### ❌ Faltante/Mejorable

1. **Flujo de Inscripción Completo**
   - No hay botón claro de "Inscribirse" en programas
   - No hay confirmación previa antes de enviar
   - No hay feedback visual durante el envío
   - No se guarda historial de inscripciones

2. **Datos de Facturación**
   - No hay pantalla dedicada para capturar estos datos
   - Se asumen valores por defecto
   - Usuario no puede editar fácilmente

3. **Validación de Requisitos**
   - Pantalla existe pero no está integrada con el flujo
   - No valida antes de permitir inscripción

4. **Experiencia de Usuario**
   - No hay indicador de progreso del perfil
   - No hay guía paso a paso
   - No hay confirmación visual clara

## Flujo Ideal de Inscripción

### Paso 1: Usuario Selecciona Programa
**Pantalla:** Programas Vigentes

**Acción:** Usuario toca "Inscribirse" en un programa

**Validación:**
```dart
// Verificar si ya está inscrito
if (_enrolledProgramIds.contains(programa.id)) {
  _showSnack('Ya estás inscrito en este programa.');
  return;
}

// Verificar datos completos
final servicioInscripcion = ServicioInscripcion();
final tieneD atos = await servicioInscripcion.tieneDatosCompletos();

if (!tieneDatos) {
  // Mostrar dialog explicando qué falta
  _mostrarDialogDatosIncompletos();
  return;
}
```

### Paso 2: Validar Requisitos
**Pantalla:** Validación de Requisitos

**Mostrar:**
- ✅ Datos personales completos
- ✅ Documentos subidos
- ✅ Datos de facturación
- ⚠️ Requisitos pendientes

**Opciones:**
- "Completar Requisitos" → Navega a pantallas faltantes
- "Continuar de Todos Modos" → Si requisitos opcionales

### Paso 3: Confirmar Datos
**Pantalla:** Confirmación de Inscripción (nueva)

**Mostrar Resumen:**
```dart
final resumen = await servicioInscripcion.obtenerResumenInscripcion(
  idPrograma: programa.id,
);

// Mostrar:
- Nombre del programa
- Modalidad
- Datos personales
- Datos de facturación
- Documentos adjuntos
```

**Botones:**
- "Editar Datos" → Volver a perfil
- "Confirmar Inscripción" → Enviar

### Paso 4: Enviar Inscripción
**Acción:** Envío con loading

```dart
// Mostrar loading overlay
showDialog(
  context: context,
  barrierDismissible: false,
  builder: (ctx) => _LoadingInscripcionDialog(),
);

try {
  final resultado = await servicioInscripcion.enviarInscripcionCompleta(
    idPrograma: programa.id,
  );
  
  // Cerrar loading
  Navigator.pop(context);
  
  // Guardar inscripción localmente
  await _guardarInscripcionLocal(programa, resultado);
  
  // Navegar a confirmación
  context.go('/inscripcion-exitosa', extra: {
    'programa': programa,
    'numeroInscripcion': resultado['data']['numeroInscripcion'],
  });
  
} catch (e) {
  // Cerrar loading
  Navigator.pop(context);
  
  // Mostrar error
  _mostrarDialogError(e.toString());
}
```

### Paso 5: Confirmación Exitosa
**Pantalla:** Confirmación Inscripción (ya existe, mejorar)

**Mostrar:**
- ✅ Animación de éxito
- Número de inscripción
- Nombre del programa
- Próximos pasos
- Botones de acción

## Mejoras Propuestas

### 1. 🔴 CRÍTICA: Integrar Botón de Inscripción

**Archivo:** `lib/features/sistema/screens/diplomados/programas_vigentes_screen.dart`

**Cambio en `_ProgramaVigenteCard`:**

```dart
ElevatedButton(
  onPressed: isEnrolled ? null : () async {
    // 1. Verificar datos completos
    final servicioInscripcion = ServicioInscripcion();
    final tieneD atos = await servicioInscripcion.tieneDatosCompletos();
    
    if (!tieneDatos) {
      _mostrarDialogDatosIncompletos(context);
      return;
    }
    
    // 2. Mostrar confirmación
    final confirmar = await _mostrarDialogConfirmacion(
      context,
      programa,
    );
    
    if (!confirmar) return;
    
    // 3. Enviar inscripción
    await _enviarInscripcion(context, programa);
  },
  child: Text(isEnrolled ? 'Ya inscrito' : 'Inscribirse'),
)
```

### 2. 🔴 CRÍTICA: Crear Pantalla de Datos de Facturación

**Archivo nuevo:** `lib/features/sistema/screens/perfil/datos_facturacion_screen.dart`

```dart
class DatosFacturacionScreen extends StatefulWidget {
  static const name = 'datos-facturacion';
  
  @override
  State<DatosFacturacionScreen> createState() => _DatosFacturacionScreenState();
}

class _DatosFacturacionScreenState extends State<DatosFacturacionScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nitController = TextEditingController();
  final _razonSocialController = TextEditingController();
  final _correoController = TextEditingController();
  final _celularController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }
  
  Future<void> _cargarDatos() async {
    final data = await LocalStorageService.getFacturacionData();
    if (data != null) {
      _nitController.text = data['nit']?.toString() ?? '';
      _razonSocialController.text = data['razonSocial']?.toString() ?? '';
      _correoController.text = data['correo']?.toString() ?? '';
      _celularController.text = data['celular']?.toString() ?? '';
    }
  }
  
  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    
    await LocalStorageService.saveFacturacionData({
      'nit': _nitController.text,
      'razonSocial': _razonSocialController.text,
      'correo': _correoController.text,
      'celular': _celularController.text,
      'tipoTributario': '1',
      'tipoDocumento': '5',
      'pais': '22',
      'nroDocumento': _nitController.text,
      'complemento': '',
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Datos guardados')),
    );
    
    Navigator.pop(context);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Datos de Facturación')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // NIT
            TextFormField(
              controller: _nitController,
              decoration: const InputDecoration(
                labelText: 'NIT o CI',
                hintText: 'Ingrese su NIT o CI',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Razón Social
            TextFormField(
              controller: _razonSocialController,
              decoration: const InputDecoration(
                labelText: 'Razón Social',
                hintText: 'Nombre o razón social',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Correo
            TextFormField(
              controller: _correoController,
              decoration: const InputDecoration(
                labelText: 'Correo Electrónico',
                hintText: 'correo@ejemplo.com',
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo requerido';
                }
                if (!value.contains('@')) {
                  return 'Correo inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Celular
            TextFormField(
              controller: _celularController,
              decoration: const InputDecoration(
                labelText: 'Celular',
                hintText: '7XXXXXXX',
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            
            // Botón Guardar
            ElevatedButton(
              onPressed: _guardar,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF005BAC),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Guardar Datos',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 3. 🟡 MEDIA: Mejorar Dialog de Confirmación

**Función helper:**

```dart
Future<bool> _mostrarDialogConfirmacion(
  BuildContext context,
  ProgramaPosgrado programa,
) async {
  final servicioInscripcion = ServicioInscripcion();
  final resumen = await servicioInscripcion.obtenerResumenInscripcion(
    idPrograma: programa.id,
  );
  
  return await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Confirmar Inscripción'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Programa
            Text(
              programa.titulo,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Modalidad: ${programa.modalidad}'),
            const Divider(height: 24),
            
            // Datos Personales
            const Text(
              'Datos Personales',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Nombre: ${resumen['nombreCompleto']}'),
            Text('CI: ${resumen['ci']}'),
            Text('Correo: ${resumen['correo']}'),
            Text('Celular: ${resumen['celular']}'),
            const Divider(height: 24),
            
            // Facturación
            const Text(
              'Datos de Facturación',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Razón Social: ${resumen['razonSocial']}'),
            Text('NIT: ${resumen['nit']}'),
            const Divider(height: 24),
            
            // Documentos
            const Text(
              'Documentos',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  resumen['tieneCiAnverso'] 
                      ? Icons.check_circle 
                      : Icons.cancel,
                  color: resumen['tieneCiAnverso'] 
                      ? Colors.green 
                      : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Text('CI Anverso'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  resumen['tieneCiReverso'] 
                      ? Icons.check_circle 
                      : Icons.cancel,
                  color: resumen['tieneCiReverso'] 
                      ? Colors.green 
                      : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Text('CI Reverso'),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF005BAC),
          ),
          child: const Text('Confirmar Inscripción'),
        ),
      ],
    ),
  ) ?? false;
}
```

### 4. 🟡 MEDIA: Mejorar Loading Durante Envío

**Widget de Loading:**

```dart
class _LoadingInscripcionDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF005BAC),
            ),
            const SizedBox(height: 24),
            const Text(
              'Enviando inscripción...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Por favor espera',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 5. 🟢 BAJA: Guardar Historial de Inscripciones

**Agregar a LocalStorageService:**

```dart
// Guardar inscripción
static Future<void> saveInscripcion(Map<String, dynamic> inscripcion) async {
  final prefs = await SharedPreferences.getInstance();
  final inscripciones = await getInscripciones();
  inscripciones.add(inscripcion);
  
  final jsonList = inscripciones.map((i) => jsonEncode(i)).toList();
  await prefs.setStringList('inscripciones', jsonList);
}

// Obtener inscripciones
static Future<List<Map<String, dynamic>>> getInscripciones() async {
  final prefs = await SharedPreferences.getInstance();
  final jsonList = prefs.getStringList('inscripciones') ?? [];
  
  return jsonList
      .map((json) => jsonDecode(json) as Map<String, dynamic>)
      .toList();
}
```

### 6. 🟢 BAJA: Indicador de Progreso del Perfil

**Widget en Perfil Screen:**

```dart
class _PerfilCompletoIndicator extends StatelessWidget {
  final double progreso; // 0.0 a 1.0
  
  @override
  Widget build(BuildContext context) {
    final porcentaje = (progreso * 100).toInt();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Perfil Completo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$porcentaje%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF005BAC),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progreso,
              backgroundColor: Colors.grey[200],
              color: const Color(0xFF005BAC),
              minHeight: 8,
            ),
          ),
          if (progreso < 1.0) ...[
            const SizedBox(height: 12),
            Text(
              'Completa tu perfil para poder inscribirte',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

## Plan de Implementación

### Fase 1: Funcionalidad Básica (2-3 horas)

1. ✅ Crear pantalla de Datos de Facturación
2. ✅ Integrar botón de inscripción en Programas Vigentes
3. ✅ Implementar dialog de confirmación
4. ✅ Implementar loading durante envío
5. ✅ Mejorar manejo de errores

**Impacto:** Flujo completo de inscripción funcional

### Fase 2: Mejoras UX (1-2 horas)

1. ✅ Agregar indicador de progreso del perfil
2. ✅ Guardar historial de inscripciones
3. ✅ Mejorar mensajes de error
4. ✅ Agregar validaciones visuales

**Impacto:** Mejor experiencia de usuario

### Fase 3: Optimizaciones (1 hora)

1. ✅ Caché de datos de inscripción
2. ✅ Optimizar carga de datos
3. ✅ Agregar analytics/tracking
4. ✅ Testing exhaustivo

**Impacto:** Rendimiento y confiabilidad

## Métricas de Éxito

### Funcionalidad
- ✅ Usuario puede inscribirse desde la app
- ✅ Datos se envían correctamente a la API
- ✅ Errores se manejan apropiadamente
- ✅ Confirmación visual clara

### UX
- ✅ Flujo intuitivo y guiado
- ✅ Feedback visual en cada paso
- ✅ Mensajes claros y en español
- ✅ Fácil de completar

### Rendimiento
- ✅ Envío en < 5 segundos
- ✅ Sin bloqueos de UI
- ✅ Manejo de errores de red
- ✅ Validaciones rápidas

## Conclusión

El flujo de inscripción tiene una base sólida con la API ya implementada. Las mejoras propuestas se enfocan en:

1. **Completar el flujo end-to-end** - Desde selección hasta confirmación
2. **Mejorar la UX** - Feedback visual, validaciones, guías
3. **Optimizar el rendimiento** - Caché, validaciones rápidas

**Prioridad:** 🔴 ALTA - Es funcionalidad core de la aplicación

**Tiempo estimado:** 4-6 horas para implementación completa

**Impacto esperado:** Flujo de inscripción completo y optimizado que permite a los usuarios inscribirse fácilmente desde la app móvil.
