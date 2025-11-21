-- =============================================================
-- VERIFICAR HASH QUE GENERA NODE.JS
-- =============================================================
-- Este script verifica qué hash se genera cuando SQL Server
-- recibe la contraseña como parámetro (como lo hace Node.js)
-- =============================================================

-- El hash que Node.js debería generar es el mismo que cuando
-- se pasa como parámetro al SP. Vamos a simularlo.

-- 1. Simular cómo Node.js envía la contraseña
-- Node.js envía: 'DicriPass#2025' como NVARCHAR
DECLARE @passwordFromNode NVARCHAR(255) = 'DicriPass#2025';

-- 2. Generar hash exactamente como lo hace el SP
DECLARE @hashFromSP NVARCHAR(255);
SET @hashFromSP = CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', @passwordFromNode), 2);

-- 3. Comparar con el hash almacenado
SELECT 
    'Hash Almacenado' as Tipo,
    PasswordHash as HashValue
FROM dicri.Usuarios
WHERE EmailLogin = 'tecnico.01@mp.gt'
UNION ALL
SELECT 
    'Hash desde SP (simulando Node.js)' as Tipo,
    @hashFromSP as HashValue
UNION ALL
SELECT 
    '¿Coinciden?' as Tipo,
    CASE 
        WHEN (SELECT PasswordHash FROM dicri.Usuarios WHERE EmailLogin = 'tecnico.01@mp.gt') = @hashFromSP 
        THEN 'SÍ - Debería funcionar'
        ELSE 'NO - Este es el problema'
    END as HashValue;

-- 4. Si no coinciden, actualizar el hash almacenado al que genera el SP
-- Esto es lo que debería hacer el SP cuando recibe la contraseña desde Node.js
IF (SELECT PasswordHash FROM dicri.Usuarios WHERE EmailLogin = 'tecnico.01@mp.gt') != @hashFromSP
BEGIN
    PRINT 'Los hashes NO coinciden. Actualizando hash almacenado...';
    
    UPDATE dicri.Usuarios
    SET PasswordHash = @hashFromSP
    WHERE EmailLogin = 'tecnico.01@mp.gt';
    
    PRINT 'Hash actualizado.';
END
ELSE
BEGIN
    PRINT 'Los hashes coinciden. El problema está en otra parte.';
END

-- 5. Verificar después de actualizar
SELECT 
    'Después de actualizar' as Estado,
    CASE 
        WHEN PasswordHash = @hashFromSP THEN '✓ Hash correcto'
        ELSE '✗ Error'
    END as Resultado,
    PasswordHash as HashActual
FROM dicri.Usuarios
WHERE EmailLogin = 'tecnico.01@mp.gt';

-- 6. Probar el SP
SELECT '=== PRUEBA DEL SP ===' as Descripcion;
EXEC dicri.sp_Auth_Login 
    @emailLogin = 'tecnico.01@mp.gt', 
    @password = 'DicriPass#2025';

