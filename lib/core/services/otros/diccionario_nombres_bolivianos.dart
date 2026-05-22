/// Diccionario de nombres y apellidos bolivianos
/// Uso: corrección auxiliar del OCR cuando el texto extraído es ambiguo
/// Enfoque: OCR + normalización + corrección inteligente + sugerencias
class DiccionarioNombresBolivianos {
  // ─────────────────────────────────────────────────────────────────────────
  // 1) DICCIONARIOS BASE
  // ─────────────────────────────────────────────────────────────────────────

  static const Set<String> nombresMasculinos = {
    'AARON', 'ABEL', 'ABELARDO', 'ABRAHAM', 'ADALBERTO', 'ADAN', 'ADOLFO',
    'AGUSTIN', 'ALBERTO', 'ALCIDES', 'ALDO', 'ALEJANDRO', 'ALEX', 'ALEXIS',
    'ALFREDO', 'ALONSO', 'ALVARO', 'AMADO', 'AMERICO', 'ANDRES', 'ANGEL',
    'ANICETO', 'ANTONIO', 'ARIEL', 'ARMANDO', 'ARNALDO', 'ARSENIO',
    'ARTURO', 'AUGUSTO', 'AURELIO', 'BALDOMERO', 'BENIGNO', 'BENITO',
    'BENJAMIN', 'BERNARDO', 'BOLIVAR', 'BRAULIO', 'BRAYAN', 'BRIAN',
    'BRYAN', 'CAMILO', 'CARLOS', 'CELESTINO', 'CESAR', 'CHRISTIAN',
    'CHRISTOPHER', 'CIPRIANO', 'CLAUDIO', 'CLEMENTE', 'CONSTANTINO',
    'CORNELIO', 'CRISTIAN', 'CRISTHIAN', 'DAMIAN', 'DANIEL', 'DARIO',
    'DAVID', 'DEMETRIO', 'DIEGO', 'DIONISIO', 'DOMINGO', 'DONATO',
    'DYLAN', 'EDGAR', 'EDUARDO', 'EFRAIN', 'ELEAZAR', 'ELIAS', 'ELISEO',
    'ELOY', 'ELVIN', 'ELVIS', 'EMERSON', 'EMILIO', 'EMILIANO', 'ENRIQUE',
    'ENZO', 'EPIFANIO', 'ERNESTO', 'ESTEBAN', 'EUGENIO', 'EUSEBIO',
    'EZEQUIEL', 'FABIAN', 'FABRIZIO', 'FAUSTO', 'FELIX', 'FERNANDO',
    'FIDEL', 'FILEMON', 'FLORENCIO', 'FLORENTINO', 'FORTUNATO', 'FRANCO',
    'FRANKLIN', 'FREDDY', 'FREDY', 'FROILAN', 'GABRIEL', 'GENARO',
    'GERMAN', 'GERSON', 'GIANCARLO', 'GILBERTO', 'GIOVANNI', 'GONZALO',
    'GREGORIO', 'GUILLERMO', 'GUSTAVO', 'HAROLD', 'HARRISON', 'HECTOR',
    'HENRY', 'HERIBERTO', 'HERNAN', 'HILARIO', 'HILTON', 'HIPOLITO',
    'HONORIO', 'HORACIO', 'HUGO', 'IGNACIO', 'IRVIN', 'ISIDORO', 'ISIDRO',
    'ISMAEL', 'ISRAEL', 'IVAN', 'JACINTO', 'JAIR', 'JAIME', 'JAIRO',
    'JAVIER', 'JEFFERSON', 'JEISON', 'JERONIMO', 'JERSON', 'JHOEL',
    'JHON', 'JHONATAN', 'JHONNY', 'JHONY', 'JIMMY', 'JOAQUIN', 'JOEL',
    'JOHN', 'JONATAN', 'JONATHAN', 'JONNY', 'JORDAN', 'JORGE', 'JOSE',
    'JOSUE', 'JUAN', 'JUNIOR', 'JUSTIN', 'JUVENAL', 'KELVIN', 'KENNETH',
    'KENNY', 'KEVIN', 'LADISLAO', 'LEANDRO', 'LEONCIO', 'LEONEL',
    'LEOPOLDO', 'LESTER', 'LEWIS', 'LINO', 'LIONEL', 'LISANDRO', 'LORGIO',
    'LORENZO', 'LUCAS', 'LUCIANO', 'LUCIO', 'LUIGI', 'LUIS', 'MACEDONIO',
    'MAICOL', 'MANUEL', 'MARCELO', 'MARCELINO', 'MARCO', 'MARCOS',
    'MARIANO', 'MARTIN', 'MAURICIO', 'MAURO', 'MAXIMO', 'MAXIMILIANO',
    'MAYKEL', 'MELCHOR', 'MICHAEL', 'MICHEL', 'MIGUEL', 'MILTHON',
    'MILTON', 'MISAEL', 'MOISES', 'NARCISO', 'NELSON', 'NICANOR',
    'NICOMEDES', 'NICOLAS', 'NOEL', 'NORBERTO', 'OBDULIO', 'OCTAVIO',
    'OLIVER', 'OMAR', 'ONESIMO', 'ORESTES', 'ORLANDO', 'OSCAR', 'OSWALDO',
    'OVIDIO', 'PABLO', 'PANTALEON', 'PASCUAL', 'PATRICIO', 'PAUL',
    'PAULO', 'PAULINO', 'PEDRO', 'PERCY', 'PETER', 'PORFIRIO', 'PRIMITIVO',
    'PRUDENCIO', 'RAFAEL', 'RAMON', 'RAUL', 'REINALDO', 'RENE', 'RENSO',
    'REYES', 'RICHARD', 'RICKY', 'RIGOBERTO', 'ROBERTO', 'RODRIGO',
    'ROGER', 'ROLANDO', 'ROMAN', 'RONALD', 'RONALDO', 'RONNY', 'ROSENDO',
    'RUBEN', 'RUDY', 'RUPERTO', 'SAMUEL', 'SANDRO', 'SANTIAGO', 'SATURNINO',
    'SECUNDINO', 'SERGIO', 'SEVERO', 'SILVERIO', 'SILVESTRE', 'SILVIO',
    'SIMON', 'SMITH', 'SOTERO', 'STIVEN', 'TEODORO', 'TIMOTEO', 'TIBURCIO',
    'TOMAS', 'TONY', 'TORIBIO', 'TRINIDAD', 'UBALDO', 'ULISES', 'URBANO',
    'VALENTIN', 'VALERIO', 'VENANCIO', 'VICTOR', 'VICENTE', 'VIRGILIO',
    'WALTER', 'WENCESLAO', 'WILBER', 'WILFREDO', 'WILLIAM', 'WILLY',
    'WILSON', 'XAVIER', 'YAIR', 'YAMIL', 'YEFERSON', 'YEISON', 'YERSON',
    'YHON', 'YOEL', 'YONATAN', 'YORDAN', 'YOVANI', 'YULIAN', 'YURI',
    'ZENOBIO', 'ZENON', 'ZANDER',
  };

