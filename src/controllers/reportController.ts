import { Request, Response } from 'express';
import * as reportService from '../services/reportService';

export const getReport = async (req: Request, res: Response) => {
  try {
    // Según especificación: query params son start_date, end_date, status
    const { start_date, end_date, status } = req.query;
    
    // Validación opcional de formato de fecha
    if (start_date && !/^\d{4}-\d{2}-\d{2}$/.test(start_date as string)) {
      return res.status(400).json({ 
        error: 'Validación fallida', 
        details: 'El formato de start_date debe ser YYYY-MM-DD.' 
      });
    }
    
    if (end_date && !/^\d{4}-\d{2}-\d{2}$/.test(end_date as string)) {
      return res.status(400).json({ 
        error: 'Validación fallida', 
        details: 'El formato de end_date debe ser YYYY-MM-DD.' 
      });
    }

    const report = await reportService.getReport(
      start_date as string, 
      end_date as string, 
      status as string
    );
    
    // Formato según especificación: Array de objetos con expedienteId, fechaRegistro, estado, tecnicoNombre, etc.
    res.status(200).json(report);
  } catch (error) {
    console.error('Error en getReport:', error);
    res.status(500).json({ 
      error: 'Error Interno del Servidor', 
      details: 'Consulte los logs del servidor para detalles.' 
    });
  }
};
