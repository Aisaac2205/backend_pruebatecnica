-- 03_insert_users.sql
-- Script para crear usuarios iniciales en la base de datos

-- Crear stored procedure para insertar usuarios (opcional, para facilitar la creación)
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'sp_Usuario_Insert')
    DROP PROCEDURE sp_Usuario_Insert;
GO

CREATE PROCEDURE sp_Usuario_Insert
    @username NVARCHAR(50),
    @email NVARCHAR(100),
    @password NVARCHAR(255),
    @rol NVARCHAR(20),
    @nombre NVARCHAR(100),
    @registro_mp NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validar que el rol sea válido
    IF @rol NOT IN ('Tecnico', 'Coordinador')
    BEGIN
        THROW 50000, 'El rol debe ser "Tecnico" o "Coordinador"', 1;
        RETURN;
    END
    
    -- Hashear la contraseña usando SHA1 (compatible con SQL Server 2014)
    -- Para SQL Server 2016 o superior, puedes usar SHA2_256 para mayor seguridad:
    -- SET @passwordHash = CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', @password), 2);
    DECLARE @passwordHash NVARCHAR(255);
    SET @passwordHash = CONVERT(NVARCHAR(255), HASHBYTES('SHA1', @password), 2);
    
    -- Insertar el usuario
    INSERT INTO Usuarios (username, email, passwordHash, rol, nombre, registro_mp)
    VALUES (@username, @email, @passwordHash, @rol, @nombre, @registro_mp);
    
    -- Retornar el ID del usuario creado
    SELECT SCOPE_IDENTITY() as id;
END
GO

-- ============================================
-- CREAR USUARIOS DE PRUEBA
-- ============================================

-- Usuario Técnico
-- Username: tecnico
-- Email: tecnico@dicri.gt
-- Password: tecnico123
EXEC sp_Usuario_Insert 
    @username = 'tecnico',
    @email = 'tecnico@dicri.gt',
    @password = 'tecnico123',
    @rol = 'Tecnico',
    @nombre = 'Juan Técnico',
    @registro_mp = 'TEC-001';

-- Usuario Coordinador
-- Username: coordinador
-- Email: coordinador@dicri.gt
-- Password: coordinador123
EXEC sp_Usuario_Insert 
    @username = 'coordinador',
    @email = 'coordinador@dicri.gt',
    @password = 'coordinador123',
    @rol = 'Coordinador',
    @nombre = 'Ana Coordinadora',
    @registro_mp = 'COORD-001';

-- Verificar que los usuarios se crearon correctamente
SELECT id, username, email, rol, nombre, registro_mp, fechaCreacion
FROM Usuarios;

