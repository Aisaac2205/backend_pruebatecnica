-- =============================================================
-- SOLUCIÓN AL PROBLEMA DE HASH
-- =============================================================
-- El problema es que el hash almacenado fue generado con una
-- contraseña diferente o hay un problema de codificación.
-- Este script verifica y corrige el problema.
-- =============================================================

-- 1. Verificar qué contraseña genera el hash almacenado
DECLARE @storedHash NVARCHAR(255) = '907407DF2C1B2B847DDC1C249B22B743CC4C38EA6B42CDE33ABF6FF8A591921B';
DECLARE @testPassword1 NVARCHAR(255) = 'DicriPass#2025';
DECLARE @testPassword2 NVARCHAR(255) = N'DicriPass#2025'; -- Con prefijo N para Unicode
DECLARE @testPassword3 NVARCHAR(255) = 'DicriPass#2025'; -- Sin espacios

-- Generar hashes con diferentes variaciones
SELECT 
    'Variación 1: Sin prefijo N' as Variacion,
    CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', @testPassword1), 2) as HashGenerado,
    CASE 
        WHEN CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', @testPassword1), 2) = @storedHash THEN '✓ COINCIDE'
        ELSE '✗ NO COINCIDE'
    END as Resultado
UNION ALL
SELECT 
    'Variación 2: Con prefijo N (Unicode)' as Variacion,
    CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', @testPassword2), 2) as HashGenerado,
    CASE 
        WHEN CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', @testPassword2), 2) = @storedHash THEN '✓ COINCIDE'
        ELSE '✗ NO COINCIDE'
    END as Resultado
UNION ALL
SELECT 
    'Variación 3: Literal directo' as Variacion,
    CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', 'DicriPass#2025'), 2) as HashGenerado,
    CASE 
        WHEN CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', 'DicriPass#2025'), 2) = @storedHash THEN '✓ COINCIDE'
        ELSE '✗ NO COINCIDE'
    END as Resultado;

-- 2. Verificar el hash almacenado vs el hash que debería ser
SELECT 
    'Hash Almacenado' as Tipo,
    PasswordHash as HashValue
FROM dicri.Usuarios
WHERE EmailLogin = 'tecnico.01@mp.gt'
UNION ALL
SELECT 
    'Hash Esperado (DicriPass#2025)' as Tipo,
    CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', 'DicriPass#2025'), 2) as HashValue;

-- 3. ACTUALIZAR EL HASH CORRECTO
-- Si el hash almacenado no coincide, actualizarlo
UPDATE dicri.Usuarios
SET PasswordHash = CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', 'DicriPass#2025'), 2)
WHERE EmailLogin = 'tecnico.01@mp.gt'
  AND PasswordHash != CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', 'DicriPass#2025'), 2);

-- 4. Verificar que ahora coincida
SELECT 
    'Después de actualizar' as Estado,
    CASE 
        WHEN PasswordHash = CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', 'DicriPass#2025'), 2) THEN '✓ Hash actualizado correctamente'
        ELSE '✗ Error al actualizar'
    END as Resultado,
    PasswordHash as HashActual
FROM dicri.Usuarios
WHERE EmailLogin = 'tecnico.01@mp.gt';

-- 5. Probar el SP después de la actualización
SELECT '=== PRUEBA DEL SP DESPUÉS DE ACTUALIZAR ===' as Descripcion;
EXEC dicri.sp_Auth_Login 
    @emailLogin = 'tecnico.01@mp.gt', 
    @password = 'DicriPass#2025';

