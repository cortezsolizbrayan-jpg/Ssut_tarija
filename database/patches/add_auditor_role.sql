-- Rol Auditor: mismos permisos que Contador
BEGIN;

INSERT INTO rol_permisos (rol, permiso_id, activo)
SELECT 'Auditor', permiso_id, activo
FROM rol_permisos
WHERE rol = 'Contador'
ON CONFLICT (rol, permiso_id) DO UPDATE SET activo = EXCLUDED.activo;

COMMIT;
