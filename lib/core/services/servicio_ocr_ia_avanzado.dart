import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Tipos de documentos que puede reconocer la IA
enum TipoDocumento {
  cedulaIdentidad,
  tituloAcademico,
  certificadoNacimiento,
  certificadoEstudios,
  cartaProrroga,
  otro,
}

/// Resultado del análisis OCR con IA
class ResultadoOcrIA {
  final TipoDocumento tipoDocumento;
  final double confianza; // 0.0 - 1.0
  final Map<String, CampoExtraido> campos;
  final List<String> advertencias;
  final List<String> sugerencias;
  final Map<String, dynamic> metadatos;

  ResultadoOcrIA({
    required this.tipoDocumento,
    required this.confianza,
    required this.campos,
    this.advertencias = const [],
    this.sugerencias = const [],
    this.metadatos = const {},
  });

  Map<String, dynamic> toJson() => {
        'tipoDocumento': tipoDocumento.toString(),
        'confianza': confianza,
        'campos': campos.map((k, v) => MapEntry(k, v.toJson())),
        'advertencias': advertencias,
        'sugerencias': sugerencias,
        'metadatos': metadatos,
      };
}

/// Campo extraído con metadatos de confianza
class CampoExtraido {
  final String valor;
  final double confianza; // 0.0 - 1.0
  final Rect? ubicacion; // Ubicación en la imagen
  final String? valorOriginal; // Antes de correcciones
  final bool corregido; // Si fue corregido por IA

  CampoExtraido({
    required this.valor,
    required this.confianza,
    this.ubicacion,
    this.valorOriginal,
    this.corregido = false,
  });

  Map<String, dynamic> toJson() => {
        'valor': valor,
        'confianza': confianza,
        'corregido': corregido,
        'valorOriginal': valorOriginal,
      };
}

/// Servicio OCR con IA Avanzada - Organización Inteligente de Información
class ServicioOcrIaAvanzado {
  /// Analiza un documento y extrae información estructurada con IA
  static Future<ResultadoOcrIA> analizarDocumento({
    required RecognizedText textoOcr,
    RecognizedText? textoOcrReverso,
    TipoDocumento? tipoEsperado,
  }) async {
    debugPrint("🤖 Iniciando OCR con IA Avanzada...");

    // 1. Detectar tipo de documento si no se especifica
    final tipo = tipoEsperado ?? _detectarTipoDocumento(textoOcr);
    debugPrint("📄 Tipo detectado: $tipo");

    // 2. Extraer campos según el tipo de documento
    Map<String, CampoExtraido> campos = {};
    List<String> advertencias = [];
    List<String> sugerencias = [];
    double confianzaGeneral = 0.0;

    switch (tipo) {
      case TipoDocumento.cedulaIdentidad:
        final resultado = await _analizarCedulaIdentidad(
          textoOcr,
          textoOcrReverso,
        );
        campos = resultado['campos'];
        advertencias = resultado['advertencias'];
        sugerencias = resultado['sugerencias'];
        confianzaGeneral = resultado['confianza'];
        break;

      case TipoDocumento.tituloAcademico:
        final resultado = await _analizarTituloAcademico(textoOcr);
        campos = resultado['campos'];
        advertencias = resultado['advertencias'];
        sugerencias = resultado['sugerencias'];
        confianzaGeneral = resultado['confianza'];
        break;

      case TipoDocumento.certificadoEstudios:
        final resultado = await _analizarCertificadoEstudios(textoOcr);
        campos = resultado['campos'];
        advertencias = resultado['advertencias'];
        sugerencias = resultado['sugerencias'];
        confianzaGeneral = resultado['confianza'];
        break;

      default:
        final resultado = await _analizarDocumentoGenerico(textoOcr);
        campos = resultado['campos'];
        advertencias = resultado['advertencias'];
        sugerencias = resultado['sugerencias'];
        confianzaGeneral = resultado['confianza'];
    }

    // 3. Validar y corregir campos
    final camposValidados = await _validarYCorregirCampos(campos, tipo);

    // 4. Generar sugerencias adicionales
    final sugerenciasAdicionales = _generarSugerencias(camposValidados, tipo);
    sugerencias.addAll(sugerenciasAdicionales);

    return ResultadoOcrIA(
      tipoDocumento: tipo,
      confianza: confianzaGeneral,
      campos: camposValidados,
      advertencias: advertencias,
      sugerencias: sugerencias,
      metadatos: {
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0-IA',
      },
    );
  }

