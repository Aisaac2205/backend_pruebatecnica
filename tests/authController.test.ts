import { Request, Response } from 'express';
import * as authController from '../src/controllers/authController';
import * as authService from '../src/services/authService';

// Mock del servicio de autenticación
jest.mock('../src/services/authService');

describe('AuthController', () => {
  let mockRequest: Partial<Request>;
  let mockResponse: Partial<Response>;

  beforeEach(() => {
    mockRequest = {
      body: {},
    };
    mockResponse = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
    };
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('POST /api/auth/login', () => {
    it('debería retornar 400 si faltan credenciales', async () => {
      mockRequest.body = {};

      await authController.login(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.status).toHaveBeenCalledWith(400);
      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          error: 'Validación fallida',
        })
      );
    });

    it('debería retornar 401 si las credenciales son inválidas', async () => {
      mockRequest.body = {
        email: 'test@example.com',
        password: 'wrongpassword',
      };

      (authService.login as jest.Mock).mockResolvedValue(null);

      await authController.login(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.status).toHaveBeenCalledWith(401);
      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          error: 'No Autorizado',
        })
      );
    });

    it('debería retornar 200 y token si las credenciales son válidas', async () => {
      mockRequest.body = {
        email: 'tecnico.01@mp.gt',
        password: 'DicriPass#2025',
      };

      const mockUser = {
        id: 1,
        nombre: 'Test User',
        rol: 'Tecnico' as const,
      };

      const mockToken = 'mock-jwt-token';

      (authService.login as jest.Mock).mockResolvedValue({
        user: mockUser,
        token: mockToken,
      });

      await authController.login(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.status).toHaveBeenCalledWith(200);
      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          token: mockToken,
          user: mockUser,
        })
      );
    });
  });
});

