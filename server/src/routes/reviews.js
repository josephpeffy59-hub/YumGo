import { Router } from 'express';
import { prisma } from '../lib/prisma.js';
import { auth, requireRole } from '../middleware/auth.js';

const router = Router();

router.get('/restaurant/:id', async (req, res) => {
  try {
    res.json(
      await prisma.review.findMany({
        where: { restaurantId: req.params.id },
        include: { customer: { select: { name: true } } },
        orderBy: { createdAt: 'desc' },
      })
    );
  } catch (err) {
    console.error('[REVIEWS LIST ERROR]', err);
    res.status(500).json({ error: err.message });
  }
});

router.post('/', auth(), requireRole('CUSTOMER'), async (req, res) => {
  try {
    const { restaurantId, rating, comment } = req.body;

    if (!restaurantId) {
      return res.status(400).json({ error: 'restaurantId is required' });
    }
    if (!Number.isInteger(rating) || rating < 1 || rating > 5) {
      return res.status(400).json({ error: 'rating must be an integer between 1 and 5' });
    }

    const restaurant = await prisma.restaurant.findUnique({
      where: { id: restaurantId },
    });
    if (!restaurant) return res.status(404).json({ error: 'Restaurant not found' });

    const existing = await prisma.review.findFirst({
      where: { restaurantId, customerId: req.user.id },
    });
    if (existing) {
      return res
        .status(409)
        .json({ error: 'You already reviewed this restaurant' });
    }

    const r = await prisma.review.create({
      data: {
        restaurantId,
        rating,
        comment: comment || null,
        customerId: req.user.id,
      },
    });

    res.json(r);
  } catch (err) {
    console.error('[REVIEW CREATE ERROR]', err);
    res.status(500).json({ error: err.message });
  }
});

export default router;