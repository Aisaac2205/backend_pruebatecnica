import * as authService from '../src/services/authService';
import * as authRepository from '../src/db/authRepository';

// Mock del repositorio de autenticación
jest.mock('../src/db/authRepository');

describe('AuthService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('login', () => {
    it('debería retornar null si el usuario no existe', async () => {
      (authRepository.loginUser as jest.Mock).mockResolvedValue(null);

      const result = await authService.login('nonexistent@example.com', 'password');

      expect(result).toBeNull();
      expect(authRepository.loginUser).toHaveBeenCalledWith('nonexistent@example.com', 'password');
    });

    it('debería retornar usuario y token si las credenciales son válidas', async () => {
      const mockUserFromRepository = {
        id: 1,
        email: 'tecnico.01@mp.gt',
        nombre: 'Test User',
        rol: 'Tecnico' as const,
      };

      (authRepository.loginUser as jest.Mock).mockResolvedValue(mockUserFromRepository);

      const result = await authService.login('tecnico.01@mp.gt', 'DicriPass#2025');

      expect(result).toBeTruthy();
      // El servicio retorna { token, user: { id, nombre, rol } } - SIN email
      expect(result?.user).toEqual({
        id: 1,
        nombre: 'Test User',
        rol: 'Tecnico',
      });
      expect(result?.token).toBeDefined();
      expect(typeof result?.token).toBe('string');
    });
  });
});

