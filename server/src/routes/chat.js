import { Router } from 'express';
import { prisma } from '../lib/prisma.js';
import { auth } from '../middleware/auth.js';

const router = Router();

router.post('/conversation', auth(), async (req, res) => {
  try {
    const { restaurantId } = req.body;
    if (!restaurantId) {
      return res.status(400).json({ error: 'restaurantId is required' });
    }

    const restaurant = await prisma.restaurant.findUnique({
      where: { id: restaurantId },
    });
    if (!restaurant) return res.status(404).json({ error: 'Restaurant not found' });

    const customerId = req.user.id;

    let conv = await prisma.conversation.findUnique({
      where: { customerId_restaurantId: { customerId, restaurantId } },
    });

    if (!conv) {
      conv = await prisma.conversation.create({
        data: { customerId, restaurantId },
      });
    }

    res.json(conv);
  } catch (err) {
    console.error('[CHAT CREATE CONVERSATION ERROR]', err);
    res.status(500).json({ error: err.message });
  }
});

router.get('/conversations', auth(), async (req, res) => {
  try {
    if (req.user.role === 'CUSTOMER') {
      return res.json(
        await prisma.conversation.findMany({
          where: { customerId: req.user.id },
          include: {
            restaurant: true,
            messages: { orderBy: { createdAt: 'desc' }, take: 1 },
          },
          orderBy: { createdAt: 'desc' },
        })
      );
    }

    if (req.user.role === 'OWNER') {
      const rest = await prisma.restaurant.findFirst({
        where: { ownerId: req.user.id },
      });
      if (!rest) return res.json([]);

      return res.json(
        await prisma.conversation.findMany({
          where: { restaurantId: rest.id },
          include: {
            customer: true,
            messages: { orderBy: { createdAt: 'desc' }, take: 1 },
          },
          orderBy: { createdAt: 'desc' },
        })
      );
    }

    res.json([]);
  } catch (err) {
    console.error('[CHAT LIST CONVERSATIONS ERROR]', err);
    res.status(500).json({ error: err.message });
  }
});

router.get('/:conversationId/messages', auth(), async (req, res) => {
  try {
    res.json(
      await prisma.message.findMany({
        where: { conversationId: req.params.conversationId },
        include: { sender: { select: { id: true, name: true, role: true } } },
        orderBy: { createdAt: 'asc' },
      })
    );
  } catch (err) {
    console.error('[CHAT LIST MESSAGES ERROR]', err);
    res.status(500).json({ error: err.message });
  }
});

router.post('/:conversationId/messages', auth(), async (req, res) => {
  try {
    const { text } = req.body;
    if (!text || !text.trim()) {
      return res.status(400).json({ error: 'text is required' });
    }

    const msg = await prisma.message.create({
      data: {
        conversationId: req.params.conversationId,
        senderId: req.user.id,
        text: text.trim(),
      },
      include: { sender: { select: { id: true, name: true, role: true } } },
    });

    res.json(msg);
  } catch (err) {
    console.error('[CHAT SEND MESSAGE ERROR]', err);
    res.status(500).json({ error: err.message });
  }
});

export default router;