  static const Set<String> nombresFemeninos = {
    'ABIGAIL', 'ADRIANA', 'AGUSTINA', 'ALBA', 'ALBINA', 'ALEJANDRA',
    'ALICIA', 'ALIDA', 'ALMA', 'AMANDA', 'AMELIA', 'AMPARO', 'ANA',
    'ANDREA', 'ANGELICA', 'ANTONIA', 'ARACELI', 'ASUNCION', 'AURORA',
    'AZUCENA', 'BEATRIZ', 'BERTHA', 'BLANCA', 'BRIGIDA', 'CAMILA',
    'CANDELARIA', 'CARLA', 'CAROLINA', 'CATALINA', 'CECILIA', 'CELIA',
    'CELESTINA', 'CINTHIA', 'CLAUDIA', 'CONCEPCION', 'CONSUELO', 'CORINA',
    'CRISTINA', 'DAIANA', 'DALILA', 'DANIELA', 'DANNA', 'DAYSI', 'DAYANA',
    'DELFINA', 'DENISE', 'DIANA', 'DOLORES', 'DOMINGA', 'EDITH', 'EDNA',
    'ELENA', 'ELBA', 'ELEONORA', 'ELISA', 'ELIZABETH', 'ELSA', 'ELVIRA',
    'EMILIA', 'ENCARNACION', 'ENRIQUETA', 'EPIFANIA', 'ESPERANZA',
    'ESTEFANIA', 'ESTHER', 'EUGENIA', 'EULALIA', 'EVARISTA', 'EVA',
    'EVELYN', 'FABIOLA', 'FELICIA', 'FELICIDAD', 'FELIPA', 'FERNANDA',
    'FILOMENA', 'FIORELLA', 'FLOR', 'FLORENCIA', 'FRANCISCA', 'GABRIELA',
    'GENOVEVA', 'GEORGINA', 'GERTRUDIS', 'GISELA', 'GISELLE', 'GLORIA',
    'GRACIELA', 'GRISELDA', 'GUADALUPE', 'HERMINIA', 'HILARIA', 'HILDA',
    'HORTENSIA', 'IGNACIA', 'INES', 'INGRID', 'IRENE', 'IRMA', 'ISABEL',
    'ISIDORA', 'IVANA', 'IVONNE', 'JACQUELINE', 'JANET', 'JANETH',
    'JAZMIN', 'JESSICA', 'JENNIFER', 'JOHANNA', 'JOSEFA', 'JOSEFINA',
    'JOSELYN', 'JUANA', 'JUDITH', 'JULIA', 'JULIANA', 'JULISSA', 'JUSTINA',
    'KAREN', 'KARINA', 'KARLA', 'KATIA', 'KELLY', 'KEYLA', 'KIARA',
    'LARA', 'LAURA', 'LEIDY', 'LEONOR', 'LETICIA', 'LIBIA', 'LIDIA',
    'LILIA', 'LILIANA', 'LINA', 'LISETH', 'LORENA', 'LOURDES', 'LUCIA',
    'LUCILA', 'LUCRECIA', 'LUISA', 'LUZ', 'LUZMILA', 'MAGDALENA',
    'MAITE', 'MANUELA', 'MARCELA', 'MARCELINA', 'MARCIA', 'MARGOT',
    'MARGARITA', 'MARIA', 'MARIANA', 'MARIELA', 'MARINA', 'MARISOL',
    'MARLENE', 'MARTHA', 'MAURA', 'MAXIMA', 'MAYRA', 'MELANIA', 'MELISA',
    'MELISSA', 'MERCEDES', 'MICAELA', 'MILAGROS', 'MILENA', 'MIREYA',
    'MIRIAM', 'MISHELL', 'MONICA', 'NADIA', 'NAHOMI', 'NAOMI', 'NANCY',
    'NATALIA', 'NATALY', 'NATHALY', 'NATIVIDAD', 'NAYELI', 'NICOL',
    'NICOLE', 'NIDIA', 'NIEVES', 'NILDA', 'NOELIA', 'NOEMI', 'NOHEMI',
    'NORA', 'NORMA', 'OBDULIA', 'OFELIA', 'OLIMPIA', 'OLGA', 'ORLANDA',
    'OTILIA', 'PAMELA', 'PAOLA', 'PATRICIA', 'PAULINA', 'PETRA', 'PETRONA',
    'PILAR', 'PRIMITIVA', 'PRISCILA', 'PRUDENCIA', 'RAMONA', 'RAQUEL',
    'REBECA', 'REMEDIOS', 'RENATA', 'RICARDA', 'ROCIO', 'ROMINA', 'ROSA',
    'ROSALIA', 'ROSARIO', 'ROXANA', 'RUFINA', 'RUTH', 'SABINA', 'SABRINA',
    'SAMANTHA', 'SANDRA', 'SARA', 'SATURNINA', 'SEBASTIANA', 'SELENA',
    'SERAFINA', 'SHAROL', 'SHARON', 'SHEILA', 'SHIRLEY', 'SILVIA',
    'SILVANA', 'SILVERIA', 'SIMONA', 'SOFIA', 'SOLEDAD', 'SONIA',
    'STEFANIA', 'STEPHANIE', 'SUSANA', 'TANIA', 'TATIANA', 'TEODORA',
    'TERESA', 'TIMOTEA', 'TOMASA', 'TRINIDAD', 'VALENTINA', 'VALERIA',
    'VANESSA', 'VENANCIA', 'VERONICA', 'VICENTA', 'VICTORIA', 'VIRGINIA',
    'VISITACION', 'VIVIANA', 'WENDY', 'XIOMARA', 'XIMENA', 'YADIRA',
    'YAMILE', 'YANETH', 'YASMIN', 'YENNY', 'YESENIA', 'YOLANDA',
    'YULIANA', 'ZENAIDA', 'ZULMA',
  };