  // ============================================================================
  // DETECCIÓN DE TIPO DE DOCUMENTO
  // ============================================================================

  static TipoDocumento _detectarTipoDocumento(RecognizedText texto) {
    final textoCompleto = texto.text.toUpperCase();
    final palabrasClave = _extraerPalabrasClave(textoCompleto);

    // Patrones para cada tipo de documento
    final patrones = {
      TipoDocumento.cedulaIdentidad: [
        'CEDULA',
        'C.I.',
        'IDENTIDAD',
        'NUMERO',
        'EMISION',
        'VALIDEZ',
        'HUELLA',
      ],
      TipoDocumento.tituloAcademico: [
        'TITULO',
        'UNIVERSIDAD',
        'LICENCIATURA',
        'MAESTRIA',
        'DOCTORADO',
        'DIPLOMA',
        'GRADUADO',
        'PROVISION NACIONAL',
      ],
      TipoDocumento.certificadoEstudios: [
        'CERTIFICADO',
        'ESTUDIOS',
        'NOTAS',
        'CALIFICACIONES',
        'PROMEDIO',
        'SEMESTRE',
      ],
      TipoDocumento.certificadoNacimiento: [
        'NACIMIENTO',
        'NACIO',
        'HIJO DE',
        'REGISTRO CIVIL',
      ],
      TipoDocumento.cartaProrroga: [
        'PRORROGA',
        'SOLICITUD',
        'DIRECTOR',
        'POSGRADO',
      ],
    };

    // Calcular score para cada tipo
    Map<TipoDocumento, double> scores = {};
    for (var entry in patrones.entries) {
      double score = 0;
      for (var patron in entry.value) {
        if (palabrasClave.contains(patron)) {
          score += 1.0;
        }
        // Fuzzy matching
        for (var palabra in palabrasClave) {
          if (_similitudTexto(palabra, patron) > 0.8) {
            score += 0.5;
          }
        }
      }
      scores[entry.key] = score;
    }

    // Retornar el tipo con mayor score
    var maxScore = 0.0;
    var tipoDetectado = TipoDocumento.otro;
    scores.forEach((tipo, score) {
      if (score > maxScore) {
        maxScore = score;
        tipoDetectado = tipo;
      }
    });

    debugPrint("📊 Scores de detección: $scores");
    return tipoDetectado;
  }

  // ============================================================================
  // ANÁLISIS DE CÉDULA DE IDENTIDAD
  // ============================================================================

