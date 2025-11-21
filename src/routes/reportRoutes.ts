import { Router } from 'express';
import * as reportController from '../controllers/reportController';
import { authMiddleware } from '../middlewares/authMiddleware';

const router = Router();

router.use(authMiddleware);

router.get('/', reportController.getReport);

export default router;