  static const Set<String> apellidos = {
    'MAMANI', 'QUISPE', 'CONDORI', 'HUANCA', 'CHOQUE', 'APAZA', 'CALLISAYA',
    'CATARI', 'CHUQUIMIA', 'COLQUE', 'COPA', 'CUSI', 'CUTIPA', 'GUARACHI',
    'HUAYHUA', 'LAIME', 'LIMACHI', 'LOZA', 'MACHACA', 'MARCA', 'NINA',
    'PACO', 'PARI', 'PATZI', 'PILCO', 'POMA', 'QUISBERT', 'TARQUI',
    'TICONA', 'TOLA', 'TUPA', 'VILLCA', 'YUJRA', 'ALANOCA', 'ALAVI',
    'ALCON', 'ARUQUIPA', 'ASPI', 'CANAZA', 'CANQUI', 'CATACORA', 'CUENTAS',
    'LLANQUE', 'MITA', 'ROQUE', 'YUCRA', 'CHAMBI', 'CHURA', 'GUALPA',
    'ILLANES', 'JANKO', 'LLUSCO', 'MAYTA', 'PACORICONA', 'PONGO',
    'QUISOCALA', 'SUXO', 'USNAYO', 'ZACARI', 'ACHACOLLO', 'ANCO',
    'ANCALLA', 'AYAVIRI', 'CALSINA', 'CAPIA', 'COPAJA', 'CORIMANYA',
    'CURACA', 'HUAYLLAS', 'IQUISE', 'JICHIRI', 'JILA', 'LUPACA',
    'QUILLA', 'TUPAC', 'ULLPU', 'USCAMAITA', 'YAPURA', 'AJATA', 'ALAVE',
    'CALLATA', 'CHILLCA', 'CHOQUEHUANCA', 'CHUCTAYA', 'CORAHUA', 'CURASI',
    'HUACANI', 'HUAYCHO', 'JUCUMARI', 'LICIDIO', 'PINAYA', 'SISA',
    'SULCATA', 'URUS', 'CANAVIRI', 'CHICHINO', 'COAQUIRA', 'GUACHALLA',
    'MIRAVE', 'MOLINARES', 'ONDA', 'OSINAGA', 'TURIN', 'BASCOPE', 'BLACUTT',
    'CHACA', 'CHOCUE', 'CONDARCO', 'CORIPUNA', 'CRUZATT', 'GALDAMES',
    'HUARA', 'OMONTE', 'PACAJES', 'SANJINEZ', 'TORRICO', 'URIARTE',
    'VIAMONT', 'VIRUEZ', 'ZUAZO',
    'ABARCA', 'ACOSTA', 'AGUILAR', 'AGUIRRE', 'ALARCON', 'ALBA', 'ALIAGA',
    'ALMENDRAS', 'ALVARADO', 'ALVAREZ', 'ANTEZANA', 'APONTE', 'ARANA',
    'ARDAYA', 'ARELLANO', 'ARGANDONA', 'ARGUELLO', 'ARCE', 'ARIAS',
    'ARNEZ', 'ARRIETA', 'ARTEAGA', 'ASCUI', 'AVILES', 'AYALA', 'BACA',
    'BALLEJOS', 'BARRIENTOS', 'BUSTAMANTE', 'CACERES', 'CALDERON',
    'CAMACHO', 'CANEDO', 'CARVAJAL', 'CARDENAS', 'CARRASCO', 'CASTANEDA',
    'CASTELLON', 'CASTRO', 'CESPEDES', 'CHAVEZ', 'CISNEROS', 'COCA',
    'CONTRERAS', 'CORONEL', 'CORTEZ', 'CRESPO', 'CRUZ', 'CUELLAR',
    'DIAZ', 'DURAN', 'ECHEVERRIA', 'ELIAS', 'ESCALANTE', 'ESCOBAR',
    'ESPINOZA', 'FAJARDO', 'FERNANDEZ', 'FLORES', 'FRANCO', 'GALARZA',
    'GALLO', 'GARCIA', 'GOMEZ', 'GONZALEZ', 'GUTIERREZ', 'HERRERA',
    'HUARACHI', 'IRIARTE', 'JALDIN', 'JAIMES', 'JIMENEZ', 'LEDEZMA',
    'LINARES', 'LIRA', 'LLANOS', 'LOPEZ', 'MACHICADO', 'MALDONADO',
    'MENDEZ', 'MENDOZA', 'MERCADO', 'MIRANDA', 'MOLINA', 'MONTANO',
    'MONTES', 'MORALES', 'MORENO', 'NAVARRO', 'ORELLANA', 'ORTIZ',
    'PADILLA', 'PAREDES', 'PENA', 'PERALTA', 'PEREIRA', 'PEREZ',
    'PINTO', 'PLATA', 'PONCE', 'POVEDA', 'PRADO', 'RAMIREZ', 'RAMOS',
    'REYES', 'RIBERA', 'RICO', 'RIOS', 'RIVERO', 'RODAS', 'RODRIGUEZ',
    'ROJAS', 'ROMERO', 'RUBIN', 'RUIZ', 'SALAS', 'SALAZAR', 'SALGADO',
    'SANCHEZ', 'SANDOVAL', 'SANTANDER', 'SAUCEDO', 'SILES', 'SILVA',
    'SOTO', 'SUAREZ', 'TAPIA', 'TELLEZ', 'TERAN', 'TORRES', 'TORO',
    'UGARTE', 'URQUIDI', 'VACA', 'VALDEZ', 'VALLEJOS', 'VARGAS',
    'VASQUEZ', 'VEGA', 'VELASQUEZ', 'VILLARROEL', 'ZAMBRANA', 'ZARATE',
    'ZENTENO', 'ZUNIGA'
  };

