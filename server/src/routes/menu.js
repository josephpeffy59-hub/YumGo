import { Router } from 'express';
import { prisma } from '../lib/prisma.js';
import { auth, requireRole } from '../middleware/auth.js';

const router = Router();

router.get('/restaurant/:id', async (req, res) => {
  res.json(await prisma.menuItem.findMany({
    where: { restaurantId: req.params.id },
    orderBy: { category: 'asc' },
  }));
});

router.post('/', auth(), requireRole('OWNER'), async (req, res) => {
  const rest = await prisma.restaurant.findFirst({ where: { ownerId: req.user.id } });
  if (!rest) return res.status(400).json({ error: 'Create a restaurant first' });
  const item = await prisma.menuItem.create({ data: { ...req.body, restaurantId: rest.id } });
  res.json(item);
});

router.put('/:id', auth(), requireRole('OWNER'), async (req, res) => {
  res.json(await prisma.menuItem.update({ where: { id: req.params.id }, data: req.body }));
});

router.delete('/:id', auth(), requireRole('OWNER'), async (req, res) => {
  await prisma.menuItem.delete({ where: { id: req.params.id } });
  res.json({ ok: true });
});

export default router;