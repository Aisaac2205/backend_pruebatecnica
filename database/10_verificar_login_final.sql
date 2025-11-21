-- =============================================================
-- VERIFICACIÓN FINAL DEL LOGIN
-- =============================================================
-- Este script verifica que el login funcione después de
-- actualizar el hash almacenado.
-- =============================================================

-- 1. Verificar el hash actual almacenado
SELECT 
    'Hash Actual Almacenado' as Tipo,
    EmailLogin,
    PasswordHash as HashValue
FROM dicri.Usuarios
WHERE EmailLogin = 'tecnico.01@mp.gt';

-- 2. Generar el hash que debería coincidir (como lo hace el SP)
DECLARE @password NVARCHAR(255) = 'DicriPass#2025';
DECLARE @expectedHash NVARCHAR(255);
SET @expectedHash = CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', @password), 2);

SELECT 
    'Hash Esperado (desde SP)' as Tipo,
    @expectedHash as HashValue;

-- 3. Verificar que coincidan
SELECT 
    'Verificación' as Tipo,
    CASE 
        WHEN (SELECT PasswordHash FROM dicri.Usuarios WHERE EmailLogin = 'tecnico.01@mp.gt') = @expectedHash
        THEN '✓ Los hashes coinciden - El login debería funcionar'
        ELSE '✗ Los hashes NO coinciden - Hay un problema'
    END as Resultado;

-- 4. Ejecutar el SP de login
SELECT '=== RESULTADO DEL SP DE LOGIN ===' as Descripcion;
EXEC dicri.sp_Auth_Login 
    @emailLogin = 'tecnico.01@mp.gt', 
    @password = 'DicriPass#2025';

-- 5. Si el SP devuelve resultados, el login debería funcionar
-- Si no devuelve resultados, hay otro problema

