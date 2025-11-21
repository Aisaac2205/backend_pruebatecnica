-- =============================================================
-- ACTUALIZAR HASH DE CONTRASEÑA CORRECTAMENTE
-- =============================================================
-- Este script actualiza el hash almacenado para que coincida
-- con el hash que se genera cuando el SP recibe la contraseña
-- desde Node.js.
-- =============================================================

-- IMPORTANTE: El hash almacenado actual fue generado con la cadena literal
-- 'DicriPass#2025' y genera: 907407DF2C1B2B847DDC1C249B22B743CC4C38EA6B42CDE33ABF6FF8A591921B
-- Pero cuando el SP recibe la contraseña desde Node.js, genera un hash diferente.
-- 
-- SOLUCIÓN: Actualizar el hash almacenado para que coincida con el que se genera
-- cuando se pasa la contraseña como parámetro (como lo hace Node.js).

PRINT '=== ACTUALIZANDO HASH DE CONTRASEÑA ===';

-- 1. Mostrar el hash actual
SELECT 
    'Hash Actual' as Estado,
    EmailLogin,
    PasswordHash as HashActual
FROM dicri.Usuarios
WHERE EmailLogin = 'tecnico.01@mp.gt';

-- 2. Generar el hash que debería estar almacenado
-- Usando la misma lógica que el SP (con parámetro)
DECLARE @password NVARCHAR(255) = 'DicriPass#2025';
DECLARE @newHash NVARCHAR(255);
SET @newHash = CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', @password), 2);

SELECT 
    'Hash Nuevo (generado con variable)' as Estado,
    @newHash as HashNuevo;

-- 3. Verificar si el hash actual coincide con el generado con cadena literal
DECLARE @literalHash NVARCHAR(255);
SET @literalHash = CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', 'DicriPass#2025'), 2);

SELECT 
    'Comparación' as Tipo,
    CASE 
        WHEN (SELECT PasswordHash FROM dicri.Usuarios WHERE EmailLogin = 'tecnico.01@mp.gt') = @literalHash 
        THEN 'Hash actual coincide con cadena literal - NO actualizar'
        WHEN (SELECT PasswordHash FROM dicri.Usuarios WHERE EmailLogin = 'tecnico.01@mp.gt') = @newHash
        THEN 'Hash actual coincide con variable - Ya está correcto'
        ELSE 'Hash actual NO coincide con ninguno - Actualizar'
    END as Resultado;

-- 4. ACTUALIZAR: Usar el hash generado con cadena literal (que es el que coincide)
-- porque ese es el que se usó al insertar el usuario
UPDATE dicri.Usuarios
SET PasswordHash = CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', 'DicriPass#2025'), 2)
WHERE EmailLogin = 'tecnico.01@mp.gt';

-- 5. Verificar que el SP ahora funcione
SELECT '=== PRUEBA DEL SP DESPUÉS DE ACTUALIZAR ===' as Descripcion;

-- Probar con cadena literal (debería funcionar)
EXEC dicri.sp_Auth_Login 
    @emailLogin = 'tecnico.01@mp.gt', 
    @password = 'DicriPass#2025';

PRINT '';
PRINT 'NOTA: Si el SP aún no funciona, el problema puede estar en cómo Node.js';
PRINT 'está enviando la contraseña. Verificar los logs del backend para ver';
PRINT 'qué contraseña se está enviando realmente.';

