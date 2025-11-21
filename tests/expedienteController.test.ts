import { Request, Response } from 'express';
import * as expedienteController from '../src/controllers/expedienteController';
import * as expedienteService from '../src/services/expedienteService';
import '../src/types'; // Importar para que TypeScript reconozca la extensión de Request

// Mock del servicio de expedientes
jest.mock('../src/services/expedienteService');

describe('ExpedienteController', () => {
  let mockRequest: Partial<Request>;
  let mockResponse: Partial<Response>;
  let mockNext: jest.Mock;

  beforeEach(() => {
    mockRequest = {
      body: {},
      params: {},
      query: {}, // Agregar query para evitar errores de desestructuración
      user: {
        id: 1,
        email: 'tecnico.01@mp.gt',
        rol: 'Tecnico',
      },
    };
    mockResponse = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
    };
    mockNext = jest.fn();
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('POST /api/expedientes', () => {
    it('debería retornar 401 si no hay usuario autenticado', async () => {
      mockRequest.user = undefined;

      await expedienteController.create(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.status).toHaveBeenCalledWith(401);
      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          error: 'No Autorizado',
        })
      );
    });

    it('debería retornar 400 si faltan datos requeridos', async () => {
      mockRequest.body = {};

      await expedienteController.create(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.status).toHaveBeenCalledWith(400);
      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          error: 'Validación fallida',
        })
      );
    });

    it('debería retornar 201 si el expediente se crea exitosamente', async () => {
      mockRequest.body = {
        datosGenerales: JSON.stringify({
          codigo: 'EXP-2025-001',
          fecha: '2025-11-20',
          tecnico: 'Test User',
        }),
        tipoExpedienteId: 1,
      };

      (expedienteService.createExpediente as jest.Mock).mockResolvedValue({
        expedienteId: 1,
        message: 'Expediente registrado con éxito.',
      });

      await expedienteController.create(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.status).toHaveBeenCalledWith(201);
      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          expedienteId: 1,
          message: 'Expediente registrado con éxito.',
        })
      );
    });
  });

  describe('GET /api/expedientes', () => {
    it('debería retornar lista de expedientes', async () => {
      const mockExpedientes = [
        {
          id: 1,
          codigo: 'EXP-2025-001',
          estado: 'EN_REVISION',
        },
      ];

      (expedienteService.getExpedientes as jest.Mock).mockResolvedValue(mockExpedientes);

      await expedienteController.list(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.status).toHaveBeenCalledWith(200);
      expect(mockResponse.json).toHaveBeenCalledWith(mockExpedientes);
    });
  });
});

