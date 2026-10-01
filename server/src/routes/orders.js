import { Router } from 'express';
import { prisma } from '../lib/prisma.js';
import { auth, requireRole } from '../middleware/auth.js';

const router = Router();

// ---------- CUSTOMER: create order ----------
router.post('/', auth(), requireRole('CUSTOMER'), async (req, res) => {
  try {
    const { restaurantId, items, note } = req.body;

    if (!restaurantId || !Array.isArray(items) || items.length === 0) {
      return res
        .status(400)
        .json({ error: 'restaurantId and items[] are required' });
    }

    const restaurant = await prisma.restaurant.findUnique({
      where: { id: restaurantId },
    });
    if (!restaurant) {
      return res.status(404).json({ error: 'Restaurant not found' });
    }

    const menuItems = await prisma.menuItem.findMany({
      where: { id: { in: items.map((i) => i.menuItemId) } },
    });

    const priced = [];
    for (const i of items) {
      const m = menuItems.find((x) => x.id === i.menuItemId);
      if (!m) {
        return res
          .status(400)
          .json({ error: `Menu item ${i.menuItemId} not found` });
      }
      if (m.restaurantId !== restaurantId) {
        return res
          .status(400)
          .json({ error: `Item ${m.name} is not on this restaurant's menu` });
      }
      if (!Number.isInteger(i.quantity) || i.quantity < 1) {
        return res
          .status(400)
          .json({ error: 'Quantity must be an integer >= 1' });
      }
      priced.push({
        menuItemId: i.menuItemId,
        quantity: i.quantity,
        price: m.price,
      });
    }

    const total = priced.reduce((s, x) => s + x.price * x.quantity, 0);

    const order = await prisma.order.create({
      data: {
        customerId: req.user.id,
        restaurantId,
        note: note || null,
        total,
        items: { create: priced },
      },
      include: {
        items: { include: { menuItem: true } },
        restaurant: true,
        customer: true,
      },
    });

    res.json(order);
  } catch (err) {
    console.error('[ORDER CREATE ERROR]', err);
    res.status(500).json({ error: err.message });
  }
});

// ---------- CUSTOMER: list own orders ----------
router.get('/mine', auth(), requireRole('CUSTOMER'), async (req, res) => {
  try {
    const orders = await prisma.order.findMany({
      where: { customerId: req.user.id },
      include: {
        items: { include: { menuItem: true } },
        restaurant: true,
      },
      orderBy: { createdAt: 'desc' },
    });
    res.json(orders);
  } catch (err) {
    console.error('[ORDERS MINE ERROR]', err);
    res.status(500).json({ error: err.message });
  }
});

// ---------- OWNER: list incoming orders ----------
router.get('/incoming', auth(), requireRole('OWNER'), async (req, res) => {
  try {
    const rest = await prisma.restaurant.findFirst({
      where: { ownerId: req.user.id },
    });
    if (!rest) return res.json([]);

    const orders = await prisma.order.findMany({
      where: { restaurantId: rest.id },
      include: {
        items: { include: { menuItem: true } },
        customer: { select: { name: true, phone: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
    res.json(orders);
  } catch (err) {
    console.error('[ORDERS INCOMING ERROR]', err);
    res.status(500).json({ error: err.message });
  }
});

// ---------- OWNER/ADMIN: update order status ----------
router.patch(
  '/:id/status',
  auth(),
  requireRole('OWNER', 'ADMIN'),
  async (req, res) => {
    try {
      const valid = [
        'PENDING',
        'ACCEPTED',
        'PREPARING',
        'READY',
        'DELIVERED',
        'CANCELLED',
      ];
      if (!valid.includes(req.body.status)) {
        return res.status(400).json({ error: 'Invalid status' });
      }

      const order = await prisma.order.update({
        where: { id: req.params.id },
        data: { status: req.body.status },
      });
      res.json(order);
    } catch (err) {
      console.error('[ORDER STATUS ERROR]', err);
      res.status(500).json({ error: err.message });
    }
  },
);

// ---------- CUSTOMER: cancel own order ----------
router.patch(
  '/:id/cancel',
  auth(),
  requireRole('CUSTOMER'),
  async (req, res) => {
    try {
      const order = await prisma.order.findUnique({
        where: { id: req.params.id },
      });
      if (!order) {
        return res.status(404).json({ error: 'Order not found' });
      }
      if (order.customerId !== req.user.id) {
        return res.status(403).json({ error: 'Not your order' });
      }
      if (!['PENDING', 'ACCEPTED'].includes(order.status)) {
        return res
          .status(400)
          .json({ error: 'Order can no longer be cancelled' });
      }

      const updated = await prisma.order.update({
        where: { id: req.params.id },
        data: { status: 'CANCELLED' },
      });
      res.json(updated);
    } catch (err) {
      console.error('[ORDER CANCEL ERROR]', err);
      res.status(500).json({ error: err.message });
    }
  },
);

export default router;