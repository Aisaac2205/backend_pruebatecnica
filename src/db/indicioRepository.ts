import { getConnection, sql } from '../config/db';

export const createIndicio = async (
  expedienteId: number,
  descripcion: string,
  color: string,
  tamano: string,
  peso: string,
  ubicacion: string,
  tecnicoId: number
) => {
  const pool = await getConnection();
  // Convertir peso de string a número (DECIMAL), usar 0 si está vacío o no es válido
  const pesoDecimal = peso && peso.trim() !== '' ? parseFloat(peso) : 0;
  
  console.log('[indicioRepository] createIndicio - Parámetros:', {
    expedienteId,
    descripcion,
    color,
    tamano,
    peso: pesoDecimal,
    ubicacion,
    tecnicoId
  });
  
  const result = await pool.request()
    .input('expedienteId', sql.Int, expedienteId)
    .input('descripcion', sql.NVarChar(500), descripcion)
    .input('color', sql.NVarChar(50), color || '')
    .input('tamano', sql.NVarChar(50), tamano || '')
    .input('peso', sql.Decimal(10, 2), pesoDecimal)
    .input('ubicacion', sql.NVarChar(100), ubicacion)
    .input('tecnicoId', sql.Int, tecnicoId)
    .execute('dicri.sp_Indicio_Insert');
  
  console.log('[indicioRepository] createIndicio - Resultado:', {
    recordsetLength: result.recordset?.length || 0,
    indicioId: result.recordset?.[0]?.IndicioID || result.recordset?.[0]?.id
  });
  
  return result.recordset[0];
};

export const getIndiciosByExpediente = async (expedienteId: number) => {
  const pool = await getConnection();
  const result = await pool.request()
    .input('expedienteId', sql.Int, expedienteId)
    .execute('dicri.sp_Indicio_SelectByExpediente');
  
  return result.recordset;
};