  static Future<Map<String, dynamic>> _analizarCedulaIdentidad(
    RecognizedText frente,
    RecognizedText? reverso,
  ) async {
    Map<String, CampoExtraido> campos = {};
    List<String> advertencias = [];
    List<String> sugerencias = [];

    // Extraer CI
    final ci = _extraerCI(frente, reverso);
    if (ci != null) {
      campos['ci'] = ci;
      if (ci.confianza < 0.7) {
        advertencias.add('La confianza del CI es baja. Verifica el número.');
      }
    } else {
      advertencias.add('No se pudo detectar el número de CI.');
      sugerencias.add('Asegúrate de que la imagen sea clara y el número esté visible.');
    }

    // Extraer nombres
    final nombres = _extraerNombres(frente, reverso);
    if (nombres != null) {
      campos['nombres'] = nombres;
      if (nombres.valor.length < 3) {
        advertencias.add('El nombre parece muy corto.');
      }
    } else {
      advertencias.add('No se pudo detectar el nombre.');
    }

    // Extraer apellidos
    final apellidos = _extraerApellidos(frente, reverso);
    if (apellidos != null) {
      campos['apellidos'] = apellidos;
    } else {
      advertencias.add('No se pudo detectar los apellidos.');
    }

    // Extraer fecha de nacimiento
    final fechaNacimiento = _extraerFechaNacimiento(frente, reverso);
    if (fechaNacimiento != null) {
      campos['fechaNacimiento'] = fechaNacimiento;
      // Validar edad razonable
      final edad = _calcularEdad(fechaNacimiento.valor);
      if (edad != null) {
        if (edad < 18) {
          advertencias.add('La persona parece ser menor de edad.');
        } else if (edad > 100) {
          advertencias.add('La fecha de nacimiento parece incorrecta.');
        }
      }
    }

    // Extraer fechas de emisión y expiración
    final fechaEmision = _extraerFechaEmision(frente, reverso);
    if (fechaEmision != null) {
      campos['fechaEmision'] = fechaEmision;
    }

    final fechaExpiracion = _extraerFechaExpiracion(frente, reverso);
    if (fechaExpiracion != null) {
      campos['fechaExpiracion'] = fechaExpiracion;
      // Verificar si está vencido
      if (_estaVencido(fechaExpiracion.valor)) {
        advertencias.add('⚠️ El documento está vencido.');
        sugerencias.add('Renueva tu cédula de identidad.');
      }
    }

    // Extraer lugar de nacimiento
    final lugarNacimiento = _extraerLugarNacimiento(frente, reverso);
    if (lugarNacimiento != null) {
      campos['lugarNacimiento'] = lugarNacimiento;
    }

    // Calcular confianza general
    double confianzaTotal = 0;
    int camposConConfianza = 0;
    campos.forEach((key, campo) {
      confianzaTotal += campo.confianza;
      camposConConfianza++;
    });
    final confianzaGeneral = camposConConfianza > 0 
        ? confianzaTotal / camposConConfianza 
        : 0.0;

    return {
      'campos': campos,
      'advertencias': advertencias,
      'sugerencias': sugerencias,
      'confianza': confianzaGeneral,
    };
  }

  // ============================================================================
  // ANÁLISIS DE TÍTULO ACADÉMICO
  // ============================================================================

  static Future<Map<String, dynamic>> _analizarTituloAcademico(
    RecognizedText texto,
  ) async {
    Map<String, CampoExtraido> campos = {};
    List<String> advertencias = [];
    List<String> sugerencias = [];

    // Extraer nombre del titular
    final nombreTitular = _extraerCampoConEtiquetas(
      texto,
      ['OTORGA', 'CONFIERE', 'NOMBRE', 'TITULAR'],
      onlyLetters: true,
    );
    if (nombreTitular != null) {
      campos['nombreTitular'] = nombreTitular;
    }

    // Extraer título obtenido
    final tituloObtenido = _extraerCampoConEtiquetas(
      texto,
      ['TITULO', 'LICENCIATURA', 'MAESTRIA', 'DOCTORADO', 'GRADO'],
      onlyLetters: true,
    );
    if (tituloObtenido != null) {
      campos['tituloObtenido'] = tituloObtenido;
    } else {
      advertencias.add('No se pudo detectar el título obtenido.');
    }

    // Extraer universidad
    final universidad = _extraerCampoConEtiquetas(
      texto,
      ['UNIVERSIDAD', 'INSTITUTO', 'ESCUELA'],
      onlyLetters: true,
    );
    if (universidad != null) {
      campos['universidad'] = universidad;
    }

    // Extraer fecha de graduación
    final fechaGraduacion = _extraerFechaGeneral(texto, ['FECHA', 'GRADUACION', 'EXPEDICION']);
    if (fechaGraduacion != null) {
      campos['fechaGraduacion'] = fechaGraduacion;
    }

    // Extraer número de registro
    final numeroRegistro = _extraerCampoConEtiquetas(
      texto,
      ['REGISTRO', 'NUMERO', 'N°', 'REG'],
      pattern: r'\d+',
    );
    if (numeroRegistro != null) {
      campos['numeroRegistro'] = numeroRegistro;
    }

    // Calcular confianza
    double confianzaTotal = 0;
    int camposConConfianza = 0;
    campos.forEach((key, campo) {
      confianzaTotal += campo.confianza;
      camposConConfianza++;
    });
    final confianzaGeneral = camposConConfianza > 0 
        ? confianzaTotal / camposConConfianza 
        : 0.0;

    if (confianzaGeneral < 0.6) {
      advertencias.add('La calidad de la imagen es baja.');
      sugerencias.add('Intenta tomar una foto con mejor iluminación.');
    }

    return {
      'campos': campos,
      'advertencias': advertencias,
      'sugerencias': sugerencias,
      'confianza': confianzaGeneral,
    };
  }

