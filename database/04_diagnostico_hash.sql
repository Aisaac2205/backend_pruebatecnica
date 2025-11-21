-- =============================================================
-- SCRIPT DE DIAGNÓSTICO PARA PROBLEMA DE HASH DE CONTRASEÑA
-- =============================================================
-- Este script ayuda a identificar problemas de inconsistencia
-- entre el hash almacenado y el hash generado durante el login.
-- =============================================================

-- =============================================================
-- 1. VERIFICAR ESTRUCTURA DE LA TABLA
-- =============================================================
PRINT '=== VERIFICACIÓN DE ESTRUCTURA DE TABLA ===';
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dicri' 
  AND TABLE_NAME = 'Usuarios'
ORDER BY ORDINAL_POSITION;

-- =============================================================
-- 2. VERIFICAR USUARIOS EXISTENTES
-- =============================================================
PRINT '';
PRINT '=== USUARIOS EN LA BASE DE DATOS ===';
SELECT 
    UsuarioID,
    EmailLogin,
    Rol,
    NombreCompleto,
    LEN(PasswordHash) as PasswordHashLength,
    LEFT(PasswordHash, 10) + '...' as PasswordHashPreview
FROM dicri.Usuarios;

-- =============================================================
-- 3. COMPARACIÓN DETALLADA DE HASHES
-- =============================================================
PRINT '';
PRINT '=== COMPARACIÓN DE HASHES ===';

-- Generar el hash de la contraseña de prueba
DECLARE @testPassword NVARCHAR(255) = 'DicriPass#2025';
DECLARE @testEmail NVARCHAR(50) = 'tecnico.01@mp.gt';
DECLARE @generatedHash NVARCHAR(255);
SET @generatedHash = CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', @testPassword), 2);

-- Obtener el hash almacenado
DECLARE @storedHash NVARCHAR(255);
SELECT @storedHash = PasswordHash 
FROM dicri.Usuarios 
WHERE EmailLogin = @testEmail;

-- Mostrar comparación en un SELECT para que se vea en los resultados
SELECT 
    'Hash Almacenado' as Tipo,
    @storedHash as HashValue,
    LEN(@storedHash) as Longitud
UNION ALL
SELECT 
    'Hash Generado' as Tipo,
    @generatedHash as HashValue,
    LEN(@generatedHash) as Longitud
UNION ALL
SELECT 
    CASE 
        WHEN @storedHash = @generatedHash THEN 'COINCIDEN'
        ELSE 'NO COINCIDEN'
    END as Tipo,
    CASE 
        WHEN @storedHash = @generatedHash THEN 'Los hashes son identicos'
        ELSE 'Los hashes son diferentes - Verificar algoritmo o contraseña'
    END as HashValue,
    CASE 
        WHEN @storedHash = @generatedHash THEN 1
        ELSE 0
    END as Longitud;

-- =============================================================
-- 4. EJECUTAR EL SP DE LOGIN MANUALMENTE
-- =============================================================
-- Este SELECT mostrará los resultados del SP
SELECT 'Resultado del SP sp_Auth_Login' as Descripcion;
EXEC dicri.sp_Auth_Login 
    @emailLogin = 'tecnico.01@mp.gt', 
    @password = 'DicriPass#2025';

-- =============================================================
-- 5. VERIFICAR ALGORITMO DE HASH EN INSERCIÓN
-- =============================================================
PRINT '';
PRINT '=== VERIFICACIÓN DE ALGORITMO DE HASH ===';
PRINT 'Hash con SHA2_256:';
SELECT CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', 'DicriPass#2025'), 2) as Hash_SHA2_256;

PRINT '';
PRINT 'Hash con SHA1 (NO DEBE USARSE):';
SELECT CONVERT(NVARCHAR(255), HASHBYTES('SHA1', 'DicriPass#2025'), 2) as Hash_SHA1;

PRINT '';
PRINT 'NOTA: Ambos scripts (inserción y login) DEBEN usar SHA2_256';
PRINT 'Si los hashes no coinciden, verificar que ambos usen el mismo algoritmo.';

-- =============================================================
-- 6. VERIFICAR PARÁMETROS DEL SP
-- =============================================================
PRINT '';
PRINT '=== VERIFICACIÓN DE PARÁMETROS DEL SP ===';
SELECT 
    PARAMETER_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    PARAMETER_MODE
FROM INFORMATION_SCHEMA.PARAMETERS
WHERE SPECIFIC_SCHEMA = 'dicri'
  AND SPECIFIC_NAME = 'sp_Auth_Login'
ORDER BY ORDINAL_POSITION;

PRINT '';
PRINT 'NOTA: El SP debe tener los parámetros:';
PRINT '  - @emailLogin NVARCHAR(50)';
PRINT '  - @password NVARCHAR(255)';

