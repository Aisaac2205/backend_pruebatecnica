import { Request, Response } from 'express';
import * as authService from '../services/authService';

// Definición de tipos para la solicitud (asumiendo que estás usando TypeScript)
interface LoginRequest extends Request {
    body: {
        email?: string; // Ahora usamos email
        password?: string;
    };
}

export const login = async (req: LoginRequest, res: Response) => {
    try {
        const { email, password } = req.body;

        // Se usa 'email' como identificador de login
        console.log('[authController] login - Recibida petición:', { email, hasPassword: !!password });

        if (!email || !password) {
            console.log('[authController] login - Faltan credenciales');
            return res.status(400).json({
                error: 'Validación fallida',
                details: 'El email y la contraseña son requeridos.'
            });
        }

        console.log('[authController] login - Llamando a authService.login');
        // El servicio debe retornar { token, user: { id, email, rol, nombre } }
        const result = await authService.login(email, password);

        console.log('[authController] login - Resultado del servicio:', {
            hasResult: !!result,
            hasToken: !!result?.token,
            hasUser: !!result?.user
        });

        if (!result) {
            console.log('[authController] login - No se obtuvo resultado, credenciales inválidas');
            return res.status(401).json({
                error: 'No Autorizado',
                details: 'Credenciales inválidas.'
            });
        }

        console.log('[authController] login - Login exitoso para:', email);

        // Formato de respuesta según especificación de integración: { token, user: { id, nombre, rol } }
        res.status(200).json({
            token: result.token,
            user: {
                id: result.user.id,
                // Las propiedades de usuario vienen del repositorio: id, nombre y rol
                nombre: result.user.nombre,
                rol: result.user.rol
            }
        });
    } catch (error: any) {
        console.error('[authController] login - ERROR:', error);
        console.error('[authController] login - Stack:', error.stack);
        console.error('[authController] login - Error details:', {
            message: error.message,
            code: error.code,
            number: error.number
        });
        // Manejo de error 500 según el contrato de errores
        res.status(500).json({
            error: 'Error Interno del Servidor',
            details: error.message || 'Consulte los logs del servidor para detalles.'
        });
    }
};