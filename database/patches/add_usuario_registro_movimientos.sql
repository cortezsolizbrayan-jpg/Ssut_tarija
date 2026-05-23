-- Guarda el usuario autenticado que registró cada movimiento
BEGIN;

ALTER TABLE movimientos
ADD COLUMN IF NOT EXISTS usuario_registro_id INTEGER NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'fk_movimientos_usuario_registro'
    ) THEN
        ALTER TABLE movimientos
        ADD CONSTRAINT fk_movimientos_usuario_registro
        FOREIGN KEY (usuario_registro_id) REFERENCES usuarios(id)
        ON DELETE SET NULL;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_movimientos_usuario_registro_id
ON movimientos(usuario_registro_id);

COMMIT;
