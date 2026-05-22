import 'package:flutter/cupertino.dart';

/// Muestra un diálogo de alerta estilo iOS
Future<T?> showIosAlert<T>({
  required BuildContext context,
  required String title,
  required String message,
  String? cancelButtonText,
  String? defaultButtonText,
  Widget? icon,
  bool barrierDismissible = true,
}) {
  return showCupertinoDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => CupertinoAlertDialog(
      title: icon != null
          ? Column(
              children: [
                icon,
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          : Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
      content: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15),
        ),
      ),
      actions: [
        if (cancelButtonText != null)
          CupertinoDialogAction(
            child: Text(
              cancelButtonText,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            onPressed: () => Navigator.of(context).pop(false),
          ),
        if (defaultButtonText != null)
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text(
              defaultButtonText,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            onPressed: () => Navigator.of(context).pop(true),
          ),
      ],
    ),
  );
}

/// Muestra un diálogo de confirmación con opciones Cancelar/Confirmar
Future<bool?> showIosConfirm({
  required BuildContext context,
  required String title,
  required String message,
  String cancelText = 'Cancelar',
  String confirmText = 'Confirmar',
  Widget? icon,
}) {
  return showIosAlert<bool>(
    context: context,
    title: title,
    message: message,
    cancelButtonText: cancelText,
    defaultButtonText: confirmText,
    icon: icon,
  );
}

/// Muestra un diálogo de opciones estilo Action Sheet
Future<T?> showIosActionSheet<T>({
  required BuildContext context,
  required String title,
  required List<ActionSheetAction> actions,
  String? cancelButtonText,
}) {
  return showCupertinoModalPopup<T>(
    context: context,
    builder: (context) => CupertinoActionSheet(
      title: Text(
        title,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
      actions: actions.map((action) {
        return CupertinoActionSheetAction(
          child: Text(
            action.title,
            style: TextStyle(
              color: action.isDestructive
                  ? CupertinoColors.destructiveRed
                  : CupertinoColors.activeBlue,
              fontWeight: FontWeight.w500,
            ),
          ),
          onPressed: () {
            Navigator.of(context).pop(action.value);
          },
        );
      }).toList(),
      cancelButton: cancelButtonText != null
          ? CupertinoActionSheetAction(
              child: Text(
                cancelButtonText,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              onPressed: () => Navigator.of(context).pop(null),
            )
          : null,
    ),
  );
}

/// Modelo para acciones del Action Sheet
class ActionSheetAction<T> {
  final String title;
  final T value;
  final bool isDestructive;

  const ActionSheetAction({
    required this.title,
    required this.value,
    this.isDestructive = false,
  });
}

