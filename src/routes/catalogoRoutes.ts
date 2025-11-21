import { Router } from 'express';
import * as catalogoController from '../controllers/catalogoController';

const router = Router();

router.get('/tipo-expediente', catalogoController.getTiposExpediente);

export default router;

