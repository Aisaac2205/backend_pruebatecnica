import { getConnection, sql } from '../config/db';

export const createExpediente = async (datosGenerales: string, tecnicoId: number, tipoExpedienteId: number) => {
  const pool = await getConnection();
  const result = await pool.request()
    .input('datosGenerales', sql.NVarChar, datosGenerales)
    .input('tecnicoId', sql.Int, tecnicoId)
    .input('tipoExpedienteId', sql.Int, tipoExpedienteId)
    .execute('dicri.sp_Expediente_Insert');
  
  console.log('[expedienteRepository] createExpediente - Resultado del SP:', {
    recordsetLength: result.recordset?.length || 0,
    recordset: result.recordset,
    firstRecord: result.recordset?.[0],
    firstRecordKeys: result.recordset?.[0] ? Object.keys(result.recordset[0]) : []
  });
  
  return result.recordset[0]; // Returns ID
};

export const updateExpedienteStatus = async (expedienteId: number, newStatus: string, justificacion: string | null, userId: number) => {
  const pool = await getConnection();
  await pool.request()
    .input('expedienteId', sql.Int, expedienteId)
    .input('newStatus', sql.NVarChar, newStatus)
    .input('justificacion', sql.NVarChar, justificacion)
    .input('userId', sql.Int, userId)
    .execute('dicri.sp_Expediente_UpdateStatus');
};

export const getAllExpedientes = async (estado?: string) => {
  const pool = await getConnection();
  const request = pool.request();
  
  if (estado) {
    request.input('estado', sql.NVarChar, estado);
  }

  const result = await request.execute('dicri.sp_Expediente_SelectAll');
  return result.recordset;
};

export const deleteExpediente = async (expedienteId: number, userId: number) => {
  const pool = await getConnection();
  const result = await pool.request()
    .input('expedienteId', sql.Int, expedienteId)
    .input('userId', sql.Int, userId)
    .execute('dicri.sp_Expediente_Delete');
  
  return result.recordset[0];
};

export const getExpedienteById = async (id: number) => {
  const pool = await getConnection();
  const result = await pool.request()
    .input('id', sql.Int, id)
    .execute('dicri.sp_Expediente_SelectById');
  
  const expediente = result.recordset?.[0] || null;
  
  console.log(`[expedienteRepository] getExpedienteById(${id}):`, {
    recordsetLength: result.recordset?.length || 0,
    hasExpediente: !!expediente,
    expedienteKeys: expediente ? Object.keys(expediente) : [],
    expedienteRaw: expediente, // Mostrar el objeto completo
    tecnicoNombre: expediente?.TecnicoNombre || expediente?.tecnicoNombre,
    datosGenerales: expediente?.DatosGenerales || expediente?.datosGenerales,
    datosGeneralesType: typeof (expediente?.DatosGenerales || expediente?.datosGenerales),
    tipoExpedienteNombre: expediente?.TipoExpedienteNombre || expediente?.tipoExpedienteNombre
  });
  
  return expediente;
};
