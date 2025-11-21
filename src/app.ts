import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import authRoutes from './routes/authRoutes';
import expedienteRoutes from './routes/expedienteRoutes';
import indicioRoutes from './routes/indicioRoutes';
import reportRoutes from './routes/reportRoutes';
import catalogoRoutes from './routes/catalogoRoutes';
import swaggerUi from 'swagger-ui-express';
import * as swaggerDocument from './swagger.json';

const app = express();

// Middleware
app.use(cors());
app.use(helmet());
app.use(morgan('dev'));
app.use(express.json());

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/expedientes', expedienteRoutes);
app.use('/api/indicios', indicioRoutes);
app.use('/api/reports', reportRoutes);
app.use('/api/catalogos', catalogoRoutes);

// Swagger
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));

// Health Check
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

export default app;
