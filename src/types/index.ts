export interface UserPayload {
  id: number;
  email?: string;
  username?: string;
  rol: 'Tecnico' | 'Coordinador';
}

declare global {
  namespace Express {
    interface Request {
      user?: UserPayload;
    }
  }
}
