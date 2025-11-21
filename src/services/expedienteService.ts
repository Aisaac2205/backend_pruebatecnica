import * as expedienteRepository from '../db/expedienteRepository';

export const createExpediente = async (datosGenerales: any, tecnicoId: number, tipoExpedienteId: number) => {
  // Validar que el tecnicoId sea válido antes de intentar crear
  if (!tecnicoId || tecnicoId <= 0) {
    throw new Error('El ID del técnico es inválido');
  }
  
  // Validar que el tipoExpedienteId sea válido
  if (!tipoExpedienteId || tipoExpedienteId <= 0) {
    throw new Error('El ID del tipo de expediente es inválido');
  }
  
  // El frontend ya envía datosGenerales como string JSON
  // Si viene como objeto, convertirlo a string
  // Si ya es string, verificar si está doblemente escapado y corregirlo
  let datosString: string;
  
  if (typeof datosGenerales === 'string') {
    // Intentar detectar si está doblemente escapado
    try {
      // Si puede parsearse y el resultado es un string, está doblemente escapado
      const parsed = JSON.parse(datosGenerales);
      if (typeof parsed === 'string') {
        // Está doblemente escapado, usar el valor parseado
        datosString = parsed;
      } else {
        // No está doblemente escapado, pero es un objeto, volver a stringify
        datosString = JSON.stringify(parsed);
      }
    } catch {
      // No es JSON válido, usar tal cual
      datosString = datosGenerales;
    }
  } else {
    // Es un objeto, convertirlo a string JSON
    datosString = JSON.stringify(datosGenerales);
  }
  
  console.log('[expedienteService] createExpediente - datosString:', datosString.substring(0, 100));
  
  try {
    return await expedienteRepository.createExpediente(datosString, tecnicoId, tipoExpedienteId);
  } catch (error: any) {
    // Si el error es sobre técnico no existente, lanzar error más descriptivo
    if (error.message && (error.message.includes('técnico') || error.message.includes('no existe'))) {
      throw new Error(`El técnico con ID ${tecnicoId} no existe en la base de datos`);
    }
    // Si el error es sobre tipo de expediente
    if (error.message && (error.message.includes('tipo de expediente') || error.message.includes('no está activo'))) {
      throw new Error(`El tipo de expediente con ID ${tipoExpedienteId} no existe o no está activo`);
    }
    throw error;
  }
};

export const updateStatus = async (expedienteId: number, newStatus: string, justificacion: string | null, userId: number) => {
  // Business logic: Check if status transition is valid?
  // For now, just call repo.
  if (newStatus === 'RECHAZADO' && !justificacion) {
    throw new Error('Justification is required for rejection');
  }
  
  await expedienteRepository.updateExpedienteStatus(expedienteId, newStatus, justificacion, userId);
};

export const getExpedientes = async (estado?: string) => {
  const expedientes = await expedienteRepository.getAllExpedientes(estado);
  // Transformar campos de PascalCase a camelCase y parsear datosGenerales
  return expedientes.map(e => {
    try {
      // Extraer código del JSON en DatosGenerales
      let codigo = null;
      let datosParsed = null;
      if (e.DatosGenerales) {
        try {
          datosParsed = typeof e.DatosGenerales === 'string' 
            ? JSON.parse(e.DatosGenerales) 
            : e.DatosGenerales;
          codigo = datosParsed?.codigo || null;
        } catch {
          datosParsed = e.DatosGenerales;
        }
      }
      
      return {
        id: e.ExpedienteID || e.id,
        codigo: codigo,
        expedienteId: e.ExpedienteID || e.id,
        datosGenerales: datosParsed || e.DatosGenerales || e.datosGenerales,
        fechaRegistro: e.FechaRegistro || e.fechaRegistro,
        tecnicoId: e.TecnicoID || e.tecnicoId,
        tipoExpedienteId: e.TipoExpedienteID || e.tipoExpedienteId,
        estado: e.Estado || e.estado,
        tecnicoNombre: e.TecnicoNombre || e.tecnicoNombre || e.tecnico,
        tipoExpedienteNombre: e.TipoExpedienteNombre || e.tipoExpedienteNombre,
        justificacionRechazo: e.JustificacionRechazo || e.justificacionRechazo || e.justificacion
      };
    } catch (error) {
      console.warn(`Error transformando expediente ${e.ExpedienteID || e.id}:`, error);
      return {
        id: e.ExpedienteID || e.id,
        expedienteId: e.ExpedienteID || e.id,
        datosGenerales: e.DatosGenerales || e.datosGenerales,
        fechaRegistro: e.FechaRegistro || e.fechaRegistro,
        tecnicoId: e.TecnicoID || e.tecnicoId,
        tipoExpedienteId: e.TipoExpedienteID || e.tipoExpedienteId,
        estado: e.Estado || e.estado,
        tecnicoNombre: e.TecnicoNombre || e.tecnicoNombre || e.tecnico,
        tipoExpedienteNombre: e.TipoExpedienteNombre || e.tipoExpedienteNombre,
        justificacionRechazo: e.JustificacionRechazo || e.justificacionRechazo || e.justificacion
      };
    }
  });
};

