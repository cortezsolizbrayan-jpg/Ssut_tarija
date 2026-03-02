import 'dart:io';
import 'dart:convert';

import 'package:animate_do/animate_do.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:refactor_template/config/constants/design_tokens.dart';
import 'package:refactor_template/core/services/servicio_almacenamiento_local.dart';
import 'package:refactor_template/core/services/servicio_generador_carta_inscripcion.dart';
import 'package:refactor_template/core/services/servicio_validacion_requisitos.dart';
import 'package:refactor_template/features/sistema/domain/entities/requisito_inscripcion.dart';
import 'package:refactor_template/features/sistema/screens/perfil/mis_datos_personales_screen.dart';
import 'package:refactor_template/features/sistema/screens/perfil/mis_documentos_personales_screen.dart';
import 'package:refactor_template/core/services/servicio_fotocopia_carnet.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
/// Pantalla para validar requisitos de inscripción antes de permitir inscribirse
class PantallaValidacionRequisitos extends StatefulWidget {
  final String tipoPrograma;
  final String nombrePrograma;
  /// Modalidad del programa (Virtual, Presencial, Semi-presencial).
  /// Si no se provee, se usa 'Virtual' por defecto.
  final String modalidad;
  final String idPrograma;
  final VoidCallback? onRequisitosCompletos;

  const PantallaValidacionRequisitos({
    super.key,
    required this.tipoPrograma,
    required this.nombrePrograma,
    required this.idPrograma,
    this.modalidad = 'Virtual',
    this.onRequisitosCompletos,
  });

  @override
  State<PantallaValidacionRequisitos> createState() =>
      _PantallaValidacionRequisitosState();
}

