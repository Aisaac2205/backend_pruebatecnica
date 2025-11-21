import { getConnection, sql } from '../config/db';

export const getReport = async (start_date?: string, end_date?: string, status?: string) => {
  const pool = await getConnection();
  const request = pool.request();

  // Mapear los nombres de la especificación a los parámetros del stored procedure
  if (start_date) request.input('startDate', sql.DateTime2, new Date(start_date));
  if (end_date) request.input('endDate', sql.DateTime2, new Date(end_date));
  if (status) request.input('estado', sql.NVarChar, status);

  const result = await request.execute('dicri.sp_Report_Get');
  return result.recordset;
};
