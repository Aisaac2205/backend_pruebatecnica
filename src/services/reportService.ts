import * as reportRepository from '../db/reportRepository';

// Los parámetros vienen del controlador con los nombres de la especificación: start_date, end_date, status
export const getReport = async (start_date?: string, end_date?: string, status?: string) => {
  const report = await reportRepository.getReport(start_date, end_date, status);
  return report.map(item => ({
    ...item,
    // Si datosGenerales es un string JSON, parsearlo; si no, dejarlo como está
    datosGenerales: typeof item.datosGenerales === 'string' 
      ? (item.datosGenerales.startsWith('{') || item.datosGenerales.startsWith('[') 
          ? JSON.parse(item.datosGenerales) 
          : item.datosGenerales)
      : item.datosGenerales
  }));
};
