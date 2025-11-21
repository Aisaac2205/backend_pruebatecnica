import * as catalogoRepository from '../db/catalogoRepository';

export const getTiposExpediente = async () => {
  const tipos = await catalogoRepository.getTiposExpediente();
  return tipos;
};

