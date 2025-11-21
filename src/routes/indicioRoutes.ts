import { Router } from 'express';
import * as indicioController from '../controllers/indicioController';
import { authMiddleware, roleMiddleware } from '../middlewares/authMiddleware';

const router = Router();

router.use(authMiddleware);

router.post('/', roleMiddleware(['Tecnico']), indicioController.create);
router.get('/:expedienteId', indicioController.listByExpediente);

export default router;
