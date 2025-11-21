import sql from 'mssql';
import dotenv from 'dotenv';

dotenv.config();

// Configuración de la base de datos
const dbConfig: sql.config = {
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  server: process.env.DB_SERVER || 'localhost',
  database: process.env.DB_NAME,
  port: parseInt(process.env.DB_PORT || '1433'),
  options: {
    encrypt: process.env.DB_ENCRYPT !== 'false', // Por defecto true, pero puede deshabilitarse
    trustServerCertificate: true, // Necesario para desarrollo local / certificados autofirmados
    enableArithAbort: true,
    connectTimeout: 30000, // 30 segundos
    requestTimeout: 30000,
  },
  pool: {
    max: 10,
    min: 0,
    idleTimeoutMillis: 30000,
  },
};

let pool: sql.ConnectionPool | null = null;

export const getConnection = async (): Promise<sql.ConnectionPool> => {
  // Si ya hay una conexión activa, reutilizarla
  if (pool && pool.connected) {
    return pool;
  }

  // Validar que las variables de entorno estén configuradas
  if (!dbConfig.user || !dbConfig.password || !dbConfig.server || !dbConfig.database) {
    throw new Error(
      'Database configuration incomplete. Please check your .env file. ' +
      'Required: DB_USER, DB_PASSWORD, DB_SERVER, DB_NAME'
    );
  }

  try {
    pool = await sql.connect(dbConfig);
    console.log(`Connected to SQL Server: ${dbConfig.server}:${dbConfig.port}/${dbConfig.database}`);
    return pool;
  } catch (err: any) {
    const errorMessage = err.message || 'Unknown error';
    console.error('--------------------------------');
    console.error(' Database connection failed:', errorMessage);
    console.error('--------------------------------');
    console.error(' Troubleshooting tips:');  
    console.error(' 1. Verify SQL Server is running');
    console.error(' 2. Check if TCP/IP is enabled in SQL Server Configuration Manager');
    console.error(' 3. Verify the connection string in .env file');
    console.error(' 4. Check firewall settings (port 1433)');
    console.error(' 5. Verify SQL Server authentication mode (SQL Server Authentication)');
    console.error('--------------------------------');
    throw err;
  }
};

// Función para cerrar la conexión
export const closeConnection = async (): Promise<void> => {
  if (pool) {
    try {
      await pool.close();
      pool = null;
      console.log('Database connection closed');
    } catch (err) {
      console.error('Error closing database connection:', err);
    }
  }
};

export { sql };
