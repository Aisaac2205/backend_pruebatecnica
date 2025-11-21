import * as authRepository from '../db/authRepository';
import jwt from 'jsonwebtoken';

// Definición de tipo para la respuesta del Repositorio
interface UserAuthData {
    id: number;
    email: string;
    rol: 'Tecnico' | 'Coordinador';
    nombre: string;
}

export const login = async (email: string, password: string) => {
    console.log('[authService] login - Iniciando login para:', email);

    // El repositorio devuelve solo el usuario si las credenciales son válidas
    const user: UserAuthData | null = await authRepository.loginUser(email, password);

    console.log('[authService] login - Usuario obtenido:', {
        hasUser: !!user,
        userId: user?.id,
        email: user?.email,
        rol: user?.rol
        // NOTA: 'username' fue eliminado aquí.
    });

    if (!user) {
        console.log('[authService] login - Usuario no encontrado o credenciales inválidas');
        return null;
    }

    // Generamos el token JWT con la información esencial.
    // CORRECCIÓN: Se eliminó 'username' del payload del token.
    const token = jwt.sign(
        { id: user.id, email: user.email, rol: user.rol },
        process.env.JWT_SECRET as string,
        { expiresIn: '24h' }
    );

    // Aseguramos que el usuario tenga el formato esperado para el Controller/Frontend: { id, nombre, rol }
    return {
        token,
        user: {
            id: user.id,
            nombre: user.nombre, // Usamos 'nombre' completo (ej. Isaac Sarceño)
            rol: user.rol
        }
    };
};