class _PantallaValidacionRequisitosState
    extends State<PantallaValidacionRequisitos> {
  final _servicioValidacion = ServicioValidacionRequisitos();
  ResultadoValidacionInscripcion? _resultado;
  bool _cargando = true;
  String? _busyRequisitoId;

  @override
  void initState() {
    super.initState();
    _validarRequisitos();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recargar requisitos cuando se vuelve a la pantalla
    // Esto asegura que los documentos generados se reflejen inmediatamente
    if (mounted) {
      // Resetear flag de auto-generación al volver a la pantalla
      _autoGeneracionIniciada = false;
      _validarRequisitos();
    }
  }

  Future<void> _validarRequisitos() async {
    setState(() => _cargando = true);

    try {
      final resultado = await _servicioValidacion.validarRequisitos(
        tipoPrograma: widget.tipoPrograma,
      );

      setState(() {
        _resultado = resultado;
        _cargando = false;
      });
      
      // Llamar después de setState para asegurar que el estado esté actualizado
      _determinarSiPuedeAutoCompletar();
      
      // Auto-completar automáticamente si es posible (solo la primera vez)
      if (_puedeAutoCompletar && !_autoGeneracionIniciada) {
        _autoGeneracionIniciada = true;
        // Ejecutar después de un pequeño delay para que la UI se actualice
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _autoCompletarTodo();
        });
      }

      // Si todos los requisitos están completos, ejecutar callback y cerrar para volver (ej. Programas Vigentes)
      if (resultado.todosLosRequisitosObligatoriosCumplidos) {
        if (mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  FadeInDown(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                      child: const Icon(Icons.check, color: Colors.white, size: 40),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('¡Trámite Listo!',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C))),
                  const SizedBox(height: 10),
                  const Text(
                    'Has cumplido con todos los requisitos obligatorios. Ya puedes proceder a inscribirte en tu programa.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _headerBlue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('CONTINUAR A INSCRIPCIÓN',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        widget.onRequisitosCompletos?.call();
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _cargando = false);
      _mostrarError('Error al validar requisitos: $e');
    }
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _irADocumentosPersonales() async {
    // Navegar usando go_router para mantener transiciones consistentes
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MisDocumentosPersonalesScreen(),
      ),
    );

    // Revalidar al volver (mantener lógica actual)
    if (resultado == true || mounted) {
      _validarRequisitos();
    }
  }

  Future<void> _saveDocPath(String key, String? path) async {
    final current =
        await LocalStorageService.getParticipantDocumentsData() ??
        <String, dynamic>{};
    
    if (path == null) {
      current.remove(key);
      if (key == 'prorroga_path') current['defer_documents'] = false;
    } else {
      current[key] = path;
      // Si se sube una prórroga, activar automáticamente el modo prórroga
      if (key == 'prorroga_path') current['defer_documents'] = true;
    }
    await LocalStorageService.saveParticipantDocumentsData(current);
  }

  Future<File> _copyToParticipantDocs(
    String originalPath,
    String prefix,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final outDir = Directory(
      '${dir.path}${Platform.pathSeparator}participant_documents',
    );
    if (!await outDir.exists()) {
      await outDir.create(recursive: true);
    }
    String ext = 'jpg';
    if (originalPath.toLowerCase().endsWith('.png')) ext = 'png';
    if (originalPath.toLowerCase().endsWith('.pdf')) ext = 'pdf';
    final fileName = '${prefix}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final dest = File('${outDir.path}${Platform.pathSeparator}$fileName');
    return File(originalPath).copy(dest.path);
  }

  bool _puedeAutoCompletar = false;
  bool _autoGeneracionIniciada = false;

  void _determinarSiPuedeAutoCompletar() {
    if (_resultado == null) return;
    
    final faltanAutoGenerables = _resultado!.resultados.any((r) => 
      r.estado == EstadoRequisito.pendiente && 
      (r.requisito.id == 'carta_inscripcion' || 
       r.requisito.id == 'ficha_inscripcion' || 
       r.requisito.id == 'formularios' ||
       (r.mensaje?.contains('PIECES_READY') ?? false))
    );

    setState(() => _puedeAutoCompletar = faltanAutoGenerables);
    
    // Auto-generar carta de inscripción automáticamente si está pendiente
    if (!_autoGeneracionIniciada && faltanAutoGenerables) {
      _autoGeneracionIniciada = true;
      _autoGenerarDocumentosBasicos();
    }
  }

  // Método para auto-generar documentos básicos sin intervención del usuario
  Future<void> _autoGenerarDocumentosBasicos() async {
    if (_resultado == null) {
      debugPrint('❌ No se puede auto-generar: _resultado es null');
      return;
    }
    
    // Solo generar carta de inscripción automáticamente
    final cartaReqs = _resultado!.resultados.where((r) => r.requisito.id == 'carta_inscripcion');
    if (cartaReqs.isEmpty) {
      debugPrint('❌ No se encontró requisito de carta_inscripcion');
      return;
    }
    
    final cartaReq = cartaReqs.first;
    debugPrint('📋 Estado de carta_inscripcion: ${cartaReq.estado}');
    
    if (cartaReq.estado == EstadoRequisito.pendiente) {
      debugPrint('🤖 Auto-generando carta de inscripción...');
      try {
        await _generarCartaInscripcion();
        debugPrint('✅ Carta de inscripción generada exitosamente');
      } catch (e) {
        debugPrint('❌ Error en auto-generación: $e');
      }
    } else {
      debugPrint('ℹ️ Carta de inscripción ya está en estado: ${cartaReq.estado}');
    }
  }

  Future<void> _autoCompletarTodo() async {
    if (_resultado == null) return;
    
    _mostrarMensaje('Iniciando recuperación y generación automática...');

    // 1. CI PDF
    final ciReqs = _resultado!.resultados.where((r) => r.requisito.id == 'ci_fotocopias');
    if (ciReqs.isNotEmpty && (ciReqs.first.mensaje?.contains('PIECES_READY') ?? false)) {
      await _generarFotocopiaCIPDF();
    }

    // 2. Carta
    final cartaReqs = _resultado!.resultados.where((r) => r.requisito.id == 'carta_inscripcion');
    if (cartaReqs.isNotEmpty && cartaReqs.first.estado == EstadoRequisito.pendiente) {
      await _generarCartaInscripcion();
    }

    // 3. Ficha
    final fichaReqs = _resultado!.resultados.where((r) => r.requisito.id == 'ficha_inscripcion' || r.requisito.id == 'formularios');
    if (fichaReqs.isNotEmpty && fichaReqs.first.estado == EstadoRequisito.pendiente) {
      await _generarFichaInscripcion();
    }

    _validarRequisitos();
  }

  TipoPrograma _getTipoProgramaEnum() {
    final t = widget.tipoPrograma.toUpperCase();
    if (t.contains('ESPECIALIDAD')) return TipoPrograma.especialidad;
    if (t.contains('MAESTR')) return TipoPrograma.maestria;
    if (t.contains('DOCTOR')) return TipoPrograma.doctorado;
    return TipoPrograma.diplomado;
  }

  Future<void> _generarCartaInscripcion() async {
    setState(() => _busyRequisitoId = 'carta_inscripcion');
    try {
      debugPrint('📝 Iniciando generación de carta de inscripción...');
      
      final personalData = await LocalStorageService.getPersonalData();
      debugPrint('📋 Datos personales obtenidos: ${personalData?.keys.toList()}');
      
      var nombreCompleto =
          '${personalData?['nombre'] ?? ''} ${personalData?['apPaterno'] ?? ''} ${personalData?['apMaterno'] ?? ''}'
              .trim();
      if (nombreCompleto.isEmpty) {
        final session = await LocalStorageService.getSessionData();
        nombreCompleto = (session?['nombreUsuario'] as String?)?.trim() ?? '';
        debugPrint('📋 Nombre obtenido de sesión: $nombreCompleto');
      } else {
        debugPrint('📋 Nombre completo: $nombreCompleto');
      }
      
      final numeroCI = (personalData?['numeroCI'] ?? '').toString().trim();
      debugPrint('📋 Número CI: ${numeroCI.isEmpty ? "VACÍO" : numeroCI}');
      
      if (numeroCI.isEmpty || nombreCompleto.isEmpty) {
        debugPrint('⚠️ Datos faltantes - CI: ${numeroCI.isEmpty}, Nombre: ${nombreCompleto.isEmpty}');
        
        if (!mounted) return;
        final bool? irACompletar = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Datos faltantes'),
            content: const Text(
              'Para generar este documento necesitamos tu nombre completo y número de CI. ¿Deseas ir a completarlos ahora?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Después'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: _headerBlue, foregroundColor: Colors.white),
                child: const Text('Ir a completar'),
              ),
            ],
          ),
        );

        if (irACompletar == true && mounted) {
           await Navigator.push(
             context,
             MaterialPageRoute(builder: (context) => const MisDatosPersonalesScreen()),
           );
           _validarRequisitos(); // Re-validar al volver
        }
        return;
      }
      
      final expedidoEn = (personalData?['expedidoEn'] ?? '').toString().trim();
      final nombrePrograma = widget.nombrePrograma.isNotEmpty
          ? widget.nombrePrograma
          : (personalData?['nombreProgramaCarta'] ??
                    'Formulación y Evaluación de Proyectos')
                .toString();
      final modalidad = widget.modalidad.isNotEmpty
          ? widget.modalidad
          : (personalData?['modalidadProgramaCarta'] ?? 'Virtual')
                .toString()
                .trim();
      
      debugPrint('📋 Programa: $nombrePrograma');
      debugPrint('📋 Modalidad: $modalidad');
      debugPrint('📋 Expedido en: ${expedidoEn.isEmpty ? "NO ESPECIFICADO" : expedidoEn}');
      
      final numeroRef = DateTime.now().millisecondsSinceEpoch % 10000;
      
      // Obtener la ruta de la firma digital
      final firmaPath = await LocalStorageService.getSignatureImagePath();
      debugPrint('✍️ Firma digital: ${firmaPath != null ? "Configurada" : "No configurada"}');
      
      final generador = ServicioGeneradorCartaInscripcion();
      
      debugPrint('🔄 Generando carta con ServicioGeneradorCartaInscripcion...');
      final ruta = await generador.generarCarta(
        tipoPrograma: _getTipoProgramaEnum(),
        nombrePrograma: nombrePrograma,
        modalidad: modalidad,
        nombreCompleto: nombreCompleto,
        numeroCI: (personalData?['numeroCI'] ?? '').toString().trim(),
        expedidoEn: expedidoEn.isEmpty ? null : expedidoEn,
        montoDeposito: '2400',
        numeroRef: '$numeroRef',
        signatureImagePath: firmaPath, // ✅ Pasar la firma
        guardarEnPreferencias: false,
      );
      
      debugPrint('✅ Carta generada en: $ruta');
      
      await _saveDocPath('carta_inscripcion_path', ruta);
      debugPrint('✅ Ruta guardada en LocalStorage');
      
      if (!mounted) return;
      _mostrarMensaje('Carta de inscripción generada');
      
      debugPrint('🔄 Re-validando requisitos...');
      await _validarRequisitos();
      debugPrint('✅ Validación completada');
      
    } catch (e, stackTrace) {
      debugPrint('❌ Error al generar carta: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      _mostrarError('Error al generar carta: $e');
    } finally {
      if (mounted) setState(() => _busyRequisitoId = null);
    }
  }

  Future<void> _generarFichaInscripcion() async {
    setState(() => _busyRequisitoId = 'ficha_inscripcion');
    try {
      final personalData = await LocalStorageService.getPersonalData();
      final participantDocs = await LocalStorageService.getParticipantDocumentsData();
      
      final nombreCompleto =
          '${personalData?['nombre'] ?? ''} ${personalData?['apPaterno'] ?? ''} ${personalData?['apMaterno'] ?? ''}'
              .trim();
      final numeroCI = (personalData?['numeroCI'] ?? '').toString().trim();
      final email = (personalData?['email'] ?? '').toString().trim();
      final telefono = (personalData?['telefono'] ?? '').toString().trim();
      final fechaNac = (personalData?['fechaNacimiento'] ?? '').toString().trim();
      final domicilio = (personalData?['domicilio'] ?? '').toString().trim();
      final ocupacion = (personalData?['ocupacion'] ?? '').toString().trim();
      final lugarTrabajo = (personalData?['lugarTrabajo'] ?? '').toString().trim();
      final institucion = (personalData?['institucion'] ?? '').toString().trim();
      final cargoActual = (personalData?['cargoActual'] ?? '').toString().trim();
      final vigencia = (personalData?['vigencia'] ?? '').toString().trim();
      final localidad = (personalData?['localidad'] ?? '').toString().trim();
      final provincia = (personalData?['provincia'] ?? '').toString().trim();
      final departamento = (personalData?['departamento'] ?? '').toString().trim();
      
      // Formación académica
      final licenciatura = (personalData?['licenciatura'] ?? '').toString().trim();
      final institucionLic = (personalData?['institucionLicenciatura'] ?? '').toString().trim();
      final anoExpedicion = (personalData?['anoExpedicionTitulo'] ?? '').toString().trim();
      final nroRegistro = (personalData?['numeroRegistroTitulo'] ?? '').toString().trim();
      final profesion = (personalData?['profesion'] ?? '').toString().trim();
      final areaEspecializacion = (personalData?['areaEspecializacion'] ?? '').toString().trim();
      
      // Foto de perfil en base64
      String fotoBase64 = '';
      final profilePhotoPath = participantDocs?['profile_photo_path'] as String?;
      if (profilePhotoPath != null && profilePhotoPath.isNotEmpty) {
        try {
          final photoFile = File(profilePhotoPath);
          if (await photoFile.exists()) {
            final bytes = await photoFile.readAsBytes();
            fotoBase64 = base64Encode(bytes);
          }
        } catch (e) {
          debugPrint('Error cargando foto: $e');
        }
      }
      
      final now = DateTime.now();
      final fechaStr = '${now.day} de ${_getMesEspanol(now.month)} de ${now.year}';
      
      final html = '''
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Ficha de Inscripción</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: Arial, sans-serif;
            background-color: #f5f5f5;
            padding: 16px;
        }
        
        .ficha {
            background: white;
            max-width: 800px;
            margin: 0 auto;
            padding: 40px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        
        @media (max-width: 768px) {
            .ficha {
                padding: 20px;
            }
        }
        
        .header {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            margin-bottom: 20px;
            border-bottom: 3px solid #005BAC;
            padding-bottom: 15px;
        }
        
        .header-left {
            flex: 1;
        }
        
        .universidad {
            font-size: 16px;
            font-style: italic;
            color: #005BAC;
            margin-bottom: 5px;
        }
        
        .direccion {
            font-size: 12px;
            color: #666;
        }
        
        .titulo-ficha {
            font-size: 24px;
            font-weight: bold;
            text-align: center;
            color: #005BAC;
            margin: 20px 0;
            text-transform: uppercase;
        }
        
        .foto-container {
            display: flex;
            justify-content: space-between;
            margin-bottom: 20px;
        }
        
        .foto {
            width: 120px;
            height: 150px;
            border: 2px solid #005BAC;
            background: #f0f0f0;
            display: flex;
            align-items: center;
            justify-content: center;
            overflow: hidden;
        }
        
        .foto img {
            width: 100%;
            height: 100%;
            object-fit: cover;
        }
        
        .info-programa {
            flex: 1;
            margin-left: 20px;
        }
        
        .info-row {
            margin-bottom: 8px;
            font-size: 14px;
        }
        
        .info-label {
            font-weight: bold;
            display: inline-block;
            min-width: 120px;
        }
        
        .seccion {
            margin: 20px 0;
        }
        
        .seccion-titulo {
            background: #005BAC;
            color: white;
            padding: 8px 12px;
            font-weight: bold;
            font-size: 14px;
            text-transform: uppercase;
            margin-bottom: 10px;
        }
        
        .campo {
            display: flex;
            margin-bottom: 10px;
            font-size: 13px;
        }
        
        .campo-label {
            font-weight: bold;
            min-width: 180px;
            color: #333;
        }
        
        .campo-valor {
            flex: 1;
            color: #000;
            border-bottom: 1px solid #ddd;
            padding-bottom: 2px;
        }
        
        .checkbox-group {
            display: flex;
            gap: 20px;
            margin: 10px 0;
        }
        
        .checkbox-item {
            display: flex;
            align-items: center;
            gap: 5px;
        }
        
        .checkbox {
            width: 16px;
            height: 16px;
            border: 2px solid #005BAC;
            display: inline-block;
        }
        
        .checkbox.checked::after {
            content: '✓';
            color: #005BAC;
            font-weight: bold;
            display: block;
            text-align: center;
            line-height: 12px;
        }
        
        .firma-section {
            margin-top: 40px;
            text-align: center;
        }
        
        .firma-linea {
            border-top: 1px solid #000;
            width: 250px;
            margin: 60px auto 10px;
        }
        
        .firma-texto {
            font-size: 12px;
            font-weight: bold;
        }
        
        .footer {
            margin-top: 30px;
            padding-top: 15px;
            border-top: 1px solid #ddd;
            display: flex;
            justify-content: space-between;
            font-size: 11px;
            color: #666;
        }
        
        .sello {
            text-align: right;
            font-size: 12px;
        }
        
        .sello-box {
            border: 2px solid #005BAC;
            border-radius: 50%;
            width: 80px;
            height: 80px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            margin-top: 10px;
        }
    </style>
</head>
<body>
    <div class="ficha">
        <div class="header">
            <div class="header-left">
                <div class="universidad">Universidad Pública de El Alto</div>
                <div class="direccion">DIRECCIÓN DE POSGRADO</div>
            </div>
            <div style="text-align: right;">
                <div style="font-weight: bold; color: #005BAC; font-size: 18px;">Posgrado</div>
            </div>
        </div>
        
        <div class="titulo-ficha">FICHA DE INSCRIPCIÓN</div>
        
        <div class="foto-container">
            <div class="foto">
                ${fotoBase64.isNotEmpty ? '<img src="data:image/jpeg;base64,$fotoBase64" alt="Foto">' : ''}
            </div>
            <div class="info-programa">
                <div class="info-row">
                    <span class="info-label">Curso/Programa:</span> ${widget.tipoPrograma}
                </div>
                <div class="info-row">
                    <span class="info-label">N° de Matrícula:</span> __________________
                </div>
                <div class="info-row">
                    <span class="info-label">Versión:</span> __________________
                </div>
            </div>
            <div class="foto">
                ${fotoBase64.isNotEmpty ? '<img src="data:image/jpeg;base64,$fotoBase64" alt="Foto">' : ''}
            </div>
        </div>
        
        <div class="seccion">
            <div class="seccion-titulo">DATOS PERSONALES</div>
            <div class="campo">
                <div class="campo-label">NOMBRE(S):</div>
                <div class="campo-valor">${personalData?['nombre'] ?? ''}</div>
            </div>
            <div class="campo">
                <div class="campo-label">APELLIDO PATERNO:</div>
                <div class="campo-valor">${personalData?['apPaterno'] ?? ''}</div>
            </div>
            <div class="campo">
                <div class="campo-label">APELLIDO MATERNO:</div>
                <div class="campo-valor">${personalData?['apMaterno'] ?? ''}</div>
            </div>
            <div class="campo">
                <div class="campo-label">FECHA NAC:</div>
                <div class="campo-valor">$fechaNac</div>
            </div>
            <div class="campo">
                <div class="campo-label">C.I.:</div>
                <div class="campo-valor">$numeroCI</div>
            </div>
            <div class="campo">
                <div class="campo-label">EXPEDIDO:</div>
                <div class="campo-valor">${personalData?['expedidoEn'] ?? ''}</div>
            </div>
            <div class="campo">
                <div class="campo-label">DOMICILIO ACTUAL:</div>
                <div class="campo-valor">$domicilio</div>
            </div>
            <div class="campo">
                <div class="campo-label">Teléf/Cel:</div>
                <div class="campo-valor">$telefono</div>
            </div>
            <div class="campo">
                <div class="campo-label">OCUPACIÓN:</div>
                <div class="campo-valor">$ocupacion</div>
            </div>
            <div class="campo">
                <div class="campo-label">DIRECCIÓN Y TELÉFONO DE LUGAR DE TRABAJO:</div>
                <div class="campo-valor">$lugarTrabajo</div>
            </div>
        </div>
        
        <div class="seccion">
            <div class="seccion-titulo">FORMACIÓN ACADÉMICA:</div>
            <div class="checkbox-group">
                <div class="checkbox-item">
                    <span class="checkbox ${licenciatura.toLowerCase().contains('licenciatura') ? 'checked' : ''}"></span>
                    <span>LICENCIATURA</span>
                </div>
                <div class="checkbox-item">
                    <span class="checkbox"></span>
                    <span>MAESTRÍA</span>
                </div>
                <div class="checkbox-item">
                    <span class="checkbox"></span>
                    <span>DOCTORADO</span>
                </div>
                <div class="checkbox-item">
                    <span class="checkbox"></span>
                    <span>OTROS</span>
                </div>
            </div>
            <div class="campo">
                <div class="campo-label">INSTITUCIÓN:</div>
                <div class="campo-valor">$institucionLic</div>
            </div>
            <div class="campo">
                <div class="campo-label">AÑO DE EXPEDICIÓN DEL TÍTULO:</div>
                <div class="campo-valor">$anoExpedicion</div>
            </div>
            <div class="campo">
                <div class="campo-label">N° REGISTRO:</div>
                <div class="campo-valor">$nroRegistro</div>
            </div>
            <div class="campo">
                <div class="campo-label">PROFESIÓN:</div>
                <div class="campo-valor">$profesion</div>
            </div>
            <div class="campo">
                <div class="campo-label">ÁREA DE ESPECIALIZACIÓN:</div>
                <div class="campo-valor">$areaEspecializacion</div>
            </div>
        </div>
        
        <div class="seccion">
            <div class="seccion-titulo">INFORMACIÓN ADICIONAL</div>
            <div class="campo">
                <div class="campo-label">INSTITUCIÓN U ORGANIZACIÓN A LA QUE PERTENECE:</div>
                <div class="campo-valor">$institucion</div>
            </div>
            <div class="campo">
                <div class="campo-label">CARGO ACTUAL:</div>
                <div class="campo-valor">$cargoActual</div>
            </div>
            <div class="campo">
                <div class="campo-label">VIGENCIA:</div>
                <div class="campo-valor">$vigencia</div>
            </div>
            <div class="campo">
                <div class="campo-label" style="min-width: 100%;">LUGAR DONDE OCUPA EL CARGO:</div>
            </div>
            <div class="campo">
                <div class="campo-label">LOCALIDAD:</div>
                <div class="campo-valor">$localidad</div>
            </div>
            <div class="campo">
                <div class="campo-label">PROVINCIA:</div>
                <div class="campo-valor">$provincia</div>
            </div>
            <div class="campo">
                <div class="campo-label">DEPARTAMENTO:</div>
                <div class="campo-valor">$departamento</div>
            </div>
        </div>
        
        <div class="firma-section">
            <div style="text-align: left; margin-bottom: 10px;">
                El Alto, $fechaStr
            </div>
            <div class="firma-linea"></div>
            <div class="firma-texto">Firma Participante</div>
            <div style="margin-top: 40px; text-align: right;">
                <div class="firma-linea" style="margin: 0 0 10px auto;"></div>
                <div class="firma-texto">Firma Encargado de Archivo</div>
            </div>
        </div>
        
        <div class="footer">
            <div>
                <div style="font-weight: bold;">Formulario N° 01</div>
                <div style="margin-top: 5px;">SERIE "B"</div>
            </div>
            <div class="sello">
                <div class="sello-box">
                    <span style="font-weight: bold; color: #005BAC;">Bs.- 5</span>
                </div>
            </div>
        </div>
    </div>
</body>
</html>''';
      
      final dir = await getApplicationDocumentsDirectory();
      final fichaDir = Directory('${dir.path}/fichas_inscripcion');
      if (!await fichaDir.exists()) await fichaDir.create(recursive: true);
      final file = File(
        '${fichaDir.path}/ficha_${numeroCI}_${now.millisecondsSinceEpoch}.html',
      );
      await file.writeAsString(html);
      await _saveDocPath('ficha_inscripcion_path', file.path);
      if (!mounted) return;
      _mostrarMensaje('Ficha de inscripción generada');
      _validarRequisitos();
    } catch (e) {
      _mostrarError('Error al generar ficha: $e');
    } finally {
      if (mounted) setState(() => _busyRequisitoId = null);
    }
  }
  
  String _getMesEspanol(int mes) {
    const meses = [
      '', 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return meses[mes];
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(mensaje, style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor: DesignTokens.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _mostrarDialogoComprobantePago() async {
    if (!mounted) return;
    
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Título
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _headerBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: _headerBlue,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subir Comprobante',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A3A5C),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Selecciona el tipo de pago',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Opciones de pago
            _buildPaymentOption(
              context: context,
              icon: Icons.school_rounded,
              title: 'Matrícula',
              subtitle: 'Comprobante de pago de matrícula',
              color: const Color(0xFF2196F3),
              onTap: () {
                Navigator.pop(context);
                _pickFileAndSave(
                  key: 'comprobante_matricula_path',
                  prefix: 'pago_matricula',
                );
              },
            ),
            
            const SizedBox(height: 12),
            
            _buildPaymentOption(
              context: context,
              icon: Icons.payment_rounded,
              title: 'Colegiatura',
              subtitle: 'Comprobante de pago de colegiatura',
              color: const Color(0xFF4CAF50),
              onTap: () {
                Navigator.pop(context);
                _pickFileAndSave(
                  key: 'comprobante_colegiatura_path',
                  prefix: 'pago_colegiatura',
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Botón cancelar
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3A5C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFileAndSave({
    required String key,
    required String prefix,
  }) async {
    setState(() => _busyRequisitoId = key);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
      );
      if (result == null || result.files.single.path == null) return;
      final originalPath = result.files.single.path!;
      final copied = await _copyToParticipantDocs(originalPath, prefix);
      await _saveDocPath(key, copied.path);
      if (!mounted) return;
      _mostrarMensaje('Documento subido correctamente');
      _validarRequisitos();
    } catch (e) {
      _mostrarError('Error al subir archivo: $e');
    } finally {
      if (mounted) setState(() => _busyRequisitoId = null);
    }
  }

  Future<void> _previewDocumento(String requisitoId) async {
    try {
      final docs =
          await LocalStorageService.getParticipantDocumentsData() ??
          <String, dynamic>{};
      String? key;
      String titulo = _getTituloRequisito(_resultado!.resultados.firstWhere((r) => r.requisito.id == requisitoId).requisito);

      switch (requisitoId) {
        case 'fotografias':
          // Para fotografías, buscar la foto de perfil
          key = 'profile_photo_path';
          break;
        case 'ficha_inscripcion':
        case 'formularios':
          key = 'ficha_inscripcion_path';
          break;
        case 'carta_inscripcion':
          key = 'carta_inscripcion_path';
          break;
        case 'ci_fotocopias':
          key = 'ci_photocopy_pdf_path';
          if (docs[key] == null) key = 'ci_letter_path';
          break;
        case 'hoja_vida':
          key = 'hoja_vida_path';
          break;
        case 'titulo_academico':
          key = 'titulo_path';
          if (docs[key] == null) key = 'prorroga_path';
          break;
        case 'pago_matricula':
          key = 'comprobante_matricula_path';
          if (docs[key] == null) key = 'comprobante_colegiatura_path';
          break;
        default:
          key = _resultado!.resultados.firstWhere((r) => r.requisito.id == requisitoId).requisito.campoDocumento;
      }

      if (key == null) {
        debugPrint('❌ No se encontró key para requisito: $requisitoId');
        _mostrarError('No se pudo determinar el documento para este requisito.');
        return;
      }
      
      final raw = docs[key];
      final path = raw?.toString().trim();
      
      debugPrint('📄 Intentando previsualizar documento:');
      debugPrint('   Requisito: $requisitoId');
      debugPrint('   Key: $key');
      debugPrint('   Path: $path');
      
      if (path == null || path.isEmpty) {
        debugPrint('❌ Path vacío o nulo para key: $key');
        _mostrarError('No se encontró el documento para este requisito. Genera el documento primero.');
        return;
      }

      final file = File(path);
      if (!await file.exists()) {
        debugPrint('❌ El archivo no existe físicamente: $path');
        _mostrarError('El archivo no existe físicamente en el dispositivo. Intenta generarlo nuevamente.');
        return;
      }

      debugPrint('✅ Archivo encontrado, abriendo: $path');

      // Manejar diferentes tipos de archivos
      if (path.toLowerCase().endsWith('.html') || path.toLowerCase().endsWith('.htm')) {
        await _showHtmlPreview(titulo, path);
      } else if (path.toLowerCase().endsWith('.pdf')) {
        // Para PDFs (como fotocopia de CI), mostrar en WebView
        await _showPdfPreview(titulo, path);
      } else if (path.toLowerCase().endsWith('.jpg') || 
                 path.toLowerCase().endsWith('.jpeg') || 
                 path.toLowerCase().endsWith('.png')) {
        // Para imágenes (como fotografías), mostrar en visor de imágenes
        await _showImagePreview(titulo, path);
      } else {
        // Para otros archivos, abrir con app externa
        await OpenFilex.open(path);
      }
    } catch (e) {
      debugPrint('❌ Error al previsualizar documento: $e');
      _mostrarError('No se pudo abrir el documento: $e');
    }
  }

  Future<void> _generarFotocopiaCIPDF() async {
    setState(() => _busyRequisitoId = 'ci_fotocopias');
    try {
      final docs = await LocalStorageService.getParticipantDocumentsData();
      final front = docs?['ci_front_path'] as String?;
      final back = docs?['ci_back_path'] as String?;
      
      if (front == null || back == null) {
        _mostrarError('Faltan capturas de anverso o reverso.');
        return;
      }

      // Verificar que los archivos existen físicamente
      if (!await File(front).exists() || !await File(back).exists()) {
        _mostrarError('Los archivos de CI no existen en el dispositivo.');
        return;
      }

      final pdfPath = await CarnetPhotocopyService.generatePdf(
        frontFile: File(front),
        backFile: File(back),
      );

      if (pdfPath != null) {
        final current = await LocalStorageService.getParticipantDocumentsData() ?? {};
        current['ci_photocopy_pdf_path'] = pdfPath;
        await LocalStorageService.saveParticipantDocumentsData(current);
        
        if (!mounted) return;
        _mostrarMensaje('Fotocopia PDF generada correctamente');
        
        // Revalidar para actualizar el estado de los requisitos
        await _validarRequisitos();
        
        debugPrint('✅ Fotocopia CI PDF guardada en: $pdfPath');
      } else {
        _mostrarError('No se pudo generar el PDF de la fotocopia.');
      }
    } catch (e) {
      debugPrint('❌ Error al generar PDF de fotocopia CI: $e');
      _mostrarError('Error al generar PDF: $e');
    } finally {
      if (mounted) {
        setState(() => _busyRequisitoId = null);
      }
    }
  }

  Future<File> _copyWithNewExtension(
    String originalPath,
    String newExtension,
    String folderName,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final outDir = Directory(
      '${dir.path}${Platform.pathSeparator}$folderName',
    );
    if (!await outDir.exists()) {
      await outDir.create(recursive: true);
    }

    final sep = Platform.pathSeparator;
    final fileName = originalPath.split(sep).last;
    final dotIndex = fileName.lastIndexOf('.');
    final baseName =
        dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;

    final outPath =
        '${outDir.path}${Platform.pathSeparator}$baseName.$newExtension';
    return File(originalPath).copy(outPath);
  }

  Future<void> _exportHtmlToWord(String htmlPath) async {
    try {
      final file = File(htmlPath);
      if (!await file.exists()) {
        _mostrarError('El archivo no existe en el dispositivo.');
        return;
      }
      // Intentar abrir directamente el HTML con la app predeterminada (Word lo abre)
      final result = await OpenFilex.open(htmlPath);
      if (result.type != ResultType.done) {
        // Fallback: intentar con url_launcher
        final uri = Uri.file(htmlPath);
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched && mounted) {
          _mostrarError(
            'No se encontró una aplicación para abrir el documento.\n'
            'Instala Microsoft Word o WPS Office e intenta de nuevo.',
          );
        }
      }
    } catch (e) {
      _mostrarError(
        'No se pudo abrir el documento.\n'
        'Asegúrate de tener Word o WPS Office instalado.\n'
        'Detalle: $e',
      );
    }
  }

  Future<void> _exportHtmlToPdf(String htmlPath, String titulo) async {
    try {
      final file = File(htmlPath);
      if (!await file.exists()) {
        _mostrarError('El archivo no existe.');
        return;
      }
      final html = await file.readAsString();

      // Usar printing para generar PDF real desde HTML preservando el diseño
      await Printing.layoutPdf(
        onLayout: (format) async => await Printing.convertHtml(
          format: format,
          html: html,
        ),
        name: titulo,
      );
    } catch (e) {
      _mostrarError('No se pudo exportar a PDF: $e');
    }
  }

  Future<void> _showHtmlPreview(String titulo, String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        _mostrarError('El archivo generado ya no existe en el dispositivo.');
        return;
      }

      final html = await file.readAsString();

      // Texto plano solo para exportar a PDF (se mantiene la lógica anterior)
      var cleanHtml = html
          .replaceAll(
              RegExp(r'<style[\s\S]*?</style>', caseSensitive: false), '')
          .replaceAll(
              RegExp(r'<script[\s\S]*?</script>', caseSensitive: false), '')
          .replaceAll(
              RegExp(r'<head[\s\S]*?</head>', caseSensitive: false), '');
      var text = cleanHtml
          .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
          .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
          .replaceAll(RegExp(r'</h[1-6]>', caseSensitive: false), '\n\n')
          .replaceAll(RegExp(r'</li>', caseSensitive: false), '\n')
          .replaceAll(RegExp(r'</tr>', caseSensitive: false), '\n')
          .replaceAll(RegExp(r'</td>', caseSensitive: false), '  ')
          .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '• ')
          .replaceAll(RegExp(r'<[^>]+>'), '')
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&amp;', '&')
          .replaceAll('&quot;', '"')
          .replaceAll('&#39;', "'")
          .replaceAll(RegExp(r'[ \t]+\n'), '\n')
          .replaceAll(RegExp(r'\n{3,}'), '\n\n')
          .trim();
      if (text.isEmpty) text = html;

      if (!mounted) return;

      // Vista previa con WebView: respeta izquierda, centro y derecha como la carta
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) {
            // Ancho fijo tipo hoja A4 (595pt) para que el HTML se renderice igual que en Word
            // Ancho fijo tipo hoja CARTA (612pt) para que el HTML se renderice igual que en Word
            const pageWidth = 612.0;
            const pageHeight = 792.0; // Letter

            // Fijar ancho de la página en el HTML para que se vea igual que en Word
            // Usar regex para asegurar que el reemplazo sea robusto
            final viewportRegex = RegExp(r'''<meta\s+name=["\']viewport["\']\s+content=["\'][^"\']*["\']\s*/?>''', caseSensitive: false);
            final htmlConViewport = html.contains(viewportRegex) 
                ? html.replaceFirst(viewportRegex, '<meta name="viewport" content="width=612, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">')
                : html.replaceFirst('<head>', '<head><meta name="viewport" content="width=612, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">');

            final controller = WebViewController()
              ..setJavaScriptMode(JavaScriptMode.unrestricted)
              ..setBackgroundColor(Colors.transparent)
              ..loadHtmlString(htmlConViewport, baseUrl: null);

            return Scaffold(
              appBar: AppBar(
                backgroundColor: _headerBlue,
                title: Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              body: Container(
                color: const Color(0xFFE5E5E5),
                child: SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final w = constraints.maxWidth;
                      final h = constraints.maxHeight;
                      final scale = (w / pageWidth) < (h / pageHeight)
                          ? (w / pageWidth) * 0.85
                          : (h / pageHeight) * 0.85;
                      final scaledW = pageWidth * scale;
                      final scaledH = pageHeight * scale;

                      return InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 3.0,
                        boundaryMargin: const EdgeInsets.all(100),
                        child: Center(
                          child: Container(
                            width: scaledW,
                            height: scaledH,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade300, width: 0.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRect(
                              child: FittedBox(
                                fit: BoxFit.contain,
                                alignment: Alignment.topCenter,
                                child: SizedBox(
                                  width: pageWidth,
                                  height: pageHeight,
                                  child: WebViewWidget(controller: controller),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              floatingActionButton: FloatingActionButton.extended(
                heroTag: 'preview_export_$titulo',
                onPressed: () async {
                  await showModalBottomSheet<void>(
                    context: ctx,
                    builder: (bottomCtx) {
                      return SafeArea(
                        child: Wrap(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.description_outlined),
                              title: const Text('Abrir en Word'),
                              onTap: () {
                                Navigator.of(bottomCtx).pop();
                                _exportHtmlToWord(path);
                              },
                            ),
                              ListTile(
                                leading:
                                    const Icon(Icons.picture_as_pdf_outlined),
                                title: const Text('Exportar a PDF'),
                                onTap: () {
                                  Navigator.of(bottomCtx).pop();
                                  _exportHtmlToPdf(path, titulo);
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
                icon: const Icon(Icons.download),
                label: const Text('Descargar'),
                backgroundColor: _headerBlue,
              ),
            );
          },
        ),
      );
    } catch (e) {
      _mostrarError('No se pudo mostrar la vista previa: $e');
    }
  }

  // Método para mostrar vista previa de imágenes (fotografías)
  Future<void> _showImagePreview(String titulo, String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        _mostrarError('La imagen no existe en el dispositivo.');
        return;
      }

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) {
            return Scaffold(
              backgroundColor: const Color(0xFF0F172A),
              appBar: AppBar(
                backgroundColor: _headerBlue,
                title: Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              body: Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Image.file(
                      file,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    } catch (e) {
      _mostrarError('No se pudo mostrar la imagen: $e');
    }
  }

  // Método para mostrar vista previa de PDFs (fotocopia CI)
  Future<void> _showPdfPreview(String titulo, String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        _mostrarError('El PDF no existe en el dispositivo.');
        return;
      }

      if (!mounted) return;

      // WebView no puede mostrar PDFs nativamente en Android
      // Usar OpenFilex para abrir con visor de PDF del sistema
      debugPrint('📱 Abriendo PDF con visor del sistema: $path');
      
      final result = await OpenFilex.open(path);
      
      if (result.type != ResultType.done) {
        debugPrint('⚠️ No se pudo abrir el PDF: ${result.message}');
        
        // Mostrar diálogo con opciones
        if (!mounted) return;
        
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Visualizar PDF'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'No se pudo abrir el PDF automáticamente.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                Text(
                  'Ubicación del archivo:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    path,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[800],
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Puedes intentar abrirlo con otra aplicación o instalando un visor de PDF.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cerrar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  // Intentar abrir nuevamente
                  await OpenFilex.open(path);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _headerBlue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Intentar de nuevo'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error al mostrar PDF: $e');
      _mostrarError('No se pudo mostrar el PDF: $e');
    }
  }

  static const Color _headerBlue = Color(0xFF005BAC);
  static const Color _headerBlueDark = Color(0xFF003F7A);
  static const Color _background = Color(0xFFF0F4F8);

  IconData _getIconoTipoPrograma() {
    final t = widget.tipoPrograma.toUpperCase();
    if (t.contains('DOCTOR')) return Icons.workspace_premium_rounded;
    if (t.contains('MAESTR')) return Icons.school_rounded;
    if (t.contains('ESPECIALIDAD')) return Icons.military_tech_rounded;
    return Icons.menu_book_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _headerBlue,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Requisitos de Inscripción',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_cargando)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              tooltip: 'Actualizar',
              onPressed: _validarRequisitos,
            ),
        ],
      ),
      body: _cargando ? _buildLoading() : _buildContenido(),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(_headerBlue),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Verificando requisitos...',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildContenido() {
    if (_resultado == null) {
      return Center(
        child: Text(
          'No se pudo cargar la información',
          style: TextStyle(color: DesignTokens.primaryText),
        ),
      );
    }

    final todosCompletos = _resultado!.todosLosRequisitosObligatoriosCumplidos;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado del programa
          FadeInDown(child: _buildEncabezadoPrograma()),

          const SizedBox(height: 24),

          // ELIMINADO: Resumen de pasos del proceso (duplicado innecesario)
          // Los pasos ya se muestran en la pantalla de programas vigentes
          // FadeInUp(
          //   delay: const Duration(milliseconds: 50),
          //   child: _buildResumenPasos(),
          // ),

          // const SizedBox(height: 30),

          // Tarjeta de progreso
          FadeInUp(
            delay: const Duration(milliseconds: 100),
            child: _buildTarjetaProgreso(),
          ),

          const SizedBox(height: 30),

          // Consejo inteligente (Smart Advice)
          _buildSmartAdvice(),

          // Lista de requisitos
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: _buildListaRequisitos(),
          ),

          const SizedBox(height: 30),

          // Botones de acción
          FadeInUp(
            delay: const Duration(milliseconds: 300),
            child: _buildBotonesAccion(todosCompletos),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEncabezadoPrograma() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_headerBlue, _headerBlueDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: _headerBlue.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_getIconoTipoPrograma(), color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.tipoPrograma.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.nombrePrograma,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700, height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.modalidad,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Resumen visual de los 4 pasos del proceso de inscripción
  Widget _buildResumenPasos() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF005BAC).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.list_alt_rounded,
                  color: Color(0xFF005BAC),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Proceso de inscripción',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '4 pasos',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          
          // Paso 1: Datos personales
          _buildPasoCard(
            numero: 1,
            titulo: 'Datos personales',
            descripcion: 'Asegúrate de tener tu nombre completo, CI y datos de contacto actualizados en tu perfil.',
            icono: Icons.person_outline,
            color: const Color(0xFF4A90E2),
          ),
          
          const SizedBox(height: 12),
          
          // Paso 2: Documentos requeridos
          _buildPasoCard(
            numero: 2,
            titulo: 'Documentos requeridos',
            descripcion: 'Prepara tu título académico, hoja de vida y fotocopia de CI en formato PDF o imagen.',
            icono: Icons.description_outlined,
            color: const Color(0xFF9B59B6),
          ),
          
          const SizedBox(height: 12),
          
          // Paso 3: Carta de inscripción
          _buildPasoCard(
            numero: 3,
            titulo: 'Carta de inscripción',
            descripcion: 'La app generará automáticamente tu carta de solicitud de inscripción con tus datos.',
            icono: Icons.article_outlined,
            color: const Color(0xFF16A085),
          ),
          
          const SizedBox(height: 12),
          
          // Paso 4: Comprobante de pago
          _buildPasoCard(
            numero: 4,
            titulo: 'Comprobante de pago',
            descripcion: 'Sube el comprobante de depósito bancario de matrícula y colegiatura para completar tu inscripción.',
            icono: Icons.receipt_long_outlined,
            color: const Color(0xFFE67E22),
          ),
        ],
      ),
    );
  }

  Widget _buildPasoCard({
    required int numero,
    required String titulo,
    required String descripcion,
    required IconData icono,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icono,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Paso $numero',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '·',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        titulo,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: color.withOpacity(0.9),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  descripcion,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaProgreso() {
    final porcentaje = _resultado!.porcentajeCompletitudObligatorios;
    final completados = _resultado!.resultados
        .where((r) => r.requisito.esObligatorio && r.estaCumplido)
        .length;
    final total = _resultado!.resultados
        .where((r) => r.requisito.esObligatorio)
        .length;
    final conProrroga = _resultado!.resultados
        .where((r) => r.estado == EstadoRequisito.conProrroga)
        .length;
    final pendientes = total - completados - conProrroga;
    final isComplete = porcentaje >= 100;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: porcentaje / 100,
                      strokeWidth: 7,
                      backgroundColor: Colors.grey.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isComplete ? DesignTokens.successGreen : _headerBlue,
                      ),
                    ),
                    Center(
                      child: Text(
                        '${porcentaje.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isComplete ? DesignTokens.successGreen : _headerBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isComplete ? '¡Listo para inscribirse!' : 'Progreso de requisitos',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isComplete ? DesignTokens.successGreen : DesignTokens.primaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildChipEstado('$completados OK', DesignTokens.successGreen),
                        const SizedBox(width: 6),
                        if (conProrroga > 0) ...[
                          _buildChipEstado('$conProrroga Prórroga', DesignTokens.warningOrange),
                          const SizedBox(width: 6),
                        ],
                        if (pendientes > 0)
                          _buildChipEstado('$pendientes Pend.', Colors.red.shade400),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: porcentaje / 100,
              minHeight: 8,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(
                isComplete ? DesignTokens.successGreen : _headerBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartAdvice() {
    if (_resultado == null) return const SizedBox.shrink();
    
    final faltantes = _resultado!.resultados.where((r) => r.requisito.esObligatorio && !r.estaCumplido).length;
    if (faltantes == 0) return const SizedBox.shrink();

    String consejo = '';
    IconData icono = Icons.lightbulb_outline_rounded;
    Color colorBase = Colors.amber;
    
    if (_puedeAutoCompletar) {
      consejo = 'He notado que tenemos tus datos básicos. Pulsa "Recuperar y Generar" arriba para ahorrar tiempo.';
      icono = Icons.auto_awesome_rounded;
      colorBase = Colors.blue;
    } else if (faltantes > 5) {
      consejo = '¡Bienvenido! Te sugiero comenzar escaneando tu Cédula de Identidad en "Mis Documentos".';
    } else if (faltantes == 1) {
      final req = _resultado!.resultados.firstWhere((r) => r.requisito.esObligatorio && !r.estaCumplido);
      final id = req.requisito.id;
      if (id == "pago_matricula") {
        consejo = '¡Ya casi terminas! Solo falta adjuntar el comprobante de tu depósito bancario.';
      } else {
        consejo = '¡Sigue así! Solo te falta completar un último requisito obligatorio.';
      }
      colorBase = Colors.green;
      icono = Icons.stars_rounded;
    } else {
      consejo = 'Consejo: Si no tienes tu título físico, puedes generar una carta de prórroga al instante.';
    }

    return FadeInRight(
      delay: const Duration(milliseconds: 150),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorBase.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorBase.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icono, color: colorBase, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                consejo,
                style: TextStyle(
                  color: colorBase, 
                  fontSize: 13, 
                  height: 1.4, 
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Intel',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChipEstado(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildListaRequisitos() {
    final obligatorios = _resultado!.resultados
        .where((r) => r.requisito.esObligatorio)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.checklist_rounded, size: 20, color: Color(0xFF005BAC)),
            const SizedBox(width: 8),
            Text(
              'Requisitos Obligatorios',
              style: TextStyle(
                color: DesignTokens.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            // Botón oculto - ahora se ejecuta automáticamente
            // if (_puedeAutoCompletar) ...[
            //   const Spacer(),
            //   TextButton.icon(...)
            // ],
          ],
        ),
        const SizedBox(height: 14),
        ...obligatorios.asMap().entries.map((entry) {
          final index = entry.key;
          return FadeInLeft(
            delay: Duration(milliseconds: 100 * index),
            duration: const Duration(milliseconds: 500),
            child: _buildRequisitoItem(entry.value, index + 1),
          );
        }),
      ],
    );
  }

  IconData _getIconoRequisito(String id) {
    switch (id) {
      case 'fotografias': return Icons.photo_camera_rounded;
      case 'pago_matricula': return Icons.receipt_long_rounded;
      case 'ficha_inscripcion':
      case 'formularios': return Icons.assignment_rounded;
      case 'ci_fotocopias': return Icons.badge_rounded;
      case 'titulo_academico': return Icons.school_rounded;
      case 'carta_inscripcion': return Icons.description_rounded;
      case 'hoja_vida': return Icons.person_pin_rounded;
      default: return Icons.task_alt_rounded;
    }
  }

  Widget _buildRequisitoItem(ResultadoValidacionRequisito resultado, int index) {
    final color = _getColorEstado(resultado.estado);
    final textoEstado = _getTextoEstado(resultado.estado);
    final isCompleto = resultado.estado == EstadoRequisito.completado;
    final isProrroga = resultado.estado == EstadoRequisito.conProrroga;
    final isPending = resultado.estado == EstadoRequisito.pendiente;
    final isFoto = resultado.requisito.id == 'fotografias';
    final isTitulo = resultado.requisito.id == 'titulo_academico';

    final isBusy = _busyRequisitoId != null;
    final icono = _getIconoRequisito(resultado.requisito.id);
    final isPiecesReady = resultado.mensaje?.contains('PIECES_READY') ?? false;

    // Quitar el prefijo técnico del mensaje para mostrarlo al usuario
    final displayMensaje = isPiecesReady 
        ? resultado.mensaje!.replaceAll('PIECES_READY: ', '') 
        : resultado.mensaje;

    final canPreviewAny = isCompleto || (isProrroga && resultado.requisito.id == 'titulo_academico');

    final hasAction = isPending &&
        (resultado.requisito.id == 'carta_inscripcion' ||
            resultado.requisito.id == 'ficha_inscripcion' ||
            resultado.requisito.id == 'formularios' ||
            resultado.requisito.id == 'hoja_vida' ||
            resultado.requisito.id == 'titulo_academico' ||
            resultado.requisito.id == 'pago_matricula' ||
            isFoto);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Línea de acento lateral
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 5,
                color: color,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fila superior: ícono + título + badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icono, color: color, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _getTituloRequisito(resultado.requisito),
                                    style: TextStyle(
                                      color: DesignTokens.primaryText,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _buildBadgeEstado(textoEstado, color, isCompleto, isProrroga),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              resultado.requisito.descripcion,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11.5,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Mensaje de estado
                    if (displayMensaje != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: isPiecesReady ? Colors.blue.withOpacity(0.1) : color.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              isCompleto ? Icons.check_circle_outline_rounded
                                  : isProrroga ? Icons.schedule_rounded
                                  : isPiecesReady ? Icons.auto_awesome_rounded : Icons.info_outline_rounded,
                              color: isPiecesReady ? Colors.blue : color,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                displayMensaje,
                                style: TextStyle(color: isPiecesReady ? Colors.blue : color, fontSize: 11.5, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  // Botones de acción
                  if (canPreviewAny || hasAction || (isTitulo && isPending) || isPiecesReady) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      alignment: WrapAlignment.end,
                      children: [
                        if (canPreviewAny)
                          _buildBotonAccion(
                            label: 'Ver documento',
                            icono: Icons.visibility_outlined,
                            color: _headerBlue,
                            outlined: true,
                            onTap: () => _previewDocumento(resultado.requisito.id),
                          ),
                        if (isPiecesReady)
                          _buildBotonAccion(
                            label: 'Integrar PDF',
                            icono: Icons.auto_awesome_rounded,
                            color: Colors.blue,
                            isBusy: isBusy && _busyRequisitoId == 'ci_fotocopias',
                            onTap: () => _generarFotocopiaCIPDF(),
                          ),
                        if (isFoto && isPending) ...[
                          _buildBotonAccion(
                            label: 'Ir a mi perfil',
                            icono: Icons.person_rounded,
                            color: const Color(0xFF7B1FA2),
                            onTap: _irADocumentosPersonales,
                          ),
                        ],
                        if (isTitulo && isPending) ...[
                          _buildBotonAccion(
                            label: 'Subir título',
                            icono: Icons.upload_file_rounded,
                            color: _headerBlue,
                            isBusy: isBusy && _busyRequisitoId == 'titulo_path',
                            onTap: () => _pickFileAndSave(key: 'titulo_path', prefix: 'titulo_prov_nacional'),
                          ),
                          _buildBotonAccion(
                            label: 'Solicitar prórroga',
                            icono: Icons.schedule_rounded,
                            color: DesignTokens.warningOrange,
                            isBusy: isBusy && _busyRequisitoId == 'prorroga_path',
                            onTap: _mostrarDialogoProrrogaTitulo,
                          ),
                        ],
                        if (hasAction && !isFoto && !isTitulo)
                          _buildBotonAccion(
                            label: _getLabelAccion(resultado.requisito.id),
                            icono: _getIconoAccion(resultado.requisito.id),
                            color: _headerBlue,
                            isBusy: isBusy && _busyRequisitoId == resultado.requisito.id,
                            onTap: isBusy ? null : () => _ejecutarAccionRequisito(resultado),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeEstado(String label, Color color, bool isCompleto, bool isProrroga) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCompleto ? Icons.check_rounded
                : isProrroga ? Icons.schedule_rounded
                : Icons.radio_button_unchecked_rounded,
            color: color,
            size: 11,
          ),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildBotonAccion({
    required String label,
    required IconData icono,
    required Color color,
    bool outlined = false,
    bool isBusy = false,
    VoidCallback? onTap,
  }) {
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icono, size: 14),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: isBusy ? null : onTap,
      icon: isBusy
          ? const SizedBox(width: 13, height: 13, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Icon(icono, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey.shade300,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
    );
  }


  IconData _getIconoAccion(String requisitoId) {
    switch (requisitoId) {
      case 'carta_inscripcion': return Icons.description_outlined;
      case 'ficha_inscripcion':
      case 'formularios': return Icons.article_outlined;
      case 'hoja_vida': return Icons.upload_file_outlined;
      case 'titulo_academico': return Icons.school_outlined;
      case 'pago_matricula': return Icons.receipt_long_outlined;
      default: return Icons.add;
    }
  }

  String _getLabelAccion(String requisitoId) {
    switch (requisitoId) {
      case 'carta_inscripcion': return 'Generar carta';
      case 'ficha_inscripcion':
      case 'formularios': return 'Generar ficha';
      case 'hoja_vida': return 'Subir hoja de vida';
      case 'titulo_academico': return 'Subir título';
      case 'pago_matricula': return 'Subir comprobante';
      default: return 'Completar';
    }
  }

  void _ejecutarAccionRequisito(ResultadoValidacionRequisito resultado) {
    final id = resultado.requisito.id;
    if (id == 'carta_inscripcion') {
      _generarCartaInscripcion();
    } else if (id == 'ficha_inscripcion' || id == 'formularios') {
      _generarFichaInscripcion();
    } else if (id == 'hoja_vida') {
      _pickFileAndSave(key: 'hoja_vida_path', prefix: 'hoja_vida');
    } else if (id == 'titulo_academico') {
      _pickFileAndSave(key: 'titulo_path', prefix: 'titulo_prov_nacional');
    } else if (id == 'pago_matricula') {
      _mostrarDialogoComprobantePago();
    }
  }


  Future<void> _mostrarDialogoProrrogaTitulo() async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.schedule_rounded, color: Color(0xFFE65100)),
            SizedBox(width: 8),
            Text('Solicitar Prórroga', style: TextStyle(fontSize: 17)),
          ],
        ),
        content: const Text(
          'Si aún no tienes tu título académico, puedes solicitar una prórroga. '
          'Se generará una carta de solicitud que deberás presentar en las oficinas de Posgrado.',
          style: TextStyle(fontSize: 13.5, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _pickFileAndSave(key: 'prorroga_path', prefix: 'prorroga_titulo');
            },
            icon: const Icon(Icons.upload_file_rounded, size: 16),
            label: const Text('Subir carta de prórroga'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE65100),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
//funcion que retorna el titulo del requisito
  String _getTituloRequisito(RequisitoInscripcion requisito) {
    switch (requisito.id) {
      case 'pago_matricula':
        return 'Comprobantes de Pago';
      case 'fotografias':
        return 'Fotografías';
      case 'formularios':
      case 'ficha_inscripcion':
        return 'Ficha de Inscripción';
      case 'ci_fotocopias':
        return 'Fotocopia de CI';
      case 'titulo_academico':
        return 'Título Académico';
      case 'carta_inscripcion':
        return 'Carta de Inscripción';
      case 'hoja_vida':
        return 'Hoja de Vida';
      default:
        return 'Requisito';
    }
  }
//funcion que retorna el icono del estado del requisito 
  IconData _getIconoEstado(EstadoRequisito estado) {
    switch (estado) {
      case EstadoRequisito.completado: return Icons.check_circle_rounded;
      case EstadoRequisito.conProrroga: return Icons.schedule_rounded;
      case EstadoRequisito.pendiente: return Icons.radio_button_unchecked_rounded;
      case EstadoRequisito.noAplica: return Icons.remove_circle_outline_rounded;
    }
  }
//funcion que retorna el color del estado del requisito
  Color _getColorEstado(EstadoRequisito estado) {
    switch (estado) {
      case EstadoRequisito.completado:
        return DesignTokens.successGreen;
      case EstadoRequisito.conProrroga:
        return DesignTokens.warningOrange;
      case EstadoRequisito.pendiente:
        return Colors.red;
      case EstadoRequisito.noAplica:
        return DesignTokens.secondaryText;
    }
  }
//funcion que retorna el texto del estado del requisito
  String _getTextoEstado(EstadoRequisito estado) {
    switch (estado) {
      case EstadoRequisito.completado:
        return 'Completo';
      case EstadoRequisito.conProrroga:
        return 'Prórroga';
      case EstadoRequisito.pendiente:
        return 'Pendiente';
      case EstadoRequisito.noAplica:
        return 'N/A';
    }
  }
//funcion que contrue el boton de accion cuando todos los requisitos estan completos
  Widget _buildBotonesAccion(bool todosCompletos) {
    return Column(
      children: [
        if (todosCompletos) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [DesignTokens.successGreen.withOpacity(0.1), DesignTokens.successGreen.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DesignTokens.successGreen.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: DesignTokens.successGreen, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('¡Todo listo!', style: TextStyle(color: DesignTokens.successGreen, fontWeight: FontWeight.w800, fontSize: 15)),
                      Text('Todos los requisitos están completos.', style: TextStyle(color: DesignTokens.successGreen.withOpacity(0.8), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () {
                widget.onRequisitosCompletos?.call();
                if (context.mounted) Navigator.pop(context, true);
              },
              icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
              label: const Text('Continuar con Inscripción', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.successGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
            ),
          ),
        ] else ...[
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _irADocumentosPersonales,
              icon: const Icon(Icons.folder_open_rounded, color: Colors.white),
              label: const Text('Ir a Mis Documentos', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _headerBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