  // ============================================================================
  // ANÁLISIS DE CERTIFICADO DE ESTUDIOS
  // ============================================================================

  static Future<Map<String, dynamic>> _analizarCertificadoEstudios(
    RecognizedText texto,
  ) async {
    Map<String, CampoExtraido> campos = {};
    List<String> advertencias = [];
    List<String> sugerencias = [];

    // Extraer nombre del estudiante
    final nombreEstudiante = _extraerCampoConEtiquetas(
      texto,
      ['ESTUDIANTE', 'ALUMNO', 'NOMBRE'],
      onlyLetters: true,
    );
    if (nombreEstudiante != null) {
      campos['nombreEstudiante'] = nombreEstudiante;
    }

    // Extraer carrera
    final carrera = _extraerCampoConEtiquetas(
      texto,
      ['CARRERA', 'PROGRAMA', 'ESPECIALIDAD'],
      onlyLetters: true,
    );
    if (carrera != null) {
      campos['carrera'] = carrera;
    }

    // Extraer promedio
    final promedio = _extraerCampoConEtiquetas(
      texto,
      ['PROMEDIO', 'NOTA'],
      pattern: r'\d+\.?\d*',
    );
    if (promedio != null) {
      campos['promedio'] = promedio;
    }

    // Extraer institución
    final institucion = _extraerCampoConEtiquetas(
      texto,
      ['UNIVERSIDAD', 'INSTITUTO', 'COLEGIO'],
      onlyLetters: true,
    );
    if (institucion != null) {
      campos['institucion'] = institucion;
    }

    double confianzaTotal = 0;
    int camposConConfianza = 0;
    campos.forEach((key, campo) {
      confianzaTotal += campo.confianza;
      camposConConfianza++;
    });
    final confianzaGeneral = camposConConfianza > 0 
        ? confianzaTotal / camposConConfianza 
        : 0.0;

    return {
      'campos': campos,
      'advertencias': advertencias,
      'sugerencias': sugerencias,
      'confianza': confianzaGeneral,
    };
  }

  // ============================================================================
  // ANÁLISIS DE DOCUMENTO GENÉRICO
  // ============================================================================

  static Future<Map<String, dynamic>> _analizarDocumentoGenerico(
    RecognizedText texto,
  ) async {
    Map<String, CampoExtraido> campos = {};
    List<String> advertencias = [];
    List<String> sugerencias = [];

    // Extraer todas las fechas
    final fechas = _extraerTodasLasFechas(texto);
    if (fechas.isNotEmpty) {
      for (var i = 0; i < fechas.length; i++) {
        campos['fecha_$i'] = fechas[i];
      }
    }

    // Extraer todos los números
    final numeros = _extraerTodosLosNumeros(texto);
    if (numeros.isNotEmpty) {
      for (var i = 0; i < numeros.length; i++) {
        campos['numero_$i'] = numeros[i];
      }
    }

    // Extraer texto completo
    campos['textoCompleto'] = CampoExtraido(
      valor: texto.text,
      confianza: 0.8,
    );

    advertencias.add('Tipo de documento no reconocido.');
    sugerencias.add('Especifica el tipo de documento para mejor precisión.');

    return {
      'campos': campos,
      'advertencias': advertencias,
      'sugerencias': sugerencias,
      'confianza': 0.5,
    };
  }

  // ============================================================================
  // EXTRACCIÓN DE CAMPOS ESPECÍFICOS
  // ============================================================================