  static Set<String> get todosLosNombres => {
        ...nombresMasculinos,
        ...nombresFemeninos,
      };

  static Set<String> get diccionarioCompleto => {
        ...todosLosNombres,
        ...apellidos,
      };

  // ─────────────────────────────────────────────────────────────────────────
  // 2) NORMALIZACIÓN OCR
  // ─────────────────────────────────────────────────────────────────────────

  static String normalizar(String input) {
    var s = input.toUpperCase().trim();

    // Correcciones típicas de OCR (caracteres confusos a letras)
    // Esto es para nombres, así que convertimos números a letras similares
    s = s
        .replaceAll('0', 'O')  // 0 -> O
        .replaceAll('1', 'I')  // 1 -> I  
        .replaceAll('2', 'Z')  // 2 -> Z (menos común)
        .replaceAll('5', 'S')  // 5 -> S
        .replaceAll('6', 'G')  // 6 -> G
        .replaceAll('8', 'B')  // 8 -> B
        .replaceAll('@', 'A')
        .replaceAll(r'$', 'S');

    // Quitar signos extraños
    s = s.replaceAll(RegExp(r'[^A-ZÁÉÍÓÚÑ\s]'), '');

    // Normalizar tildes a versión sin tilde para comparar
    s = _quitarTildes(s);

    // Espacios múltiples
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

    return s;
  }

