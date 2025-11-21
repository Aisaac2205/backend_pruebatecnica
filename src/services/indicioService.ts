import * as indicioRepository from '../db/indicioRepository';

export const createIndicio = async (
  expedienteId: number,
  descripcion: string,
  color: string,
  tamano: string,
  peso: string,
  ubicacion: string,
  tecnicoId: number
) => {
  return await indicioRepository.createIndicio(expedienteId, descripcion, color, tamano, peso, ubicacion, tecnicoId);
};

export const getIndicios = async (expedienteId: number) => {
  const indicios = await indicioRepository.getIndiciosByExpediente(expedienteId);
  // Transformar campos de PascalCase a camelCase
  return indicios.map((indicio: any) => ({
    id: indicio.IndicioID || indicio.id,
    descripcion: indicio.Descripcion || indicio.descripcion || '',
    color: indicio.Color || indicio.color || '',
    tamano: indicio.Tamano || indicio.tamano || '',
    peso: indicio.Peso !== null && indicio.Peso !== undefined 
      ? (typeof indicio.Peso === 'number' ? `${indicio.Peso}kg` : indicio.Peso.toString())
      : (indicio.peso || '0kg'),
    ubicacion: indicio.Ubicacion || indicio.ubicacion || '',
    tecnicoId: indicio.TecnicoID || indicio.tecnicoId,
    fechaRegistro: indicio.FechaRegistro || indicio.fechaRegistro
  }));
};
