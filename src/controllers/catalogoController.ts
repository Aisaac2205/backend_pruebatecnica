import { Request, Response } from 'express';
import * as catalogoService from '../services/catalogoService';

export const getTiposExpediente = async (req: Request, res: Response) => {
  try {
    const tipos = await catalogoService.getTiposExpediente();
    res.status(200).json(tipos);
  } catch (error: any) {
    console.error('[catalogoController] getTiposExpediente - ERROR:', error);
    res.status(500).json({ 
      error: 'Error Interno del Servidor', 
      details: error.message || 'Consulte los logs del servidor para detalles.' 
    });
  }
};

