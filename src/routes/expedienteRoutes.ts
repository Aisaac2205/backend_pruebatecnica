import { Router } from 'express';
import * as expedienteController from '../controllers/expedienteController';
import { authMiddleware, roleMiddleware } from '../middlewares/authMiddleware';

const router = Router();

router.use(authMiddleware);

// Rutas específicas primero (más específicas antes de las dinámicas)
router.post('/', roleMiddleware(['Tecnico']), expedienteController.create);
router.get('/', expedienteController.list);
router.put('/:id/review', roleMiddleware(['Coordinador']), expedienteController.review);
router.delete('/:id', expedienteController.deleteExpediente); // Técnico y Coordinador pueden eliminar (validado en SP)
// Ruta dinámica al final
router.get('/:id', expedienteController.getById);

export default router;