  static CampoExtraido? _extraerCI(
    RecognizedText frente,
    RecognizedText? reverso,
  ) {
    // Buscar en frente
    final ciFrente = _extraerCampoConEtiquetas(
      frente,
      ['CEDULA', 'C.I.', 'NUMERO', 'CI'],
      pattern: r'\d{5,10}',
    );
    if (ciFrente != null && ciFrente.confianza > 0.6) {
      return ciFrente;
    }

    // Buscar en reverso si existe
    if (reverso != null) {
      final ciReverso = _extraerCampoConEtiquetas(
        reverso,
        ['CEDULA', 'C.I.', 'NUMERO', 'CI'],
        pattern: r'\d{5,10}',
      );
      if (ciReverso != null) {
        return ciReverso;
      }
    }

    // Fallback: buscar patrón directo
    return _extraerPatronDirecto(frente, r'\b\d{5,10}\b');
  }

  static CampoExtraido? _extraerNombres(
    RecognizedText frente,
    RecognizedText? reverso,
  ) {
    return _extraerCampoConEtiquetas(
      frente,
      ['NOMBRES', 'NOMBRE'],
      onlyLetters: true,
    );
  }

  static CampoExtraido? _extraerApellidos(
    RecognizedText frente,
    RecognizedText? reverso,
  ) {
    // Intentar extraer apellido paterno y materno por separado
    final paterno = _extraerCampoConEtiquetas(
      frente,
      ['PATERNO', 'AP. PATERNO'],
      onlyLetters: true,
    );
    final materno = _extraerCampoConEtiquetas(
      frente,
      ['MATERNO', 'AP. MATERNO'],
      onlyLetters: true,
    );

    if (paterno != null && materno != null) {
      return CampoExtraido(
        valor: '${paterno.valor} ${materno.valor}'.trim(),
        confianza: (paterno.confianza + materno.confianza) / 2,
        ubicacion: paterno.ubicacion,
      );
    }

    // Fallback: buscar "APELLIDOS"
    return _extraerCampoConEtiquetas(
      frente,
      ['APELLIDOS', 'APELLIDO'],
      onlyLetters: true,
    );
  }

  static CampoExtraido? _extraerFechaNacimiento(
    RecognizedText frente,
    RecognizedText? reverso,
  ) {
    return _extraerFechaGeneral(
      frente,
      ['NACIMIENTO', 'FECHA DE NACIMIENTO', 'NACIO', 'F. NAC'],
    );
  }

  static CampoExtraido? _extraerFechaEmision(
    RecognizedText frente,
    RecognizedText? reverso,
  ) {
    return _extraerFechaGeneral(
      frente,
      ['EMISION', 'EMISIÓN', 'EXPEDICION', 'FECHA DE EMISION'],
    );
  }

  static CampoExtraido? _extraerFechaExpiracion(
    RecognizedText frente,
    RecognizedText? reverso,
  ) {
    return _extraerFechaGeneral(
      frente,
      ['EXPIRACION', 'VENCIMIENTO', 'VALIDEZ', 'VÁLIDA HASTA', 'VENCE'],
    );
  }

  static CampoExtraido? _extraerLugarNacimiento(
    RecognizedText frente,
    RecognizedText? reverso,
  ) {
    return _extraerCampoConEtiquetas(
      frente,
      ['LUGAR DE NACIMIENTO', 'NACIMIENTO', 'LUGAR'],
      onlyLetters: true,
    );
  }

  // ============================================================================
  // UTILIDADES DE EXTRACCIÓN
  // ============================================================================

  static CampoExtraido? _extraerCampoConEtiquetas(
    RecognizedText texto,
    List<String> etiquetas, {
    String? pattern,
    bool onlyLetters = false,
  }) {
    // Buscar bloque con etiqueta
    TextBlock? bloqueEtiqueta;
    for (final etiqueta in etiquetas) {
      bloqueEtiqueta = _buscarBloquePorPalabra(texto, etiqueta);
      if (bloqueEtiqueta != null) break;
    }

    if (bloqueEtiqueta == null) return null;

    // Buscar valor cerca de la etiqueta
    final valor = _buscarTextoCerca(
      texto,
      bloqueEtiqueta.boundingBox,
      [Direction.right, Direction.bottom],
      pattern: pattern,
      onlyLetters: onlyLetters,
    );

    if (valor.isEmpty) return null;

    return CampoExtraido(
      valor: valor,
      confianza: 0.8, // Confianza base para extracción con etiqueta
      ubicacion: bloqueEtiqueta.boundingBox,
    );
  }

