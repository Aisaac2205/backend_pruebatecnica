import { Request, Response } from 'express';
import * as indicioService from '../services/indicioService';

export const create = async (req: Request, res: Response) => {
  try {
    const { expedienteId, descripcion, color, tamano, peso, ubicacion, tecnicoId } = req.body;
    const authTecnicoId = req.user?.id;

    console.log('[indicioController] create - Datos recibidos:', {
      expedienteId,
      descripcion,
      color,
      tamano,
      peso,
      ubicacion,
      tecnicoId,
      authTecnicoId,
      bodyKeys: Object.keys(req.body),
      bodyValues: req.body
    });

    if (!authTecnicoId) {
      return res.status(401).json({ 
        error: 'No Autorizado', 
        details: 'Token de autenticación inválido o ausente.' 
      });
    }

    // Validación de datos de entrada (descripcion y ubicacion son obligatorios según el frontend)
    if (!expedienteId || !descripcion || !ubicacion) {
      console.log('[indicioController] create - Validación fallida:', {
        tieneExpedienteId: !!expedienteId,
        tieneDescripcion: !!descripcion,
        tieneUbicacion: !!ubicacion,
        expedienteId,
        descripcion,
        ubicacion
      });
      return res.status(400).json({ 
        error: 'Validación fallida', 
        details: 'Los campos obligatorios son: expedienteId, descripcion, ubicacion.' 
      });
    }

    // Usar tecnicoId del body o del token autenticado
    const finalTecnicoId = tecnicoId || authTecnicoId;

    // Convertir peso a string si es number, permitir valores vacíos/null
    const pesoString = peso !== undefined && peso !== null 
      ? (typeof peso === 'number' ? peso.toString() : peso)
      : '0';

    // Asegurar que color y tamano sean strings (pueden ser vacíos)
    const colorString = color || '';
    const tamanoString = tamano || '';

    console.log('[indicioController] create - Datos recibidos:', {
      expedienteId,
      descripcion,
      color: colorString,
      tamano: tamanoString,
      peso: pesoString,
      ubicacion,
      tecnicoId: finalTecnicoId
    });

    const result = await indicioService.createIndicio(
      expedienteId, 
      descripcion, 
      colorString, 
      tamanoString, 
      pesoString, 
      ubicacion, 
      finalTecnicoId
    );
    
    // Formato según especificación: { indicioId, message }
    res.status(201).json({
      indicioId: result.indicioId || result.id,
      message: 'Indicio registrado con éxito.'
    });
  } catch (error: any) {
    console.error('Error en create indicio:', error);
    
    if (error.message && error.message.includes('no existe')) {
      return res.status(404).json({ 
        error: 'Recurso no encontrado', 
        details: error.message 
      });
    }
    
    res.status(500).json({ 
      error: 'Error Interno del Servidor', 
      details: 'Consulte los logs del servidor para detalles.' 
    });
  }
};

export const listByExpediente = async (req: Request, res: Response) => {
  try {
    const { expedienteId } = req.params;
    
    if (!expedienteId || isNaN(Number(expedienteId))) {
      return res.status(400).json({ 
        error: 'Validación fallida', 
        details: 'El expedienteId debe ser un número válido.' 
      });
    }

    const indicios = await indicioService.getIndicios(Number(expedienteId));
    res.status(200).json(indicios);
  } catch (error: any) {
    console.error('Error en list indicios:', error);
    
    if (error.message && error.message.includes('no existe')) {
      return res.status(404).json({ 
        error: 'Recurso no encontrado', 
        details: error.message 
      });
    }
    
    res.status(500).json({ 
      error: 'Error Interno del Servidor', 
      details: 'Consulte los logs del servidor para detalles.' 
    });
  }
};
