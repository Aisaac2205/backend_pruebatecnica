import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { UserPayload } from '../types';

export const authMiddleware = (req: Request, res: Response, next: NextFunction) => {
  const authHeader = req.header('Authorization');
  
  console.log('[authMiddleware] Verificando autenticación:', {
    hasAuthHeader: !!authHeader,
    authHeaderPreview: authHeader ? authHeader.substring(0, 20) + '...' : null,
    path: req.path,
    method: req.method
  });
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    console.log('[authMiddleware] No hay token o formato incorrecto');
    return res.status(401).json({ 
      error: 'No Autorizado', 
      details: 'Token de autenticación inválido o ausente.' 
    });
  }

  const token = authHeader.replace('Bearer ', '');

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET as string) as UserPayload;
    console.log('[authMiddleware] Token válido:', {
      userId: decoded.id,
      rol: decoded.rol,
      email: decoded.email
    });
    req.user = decoded;
    next();
  } catch (err: any) {
    console.error('[authMiddleware] Error al verificar token:', {
      error: err.message,
      name: err.name
    });
    return res.status(401).json({ 
      error: 'No Autorizado', 
      details: 'Token de autenticación inválido o ausente.' 
    });
  }
};

export const roleMiddleware = (allowedRoles: string[]) => {
  return (req: Request, res: Response, next: NextFunction) => {
    if (!req.user || !allowedRoles.includes(req.user.rol)) {
      return res.status(403).json({ 
        error: 'Acceso Denegado', 
        details: `El rol ${allowedRoles.join(' o ')} es requerido para esta acción.` 
      });
    }
    next();
  };
};
