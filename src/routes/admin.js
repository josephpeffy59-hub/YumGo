import { Router } from 'express';
import { prisma } from '../lib/prisma.js';
import { auth, requireRole } from '../middleware/auth.js';

const router = Router();
router.use(auth(), requireRole('ADMIN'));

router.get('/stats', async (_req, res) => {
  try {
    const [users, restaurants, orders, reviews] = await Promise.all([
      prisma.user.count(),
      prisma.restaurant.count(),
      prisma.order.count(),
      prisma.review.count(),
    ]);
    const revenue = await prisma.order.aggregate({ _sum: { total: true } });

    res.json({
      users,
      restaurants,
      orders,
      reviews,
      revenue: revenue._sum.total || 0,
    });
  } catch (err) {
    console.error('[ADMIN STATS ERROR]', err);
    res.status(500).json({ error: err.message });
  }
});

router.get('/users', async (_req, res) => {
  try {
    res.json(
      await prisma.user.findMany({
        select: {
          id: true,
          email: true,
          name: true,
          role: true,
          createdAt: true,
        },
        orderBy: { createdAt: 'desc' },
      })
    );
  } catch (err) {
    console.error('[ADMIN USERS ERROR]', err);
    res.status(500).json({ error: err.message });
  }
});

router.get('/orders', async (_req, res) => {
  try {
    res.json(
      await prisma.order.findMany({
        include: { customer: true, restaurant: true },
        orderBy: { createdAt: 'desc' },
      })
    );
  } catch (err) {
    console.error('[ADMIN ORDERS ERROR]', err);
    res.status(500).json({ error: err.message });
  }
});

router.delete('/users/:id', async (req, res) => {
  try {
    if (req.params.id === req.user.id) {
      return res.status(400).json({ error: 'Cannot delete yourself' });
    }
    await prisma.user.delete({ where: { id: req.params.id } });
    res.json({ ok: true });
  } catch (err) {
    console.error('[ADMIN DELETE USER ERROR]', err);
    res.status(500).json({ error: err.message });
  }
});

export default router;