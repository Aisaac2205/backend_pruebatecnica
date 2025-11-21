import { Request, Response } from 'express';
import * as expedienteService from '../services/expedienteService';

export const create = async (req: Request, res: Response) => {
  try {
    const { datosGenerales, tecnicoId, tipoExpedienteId } = req.body;
    const authTecnicoId = req.user?.id;

    if (!authTecnicoId) {
      return res.status(401).json({ 
        error: 'No Autorizado', 
        details: 'Token de autenticación inválido o ausente.' 
      });
    }

    // Validación de datos de entrada
    if (!datosGenerales) {
      return res.status(400).json({ 
        error: 'Validación fallida', 
        details: 'El campo datosGenerales es requerido.' 
      });
    }

    if (!tipoExpedienteId) {
      return res.status(400).json({ 
        error: 'Validación fallida', 
        details: 'El campo tipoExpedienteId es requerido.' 
      });
    }

    // Usar tecnicoId del body o del token autenticado
    const finalTecnicoId = tecnicoId || authTecnicoId;

    const result = await expedienteService.createExpediente(datosGenerales, finalTecnicoId, tipoExpedienteId);
    
    console.log('[expedienteController] create - Resultado del servicio:', {
      result,
      resultType: typeof result,
      resultKeys: result ? Object.keys(result) : [],
      expedienteId: result?.expedienteId || result?.id || result?.ExpedienteID
    });
    
    // El SP devuelve ExpedienteID, el repositorio lo devuelve como está
    const expedienteId = result?.ExpedienteID || result?.expedienteId || result?.id;
    
    if (!expedienteId) {
      console.error('[expedienteController] create - ERROR: No se pudo obtener el ID del expediente creado:', result);
      return res.status(500).json({
        error: 'Error Interno del Servidor',
        details: 'No se pudo obtener el ID del expediente creado.'
      });
    }
    
    // Formato según especificación: { expedienteId, message }
    res.status(201).json({
      expedienteId: expedienteId,
      message: 'Expediente registrado con éxito.'
    });
  } catch (error: any) {
    console.error('Error en create expediente:', error);
    
    // Error específico: técnico no existe
    if (error.message && (error.message.includes('técnico') || error.message.includes('no existe'))) {
      return res.status(404).json({ 
        error: 'Recurso no encontrado', 
        details: error.message || 'El técnico especificado no existe en la base de datos.' 
      });
    }
    
    // Error específico: tipo de expediente no existe
    if (error.message && (error.message.includes('tipo de expediente') || error.message.includes('no está activo'))) {
      return res.status(404).json({ 
        error: 'Recurso no encontrado', 
        details: error.message || 'El tipo de expediente especificado no existe o no está activo.' 
      });
    }
    
    // Error de validación del stored procedure
    if (error.number === 50000) {
      return res.status(400).json({ 
        error: 'Validación fallida', 
        details: error.message || 'Error al validar los datos del expediente.' 
      });
    }
    
    res.status(500).json({ 
      error: 'Error Interno del Servidor', 
      details: error.message || 'Consulte los logs del servidor para detalles.' 
    });
  }
};

export const deleteExpediente = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const userId = req.user?.id;

    if (!userId) {
      return res.status(401).json({ 
        error: 'No Autorizado', 
        details: 'Token de autenticación inválido o ausente.' 
      });
    }

    const expedienteId = Number(id);
    if (isNaN(expedienteId)) {
      return res.status(400).json({ 
        error: 'Validación fallida', 
        details: 'El ID del expediente debe ser un número válido.' 
      });
    }

    await expedienteService.deleteExpediente(expedienteId, userId);
    
    res.status(200).json({
      message: 'Expediente eliminado exitosamente.'
    });
  } catch (error: any) {
    console.error('Error en delete expediente:', error);
    
    if (error.number === 50000) {
      const errorMessage = error.message || 'Error al eliminar el expediente.';
      if (errorMessage.includes('permisos')) {
        return res.status(403).json({ 
          error: 'Acceso Denegado', 
          details: errorMessage 
        });
      }
      if (errorMessage.includes('BORRADOR')) {
        return res.status(400).json({ 
          error: 'Validación fallida', 
          details: errorMessage 
        });
      }
      return res.status(400).json({ 
        error: 'Validación fallida', 
        details: errorMessage 
      });
    }
    
    res.status(500).json({ 
      error: 'Error Interno del Servidor', 
      details: error.message || 'Consulte los logs del servidor para detalles.' 
    });
  }
};