  static CampoExtraido? _extraerFechaGeneral(
    RecognizedText texto,
    List<String> etiquetas,
  ) {
    final patron = r'\d{1,2}[-/. ]\d{1,2}[-/. ]\d{2,4}';
    final campo = _extraerCampoConEtiquetas(
      texto,
      etiquetas,
      pattern: patron,
    );

    if (campo != null) {
      // Normalizar formato de fecha
      final fechaNormalizada = _normalizarFecha(campo.valor);
      return CampoExtraido(
        valor: fechaNormalizada,
        confianza: campo.confianza,
        ubicacion: campo.ubicacion,
        valorOriginal: campo.valor,
        corregido: fechaNormalizada != campo.valor,
      );
    }

    return null;
  }

  static CampoExtraido? _extraerPatronDirecto(
    RecognizedText texto,
    String patron,
  ) {
    final regex = RegExp(patron);
    for (final bloque in texto.blocks) {
      final match = regex.firstMatch(bloque.text);
      if (match != null) {
        return CampoExtraido(
          valor: match.group(0)!,
          confianza: 0.6, // Confianza menor sin etiqueta
          ubicacion: bloque.boundingBox,
        );
      }
    }
    return null;
  }

  static List<CampoExtraido> _extraerTodasLasFechas(RecognizedText texto) {
    final patron = r'\d{1,2}[-/. ]\d{1,2}[-/. ]\d{2,4}';
    final regex = RegExp(patron);
    final fechas = <CampoExtraido>[];

    for (final bloque in texto.blocks) {
      final matches = regex.allMatches(bloque.text);
      for (final match in matches) {
        final fechaNormalizada = _normalizarFecha(match.group(0)!);
        fechas.add(CampoExtraido(
          valor: fechaNormalizada,
          confianza: 0.7,
          ubicacion: bloque.boundingBox,
        ));
      }
    }

    return fechas;
  }

  static List<CampoExtraido> _extraerTodosLosNumeros(RecognizedText texto) {
    final patron = r'\b\d+\b';
    final regex = RegExp(patron);
    final numeros = <CampoExtraido>[];

    for (final bloque in texto.blocks) {
      final matches = regex.allMatches(bloque.text);
      for (final match in matches) {
        numeros.add(CampoExtraido(
          valor: match.group(0)!,
          confianza: 0.8,
          ubicacion: bloque.boundingBox,
        ));
      }
    }

    return numeros;
  }

  // ============================================================================
  // VALIDACIÓN Y CORRECCIÓN
  // ============================================================================

  static Future<Map<String, CampoExtraido>> _validarYCorregirCampos(
    Map<String, CampoExtraido> campos,
    TipoDocumento tipo,
  ) async {
    final camposCorregidos = <String, CampoExtraido>{};

    for (var entry in campos.entries) {
      final key = entry.key;
      final campo = entry.value;
      var valorCorregido = campo.valor;
      var corregido = false;

      // Correcciones específicas por tipo de campo
      if (key == 'ci') {
        valorCorregido = _corregirCI(campo.valor);
        corregido = valorCorregido != campo.valor;
      } else if (key.contains('fecha')) {
        valorCorregido = _normalizarFecha(campo.valor);
        corregido = valorCorregido != campo.valor;
      } else if (key.contains('nombre') || key.contains('apellido')) {
        valorCorregido = _corregirNombre(campo.valor);
        corregido = valorCorregido != campo.valor;
      }

      camposCorregidos[key] = CampoExtraido(
        valor: valorCorregido,
        confianza: campo.confianza,
        ubicacion: campo.ubicacion,
        valorOriginal: corregido ? campo.valor : null,
        corregido: corregido,
      );
    }

    return camposCorregidos;
  }

