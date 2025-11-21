-- =============================================================
-- SCRIPT DE CREACIÓN DE ESQUEMA Y TABLAS PARA DICRI
-- SQL Server 2019 - Buenas Prácticas
-- =============================================================

-- 1. CREACIÓN DEL ESQUEMA (BUENA PRÁCTICA)
-- Esto ayuda a organizar los objetos de la base de datos y a separarlos del esquema 'dbo' por defecto.
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'dicri')
BEGIN
    EXEC('CREATE SCHEMA dicri');
END

-- =============================================================
-- 2. TABLAS DE SEGURIDAD Y USUARIOS
-- =============================================================

-- 2.1. Tabla dicri.Usuarios
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Usuarios' AND schema_id = SCHEMA_ID('dicri'))
BEGIN
    CREATE TABLE dicri.Usuarios (
        UsuarioID INT IDENTITY(1,1) NOT NULL,
        EmailLogin NVARCHAR(50) NOT NULL, -- RENOMBRADO de 'Username' a 'EmailLogin'
        PasswordHash NVARCHAR(255) NOT NULL,
        Rol NVARCHAR(20) NOT NULL,
        NombreCompleto NVARCHAR(100) NOT NULL,
        RegistroMP NVARCHAR(50) NULL,
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Usuarios_FechaCreacion DEFAULT GETDATE(),

        -- Claves y Restricciones
        CONSTRAINT PK_Usuarios PRIMARY KEY (UsuarioID),
        CONSTRAINT UQ_Usuarios_EmailLogin UNIQUE (EmailLogin), -- Renombrada la restricción UNIQUE
        -- Uso de CHECK CONSTRAINT para forzar los roles permitidos
        CONSTRAINT CHK_Usuarios_Rol CHECK (Rol IN ('Tecnico', 'Coordinador'))
    );
END

-- =============================================================
-- 3. TABLAS DE CATÁLOGOS
-- =============================================================

-- 3.1. Tabla dicri.TipoExpediente (Catálogo de Clasificaciones)
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'TipoExpediente' AND schema_id = SCHEMA_ID('dicri'))
BEGIN
    CREATE TABLE dicri.TipoExpediente (
        TipoExpedienteID INT IDENTITY(1,1) NOT NULL,
        Nombre NVARCHAR(100) NOT NULL,
        Activo BIT NOT NULL CONSTRAINT DF_TipoExpediente_Activo DEFAULT 1,
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_TipoExpediente_FechaCreacion DEFAULT GETDATE(),

        -- Claves y Restricciones
        CONSTRAINT PK_TipoExpediente PRIMARY KEY (TipoExpedienteID),
        CONSTRAINT UQ_TipoExpediente_Nombre UNIQUE (Nombre)
    );
END

-- =============================================================
-- 4. TABLAS DE GESTIÓN DE EVIDENCIAS (MAESTRO/DETALLE)
-- =============================================================

-- 4.1. Tabla dicri.Expedientes (Maestro)
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Expedientes' AND schema_id = SCHEMA_ID('dicri'))
BEGIN
    CREATE TABLE dicri.Expedientes (
        ExpedienteID INT IDENTITY(1,1) NOT NULL,
        -- Usamos NVARCHAR(MAX) para datosGenerales, pero si es JSON, JSON es más explícito
        DatosGenerales NVARCHAR(MAX) NOT NULL,
        FechaRegistro DATETIME2(0) NOT NULL CONSTRAINT DF_Expedientes_FechaRegistro DEFAULT GETDATE(),
        TecnicoID INT NOT NULL,
        TipoExpedienteID INT NOT NULL,
        Estado NVARCHAR(20) NOT NULL CONSTRAINT DF_Expedientes_Estado DEFAULT 'REGISTRADO',
        JustificacionRechazo NVARCHAR(MAX) NULL,

        -- Claves y Restricciones
        CONSTRAINT PK_Expedientes PRIMARY KEY (ExpedienteID),
        CONSTRAINT FK_Expedientes_TecnicoID FOREIGN KEY (TecnicoID) REFERENCES dicri.Usuarios(UsuarioID),
        CONSTRAINT FK_Expedientes_TipoExpedienteID FOREIGN KEY (TipoExpedienteID) REFERENCES dicri.TipoExpediente(TipoExpedienteID),
        CONSTRAINT CHK_Expedientes_Estado CHECK (Estado IN ('REGISTRADO', 'PENDIENTE', 'APROBADO', 'RECHAZADO'))
    );
