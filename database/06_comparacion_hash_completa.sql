-- =============================================================
-- COMPARACIÓN COMPLETA DE HASHES - LADO A LADO
-- =============================================================
-- Este script muestra los hashes completos para comparación visual
-- =============================================================

DECLARE @storedHash NVARCHAR(255);
DECLARE @generatedHash NVARCHAR(255);
DECLARE @testPassword NVARCHAR(255) = 'DicriPass#2025';
DECLARE @testEmail NVARCHAR(50) = 'tecnico.01@mp.gt';

-- Obtener hash almacenado
SELECT @storedHash = PasswordHash 
FROM dicri.Usuarios 
WHERE EmailLogin = @testEmail;

-- Generar hash
SET @generatedHash = CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', @testPassword), 2);

-- Mostrar comparación completa
SELECT 
    'HASH ALMACENADO' as Tipo,
    @storedHash as HashCompleto,
    LEN(@storedHash) as Longitud
UNION ALL
SELECT 
    'HASH GENERADO' as Tipo,
    @generatedHash as HashCompleto,
    LEN(@generatedHash) as Longitud
UNION ALL
SELECT 
    '¿SON IGUALES?' as Tipo,
    CASE 
        WHEN @storedHash = @generatedHash THEN 'SÍ - Los hashes son idénticos'
        WHEN @storedHash IS NULL THEN 'ERROR - Hash almacenado es NULL'
        ELSE 'NO - Los hashes son diferentes'
    END as HashCompleto,
    CASE 
        WHEN @storedHash = @generatedHash THEN 1
        ELSE 0
    END as Longitud;

-- Verificar el SP paso a paso
PRINT '=== SIMULACIÓN DEL SP PASO A PASO ===';

DECLARE @spPasswordHash NVARCHAR(255);
SET @spPasswordHash = CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', @testPassword), 2);

SELECT 
    'Paso 1: Hash generado en SP' as Paso,
    @spPasswordHash as Valor;

SELECT 
    'Paso 2: Usuario encontrado por EmailLogin' as Paso,
    UsuarioID,
    EmailLogin,
    PasswordHash,
    CASE 
        WHEN EmailLogin = @testEmail THEN 'Email coincide'
        ELSE 'Email NO coincide'
    END as VerificacionEmail
FROM dicri.Usuarios
WHERE EmailLogin = @testEmail;

SELECT 
    'Paso 3: Comparación de PasswordHash' as Paso,
    CASE 
        WHEN @storedHash = @spPasswordHash THEN 'PasswordHash coincide'
        ELSE 'PasswordHash NO coincide'
    END as VerificacionHash,
    @storedHash as HashAlmacenado,
    @spPasswordHash as HashGeneradoEnSP;

-- Ejecutar el SP completo
SELECT '=== RESULTADO DEL SP ===' as Descripcion;
EXEC dicri.sp_Auth_Login 
    @emailLogin = @testEmail, 
    @password = @testPassword;

