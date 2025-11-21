// Configuración global para las pruebas
// Este archivo se ejecuta antes de cada test

// Mock de variables de entorno si es necesario
process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-secret-key-for-testing-only';
process.env.DB_SERVER = 'localhost';
process.env.DB_DATABASE = 'test_db';
process.env.DB_USER = 'test_user';
process.env.DB_PASSWORD = 'test_password';