export const getExpediente = async (id: number) => {
  console.log(`[expedienteService] getExpediente(${id}) - Iniciando búsqueda`);
  const expediente = await expedienteRepository.getExpedienteById(id);
  
  console.log(`[expedienteService] getExpediente(${id}) - Antes de procesar:`, {
    encontrado: !!expediente,
    tieneDatosGenerales: !!(expediente?.DatosGenerales || expediente?.datosGenerales),
    tipoDatosGenerales: typeof (expediente?.DatosGenerales || expediente?.datosGenerales),
    tieneTecnicoNombre: !!(expediente?.TecnicoNombre || expediente?.tecnicoNombre),
    datosGeneralesPreview: (expediente?.DatosGenerales || expediente?.datosGenerales) ? 
      (typeof (expediente.DatosGenerales || expediente.datosGenerales) === 'string' ? 
        (expediente.DatosGenerales || expediente.datosGenerales).substring(0, 150) : 
        JSON.stringify(expediente.DatosGenerales || expediente.datosGenerales).substring(0, 150)) : 
      'null'
  });
  
  if (!expediente) {
    console.log(`[expedienteService] getExpediente(${id}) - Expediente no encontrado en el repositorio`);
    return null;
  }
  
  // Normalizar campos de PascalCase a camelCase para consistencia
  const expedienteNormalizado: any = {
    ...expediente,
    id: expediente.ExpedienteID || expediente.id,
    expedienteId: expediente.ExpedienteID || expediente.id,
    datosGenerales: expediente.DatosGenerales || expediente.datosGenerales,
    fechaRegistro: expediente.FechaRegistro || expediente.fechaRegistro,
    tecnicoId: expediente.TecnicoID || expediente.tecnicoId,
    tipoExpedienteId: expediente.TipoExpedienteID || expediente.tipoExpedienteId,
    estado: expediente.Estado || expediente.estado,
    tecnicoNombre: expediente.TecnicoNombre || expediente.tecnicoNombre,
    tipoExpedienteNombre: expediente.TipoExpedienteNombre || expediente.tipoExpedienteNombre,
    justificacionRechazo: expediente.JustificacionRechazo || expediente.justificacionRechazo
  };
  
  // Verificar que tenga tecnicoNombre (debe venir del JOIN)
  if (!expedienteNormalizado.tecnicoNombre) {
    console.error(`[expedienteService] ERROR: Expediente ${id} no tiene tecnicoNombre. El JOIN falló o el técnico no existe.`);
  }
  
  // Intentar parsear datosGenerales si es un string JSON válido
  // Puede estar doblemente escapado, así que intentar parsear múltiples veces
  try {
    if (typeof expedienteNormalizado.datosGenerales === 'string') {
      let datos = expedienteNormalizado.datosGenerales.trim();
      
      // Si está doblemente escapado (empieza con comillas), parsear dos veces
      if (datos.startsWith('"') && datos.endsWith('"')) {
        datos = JSON.parse(datos);
        // Si el resultado es otro string JSON, parsear de nuevo
        if (typeof datos === 'string') {
          datos = JSON.parse(datos);
        }
        expedienteNormalizado.datosGenerales = datos;
        console.log(`[expedienteService] getExpediente(${id}) - JSON doblemente escapado parseado correctamente`);
      } else if (datos.startsWith('{') || datos.startsWith('[')) {
        // JSON normal, parsear una vez
        expedienteNormalizado.datosGenerales = JSON.parse(datos);
        console.log(`[expedienteService] getExpediente(${id}) - JSON parseado correctamente`);
      }
    }
  } catch (error: any) {
    // Si no es JSON válido, dejarlo como string
    console.warn(`[expedienteService] Warning: datosGenerales del expediente ${id} no es JSON válido, se mantiene como string`, error.message);
  }
  
  console.log(`[expedienteService] getExpediente(${id}) - Después de procesar:`, {
    tieneDatosGenerales: !!expedienteNormalizado?.datosGenerales,
    tipoDatosGenerales: typeof expedienteNormalizado?.datosGenerales,
    tieneTecnicoNombre: !!expedienteNormalizado?.tecnicoNombre,
    tieneTipoExpedienteNombre: !!expedienteNormalizado?.tipoExpedienteNombre
  });
  
  return expedienteNormalizado;
};

export const deleteExpediente = async (expedienteId: number, userId: number) => {
  return await expedienteRepository.deleteExpediente(expedienteId, userId);
};
