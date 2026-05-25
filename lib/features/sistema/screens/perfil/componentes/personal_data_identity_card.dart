import 'package:flutter/material.dart';
import 'datos_personales_validators.dart';

class PersonalDataIdentityCard extends StatelessWidget {
  final String? ciFrontPath;
  final String? ciBackPath;
  final String? ciPhotocopyPath;
  final String? profilePhotoPath;
  final String ciNumber;
  final VoidCallback onTapManage;

  const PersonalDataIdentityCard({
    super.key,
    this.ciFrontPath,
    this.ciBackPath,
    this.ciPhotocopyPath,
    this.profilePhotoPath,
    required this.ciNumber,
    required this.onTapManage,
  });

  bool get _hasFront => (ciFrontPath ?? '').isNotEmpty;
  bool get _hasBack => (ciBackPath ?? '').isNotEmpty;
  bool get _hasPdf => (ciPhotocopyPath ?? '').isNotEmpty;
  bool get _hasPhoto => (profilePhotoPath ?? '').isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8EEF7)),
        boxShadow: [
          BoxShadow(
            color: DatosPersonalesConstants.primaryBlue.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildCompactStatusTile(
                  'Anverso C.I.',
                  _hasFront,
                  Icons.badge_outlined,
                ),
                _buildCompactStatusTile(
                  'Reverso C.I.',
                  _hasBack,
                  Icons.badge_outlined,
                ),
                _buildCompactStatusTile(
                  'Fotocopia PDF',
                  _hasPdf,
                  Icons.picture_as_pdf_outlined,
                ),
                _buildCompactStatusTile(
                  'Foto 4x4',
                  _hasPhoto,
                  Icons.face_retouching_natural_outlined,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE8EEF7)),
          InkWell(
            onTap: onTapManage,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_upload_outlined,
                    color: Color(0xFF005BAC),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'GESTIONAR DOCUMENTOS',
                    style: TextStyle(
                      color: Color(0xFF005BAC),
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatusTile(String label, bool isReady, IconData icon) {
    return Builder(
      builder: (context) {
        final width = MediaQuery.of(context).size.width;
        return Container(
          width: (width * 0.45) - 34,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isReady
                ? Colors.green.withOpacity(0.05)
                : Colors.orange.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isReady
                  ? Colors.green.withOpacity(0.2)
                  : Colors.orange.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isReady ? Icons.check_circle_rounded : Icons.pending_rounded,
                size: 16,
                color: isReady ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: DatosPersonalesConstants.primaryBlue.withOpacity(
                      0.8,
                    ),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}



