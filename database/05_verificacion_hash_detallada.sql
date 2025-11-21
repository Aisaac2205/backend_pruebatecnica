-- =============================================================
-- VERIFICACIÓN DETALLADA DE HASHES
-- =============================================================
-- Este script compara los hashes completos y verifica
-- posibles problemas de codificación o espacios
-- =============================================================

-- 1. Obtener hash almacenado completo
SELECT 
    'Hash Almacenado en BD' as Tipo,
    EmailLogin,
    PasswordHash as HashCompleto,
    LEN(PasswordHash) as Longitud,
    ASCII(SUBSTRING(PasswordHash, 1, 1)) as PrimerCharASCII
FROM dicri.Usuarios
WHERE EmailLogin = 'tecnico.01@mp.gt';

-- 2. Generar hash de prueba
SELECT 
    'Hash Generado (SHA2_256)' as Tipo,
    'tecnico.01@mp.gt' as EmailLogin,
    CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', 'DicriPass#2025'), 2) as HashCompleto,
    LEN(CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', 'DicriPass#2025'), 2)) as Longitud,
    ASCII(SUBSTRING(CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', 'DicriPass#2025'), 2), 1, 1)) as PrimerCharASCII;

-- 3. Comparación directa
DECLARE @storedHash NVARCHAR(255);
DECLARE @generatedHash NVARCHAR(255);
DECLARE @testPassword NVARCHAR(255) = 'DicriPass#2025';

SELECT @storedHash = PasswordHash 
FROM dicri.Usuarios 
WHERE EmailLogin = 'tecnico.01@mp.gt';

SET @generatedHash = CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', @testPassword), 2);

SELECT 
    'COMPARACIÓN' as Tipo,
    CASE 
        WHEN @storedHash = @generatedHash THEN '✓ IDÉNTICOS'
        WHEN @storedHash IS NULL THEN '✗ Hash almacenado es NULL'
        ELSE '✗ DIFERENTES'
    END as Resultado,
    @storedHash as HashAlmacenado,
    @generatedHash as HashGenerado,
    LEN(@storedHash) as LongitudAlmacenado,
    LEN(@generatedHash) as LongitudGenerado,
    CASE 
        WHEN @storedHash = @generatedHash THEN 'Los hashes coinciden - El problema está en otra parte'
        ELSE 'Los hashes NO coinciden - Verificar algoritmo o contraseña'
    END as Diagnostico;

-- 4. Verificar si el problema es con espacios o caracteres especiales
SELECT 
    'Verificación de Contraseña' as Tipo,
    'DicriPass#2025' as ContraseñaOriginal,
    LEN('DicriPass#2025') as LongitudContraseña,
    ASCII('#') as ASCIIHash,
    UNICODE('#') as UnicodeHash;

-- 5. Probar el SP directamente con diferentes variaciones
SELECT '=== PRUEBA 1: SP con contraseña exacta ===' as Prueba;
EXEC dicri.sp_Auth_Login 
    @emailLogin = 'tecnico.01@mp.gt', 
    @password = 'DicriPass#2025';

-- 6. Verificar si hay espacios al inicio o final en el hash almacenado
SELECT 
    'Verificación de Espacios' as Tipo,
    EmailLogin,
    PasswordHash,
    LTRIM(RTRIM(PasswordHash)) as HashSinEspacios,
    CASE 
        WHEN PasswordHash = LTRIM(RTRIM(PasswordHash)) THEN 'Sin espacios'
        ELSE 'TIENE ESPACIOS'
    END as TieneEspacios,
    LEN(PasswordHash) as LongitudOriginal,
    LEN(LTRIM(RTRIM(PasswordHash))) as LongitudSinEspacios
FROM dicri.Usuarios
WHERE EmailLogin = 'tecnico.01@mp.gt';

-- 7. Comparar byte por byte (primeros 20 caracteres)
SELECT 
    'Comparación Byte a Byte (primeros 20)' as Tipo,
    LEFT(@storedHash, 20) as Primeros20_Almacenado,
    LEFT(@generatedHash, 20) as Primeros20_Generado,
    CASE 
        WHEN LEFT(@storedHash, 20) = LEFT(@generatedHash, 20) THEN '✓ Coinciden'
        ELSE '✗ Difieren'
    END as Comparacion;