  static String _quitarTildes(String s) {
    const mapa = {
      'Á': 'A',
      'É': 'E',
      'Í': 'I',
      'Ó': 'O',
      'Ú': 'U',
      'Ü': 'U',
      'Ñ': 'N', // para comparar mejor, aunque luego puedes restaurar visualmente
    };

    var out = s;
    mapa.forEach((k, v) {
      out = out.replaceAll(k, v);
    });
    return out;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3) UTILIDADES
  // ─────────────────────────────────────────────────────────────────────────

  static bool esNombreConocido(String palabra) {
    final p = normalizar(palabra);
    return todosLosNombres.map(_quitarTildes).contains(p);
  }

  static bool esApellidoConocido(String palabra) {
    final p = normalizar(palabra);
    return apellidos.map(_quitarTildes).contains(p);
  }

  static bool esNombreOApellido(String palabra) =>
      esNombreConocido(palabra) || esApellidoConocido(palabra);

  static int _distanciaLevenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final matrix = List.generate(
      a.length + 1,
      (_) => List.filled(b.length + 1, 0),
    );

    for (int i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        final costo = a[i - 1] == b[j - 1] ? 0 : 1;
        final arriba = matrix[i - 1][j] + 1;
        final izquierda = matrix[i][j - 1] + 1;
        final diagonal = matrix[i - 1][j - 1] + costo;

        matrix[i][j] = [arriba, izquierda, diagonal]
            .reduce((x, y) => x < y ? x : y);
      }
    }

    return matrix[a.length][b.length];
  }

  static double _similitud(String a, String b) {
    final aa = normalizar(a);
    final bb = normalizar(b);
    final dist = _distanciaLevenshtein(aa, bb);
    final maxLen = aa.length > bb.length ? aa.length : bb.length;
    if (maxLen == 0) return 1.0;
    return 1.0 - (dist / maxLen);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 4) MODELO DE RESULTADO
  // ─────────────────────────────────────────────────────────────────────────

  static Map<String, dynamic> buscarMejorCoincidencia(
    String palabra, {
    bool soloNombres = false,
    bool soloApellidos = false,
    int maxSugerencias = 3,
    double umbral = 0.70,
  }) {
    final original = palabra;
    final objetivo = normalizar(palabra);

    if (objetivo.length < 2) {
      return {
        'original': original,
        'normalizado': objetivo,
        'corregido': original.toUpperCase(),
        'confianza': 0.0,
        'cambiado': false,
        'sugerencias': <String>[],
      };
    }

    final Set<String> base = soloApellidos
        ? apellidos
        : soloNombres
            ? todosLosNombres
            : diccionarioCompleto;

    String? mejor;
    double mejorScore = 0.0;

    final candidatos = <Map<String, dynamic>>[];

    for (final entrada in base) {
      final entradaNorm = _quitarTildes(entrada);

      // filtro por longitud para acelerar
      if ((entradaNorm.length - objetivo.length).abs() > 3) continue;

      final score = _similitud(objetivo, entradaNorm);

      if (score >= umbral) {
        candidatos.add({
          'valor': entrada,
          'score': score,
        });
      }

      if (score > mejorScore) {
        mejorScore = score;
        mejor = entrada;
      }
    }

    candidatos.sort((a, b) =>
        (b['score'] as double).compareTo(a['score'] as double));

    final sugerencias = candidatos
        .take(maxSugerencias)
        .map((e) => e['valor'] as String)
        .toList();

    final corregido = mejorScore >= umbral && mejor != null
        ? mejor
        : original.toUpperCase();

    return {
      'original': original,
      'normalizado': objetivo,
      'corregido': corregido,
      'confianza': mejorScore,
      'cambiado': corregido != original.toUpperCase(),
      'sugerencias': sugerencias,
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 5) CORRECCIÓN DE PALABRA
  // ─────────────────────────────────────────────────────────────────────────

  static String corregirPalabra(
    String palabra, {
    bool soloNombres = false,
    bool soloApellidos = false,
    double umbral = 0.72,
  }) {
    final res = buscarMejorCoincidencia(
      palabra,
      soloNombres: soloNombres,
      soloApellidos: soloApellidos,
      umbral: umbral,
    );

    return res['corregido'] as String;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 6) CORRECCIÓN DE CADENA SIMPLE
  // ─────────────────────────────────────────────────────────────────────────

  static String corregirCadena(String texto, {double umbral = 0.72}) {
    if (texto.trim().isEmpty) return texto;

    final limpio = normalizar(texto);
    final partes = limpio.split(RegExp(r'\s+'));

    final corregidas = partes.map((p) {
      if (p.length < 2) return p;
      return corregirPalabra(p, umbral: umbral);
    }).toList();

    return corregidas.join(' ');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 7) CORRECCIÓN INTELIGENTE DE NOMBRE COMPLETO
  //    Regla:
  //    - 1ra y 2da palabra: priorizar nombres
  //    - últimas palabras: priorizar apellidos
  // ─────────────────────────────────────────────────────────────────────────

  static Map<String, dynamic> corregirNombreCompleto(
    String texto, {
    double umbralNombres = 0.70,
    double umbralApellidos = 0.70,
  }) {
    if (texto.trim().isEmpty) {
      return {
        'original': texto,
        'corregido': texto,
        'partes': <Map<String, dynamic>>[],
      };
    }

    final limpio = normalizar(texto);
    final tokens = limpio.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();

    final resultados = <Map<String, dynamic>>[];
    final salida = <String>[];

    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];

      final bool pareceNombre = i < 2;
      final bool pareceApellido = i >= 2;

      Map<String, dynamic> r;

      if (tokens.length == 1) {
        r = buscarMejorCoincidencia(token, umbral: 0.72);
      } else if (pareceNombre) {
        r = buscarMejorCoincidencia(
          token,
          soloNombres: true,
          umbral: umbralNombres,
        );
      } else if (pareceApellido) {
        r = buscarMejorCoincidencia(
          token,
          soloApellidos: true,
          umbral: umbralApellidos,
        );
      } else {
        r = buscarMejorCoincidencia(token, umbral: 0.72);
      }

      resultados.add(r);
      salida.add(r['corregido'] as String);
    }

    return {
      'original': texto,
      'normalizado': limpio,
      'corregido': salida.join(' '),
      'partes': resultados,
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 8) TOP SUGERENCIAS PARA UI
  // ─────────────────────────────────────────────────────────────────────────

  static List<String> sugerirNombres(String texto, {int max = 5}) {
    final res = corregirNombreCompleto(texto);
    final partes = (res['partes'] as List).cast<Map<String, dynamic>>();

    final sugerenciasPorParte = <List<String>>[];

    for (final p in partes) {
      final sug = (p['sugerencias'] as List?)?.cast<String>() ?? [];
      if (sug.isEmpty) {
        sugerenciasPorParte.add([p['corregido'] as String]);
      } else {
        sugerenciasPorParte.add(sug.take(2).toList());
      }
    }

    // combinar pocas opciones (máximo simple)
    final combinaciones = <String>[];

    void backtrack(int idx, List<String> actual) {
      if (combinaciones.length >= max) return;
      if (idx == sugerenciasPorParte.length) {
        combinaciones.add(actual.join(' '));
        return;
      }

      for (final opcion in sugerenciasPorParte[idx]) {
        actual.add(opcion);
        backtrack(idx + 1, actual);
        actual.removeLast();
      }
    }

    backtrack(0, []);
    return combinaciones.toSet().take(max).toList();
  }
}
