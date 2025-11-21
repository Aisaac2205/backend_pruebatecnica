import { getConnection, sql } from '../config/db';

export const loginUser = async (email: string, password: string) => {
  try {
    const pool = await getConnection();
    console.log('[authRepository] loginUser - Intentando login:', { email });

    // CORRECCIÓN 1: Se incluye el nombre del esquema 'dicri'
    const storedProcedureName = 'dicri.sp_Auth_Login';
    console.log(`[authRepository] loginUser - Ejecutando stored procedure ${storedProcedureName}`);

    const request = pool.request();

    // CORRECCIÓN 2: El parámetro debe llamarse 'emailLogin' para coincidir con el SP
    // CORRECCIÓN 3: El tipo de dato debe ser NVARCHAR(50) para coincidir con el SP
    request.input('emailLogin', sql.NVarChar(50), email);
    request.input('password', sql.NVarChar(255), password);

    // NOTA: El logging de passwordFull y passwordCharCodes es solo para diagnóstico
    // REMOVER EN PRODUCCIÓN por seguridad
    console.log('[authRepository] loginUser - Parámetros enviados:', {
      emailLogin: email,
      passwordLength: password.length,
      passwordPreview: password.substring(0, 3) + '...',
      // DIAGNÓSTICO TEMPORAL - REMOVER EN PRODUCCIÓN
      passwordFull: password,
      passwordCharCodes: password.split('').map(c => c.charCodeAt(0)).join(',')
    });

    const result = await request.execute(storedProcedureName);

    console.log('[authRepository] loginUser - Resultado del SP:', {
      recordsetLength: result.recordset?.length || 0,
      hasRecordset: !!result.recordset,
      firstRecord: result.recordset?.[0] || null
    });

    if (result.recordset && result.recordset.length > 0) {
      const user = result.recordset[0];
      console.log('[authRepository] loginUser - Usuario encontrado:', {
        id: user.UsuarioID, // Nota: Corregido el nombre de la columna PK a UsuarioID
        email: user.EmailLogin, // Nota: Corregido el nombre de la columna a EmailLogin
        rol: user.Rol,
        nombre: user.NombreCompleto
      });
      // Retornar solo las propiedades necesarias con nombres consistentes para el Service/Controller
      return {
          id: user.UsuarioID,
          email: user.EmailLogin,
          rol: user.Rol,
          nombre: user.NombreCompleto
      };
    } else {
      console.log('[authRepository] loginUser - No se encontró usuario (credenciales inválidas)');
      return null;
    }
  } catch (error: any) {
    console.error('[authRepository] loginUser - ERROR:', error);
    // ... manejo de errores ...
    throw error;
  }
};