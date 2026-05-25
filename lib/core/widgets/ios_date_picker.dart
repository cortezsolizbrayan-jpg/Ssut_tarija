import 'package:flutter/material.dart';

/// Selector de fecha estilo iPhone (ruedas giratorias / drum-roll).
///
/// - **Día**: scroll infinito 01-31 (se clampea al confirmar según el mes/año).
/// - **Mes**: scroll infinito Ene-Dic.
/// - **Año**: scroll acotado dentro del rango permitido.
///
/// Regla de 18 años:
///   - `esFechaNacimiento: true`  → año máximo = hoy - 18, año mínimo = hoy - 100.
///   - `esFechaNacimiento: false` → usa `minimumYear` / `maximumYear`.
class IosFechaPicker extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime> onDateChanged;
  final bool esFechaNacimiento;
  final int? minimumYear;
  final int? maximumYear;

  const IosFechaPicker({
    super.key,
    required this.initialDate,
    required this.onDateChanged,
    this.esFechaNacimiento = false,
    this.minimumYear,
    this.maximumYear,
  });

  @override
  State<IosFechaPicker> createState() => _IosFechaPickerState();
}

class _IosFechaPickerState extends State<IosFechaPicker> {
  // itemExtent de cada ítem de las ruedas
  static const double _kItemExtent = 42.0;

  // Multiplicador para simular scroll "infinito"
  // Días: 31 fijo × 500  = 15 500
  // Meses: 12 × 1000     = 12 000
  static const int _kDayMult   = 500;
  static const int _kMonthMult = 1000;

  // Siempre 31 días en la rueda (se clampea al confirmar)
  static const int _kDaysInWheel = 31;

  late int _selDay;
  late int _selMonth;
  late int _selYear;

  late int _minYear;
  late int _maxYear;

  late FixedExtentScrollController _dayCtrl;
  late FixedExtentScrollController _monthCtrl;
  late FixedExtentScrollController _yearCtrl;

  static const List<String> _kMonths = [
    'Ene','Feb','Mar','Abr','May','Jun',
    'Jul','Ago','Sep','Oct','Nov','Dic',
  ];

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    // ── Rango de años ──────────────────────────────────────────────
    if (widget.esFechaNacimiento) {
      _maxYear = now.year - 18;
      _minYear = now.year - 100;
    } else {
      _minYear = widget.minimumYear ?? 1950;
      _maxYear = widget.maximumYear ?? now.year;
    }

    // ── Fecha inicial (clampada al rango) ─────────────────────────
    DateTime d = widget.initialDate;
    if (d.year > _maxYear) d = DateTime(_maxYear, d.month, d.day);
    if (d.year < _minYear) d = DateTime(_minYear, d.month, d.day);

    _selDay   = d.day.clamp(1, 31);
    _selMonth = d.month.clamp(1, 12);
    _selYear  = d.year.clamp(_minYear, _maxYear);

    // ── Posición inicial de cada rueda ────────────────────────────
    // Centrada en la mitad del bucle multiplicado para eliminar bordes
    final int dayInit =
        (_selDay - 1) + (_kDayMult ~/ 2) * _kDaysInWheel;
    final int monthInit =
        (_selMonth - 1) + (_kMonthMult ~/ 2) * 12;
    final int yearInit  = _selYear - _minYear;

