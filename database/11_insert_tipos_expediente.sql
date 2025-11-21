-- =============================================================
-- SCRIPT DE INSERCIÓN DE TIPOS DE EXPEDIENTE (CATÁLOGO)
-- =============================================================
-- Este script inserta los tipos de expediente iniciales
-- =============================================================

-- Verificar si ya existen tipos para evitar duplicados
IF NOT EXISTS (SELECT 1 FROM dicri.TipoExpediente)
BEGIN
    INSERT INTO dicri.TipoExpediente (Nombre, Activo)
    VALUES 
        ('ARMAS DE FUEGO', 1),
        ('BIOLÓGICA (Cuerpos/Fluidos)', 1),
        ('DOCUMENTAL/DIGITAL', 1),
        ('SUSTANCIAS CONTROLADAS', 1),
        ('VARIOS/MISCELÁNEOS', 1),
        ('VESTUARIO/TEXTILES', 1);

    PRINT 'Tipos de expediente insertados correctamente.';
END
ELSE
BEGIN
    PRINT 'Los tipos de expediente ya existen en la base de datos.';
END

-- Verificar los tipos insertados
SELECT TipoExpedienteID as id, Nombre as nombre, Activo
FROM dicri.TipoExpediente
ORDER BY Nombre;