  static String _corregirCI(String ci) {
    // Eliminar espacios y caracteres no numéricos
    var corregido = ci.replaceAll(RegExp(r'[^\d]'), '');
    
    // Correcciones comunes de OCR
    corregido = corregido
        .replaceAll('O', '0')
        .replaceAll('I', '1')
        .replaceAll('l', '1')
        .replaceAll('B', '8')
        .replaceAll('S', '5')
        .replaceAll('Z', '2');

    return corregido;
  }

  static String _corregirNombre(String nombre) {
    // Capitalizar correctamente
    final palabras = nombre.split(' ');
    final corregidas = palabras.map((palabra) {
      if (palabra.isEmpty) return '';
      return palabra[0].toUpperCase() + palabra.substring(1).toLowerCase();
    });
    return corregidas.join(' ');
  }

  static String _normalizarFecha(String fecha) {
    // Normalizar separadores a '/'
    var normalizada = fecha.replaceAll(RegExp(r'[-. ]'), '/');
    
    // Intentar parsear y reformatear
    final partes = normalizada.split('/');
    if (partes.length == 3) {
      var dia = partes[0].padLeft(2, '0');
      var mes = partes[1].padLeft(2, '0');
      var anio = partes[2];
      
      // Convertir año de 2 dígitos a 4
      if (anio.length == 2) {
        final anioInt = int.tryParse(anio);
        if (anioInt != null) {
          anio = anioInt > 30 ? '19$anio' : '20$anio';
        }
      }
      
      return '$dia/$mes/$anio';
    }
    
    return normalizada;
  }

  // ============================================================================
  // GENERACIÓN DE SUGERENCIAS
  // ============================================================================

  static List<String> _generarSugerencias(
    Map<String, CampoExtraido> campos,
    TipoDocumento tipo,
  ) {
    final sugerencias = <String>[];

    // Verificar campos con baja confianza
    campos.forEach((key, campo) {
      if (campo.confianza < 0.6) {
        sugerencias.add('Verifica el campo "$key" manualmente.');
      }
    });

    // Sugerencias específicas por tipo
    if (tipo == TipoDocumento.cedulaIdentidad) {
      if (!campos.containsKey('ci')) {
        sugerencias.add('Asegúrate de que el número de CI sea visible.');
      }
      if (!campos.containsKey('nombres') || !campos.containsKey('apellidos')) {
        sugerencias.add('Verifica que el nombre completo sea legible.');
      }
    }

    return sugerencias;
  }

  // ============================================================================
  // UTILIDADES AUXILIARES
  // ============================================================================

  static TextBlock? _buscarBloquePorPalabra(
    RecognizedText texto,
    String palabra,
  ) {
    final palabraNormalizada = palabra.toUpperCase();
    
    for (final bloque in texto.blocks) {
      final textoBloque = bloque.text.toUpperCase();
      if (textoBloque.contains(palabraNormalizada)) {
        return bloque;
      }
      
      // Fuzzy matching
      if (_similitudTexto(textoBloque, palabraNormalizada) > 0.7) {
        return bloque;
      }
    }
    
    return null;
  }

