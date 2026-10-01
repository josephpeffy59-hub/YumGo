import { Router } from 'express';
import { prisma } from '../lib/prisma.js';
import { auth, requireRole } from '../middleware/auth.js';

const router = Router();

router.get('/', async (req, res) => {
  try {
    const { q } = req.query;
    const restaurants = await prisma.restaurant.findMany({
      where: q
        ? { name: { contains: q, mode: 'insensitive' } }
        : {},
      include: {
        reviews: { select: { rating: true } },
        _count: { select: { menuItems: true } },
      },
      orderBy: { createdAt: 'desc' },
    });

    res.json(
      restaurants.map((r) => ({
        ...r,
        avgRating: r.reviews.length
          ? r.reviews.reduce((s, x) => s + x.rating, 0) / r.reviews.length
          : 0,
        reviewCount: r.reviews.length,
      }))
    );
  } catch (err) {
    console.error('[RESTAURANTS LIST ERROR]', err);
    res.status(500).json({ error: err.message });
  }
});

router.get('/mine', auth(), requireRole('OWNER'), async (req, res) => {
  try {
    const r = await prisma.restaurant.findFirst({
      where: { ownerId: req.user.id },
    });
    res.json(r);
  } catch (err) {
    console.error('[RESTAURANTS MINE ERROR]', err);
    res.status(500).json({ error: err.message });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const r = await prisma.restaurant.findUnique({
      where: { id: req.params.id },
      include: {
        menuItems: true,
        reviews: {
          include: { customer: { select: { name: true } } },
          orderBy: { createdAt: 'desc' },
        },
      },
    });
    if (!r) return res.status(404).json({ error: 'Restaurant not found' });

    const avgRating = r.reviews.length
      ? r.reviews.reduce((s, x) => s + x.rating, 0) / r.reviews.length
      : 0;

    res.json({ ...r, avgRating });
  } catch (err) {
    console.error('[RESTAURANT GET ERROR]', err);
    res.status(500).json({ error: err.message });
  }
});

router.post('/', auth(), requireRole('OWNER'), async (req, res) => {
  try {
    const { name, description, address, phone, imageUrl } = req.body;
    if (!name) return res.status(400).json({ error: 'name is required' });

    const existing = await prisma.restaurant.findFirst({
      where: { ownerId: req.user.id },
    });
    if (existing) {
      return res.status(409).json({ error: 'You already have a restaurant' });
    }

    const r = await prisma.restaurant.create({
      data: {
        ownerId: req.user.id,
        name,
        description: description || null,
        address: address || null,
        phone: phone || null,
        imageUrl: imageUrl || null,
      },
    });

    res.json(r);
  } catch (err) {
    console.error('[RESTAURANT CREATE ERROR]', err);
    res.status(500).json({ error: err.message });
  }
});

router.put('/:id', auth(), requireRole('OWNER', 'ADMIN'), async (req, res) => {
  try {
    const r = await prisma.restaurant.update({
      where: { id: req.params.id },
      data: req.body,
    });
    res.json(r);
  } catch (err) {
    console.error('[RESTAURANT UPDATE ERROR]', err);
    res.status(500).json({ error: err.message });
  }
});

export default router;