import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:refactor_template/core/services/otros/diccionario_nombres_bolivianos.dart';

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
    debugPrint(" Iniciando OCR con IA Avanzada...");

    // 1. Detectar tipo de documento si no se especifica
    final tipo = tipoEsperado ?? _detectarTipoDocumento(textoOcr);
    debugPrint(" Tipo detectado: $tipo");

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
      sugerencias.add(
        'Asegúrate de que la imagen sea clara y el número esté visible.',
      );
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
    final nombreTitular = _extraerCampoConEtiquetas(texto, [
      'OTORGA',
      'CONFIERE',
      'NOMBRE',
      'TITULAR',
    ], onlyLetters: true);
    if (nombreTitular != null) {
      campos['nombreTitular'] = nombreTitular;
    }

    // Extraer título obtenido
    final tituloObtenido = _extraerCampoConEtiquetas(texto, [
      'TITULO',
      'LICENCIATURA',
      'MAESTRIA',
      'DOCTORADO',
      'GRADO',
    ], onlyLetters: true);
    if (tituloObtenido != null) {
      campos['tituloObtenido'] = tituloObtenido;
    } else {
      advertencias.add('No se pudo detectar el título obtenido.');
    }

    // Extraer universidad
    final universidad = _extraerCampoConEtiquetas(texto, [
      'UNIVERSIDAD',
      'INSTITUTO',
      'ESCUELA',
    ], onlyLetters: true);
    if (universidad != null) {
      campos['universidad'] = universidad;
    }

    // Extraer fecha de graduación
    final fechaGraduacion = _extraerFechaGeneral(texto, [
      'FECHA',
      'GRADUACION',
      'EXPEDICION',
    ]);
    if (fechaGraduacion != null) {
      campos['fechaGraduacion'] = fechaGraduacion;
    }

    // Extraer número de registro
    final numeroRegistro = _extraerCampoConEtiquetas(texto, [
      'REGISTRO',
      'NUMERO',
      'N°',
      'REG',
    ], pattern: r'\d+');
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
    final nombreEstudiante = _extraerCampoConEtiquetas(texto, [
      'ESTUDIANTE',
      'ALUMNO',
      'NOMBRE',
    ], onlyLetters: true);
    if (nombreEstudiante != null) {
      campos['nombreEstudiante'] = nombreEstudiante;
    }

    // Extraer carrera
    final carrera = _extraerCampoConEtiquetas(texto, [
      'CARRERA',
      'PROGRAMA',
      'ESPECIALIDAD',
    ], onlyLetters: true);
    if (carrera != null) {
      campos['carrera'] = carrera;
    }

    // Extraer promedio
    final promedio = _extraerCampoConEtiquetas(texto, [
      'PROMEDIO',
      'NOTA',
    ], pattern: r'\d+\.?\d*');
    if (promedio != null) {
      campos['promedio'] = promedio;
    }

    // Extraer institución
    final institucion = _extraerCampoConEtiquetas(texto, [
      'UNIVERSIDAD',
      'INSTITUTO',
      'COLEGIO',
    ], onlyLetters: true);
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
    campos['textoCompleto'] = CampoExtraido(valor: texto.text, confianza: 0.8);

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
    // Estrategia 1: buscar con etiquetas en frente
    final ciFrente = _extraerCampoConEtiquetas(frente, [
      'CEDULA',
      'C.I.',
      'NUMERO',
      'CI',
      'NRO',
    ], pattern: r'\d{5,10}');
    if (ciFrente != null && ciFrente.confianza > 0.6) {
      final corregido = _corregirCI(ciFrente.valor);
      return CampoExtraido(
        valor: corregido,
        confianza: ciFrente.confianza,
        ubicacion: ciFrente.ubicacion,
        valorOriginal: ciFrente.valor,
        corregido: corregido != ciFrente.valor,
      );
    }

    // Estrategia 2: buscar con etiquetas en reverso
    if (reverso != null) {
      final ciReverso = _extraerCampoConEtiquetas(reverso, [
        'CEDULA',
        'C.I.',
        'NUMERO',
        'CI',
        'NRO',
      ], pattern: r'\d{5,10}');
      if (ciReverso != null) {
        final corregido = _corregirCI(ciReverso.valor);
        return CampoExtraido(
          valor: corregido,
          confianza: ciReverso.confianza,
          ubicacion: ciReverso.ubicacion,
          valorOriginal: ciReverso.valor,
          corregido: corregido != ciReverso.valor,
        );
      }
    }

    // Estrategia 3: patrón directo — CI boliviano 7-8 dígitos
    // Primero buscar con complemento (ej: 8167727-A)
    final conComplemento = _extraerPatronDirecto(
      frente,
      r'\b(\d{7,8})-?([A-Z])?\b',
    );
    if (conComplemento != null) {
      final corregido = _corregirCI(conComplemento.valor);
      return CampoExtraido(
        valor: corregido,
        confianza: 0.65,
        ubicacion: conComplemento.ubicacion,
        valorOriginal: conComplemento.valor,
        corregido: corregido != conComplemento.valor,
      );
    }

    return _extraerPatronDirecto(frente, r'\b\d{7,8}\b');
  }

  /// Corrige confusiones comunes del OCR en números de CI.
  /// La implementación completa está más abajo en _corregirCI.

  static CampoExtraido? _extraerNombres(
    RecognizedText frente,
    RecognizedText? reverso,
  ) {
    // Estrategia 1: Buscar con etiquetas "NOMBRES" o "NOMBRE"
    final conEtiqueta = _extraerCampoConEtiquetas(frente, [
      'NOMBRES',
      'NOMBRE',
    ], onlyLetters: true);
    if (conEtiqueta != null && conEtiqueta.confianza > 0.6) {
      return conEtiqueta;
    }

    // Estrategia 2: Si hay reverso, buscar en reverso con patrón "PERTENECE A:"
    if (reverso != null) {
      final nombresReverso = _extraerNombresDesdePertenece(reverso);
      if (nombresReverso != null) return nombresReverso;
    }

    // Estrategia 3: Buscar en frente con patrón "PERTENECE A:"
    final nombresFrente = _extraerNombresDesdePertenece(frente);
    if (nombresFrente != null) return nombresFrente;

    // Estrategia 4: Usar diccionario de nombres conocidos para detectar
    final nombresDiccionario = _extraerNombresConDiccionario(frente);
    if (nombresDiccionario != null) return nombresDiccionario;

    return null;
  }

  /// Extrae nombres desde el patrón "PERTENECE A:" del carnet boliviano
  static CampoExtraido? _extraerNombresDesdePertenece(RecognizedText texto) {
    final textoCompleto = texto.text;
    final upper = textoCompleto.toUpperCase();

    // Buscar "PERTENECE A:" o similar
    final perteneceIdx = upper.indexOf('PERTENECE');
    if (perteneceIdx == -1) return null;

    // Extraer segmento después de "PERTENECE"
    String segmento = textoCompleto.substring(perteneceIdx);
    segmento = segmento.replaceFirst(
      RegExp(r'PERTENECE\s*A?\s*:?\s*', caseSensitive: false),
      '',
    );

    // Tomar primera línea (nombre completo en carnet boliviano)
    final lineas = segmento.split(RegExp(r'\n|\r\n|\r'));
    for (final linea in lineas) {
      final limpia = linea.trim();
      if (limpia.isEmpty) continue;

      // Parar si encontramos otros campos
      final limpiaUpper = limpia.toUpperCase();
      if (limpiaUpper.startsWith('NACIDO') ||
          limpiaUpper.startsWith('NACIDA') ||
          limpiaUpper.startsWith('EN:') ||
          limpiaUpper.startsWith('PROFESION') ||
          limpiaUpper.startsWith('PROFESIÓN') ||
          limpiaUpper.startsWith('DOMICILIO') ||
          limpiaUpper.startsWith('DOCUMENTOS') ||
          limpiaUpper.startsWith('ESTADO CIVIL') ||
          limpiaUpper.startsWith('FIRMA')) {
        continue;
      }

      // Validar que parezca un nombre
      if (_esPosibleNombre(limpia)) {
        // Extraer solo nombres (primera parte antes de apellidos)
        final palabras = limpia
            .split(RegExp(r'\s+'))
            .where((p) => p.isNotEmpty)
            .toList();
        if (palabras.length >= 3) {
          // Asumir: NOMBRE1 NOMBRE2 APELLIDO1 APELLIDO2
          // Tomar primeras 2 palabras como nombres
          final nombres = palabras.take(2).join(' ');
          return CampoExtraido(valor: nombres.toUpperCase(), confianza: 0.85);
        } else if (palabras.length == 2) {
          // Si solo 2 palabras, asumir que es el nombre
          return CampoExtraido(
            valor: palabras[0].toUpperCase(),
            confianza: 0.75,
          );
        }
      }
    }

    return null;
  }

  /// Usa el diccionario de nombres bolivianos para detectar nombres
  static CampoExtraido? _extraerNombresConDiccionario(RecognizedText texto) {
    final candidatos = <String>[];

    for (final block in texto.blocks) {
      for (final line in block.lines) {
        final textoLine = line.text.trim();
        if (textoLine.length < 3 || textoLine.length > 50) continue;

        // Dividir en palabras
        final palabras = textoLine.split(RegExp(r'\s+'));
        if (palabras.isEmpty || palabras.length > 4) continue;

        // Verificar si alguna palabra coincide con el diccionario
        final palabrasConocidas = palabras.where((p) {
          final limpia = p
              .replaceAll(RegExp(r'[^A-Za-z\u00C0-\u024F]'), '')
              .toUpperCase();
          return DiccionarioNombresBolivianos.esNombreConocido(limpia);
        }).toList();

        if (palabrasConocidas.isNotEmpty) {
          // Es probable que sea un nombre
          final textoLimpio = _limpiarTextoNombre(textoLine);
          if (textoLimpio.isNotEmpty) {
            candidatos.add(textoLimpio);
          }
        }
      }
    }

    if (candidatos.isEmpty) return null;

    // Retornar el candidato con más coincidencias de diccionario
    String mejorCandidato = candidatos.first;
    double mejorConfianza = 0.7;

    for (final candidato in candidatos) {
      final palabras = candidato.split(' ');
      int coincidencias = 0;
      for (final palabra in palabras) {
        if (DiccionarioNombresBolivianos.esNombreConocido(
          palabra.toUpperCase(),
        )) {
          coincidencias++;
        }
      }
      final confianza = coincidencias / palabras.length;
      if (confianza > mejorConfianza) {
        mejorConfianza = confianza;
        mejorCandidato = candidato;
      }
    }

    return CampoExtraido(
      valor: mejorCandidato.toUpperCase(),
      confianza: mejorConfianza,
    );
  }

  /// Limpia un texto para usarlo como nombre
  static String _limpiarTextoNombre(String texto) {
    String limpio = texto.trim();

    // Eliminar etiquetas comunes
    limpio = limpio.replaceAll(
      RegExp(r'^(NOMBRES?\s*:?\s*)', caseSensitive: false),
      '',
    );
    limpio = limpio.replaceAll(
      RegExp(r'^(APELLIDOS?\s*:?\s*)', caseSensitive: false),
      '',
    );

    // Solo letras, espacios, guiones y apóstrofes
    limpio = limpio.replaceAll(RegExp(r"[^A-Za-z\u00C0-\u024F\s\-']"), '');

    // Espacios múltiples
    limpio = limpio.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (limpio.length < 2 || limpio.length > 80) return '';

    return limpio;
  }

  /// Verifica si un texto parece ser un nombre válido
  static bool _esPosibleNombre(String texto) {
    final limpio = texto.trim();
    if (limpio.length < 3 || limpio.length > 80) return false;

    // No debe contener muchos números
    final numeros = limpio.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeros.length > 2) return false;

    // Debe tener más letras que números
    final letras = limpio.replaceAll(RegExp(r'[^A-Za-z\u00C0-\u024F]'), '');
    if (letras.length < limpio.length * 0.7) return false;

    // No debe ser texto institucional
    final upper = limpio.toUpperCase();
    const textoInstitucional = [
      'ESTADO PLURINACIONAL',
      'REPUBLICA DE BOLIVIA',
      'CEDULA DE IDENTIDAD',
      'SERVICIO GENERAL',
      'SEGIP',
    ];
    for (final institucional in textoInstitucional) {
      if (upper.contains(institucional)) return false;
    }

    return true;
  }

  static CampoExtraido? _extraerApellidos(
    RecognizedText frente,
    RecognizedText? reverso,
  ) {
    // Estrategia 1: Intentar extraer apellido paterno y materno por separado
    final paterno = _extraerCampoConEtiquetas(frente, [
      'PATERNO',
      'AP. PATERNO',
      'APELLIDO PATERNO',
    ], onlyLetters: true);
    final materno = _extraerCampoConEtiquetas(frente, [
      'MATERNO',
      'AP. MATERNO',
      'APELLIDO MATERNO',
    ], onlyLetters: true);

    if (paterno != null && materno != null) {
      return CampoExtraido(
        valor: '${paterno.valor} ${materno.valor}'.trim(),
        confianza: (paterno.confianza + materno.confianza) / 2,
        ubicacion: paterno.ubicacion,
      );
    }

    // Estrategia 2: Fallback - buscar "APELLIDOS" o "APELLIDO"
    final conEtiqueta = _extraerCampoConEtiquetas(frente, [
      'APELLIDOS',
      'APELLIDO',
    ], onlyLetters: true);
    if (conEtiqueta != null && conEtiqueta.confianza > 0.6) {
      return conEtiqueta;
    }

    // Estrategia 3: Si hay reverso, extraer desde "PERTENECE A:"
    if (reverso != null) {
      final apellidosReverso = _extraerApellidosDesdePertenece(reverso);
      if (apellidosReverso != null) return apellidosReverso;
    }

    // Estrategia 4: Extraer desde "PERTENECE A:" en frente
    final apellidosFrente = _extraerApellidosDesdePertenece(frente);
    if (apellidosFrente != null) return apellidosFrente;

    // Estrategia 5: Usar diccionario de apellidos conocidos
    final apellidosDiccionario = _extraerApellidosConDiccionario(frente);
    if (apellidosDiccionario != null) return apellidosDiccionario;

    return null;
  }

  /// Extrae apellidos desde el patrón "PERTENECE A:" del carnet boliviano
  static CampoExtraido? _extraerApellidosDesdePertenece(RecognizedText texto) {
    final textoCompleto = texto.text;
    final upper = textoCompleto.toUpperCase();

    final perteneceIdx = upper.indexOf('PERTENECE');
    if (perteneceIdx == -1) return null;

    String segmento = textoCompleto.substring(perteneceIdx);
    segmento = segmento.replaceFirst(
      RegExp(r'PERTENECE\s*A?\s*:?\s*', caseSensitive: false),
      '',
    );

    final lineas = segmento.split(RegExp(r'\n|\r\n|\r'));
    for (final linea in lineas) {
      final limpia = linea.trim();
      if (limpia.isEmpty) continue;

      final limpiaUpper = limpia.toUpperCase();
      if (limpiaUpper.startsWith('NACIDO') ||
          limpiaUpper.startsWith('NACIDA') ||
          limpiaUpper.startsWith('EN:') ||
          limpiaUpper.startsWith('PROFESION') ||
          limpiaUpper.startsWith('PROFESIÓN') ||
          limpiaUpper.startsWith('DOMICILIO') ||
          limpiaUpper.startsWith('DOCUMENTOS') ||
          limpiaUpper.startsWith('ESTADO CIVIL') ||
          limpiaUpper.startsWith('FIRMA')) {
        continue;
      }

      if (_esPosibleNombre(limpia)) {
        final palabras = limpia
            .split(RegExp(r'\s+'))
            .where((p) => p.isNotEmpty)
            .toList();
        if (palabras.length >= 3) {
          // Asumir: NOMBRE1 NOMBRE2 APELLIDO1 APELLIDO2
          // Tomar últimas 2 palabras como apellidos
          final apellidos = palabras.skip(palabras.length - 2).join(' ');
          return CampoExtraido(valor: apellidos.toUpperCase(), confianza: 0.85);
        } else if (palabras.length == 2) {
          // Si solo 2 palabras, asumir que es el apellido
          return CampoExtraido(
            valor: palabras[1].toUpperCase(),
            confianza: 0.75,
          );
        }
      }
    }

    return null;
  }

  /// Usa el diccionario de apellidos bolivianos para detectar apellidos
  static CampoExtraido? _extraerApellidosConDiccionario(RecognizedText texto) {
    final candidatos = <String, int>{};

    for (final block in texto.blocks) {
      for (final line in block.lines) {
        final textoLine = line.text.trim();
        if (textoLine.length < 3 || textoLine.length > 50) continue;

        final palabras = textoLine.split(RegExp(r'\s+'));
        if (palabras.isEmpty || palabras.length > 4) continue;

        // Verificar si alguna palabra coincide con apellidos conocidos
        for (final palabra in palabras) {
          final limpia = palabra
              .replaceAll(RegExp(r'[^A-Za-z\u00C0-\u024F]'), '')
              .toUpperCase();
          if (DiccionarioNombresBolivianos.esApellidoConocido(limpia)) {
            // Encontró un apellido, agregar a candidatos
            final count = candidatos[limpia] ?? 0;
            candidatos[limpia] = count + 1;
          }
        }
      }
    }

    if (candidatos.isEmpty) return null;

    // Ordenar por frecuencia y construir apellidos
    final apellidosOrdenados = candidatos.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Tomar los 2 apellidos más frecuentes (paterno y materno)
    final topApellidos = apellidosOrdenados.take(2).map((e) => e.key).toList();

    return CampoExtraido(valor: topApellidos.join(' '), confianza: 0.75);
  }

  static CampoExtraido? _extraerFechaNacimiento(
    RecognizedText frente,
    RecognizedText? reverso,
  ) {
    // 1. Intentar con etiquetas específicas
    final conEtiqueta = _extraerFechaGeneral(frente, [
      'NACIMIENTO',
      'FECHA DE NACIMIENTO',
      'NACIO',
      'NACIÓ',
      'F. NAC',
      'FECHA NAC',
      'F.NAC',
      'NACIDO',
      'NACIDA',
    ]);
    if (conEtiqueta != null) return conEtiqueta;

    // 2. Buscar en reverso con etiquetas
    if (reverso != null) {
      final conEtiquetaRev = _extraerFechaGeneral(reverso, [
        'NACIMIENTO',
        'NACIO',
        'NACIÓ',
        'F. NAC',
        'NACIDO',
        'NACIDA',
      ]);
      if (conEtiquetaRev != null) return conEtiquetaRev;
    }

    // 3. Buscar formato DDMMYYYY pegado (sin separadores) — común en carnets bolivianos
    final sinSeparador = _extraerFechaSinSeparador(frente);
    if (sinSeparador != null) return sinSeparador;

    // 4. Fallback: buscar todas las fechas y filtrar por rango de edad válido (16-100 años)
    final todasLasFechas = _extraerTodasLasFechas(frente);
    if (reverso != null) {
      todasLasFechas.addAll(_extraerTodasLasFechas(reverso));
    }

    if (todasLasFechas.isEmpty) return null;

    // Priorizar fechas que den una edad entre 16 y 100 años
    CampoExtraido? mejorCandidata;
    int mejorEdad = -1;
    for (final fecha in todasLasFechas) {
      final edad = _calcularEdad(fecha.valor);
      if (edad != null && edad >= 16 && edad <= 100) {
        // Preferir edades más "típicas" (18-80)
        if (mejorCandidata == null ||
            (edad >= 18 && edad <= 80 && (mejorEdad < 18 || mejorEdad > 80))) {
          mejorCandidata = fecha;
          mejorEdad = edad;
        }
      }
    }

    return mejorCandidata;
  }

  /// Extrae fechas en formato DDMMYYYY sin separadores (ej: "15061985")
  static CampoExtraido? _extraerFechaSinSeparador(RecognizedText texto) {
    final regex = RegExp(r'\b(\d{2})(\d{2})(\d{4})\b');
    for (final bloque in texto.blocks) {
      final match = regex.firstMatch(bloque.text);
      if (match != null) {
        final dia = int.tryParse(match.group(1)!) ?? 0;
        final mes = int.tryParse(match.group(2)!) ?? 0;
        final anio = int.tryParse(match.group(3)!) ?? 0;
        if (dia >= 1 &&
            dia <= 31 &&
            mes >= 1 &&
            mes <= 12 &&
            anio >= 1920 &&
            anio <= DateTime.now().year - 16) {
          final fecha =
              '${match.group(1)!}/${match.group(2)!}/${match.group(3)!}';
          return CampoExtraido(
            valor: fecha,
            confianza: 0.7,
            ubicacion: bloque.boundingBox,
            valorOriginal: match.group(0),
          );
        }
      }
    }
    return null;
  }

  static CampoExtraido? _extraerFechaEmision(
    RecognizedText frente,
    RecognizedText? reverso,
  ) {
    // Buscar en frente
    final f = _extraerFechaGeneral(frente, [
      'EMISION',
      'EMISIÓN',
      'EXPEDICION',
      'FECHA DE EMISION',
    ]);
    if (f != null) return f;

    // Buscar en reverso
    if (reverso != null) {
      return _extraerFechaGeneral(reverso, [
        'EMISION',
        'EMISIÓN',
        'EXPEDICION',
        'FECHA DE EMISION',
      ]);
    }
    return null;
  }

  static CampoExtraido? _extraerFechaExpiracion(
    RecognizedText frente,
    RecognizedText? reverso,
  ) {
    // Buscar en frente
    final f = _extraerFechaGeneral(frente, [
      'EXPIRACION',
      'VENCIMIENTO',
      'VALIDEZ',
      'VÁLIDA HASTA',
      'VENCE',
    ]);
    if (f != null) return f;

    // Buscar en reverso
    if (reverso != null) {
      return _extraerFechaGeneral(reverso, [
        'EXPIRACION',
        'VENCIMIENTO',
        'VALIDEZ',
        'VÁLIDA HASTA',
        'VENCE',
      ]);
    }
    return null;
  }

  static CampoExtraido? _extraerLugarNacimiento(
    RecognizedText frente,
    RecognizedText? reverso,
  ) {
    // Buscar en frente
    final f = _extraerCampoConEtiquetas(frente, [
      'LUGAR DE NACIMIENTO',
      'NACIMIENTO',
      'LUGAR',
    ], onlyLetters: true);
    if (f != null) return f;

    // Buscar en reverso
    if (reverso != null) {
      return _extraerCampoConEtiquetas(reverso, [
        'LUGAR DE NACIMIENTO',
        'NACIMIENTO',
        'LUGAR',
      ], onlyLetters: true);
    }
    return null;
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
    final campo = _extraerCampoConEtiquetas(texto, etiquetas, pattern: patron);

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
    // Patrones ampliados — incluye separadores variados y formatos bolivianos
    final patrones = [
      r'\b(\d{1,2})[/\-. ](\d{1,2})[/\-. ](\d{4})\b', // DD/MM/AAAA
      r'\b(\d{1,2})[/\-. ](\d{1,2})[/\-. ](\d{2})\b', // DD/MM/AA
      r'\b(\d{4})[/\-. ](\d{1,2})[/\-. ](\d{1,2})\b', // AAAA/MM/DD
      // Meses en texto (ej: "15 DE ENERO DE 1985")
      r'\b(\d{1,2})\s+(?:DE\s+)?([A-ZÁÉÍÓÚ]+)\s+(?:DE\s+)?(\d{4})\b',
    ];

    final mesesTexto = {
      'ENERO': '01', 'FEBRERO': '02', 'MARZO': '03', 'ABRIL': '04',
      'MAYO': '05', 'JUNIO': '06', 'JULIO': '07', 'AGOSTO': '08',
      'SEPTIEMBRE': '09', 'OCTUBRE': '10', 'NOVIEMBRE': '11', 'DICIEMBRE': '12',
      // Abreviaciones
      'ENE': '01', 'FEB': '02', 'MAR': '03', 'ABR': '04',
      'JUN': '06', 'JUL': '07', 'AGO': '08', 'SEP': '09',
      'OCT': '10', 'NOV': '11', 'DIC': '12',
    };

    final fechas = <CampoExtraido>[];
    final fechasVistas = <String>{};

    for (int pi = 0; pi < patrones.length; pi++) {
      final regex = RegExp(patrones[pi], caseSensitive: false);

      for (final bloque in texto.blocks) {
        // Corregir confusiones OCR en el texto antes de parsear
        final textoCorregido = _corregirConfusionesEnFecha(bloque.text);
        final matches = regex.allMatches(textoCorregido);

        for (final match in matches) {
          String dia, mes, anio;

          if (pi == 3) {
            // Formato con mes en texto
            dia = match.group(1)!.padLeft(2, '0');
            final mesTexto = match.group(2)!.toUpperCase();
            mes = mesesTexto[mesTexto] ?? '00';
            anio = match.group(3)!;
            if (mes == '00') continue;
          } else if (pi == 2) {
            // AAAA/MM/DD
            anio = match.group(1)!;
            mes = match.group(2)!.padLeft(2, '0');
            dia = match.group(3)!.padLeft(2, '0');
          } else {
            dia = match.group(1)!.padLeft(2, '0');
            mes = match.group(2)!.padLeft(2, '0');
            anio = match.group(3)!;
            // Expandir año de 2 dígitos
            if (anio.length == 2) {
              final y = int.parse(anio);
              anio = y > 30 ? '19$anio' : '20$anio';
            }
          }

          final fechaNorm = '$dia/$mes/$anio';
          if (fechasVistas.contains(fechaNorm)) continue;
          fechasVistas.add(fechaNorm);

          if (_esFechaValida(fechaNorm)) {
            fechas.add(
              CampoExtraido(
                valor: fechaNorm,
                confianza: pi == 0 ? 0.85 : 0.75,
                ubicacion: bloque.boundingBox,
                valorOriginal: match.group(0),
              ),
            );
          }
        }
      }
    }

    return fechas;
  }

  /// Corrige confusiones OCR comunes en fechas (O→0, l→1, etc.)
  static String _corregirConfusionesEnFecha(String texto) {
    // Solo corregir en secuencias que parecen números de fecha
    return texto.replaceAllMapped(
      RegExp(
        r'\b[\dOlISBGZ]{1,4}[/\-. ][\dOlISBGZ]{1,2}[/\-. ][\dOlISBGZ]{2,4}\b',
      ),
      (m) => m
          .group(0)!
          .replaceAll('O', '0')
          .replaceAll('l', '1')
          .replaceAll('I', '1')
          .replaceAll('S', '5')
          .replaceAll('B', '8')
          .replaceAll('G', '6')
          .replaceAll('Z', '2'),
    );
  }

  /// Verifica si una fecha es válida y razonable
  static bool _esFechaValida(String fecha) {
    try {
      final partes = fecha.split('/');
      if (partes.length != 3) return false;

      final dia = int.tryParse(partes[0]);
      final mes = int.tryParse(partes[1]);
      final anio = int.tryParse(partes[2]);

      if (dia == null || mes == null || anio == null) return false;

      // Validar rangos razonables
      if (dia < 1 || dia > 31) return false;
      if (mes < 1 || mes > 12) return false;
      if (anio < 1900 || anio > DateTime.now().year + 10) return false;

      // No puede ser fecha futura lejana
      final fechaParsed = DateTime(anio, mes, dia);
      if (fechaParsed.isAfter(DateTime.now().add(const Duration(days: 3650)))) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  static List<CampoExtraido> _extraerTodosLosNumeros(RecognizedText texto) {
    final patron = r'\b\d+\b';
    final regex = RegExp(patron);
    final numeros = <CampoExtraido>[];

    for (final bloque in texto.blocks) {
      final matches = regex.allMatches(bloque.text);
      for (final match in matches) {
        numeros.add(
          CampoExtraido(
            valor: match.group(0)!,
            confianza: 0.8,
            ubicacion: bloque.boundingBox,
          ),
        );
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

    // Correcciones exhaustivas de OCR para números
    // Mapeo completo de caracteres confusos
    final Map<String, String> correccionesOCR = {
      'O': '0', // O mayúscula -> 0
      'o': '0', // O minúscula -> 0
      'Q': '0', // Q -> 0
      'q': '0', // q -> 0
      'I': '1', // I mayúscula -> 1
      'l': '1', // L minúscula -> 1
      'i': '1', // i -> 1
      'B': '8', // B -> 8 (solo si está en contexto numérico)
      'b': '6', // b -> 6
      'S': '5', // S -> 5
      's': '5', // s -> 5
      'Z': '2', // Z -> 2
      'z': '2', // z -> 2
      'G': '6', // G -> 6
      'g': '9', // g -> 9
      'D': '0', // D -> 0 (en contexto numérico)
      'd': '0', // d -> 0
      'T': '7', // T -> 7
      't': '7', // t -> 7
    };

    // Aplicar correcciones solo si el resultado es un número válido
    for (var entry in correccionesOCR.entries) {
      corregido = corregido.replaceAll(entry.key, entry.value);
    }

    // Validar que solo queden dígitos
    corregido = corregido.replaceAll(RegExp(r'[^\d]'), '');

    return corregido;
  }

  static String _corregirNombre(String nombre) {
    // Correcciones de caracteres confusos en nombres
    var corregido = nombre;

    // Capitalizar correctamente
    final palabras = corregido.split(' ');
    final corregidas = palabras.map((palabra) {
      if (palabra.isEmpty) return '';
      return palabra[0].toUpperCase() + palabra.substring(1).toLowerCase();
    });
    return corregidas.join(' ');
  }

  static String _normalizarFecha(String fecha) {
    if (fecha.trim().isEmpty) return fecha;

    // Normalizar separadores a '/'
    var normalizada = fecha.replaceAll(RegExp(r'[-. ]'), '/');

    // Intentar parsear y reformatear
    final partes = normalizada.split('/');
    if (partes.length == 3) {
      // Intentar detectar qué es día, mes y año
      int? dia, mes, anio;

      // Caso 1: DD/MM/AAAA (formato más común en Bolivia)
      final p0 = int.tryParse(partes[0]);
      final p1 = int.tryParse(partes[1]);
      final p2 = int.tryParse(partes[2]);

      if (p0 != null && p1 != null && p2 != null) {
        // Si una parte es > 31, es año
        if (p0 > 31) {
          // AAAA/MM/DD o AAAA/DD/MM
          anio = p0;
          if (p1 > 12) {
            // AAAA/DD/MM
            dia = p1;
            mes = p2;
          } else if (p2 > 12) {
            // AAAA/MM/DD
            dia = p2;
            mes = p1;
          } else {
            // Asumir AAAA/MM/DD
            anio = p0;
            mes = p1;
            dia = p2;
          }
        } else if (p2 > 31 || (p2 > 12 && p2 < 100)) {
          // DD/MM/AA o DD/MM/AAAA
          dia = p0;
          mes = p1;
          anio = p2;
        } else if (p2 >= 100) {
          // DD/MM/AAAA
          dia = p0;
          mes = p1;
          anio = p2;
        } else {
          // Todos <= 31, asumir DD/MM/AA
          dia = p0;
          mes = p1;
          anio = p2;
        }
      }

      if (dia != null && mes != null && anio != null) {
        // Validar rangos
        if (dia >= 1 && dia <= 31 && mes >= 1 && mes <= 12 && anio >= 1900) {
          var diaStr = dia.toString().padLeft(2, '0');
          var mesStr = mes.toString().padLeft(2, '0');

          // Convertir año de 2 dígitos a 4
          if (anio < 100) {
            anio = anio > 30 ? 1900 + anio : 2000 + anio;
          }

          return '$diaStr/$mesStr/$anio';
        }
      }
    }

    // Si no se pudo normalizar, retornar original con separadores normalizados
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
        if (contenido.contains(RegExp(r'[0-9]')) && contenido.length < 5) {
          continue;
        }
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

          if (alineadoVertical &&
              bloque.boundingBox.left > (ancla.right - 20)) {
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
              solapamientoX >
              (math.min(ancla.width, bloque.boundingBox.width) * 0.3);

          if (alineadoHorizontal &&
              bloque.boundingBox.top > (ancla.bottom - 10)) {
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
