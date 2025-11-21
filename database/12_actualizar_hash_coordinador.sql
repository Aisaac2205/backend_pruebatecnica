-- =============================================================
-- ACTUALIZAR HASH DEL COORDINADOR
-- =============================================================
-- Este script actualiza el hash del coordinador para que coincida
-- con el hash que genera el SP cuando recibe la contraseña como parámetro
-- =============================================================

-- 1. Verificar el hash actual del coordinador
SELECT 
    'Hash Actual Almacenado' as Tipo,
    EmailLogin,
    PasswordHash as HashValue
FROM dicri.Usuarios
WHERE EmailLogin = 'coordinador.01@mp.gt';

-- 2. Generar el hash que debería coincidir (como lo hace el SP)
DECLARE @password NVARCHAR(255) = 'RevisorMP@2025';
DECLARE @expectedHash NVARCHAR(255);
SET @expectedHash = CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', @password), 2);

SELECT 
    'Hash Esperado (desde SP)' as Tipo,
    @expectedHash as HashValue;

-- 3. Verificar que coincidan
SELECT 
    'Verificación' as Tipo,
    CASE 
        WHEN (SELECT PasswordHash FROM dicri.Usuarios WHERE EmailLogin = 'coordinador.01@mp.gt') = @expectedHash
        THEN '✓ Los hashes coinciden - El login debería funcionar'
        ELSE '✗ Los hashes NO coinciden - Actualizando hash...'
    END as Resultado;

-- 4. ACTUALIZAR el hash almacenado al que genera el SP
UPDATE dicri.Usuarios
SET PasswordHash = @expectedHash
WHERE EmailLogin = 'coordinador.01@mp.gt';

-- 5. Verificar después de actualizar
SELECT 
    'Después de actualizar' as Estado,
    CASE 
        WHEN PasswordHash = @expectedHash THEN '✓ Hash correcto'
        ELSE '✗ Error'
    END as Resultado,
    PasswordHash as HashActual
FROM dicri.Usuarios
WHERE EmailLogin = 'coordinador.01@mp.gt';

-- 6. Probar el SP
SELECT '=== PRUEBA DEL SP ===' as Descripcion;
EXEC dicri.sp_Auth_Login 
    @emailLogin = 'coordinador.01@mp.gt', 
    @password = 'RevisorMP@2025';