END
ELSE
BEGIN
    -- Migración: Agregar columna TipoExpedienteID si no existe
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dicri.Expedientes') AND name = 'TipoExpedienteID')
    BEGIN
        -- Primero asegurar que existe la tabla TipoExpediente
        IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'TipoExpediente' AND schema_id = SCHEMA_ID('dicri'))
        BEGIN
            CREATE TABLE dicri.TipoExpediente (
                TipoExpedienteID INT IDENTITY(1,1) NOT NULL,
                Nombre NVARCHAR(100) NOT NULL,
                Activo BIT NOT NULL CONSTRAINT DF_TipoExpediente_Activo DEFAULT 1,
                FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_TipoExpediente_FechaCreacion DEFAULT GETDATE(),
                CONSTRAINT PK_TipoExpediente PRIMARY KEY (TipoExpedienteID),
                CONSTRAINT UQ_TipoExpediente_Nombre UNIQUE (Nombre)
            );
        END

        -- Agregar columna con valor por defecto temporal
        ALTER TABLE dicri.Expedientes
        ADD TipoExpedienteID INT NULL;

        -- Crear un tipo por defecto si no existe ninguno
        IF NOT EXISTS (SELECT 1 FROM dicri.TipoExpediente)
        BEGIN
            INSERT INTO dicri.TipoExpediente (Nombre) VALUES ('SIN CLASIFICAR');
        END

        -- Actualizar registros existentes con el primer tipo disponible
        DECLARE @defaultTipoId INT;
        SELECT @defaultTipoId = MIN(TipoExpedienteID) FROM dicri.TipoExpediente;
        
        UPDATE dicri.Expedientes
        SET TipoExpedienteID = @defaultTipoId
        WHERE TipoExpedienteID IS NULL;

        -- Hacer la columna NOT NULL
        ALTER TABLE dicri.Expedientes
        ALTER COLUMN TipoExpedienteID INT NOT NULL;

        -- Agregar la foreign key
        ALTER TABLE dicri.Expedientes
        ADD CONSTRAINT FK_Expedientes_TipoExpedienteID 
        FOREIGN KEY (TipoExpedienteID) REFERENCES dicri.TipoExpediente(TipoExpedienteID);
    END
END

-- 4.2. Tabla dicri.Indicios (Detalle)
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Indicios' AND schema_id = SCHEMA_ID('dicri'))
BEGIN
    CREATE TABLE dicri.Indicios (
        IndicioID INT IDENTITY(1,1) NOT NULL,
        ExpedienteID INT NOT NULL,
        Descripcion NVARCHAR(500) NOT NULL, -- Aumentar a 500 para una descripción más detallada
        Color NVARCHAR(50) NULL,
        Tamano NVARCHAR(50) NULL,
        Peso DECIMAL(10, 2) NULL, -- Uso de DECIMAL para peso (más preciso que NVARCHAR)
        Ubicacion NVARCHAR(100) NULL,
        TecnicoID INT NOT NULL,
        FechaRegistro DATETIME2(0) NOT NULL CONSTRAINT DF_Indicios_FechaRegistro DEFAULT GETDATE(),

        -- Claves y Restricciones
        CONSTRAINT PK_Indicios PRIMARY KEY (IndicioID),
        CONSTRAINT FK_Indicios_ExpedienteID FOREIGN KEY (ExpedienteID) REFERENCES dicri.Expedientes(ExpedienteID),
        CONSTRAINT FK_Indicios_TecnicoID FOREIGN KEY (TecnicoID) REFERENCES dicri.Usuarios(UsuarioID)
    );
END

-- 4.3. Tabla dicri.LogRevisiones
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'LogRevisiones' AND schema_id = SCHEMA_ID('dicri'))
BEGIN
    CREATE TABLE dicri.LogRevisiones (
        LogID INT IDENTITY(1,1) NOT NULL,
        ExpedienteID INT NOT NULL,
        UsuarioID INT NOT NULL,
        Accion NVARCHAR(50) NOT NULL,
        Fecha DATETIME2(0) NOT NULL CONSTRAINT DF_LogRevisiones_Fecha DEFAULT GETDATE(),
        Detalles NVARCHAR(MAX) NULL,

        -- Claves y Restricciones
        CONSTRAINT PK_LogRevisiones PRIMARY KEY (LogID),
        CONSTRAINT FK_LogRevisiones_ExpedienteID FOREIGN KEY (ExpedienteID) REFERENCES dicri.Expedientes(ExpedienteID),
        CONSTRAINT FK_LogRevisiones_UsuarioID FOREIGN KEY (UsuarioID) REFERENCES dicri.Usuarios(UsuarioID)
    );
END