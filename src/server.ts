import app from './app';
import dotenv from 'dotenv';
import { getConnection } from './config/db';

dotenv.config();

const PORT = process.env.PORT || 3000;

const startServer = async () => {
  // Intentar conectar a la base de datos, pero no bloquear el inicio del servidor
  try {
    await getConnection();
    console.log('Database connected successfully');
  } catch (error: any) {
    console.warn('Database connection failed:', error.message);
    console.warn('Server will start without database connection.');
    console.warn('API endpoints that require database will fail.');
    console.warn('Swagger UI will still be available at http://localhost:' + PORT + '/api-docs');
  }
  
  // Iniciar el servidor independientemente de la conexión a la BD
  app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
    console.log(`Swagger UI available at http://localhost:${PORT}/api-docs`);
    console.log(`Health check available at http://localhost:${PORT}/health`);
  });
};

startServer();