  static String _buscarTextoCerca(
    RecognizedText texto,
    Rect ancla,
    List<Direction> direcciones, {
    String? pattern,
    bool onlyLetters = false,
  }) {
    double distanciaMinima = double.infinity;
    String mejorCoincidencia = '';

    for (final bloque in texto.blocks) {
      if (bloque.boundingBox == ancla) continue;

      String contenido = bloque.text.trim();
      
      // Aplicar filtros
      if (pattern != null) {
        final regex = RegExp(pattern);
        if (!regex.hasMatch(contenido)) continue;
        final match = regex.firstMatch(contenido);
        if (match != null) contenido = match.group(0)!;
      }
      
      if (onlyLetters) {
        if (contenido.length < 3) continue;
        if (contenido.contains(RegExp(r'[0-9]')) && contenido.length < 5) continue;
      }

      // Calcular distancia según dirección
      bool esCandidato = false;
      double distancia = double.infinity;

      for (final dir in direcciones) {
        if (dir == Direction.right) {
          // Verificar alineación vertical
          final solapamientoY = math.max(
            0,
            math.min(ancla.bottom, bloque.boundingBox.bottom) -
                math.max(ancla.top, bloque.boundingBox.top),
          );
          final alineadoVertical = solapamientoY > (ancla.height * 0.3);

          if (alineadoVertical && bloque.boundingBox.left > (ancla.right - 20)) {
            final d = bloque.boundingBox.left - ancla.right;
            if (d > -20 && d < 300) {
              if (d < distancia) {
                distancia = d;
                esCandidato = true;
              }
            }
          }
        } else if (dir == Direction.bottom) {
          // Verificar alineación horizontal
          final solapamientoX = math.max(
            0,
            math.min(ancla.right, bloque.boundingBox.right) -
                math.max(ancla.left, bloque.boundingBox.left),
          );
          final alineadoHorizontal =
              solapamientoX > (math.min(ancla.width, bloque.boundingBox.width) * 0.3);

          if (alineadoHorizontal && bloque.boundingBox.top > (ancla.bottom - 10)) {
            final d = bloque.boundingBox.top - ancla.bottom;
            if (d > -10 && d < 150) {
              if (d < distancia) {
                distancia = d;
                esCandidato = true;
              }
            }
          }
        }
      }

      if (esCandidato && distancia < distanciaMinima) {
        distanciaMinima = distancia;
        mejorCoincidencia = contenido;
      }
    }

    return mejorCoincidencia.replaceAll(RegExp(r'[\r\n]'), ' ').trim();
  }

  static Set<String> _extraerPalabrasClave(String texto) {
    final palabras = texto.split(RegExp(r'\s+'));
    final palabrasClave = <String>{};
    
    for (var palabra in palabras) {
      palabra = palabra.replaceAll(RegExp(r'[^\w]'), '');
      if (palabra.length > 3) {
        palabrasClave.add(palabra.toUpperCase());
      }
    }
    
    return palabrasClave;
  }

  static double _similitudTexto(String s1, String s2) {
    final distancia = _levenshtein(s1, s2);
    final maxLen = math.max(s1.length, s2.length);
    if (maxLen == 0) return 1.0;
    return 1.0 - (distancia / maxLen);
  }

  static int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;
    
    List<int> v0 = List<int>.filled(t.length + 1, 0);
    List<int> v1 = List<int>.filled(t.length + 1, 0);
    
    for (int i = 0; i < v0.length; i++) {
      v0[i] = i;
    }
    
    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = [v1[j] + 1, v0[j + 1] + 1, v0[j] + cost].reduce(math.min);
      }
      for (int j = 0; j < v0.length; j++) {
        v0[j] = v1[j];
      }
    }
    
    return v1[t.length];
  }

  static int? _calcularEdad(String fechaNacimiento) {
    final partes = fechaNacimiento.split('/');
    if (partes.length != 3) return null;
    
    final dia = int.tryParse(partes[0]);
    final mes = int.tryParse(partes[1]);
    final anio = int.tryParse(partes[2]);
    
    if (dia == null || mes == null || anio == null) return null;
    
    final fechaNac = DateTime(anio, mes, dia);
    final ahora = DateTime.now();
    var edad = ahora.year - fechaNac.year;
    
    if (ahora.month < fechaNac.month ||
        (ahora.month == fechaNac.month && ahora.day < fechaNac.day)) {
      edad--;
    }
    
    return edad;
  }

  static bool _estaVencido(String fechaExpiracion) {
    final partes = fechaExpiracion.split('/');
    if (partes.length != 3) return false;
    
    final dia = int.tryParse(partes[0]);
    final mes = int.tryParse(partes[1]);
    final anio = int.tryParse(partes[2]);
    
    if (dia == null || mes == null || anio == null) return false;
    
    final fechaExp = DateTime(anio, mes, dia);
    return fechaExp.isBefore(DateTime.now());
  }
}

enum Direction { right, bottom }
