import { getConnection } from '../config/db';

export const getTiposExpediente = async () => {
  const pool = await getConnection();
  const result = await pool.request()
    .execute('dicri.sp_TipoExpediente_SelectAll');
  
  return result.recordset;
};

