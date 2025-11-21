-- =============================================================
-- SCRIPT DE INSERCIÓN DE USUARIOS DE PRUEBA
-- Utiliza el esquema 'dicri' y el hash seguro SHA2_256.
-- =============================================================

-- 1. LIMPIEZA (OPCIONAL)
-- Elimina los usuarios de prueba existentes para que el script sea idempotente.
DELETE FROM dicri.Usuarios WHERE EmailLogin IN ('tecnico.01@mp.gt', 'coordinador.01@mp.gt');

-- 2. INSERCIÓN DE USUARIOS
-- IMPORTANTE: Usar variables para asegurar que el hash coincida con el que genera el SP
-- cuando recibe la contraseña como parámetro desde Node.js
DECLARE @passwordTecnico NVARCHAR(255) = 'DicriPass#2025';
DECLARE @passwordCoordinador NVARCHAR(255) = 'RevisorMP@2025';

-- Usuario 1: Técnico
-- Login (Email): tecnico.01@mp.gt
-- Contraseña: DicriPass#2025
INSERT INTO dicri.Usuarios (EmailLogin, PasswordHash, Rol, NombreCompleto, RegistroMP)
VALUES (
    'tecnico.01@mp.gt',
    -- Uso de SHA2_256 con variable (igual que el SP) para asegurar consistencia
    CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', @passwordTecnico), 2),
    'Tecnico',
    'Isaac Sarceño (Técnico)', -- Nombre actualizado
    'TEC-2025-01'
);

-- Usuario 2: Coordinador
-- Login (Email): coordinador.01@mp.gt
-- Contraseña: RevisorMP@2025
INSERT INTO dicri.Usuarios (EmailLogin, PasswordHash, Rol, NombreCompleto, RegistroMP)
VALUES (
    'coordinador.01@mp.gt',
    -- Uso de SHA2_256 con variable (igual que el SP) para asegurar consistencia
    CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', @passwordCoordinador), 2),
    'Coordinador',
    'Fernanda Mejía (Coordinadora)', -- Nombre actualizado
    'COORD-2025-01'
);

-- 3. VERIFICACIÓN
-- Se selecciona la información sin mostrar el hash de la contraseña por seguridad.
SELECT UsuarioID, EmailLogin, Rol, NombreCompleto, RegistroMP, FechaCreacion
FROM dicri.Usuarios
WHERE EmailLogin IN ('tecnico.01@mp.gt', 'coordinador.01@mp.gt');