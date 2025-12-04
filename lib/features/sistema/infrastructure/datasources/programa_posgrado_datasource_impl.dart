import 'package:dio/dio.dart';
import 'package:refactor_template/features/sistema/domain/entities/programa_posgrado.dart';
import 'package:refactor_template/features/sistema/infrastructure/datasources/programa_posgrado_datasource.dart';
import 'package:refactor_template/features/sistema/infrastructure/models/programa_posgrado_model.dart';

/// Implementación del datasource para obtener programas desde el sitio web.
class ProgramaPosgradoDatasourceImpl implements ProgramaPosgradoDatasource {
  final Dio dio;
  static const String baseUrl = 'https://posgradouap.edu.bo';

  ProgramaPosgradoDatasourceImpl({Dio? dio}) : dio = dio ?? Dio();

  @override
  Future<List<ProgramaPosgrado>> obtenerProgramasDesdeWeb({
    String? area,
    String? tipo,
  }) async {
    try {
      // Obtener el HTML de la página
      final response = await dio.get(
        '$baseUrl/area-de-educacion/',
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
        ),
      );

      // Parsear el HTML y extraer programas
      return _parsearHtml(response.data.toString(), area: area, tipo: tipo);
    } catch (e) {
      // Si falla, retornar datos de ejemplo basados en el sitio web
      return _obtenerProgramasEjemplo(area: area, tipo: tipo);
    }
  }

  @override
  Future<List<ProgramaPosgrado>> obtenerProgramasDesdeApi({
    String? area,
    String? tipo,
  }) async {
    // Si en el futuro hay una API REST, implementar aquí
    throw UnimplementedError('API no disponible aún');
  }

  /// Parsea el HTML y extrae información de los programas.
  List<ProgramaPosgrado> _parsearHtml(
    String html, {
    String? area,
    String? tipo,
  }) {
    final programas = <ProgramaPosgrado>[];

    // Extraer información usando expresiones regulares básicas
    // Nota: Para un parsing más robusto, considerar usar el paquete 'html'
    final programaPattern = RegExp(
      r'<h[1-6][^>]*>([^<]*(?:INSCRIPCIONES|PREINSCRIPCIONES|INICIARON)[^<]*)</h[1-6]>',
      caseSensitive: false,
    );

    final matches = programaPattern.allMatches(html);
    int index = 0;

    for (final match in matches) {
      final tituloCompleto = match.group(1) ?? '';

      // Extraer información del programa
      final programa = _extraerDatosPrograma(tituloCompleto, html, index);
      if (programa != null) {
        // Filtrar por área y tipo si se especifica
        if (area == null ||
            programa.area.toLowerCase().contains(area.toLowerCase())) {
          if (tipo == null ||
              programa.tipo.toLowerCase().contains(tipo.toLowerCase())) {
            programas.add(programa);
          }
        }
      }
      index++;
    }

    // Si no se encontraron programas, retornar ejemplos
    if (programas.isEmpty) {
      return _obtenerProgramasEjemplo(area: area, tipo: tipo);
    }

    return programas;
  }

  /// Extrae datos de un programa desde el HTML.
  ProgramaPosgrado? _extraerDatosPrograma(
    String titulo,
    String html,
    int index,
  ) {
    try {
      // Buscar información adicional en el HTML alrededor del título
      final duracionMatch = RegExp(
        r'Duración:\s*(\d+)\s*meses',
        caseSensitive: false,
      ).firstMatch(html);
      final horasMatch = RegExp(
        r'(\d+)\s*Hrs\.\s*Académicas',
        caseSensitive: false,
      ).firstMatch(html);
      final creditosMatch = RegExp(
        r'(\d+)\s*Créditos',
        caseSensitive: false,
      ).firstMatch(html);
      final descuentoMatch = RegExp(
        r'(\d+)%\s*de\s*descuento',
        caseSensitive: false,
      ).firstMatch(html);

      final duracion = duracionMatch?.group(1) ?? '6';
      final horas = horasMatch?.group(1) ?? '800';
      final creditos = int.tryParse(creditosMatch?.group(1) ?? '20') ?? 20;
      final descuento = double.tryParse(descuentoMatch?.group(1) ?? '');

      // Determinar tipo basado en el título
      String tipoPrograma = 'DIPLOMADO';
      if (titulo.toUpperCase().contains('MAESTRÍA') ||
          titulo.toUpperCase().contains('MAESTRIA')) {
        tipoPrograma = 'MAESTRÍA';
      } else if (titulo.toUpperCase().contains('DOCTORADO')) {
        tipoPrograma = 'DOCTORADO';
      }

      // Determinar estado
      String estado = 'INSCRIPCIONES ABIERTAS';
      if (titulo.toUpperCase().contains('PREINSCRIPCIONES')) {
        estado = 'PREINSCRIPCIONES';
      } else if (titulo.toUpperCase().contains('INICIARON')) {
        estado = 'INICIARON LAS CLASES';
      }

      return ProgramaPosgradoModel.fromHtml(
        id: 'programa_${index}_${DateTime.now().millisecondsSinceEpoch}',
        titulo: titulo.trim(),
        tipo: tipoPrograma,
        modalidad: '100% Virtual',
        duracion: '$duracion meses',
        cargaHoraria: '$horas Hrs. Académicas',
        creditos: creditos,
        estado: estado,
        descuento: descuento,
        area: 'ÁREA DE EDUCACIÓN',
        universidad: 'Universidad Amazónica de Pando',
      );
    } catch (e) {
      return null;
    }
  }

  /// Retorna programas de ejemplo basados en el contenido del sitio web.
  List<ProgramaPosgrado> _obtenerProgramasEjemplo({
    String? area,
    String? tipo,
  }) {
    final programas = [
      ProgramaPosgradoModel.fromHtml(
        id: '1',
        titulo: 'DIPLOMADO EN EDUCACIÓN SUPERIOR BASADO EN COMPETENCIAS',
        tipo: 'DIPLOMADO',
        modalidad: '100% Virtual',
        duracion: '6 meses',
        cargaHoraria: '800 Hrs. Académicas',
        creditos: 20,
        estado: 'INSCRIPCIONES ABIERTAS',
        descuento: 20.0,
        area: 'ÁREA DE EDUCACIÓN',
        universidad: 'Universidad Amazónica de Pando',
      ),
      ProgramaPosgradoModel.fromHtml(
        id: '2',
        titulo: 'MAESTRÍA EN EDUCACIÓN SUPERIOR',
        tipo: 'MAESTRÍA',
        modalidad: '100% Virtual',
        duracion: '9 meses',
        cargaHoraria: '1.000 Hrs. Académicas',
        creditos: 25,
        estado: 'INSCRIPCIONES ABIERTAS',
        descuento: 20.0,
        area: 'ÁREA DE EDUCACIÓN',
        universidad: 'Universidad Amazónica de Pando',
      ),
      ProgramaPosgradoModel.fromHtml(
        id: '3',
        titulo: 'DOCTORADO EN EDUCACIÓN',
        tipo: 'DOCTORADO',
        modalidad: '100% Virtual',
        duracion: '16 meses',
        cargaHoraria: '2.400 Hrs. Académicas',
        creditos: 60,
        estado: 'INSCRIPCIONES ABIERTAS',
        descuento: 20.0,
        area: 'ÁREA DE EDUCACIÓN',
        universidad: 'Universidad Amazónica de Pando',
      ),
    ];

    // Filtrar por área y tipo si se especifica
    return programas.where((p) {
      if (area != null && !p.area.toLowerCase().contains(area.toLowerCase())) {
        return false;
      }
      if (tipo != null && !p.tipo.toLowerCase().contains(tipo.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }
}