    _dayCtrl   = FixedExtentScrollController(initialItem: dayInit);
    _monthCtrl = FixedExtentScrollController(initialItem: monthInit);
    _yearCtrl  = FixedExtentScrollController(initialItem: yearInit);
  }

  @override
  void dispose() {
    _dayCtrl.dispose();
    _monthCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────

  int _daysInMonth(int m, int y) => DateTime(y, m + 1, 0).day;

  void _notify() {
    final maxD = _daysInMonth(_selMonth, _selYear);
    final safeDay = _selDay.clamp(1, maxD);
    widget.onDateChanged(DateTime(_selYear, _selMonth, safeDay));
  }

  // ── Callbacks ─────────────────────────────────────────────────

  void _onDay(int i) {
    _selDay = (i % _kDaysInWheel) + 1;
    _notify();
  }

  void _onMonth(int i) {
    _selMonth = (i % 12) + 1;
    _notify();
  }

  void _onYear(int i) {
    _selYear = (_minYear + i).clamp(_minYear, _maxYear);
    _notify();
  }

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final int totalYears = (_maxYear - _minYear + 1).clamp(1, 9999);

    return Row(
      children: [
        // ── Día ──────────────────────────────────────────────────
        Expanded(
          flex: 2,
          child: _Wheel(
            controller: _dayCtrl,
            itemCount: _kDaysInWheel * _kDayMult,
            itemExtent: _kItemExtent,
            onChanged: _onDay,
            builder: (i) => (i % _kDaysInWheel + 1).toString().padLeft(2, '0'),
          ),
        ),
        // ── Mes ──────────────────────────────────────────────────
        Expanded(
          flex: 3,
          child: _Wheel(
            controller: _monthCtrl,
            itemCount: 12 * _kMonthMult,
            itemExtent: _kItemExtent,
            onChanged: _onMonth,
            builder: (i) => _kMonths[i % 12],
          ),
        ),
        // ── Año ──────────────────────────────────────────────────
        Expanded(
          flex: 3,
          child: _Wheel(
            controller: _yearCtrl,
            itemCount: totalYears,
            itemExtent: _kItemExtent,
            onChanged: _onYear,
            builder: (i) => (_minYear + i).toString(),
          ),
        ),
      ],
    );
  }
}

// ── Rueda genérica ─────────────────────────────────────────────────────────

class _Wheel extends StatelessWidget {
  final FixedExtentScrollController controller;
  final int itemCount;
  final double itemExtent;
  final ValueChanged<int> onChanged;
  final String Function(int index) builder;

  const _Wheel({
    required this.controller,
    required this.itemCount,
    required this.itemExtent,
    required this.onChanged,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: itemExtent,
      onSelectedItemChanged: onChanged,
      physics: const FixedExtentScrollPhysics(),
      perspective: 0.002,
      diameterRatio: 1.5,
      overAndUnderCenterOpacity: 0.35,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: itemCount,
        builder: (context, index) {
          if (index < 0 || index >= itemCount) return null;
          return Center(
            child: Text(
              builder(index),
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A1A),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Bottom-sheet helper ────────────────────────────────────────────────────

/// Muestra el picker en un bottom-sheet y devuelve la fecha elegida.
Future<DateTime?> mostrarIosFechaPicker({
  required BuildContext context,
  DateTime? initialDate,
  String titulo = 'Seleccionar Fecha',
  bool esFechaNacimiento = false,
  int? minimumYear,
  int? maximumYear,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _IosFechaSheet(
      initialDate: initialDate ?? DateTime.now(),
      titulo: titulo,
      esFechaNacimiento: esFechaNacimiento,
      minimumYear: minimumYear,
      maximumYear: maximumYear,
    ),
  );
}

// ── Sheet interna ──────────────────────────────────────────────────────────

class _IosFechaSheet extends StatefulWidget {
  final DateTime initialDate;
  final String titulo;
  final bool esFechaNacimiento;
  final int? minimumYear;
  final int? maximumYear;

  const _IosFechaSheet({
    required this.initialDate,
    required this.titulo,
    required this.esFechaNacimiento,
    this.minimumYear,
    this.maximumYear,
  });

  @override
  State<_IosFechaSheet> createState() => _IosFechaSheetState();
}

class _IosFechaSheetState extends State<_IosFechaSheet> {
  late DateTime _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 320,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // ── Asa ──────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 2),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // ── Header ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      widget.titulo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A3A5C),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, _current),
                    child: const Text(
                      'Confirmar',
                      style: TextStyle(
                        color: Color(0xFF005BAC),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 0.5),

            // ── Picker ───────────────────────────────────────────
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Ruedas
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        textScaler: TextScaler.noScaling,
                      ),
                      child: IosFechaPicker(
                        initialDate: widget.initialDate,
                        onDateChanged: (d) => _current = d,
                        esFechaNacimiento: widget.esFechaNacimiento,
                        minimumYear: widget.minimumYear,
                        maximumYear: widget.maximumYear,
                      ),
                    ),
                  ),

                  // Indicador de selección (líneas estilo iOS)
                  IgnorePointer(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Línea superior
                        Container(
                          height: 0.5,
                          color: Colors.grey.shade400,
                        ),
                        SizedBox(height: 42), // coincide con _kItemExtent
                        // Línea inferior
                        Container(
                          height: 0.5,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