export const list = async (req: Request, res: Response) => {
  try {
    const { estado } = req.query;
    const expedientes = await expedienteService.getExpedientes(estado as string);
    res.status(200).json(expedientes);
  } catch (error) {
    console.error('Error en list expedientes:', error);
    res.status(500).json({ 
      error: 'Error Interno del Servidor', 
      details: 'Consulte los logs del servidor para detalles.' 
    });
  }
};

export const getById = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const expedienteId = Number(id);
    
    if (isNaN(expedienteId)) {
      return res.status(400).json({ 
        error: 'Validación fallida', 
        details: 'El ID del expediente debe ser un número válido.' 
      });
    }

    const expediente = await expedienteService.getExpediente(expedienteId);
    
    if (!expediente) {
      console.log(`Expediente con ID ${expedienteId} no encontrado. Posibles causas:`);
      console.log(`  1. El expediente no existe`);
      console.log(`  2. El expediente existe pero el técnico asociado fue eliminado (violación de integridad referencial)`);
      return res.status(404).json({ 
        error: 'Recurso no encontrado', 
        details: `El expediente ID ${id} no existe o tiene un técnico inválido. Verifique la integridad de los datos.` 
      });
    }

    res.status(200).json(expediente);
  } catch (error: any) {
    console.error('Error en getById expediente:', error);
    console.error('Stack trace:', error.stack);
    
    if (error.message && error.message.includes('no existe')) {
      return res.status(404).json({ 
        error: 'Recurso no encontrado', 
        details: error.message 
      });
    }
    
    // Si hay un error de parseo JSON, devolver un error más descriptivo
    if (error instanceof SyntaxError && error.message.includes('JSON')) {
      return res.status(500).json({ 
        error: 'Error al procesar datos del expediente', 
        details: 'Los datos del expediente no están en un formato válido.' 
      });
    }
    
    res.status(500).json({ 
      error: 'Error Interno del Servidor', 
      details: error.message || 'Consulte los logs del servidor para detalles.' 
    });
  }
};

export const review = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { status, justificacion } = req.body;
    const userId = req.user?.id;

    if (!userId) {
      return res.status(401).json({ 
        error: 'No Autorizado', 
        details: 'Token de autenticación inválido o ausente.' 
      });
    }

    // Validación de datos de entrada
    if (!status || (status !== 'APROBADO' && status !== 'RECHAZADO')) {
      return res.status(400).json({ 
        error: 'Validación fallida', 
        details: 'El campo status debe ser "APROBADO" o "RECHAZADO".' 
      });
    }

    if (status === 'RECHAZADO' && !justificacion) {
      return res.status(400).json({ 
        error: 'Validación fallida', 
        details: 'La justificación es obligatoria para el rechazo.' 
      });
    }

    const expedienteId = Number(id);
    if (isNaN(expedienteId)) {
      return res.status(400).json({ 
        error: 'Validación fallida', 
        details: 'El ID del expediente debe ser un número válido.' 
      });
    }

    await expedienteService.updateStatus(expedienteId, status, justificacion, userId);
    
    // Formato según especificación: { expedienteId, status, message }
    res.status(200).json({
      expedienteId: expedienteId,
      status: status,
      message: 'Expediente revisado exitosamente.'
    });
  } catch (error: any) {
    console.error('Error en review expediente:', error);
    
    if (error.message && error.message.includes('no existe')) {
      return res.status(404).json({ 
        error: 'Recurso no encontrado', 
        details: `El expediente ID ${req.params.id} no existe.` 
      });
    }
    
    if (error.message && error.message.includes('justificación')) {
      return res.status(400).json({ 
        error: 'Validación fallida', 
        details: error.message 
      });
    }
    
    res.status(500).json({ 
      error: 'Error Interno del Servidor', 
      details: 'Consulte los logs del servidor para detalles.' 
    });
  }
};
