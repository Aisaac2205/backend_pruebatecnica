-- =============================================================
-- SCRIPT DE CREACIÓN DE PROCEDIMIENTOS ALMACENADOS (SPs) PARA DICRI
-- Adaptado a esquema 'dicri' y nombres de columna PK_ID.
-- =============================================================

-- Catálogos
-- -------------------------------------------------------------
/*
CREATE OR ALTER PROCEDURE dicri.sp_TipoExpediente_SelectAll
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        TipoExpedienteID as id,
        Nombre as nombre
    FROM dicri.TipoExpediente
    WHERE Activo = 1
    ORDER BY Nombre;
END
GO

-- Auth
-- -------------------------------------------------------------
CREATE OR ALTER PROCEDURE dicri.sp_Auth_Login
    @emailLogin NVARCHAR(50), -- Nombre de parámetro actualizado
    @password NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    -- Usar SHA2_256 (más seguro) si SQL Server 2016+
    -- Si es SQL Server 2019 Express, SHA2_256 es compatible.
    DECLARE @passwordHash NVARCHAR(255);
    SET @passwordHash = CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', @password), 2);

    -- Se selecciona el UsuarioID (PK) y Rol para el JWT
    SELECT UsuarioID, EmailLogin, Rol, NombreCompleto -- Seleccionando EmailLogin
    FROM dicri.Usuarios
    WHERE EmailLogin = @emailLogin -- Comparando con EmailLogin
      AND PasswordHash = @passwordHash;
END
GO

-- Expedientes (CRUD)
-- -------------------------------------------------------------
CREATE OR ALTER PROCEDURE dicri.sp_Expediente_Insert
    @datosGenerales NVARCHAR(MAX),
    @tecnicoId INT,
    @tipoExpedienteId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar que el técnico existe (usando UsuarioID)
    IF NOT EXISTS (SELECT 1 FROM dicri.Usuarios WHERE UsuarioID = @tecnicoId)
    BEGIN
        THROW 50000, 'El técnico especificado no existe en la base de datos', 1;
        RETURN;
    END

    -- Validar que el tipo de expediente existe
    IF NOT EXISTS (SELECT 1 FROM dicri.TipoExpediente WHERE TipoExpedienteID = @tipoExpedienteId AND Activo = 1)
    BEGIN
        THROW 50000, 'El tipo de expediente especificado no existe o no está activo', 1;
        RETURN;
    END

    -- Se usa ExpedienteID, TecnicoID y TipoExpedienteID
    INSERT INTO dicri.Expedientes (DatosGenerales, TecnicoID, TipoExpedienteID, Estado)
    OUTPUT INSERTED.ExpedienteID -- Devuelve el ID generado al Backend
    VALUES (@datosGenerales, @tecnicoId, @tipoExpedienteId, 'REGISTRADO');
END
-- GO

CREATE OR ALTER PROCEDURE dicri.sp_Expediente_UpdateStatus
    @expedienteId INT,
    @newStatus NVARCHAR(20),
    @justificacion NVARCHAR(MAX) = NULL,
    @userId INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Actualizar el expediente
        UPDATE dicri.Expedientes
        SET Estado = @newStatus,
            JustificacionRechazo = @justificacion
        WHERE ExpedienteID = @expedienteId;

        -- Registrar el evento en el log (transaccional)
        INSERT INTO dicri.LogRevisiones (ExpedienteID, UsuarioID, Accion, Detalles)
        VALUES (@expedienteId, @userId, @newStatus, @justificacion);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- En caso de error, deshacer los cambios
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW; -- Propagar el error al llamador (Node.js)
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE dicri.sp_Expediente_SelectAll
    @estado NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    -- Alias para mayor claridad (e=Expedientes, u=Usuarios, t=TipoExpediente)
    SELECT e.ExpedienteID, e.DatosGenerales, e.FechaRegistro, e.TecnicoID, e.TipoExpedienteID, e.Estado,
           u.NombreCompleto as TecnicoNombre,
           t.Nombre as TipoExpedienteNombre
    FROM dicri.Expedientes e
    INNER JOIN dicri.Usuarios u ON e.TecnicoID = u.UsuarioID
    INNER JOIN dicri.TipoExpediente t ON e.TipoExpedienteID = t.TipoExpedienteID
    WHERE (@estado IS NULL OR e.Estado = @estado)
    ORDER BY e.FechaRegistro DESC;
END
GO

CREATE OR ALTER PROCEDURE dicri.sp_Expediente_SelectById
    @id INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT e.ExpedienteID, e.DatosGenerales, e.FechaRegistro, e.TecnicoID, e.TipoExpedienteID, e.Estado, e.JustificacionRechazo,
           u.NombreCompleto as TecnicoNombre,
           t.Nombre as TipoExpedienteNombre
    FROM dicri.Expedientes e
    LEFT JOIN dicri.Usuarios u ON e.TecnicoID = u.UsuarioID
    LEFT JOIN dicri.TipoExpediente t ON e.TipoExpedienteID = t.TipoExpedienteID
    WHERE e.ExpedienteID = @id;
END
GO

CREATE OR ALTER PROCEDURE dicri.sp_Expediente_Delete
    @expedienteId INT,
    @userId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validar que el expediente existe
    IF NOT EXISTS (SELECT 1 FROM dicri.Expedientes WHERE ExpedienteID = @expedienteId)
    BEGIN
        THROW 50000, 'El expediente especificado no existe en la base de datos', 1;
        RETURN;
    END
    
    -- Validar que el usuario existe
    IF NOT EXISTS (SELECT 1 FROM dicri.Usuarios WHERE UsuarioID = @userId)
    BEGIN
        THROW 50000, 'El usuario especificado no existe en la base de datos', 1;
        RETURN;
    END
    
    -- Obtener el estado y técnico del expediente
    DECLARE @estado NVARCHAR(20);
    DECLARE @tecnicoId INT;
    DECLARE @usuarioRol NVARCHAR(20);
    
    SELECT @estado = Estado, @tecnicoId = TecnicoID
    FROM dicri.Expedientes
    WHERE ExpedienteID = @expedienteId;
    
    SELECT @usuarioRol = Rol
    FROM dicri.Usuarios
    WHERE UsuarioID = @userId;
    
    -- Validar permisos según el rol
    IF @usuarioRol = 'Tecnico'
    BEGIN
        -- Técnico solo puede eliminar sus propios expedientes
        IF @tecnicoId != @userId
        BEGIN
            THROW 50000, 'No tiene permisos para eliminar este expediente. Solo puede eliminar sus propios expedientes.', 1;
            RETURN;
        END
        
        -- Técnico puede eliminar expedientes en REGISTRADO, PENDIENTE, RECHAZADO o APROBADO
        -- (REGISTRADO y PENDIENTE corresponden a EN_REVISION en el frontend)
        IF @estado NOT IN ('REGISTRADO', 'PENDIENTE', 'RECHAZADO', 'APROBADO')
        BEGIN
            THROW 50000, 'Solo se pueden eliminar expedientes en estado REGISTRADO, PENDIENTE, RECHAZADO o APROBADO', 1;
            RETURN;
        END
    END
    ELSE IF @usuarioRol = 'Coordinador'
    BEGIN
        -- Coordinador solo puede eliminar expedientes en estado REGISTRADO (corresponde a BORRADOR/EN_REVISION en el frontend)
        IF @estado != 'REGISTRADO'
        BEGIN
            THROW 50000, 'El coordinador solo puede eliminar expedientes en estado REGISTRADO', 1;
            RETURN;
        END
    END
    ELSE
    BEGIN
        THROW 50000, 'Rol de usuario no válido', 1;
        RETURN;
    END
    
    -- Eliminar primero los indicios asociados (CASCADE)
    DELETE FROM dicri.Indicios WHERE ExpedienteID = @expedienteId;
    
    -- Eliminar los logs de revisión asociados (si la tabla existe)
    IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'LogRevisiones' AND schema_id = SCHEMA_ID('dicri'))
    BEGIN
        DELETE FROM dicri.LogRevisiones WHERE ExpedienteID = @expedienteId;
    END
    
    -- Eliminar el expediente
    DELETE FROM dicri.Expedientes WHERE ExpedienteID = @expedienteId;
    
    -- Retornar confirmación
    SELECT @expedienteId as ExpedienteID, 'Expediente eliminado exitosamente' as Mensaje;
END
GO

-- Indicios (CRUD)
-- -------------------------------------------------------------
CREATE OR ALTER PROCEDURE dicri.sp_Indicio_Insert
    @expedienteId INT,
    @descripcion NVARCHAR(500), -- Cambiado a 500 según DDL
    @color NVARCHAR(50) = NULL,
    @tamano NVARCHAR(50) = NULL,
    @peso DECIMAL(10, 2) = NULL,     -- Cambiado a DECIMAL según DDL
    @ubicacion NVARCHAR(100) = NULL,
    @tecnicoId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validar que el expediente exista
    IF NOT EXISTS (SELECT 1 FROM dicri.Expedientes WHERE ExpedienteID = @expedienteId)
    BEGIN
        THROW 50000, 'El expediente especificado no existe en la base de datos', 1;
        RETURN;
    END
    
    -- Validar que el técnico exista
    IF NOT EXISTS (SELECT 1 FROM dicri.Usuarios WHERE UsuarioID = @tecnicoId)
    BEGIN
        THROW 50000, 'El técnico especificado no existe en la base de datos', 1;
        RETURN;
    END
    
    -- Convertir strings vacíos a NULL para campos opcionales
    DECLARE @colorValue NVARCHAR(50) = NULLIF(LTRIM(RTRIM(ISNULL(@color, ''))), '');
    DECLARE @tamanoValue NVARCHAR(50) = NULLIF(LTRIM(RTRIM(ISNULL(@tamano, ''))), '');
    DECLARE @ubicacionValue NVARCHAR(100) = NULLIF(LTRIM(RTRIM(ISNULL(@ubicacion, ''))), '');
    
    -- Se usa IndicioID, ExpedienteID, TecnicoID, y el tipo de dato DECIMAL
    INSERT INTO dicri.Indicios (ExpedienteID, Descripcion, Color, Tamano, Peso, Ubicacion, TecnicoID)
    OUTPUT INSERTED.IndicioID
    VALUES (@expedienteId, @descripcion, @colorValue, @tamanoValue, @peso, @ubicacionValue, @tecnicoId);
END
GO

CREATE OR ALTER PROCEDURE dicri.sp_Indicio_SelectByExpediente
    @expedienteId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM dicri.Indicios WHERE ExpedienteID = @expedienteId;
END
GO

-- Logs
-- -------------------------------------------------------------
CREATE OR ALTER PROCEDURE dicri.sp_Log_Insert
    @expedienteId INT,
    @usuarioId INT,
    @accion NVARCHAR(50),
    @detalles NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dicri.LogRevisiones (ExpedienteID, UsuarioID, Accion, Detalles)
    VALUES (@expedienteId, @usuarioId, @accion, @detalles);
END
GO

-- Reports
-- -------------------------------------------------------------
CREATE OR ALTER PROCEDURE dicri.sp_Report_Get
    @startDate DATETIME2(0) = NULL, -- Usar DATETIME2(0) para consistencia
    @endDate DATETIME2(0) = NULL,   -- Usar DATETIME2(0) para consistencia
    @estado NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT e.ExpedienteID, e.FechaRegistro, e.Estado,
           u.NombreCompleto as TecnicoNombre,
           (SELECT COUNT(*) FROM dicri.Indicios i WHERE i.ExpedienteID = e.ExpedienteID) as TotalIndicios
    FROM dicri.Expedientes e
    JOIN dicri.Usuarios u ON e.TecnicoID = u.UsuarioID
    WHERE (@estado IS NULL OR e.Estado = @estado)
      -- Modificar el filtro de fecha para usar DATETIME2(0)
      AND (@startDate IS NULL OR e.FechaRegistro >= @startDate)
      AND (@endDate IS NULL OR e.FechaRegistro <= @endDate)
    ORDER BY e.FechaRegistro DESC;
END
GO
