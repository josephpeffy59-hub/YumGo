import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import http from 'http';
import { Server } from 'socket.io';
import { prisma } from './lib/prisma.js';

import authRoutes from './routes/auth.js';
import restaurantRoutes from './routes/restaurants.js';
import menuRoutes from './routes/menu.js';
import orderRoutes from './routes/orders.js';
import chatRoutes from './routes/chat.js';
import reviewRoutes from './routes/reviews.js';
import adminRoutes from './routes/admin.js';
import uploadRoutes from './routes/upload.js';

// ---------- GLOBAL CRASH GUARDS ----------
// Must come before dotenv.config() and app setup so they catch
// every async error from anywhere in the app.
process.on('unhandledRejection', (reason) => {
  console.error('[UNHANDLED REJECTION]', reason);
});
process.on('uncaughtException', (err) => {
  console.error('[UNCAUGHT EXCEPTION]', err);
});
// -----------------------------------------

dotenv.config();

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*', methods: ['GET', 'POST'] },
});

// ---------- MIDDLEWARE ----------
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));
app.use('/uploads', express.static('uploads'));

// ---------- ROUTES ----------
app.use('/api/auth', authRoutes);
app.use('/api/restaurants', restaurantRoutes);
app.use('/api/menu', menuRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/reviews', reviewRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/upload', uploadRoutes);

// ---------- HEALTH ----------
app.get('/api/health', (_req, res) =>
  res.json({ ok: true, app: 'YumGo', ts: Date.now() })
);

// ---------- 404 ----------
app.use((req, res) => {
  res.status(404).json({ error: `Route not found: ${req.method} ${req.originalUrl}` });
});

// ---------- ERROR HANDLER ----------
app.use((err, _req, res, _next) => {
  console.error('[EXPRESS ERROR]', err);
  res.status(500).json({ error: err.message || 'Internal server error' });
});

// ---------- SOCKET.IO ----------
io.on('connection', (socket) => {
  console.log('[SOCKET CONNECTED]', socket.id);

  socket.on('join', (room) => {
    socket.join(room);
    console.log(`[SOCKET] ${socket.id} joined ${room}`);
  });

  socket.on('leave', (room) => {
    socket.leave(room);
    console.log(`[SOCKET] ${socket.id} left ${room}`);
  });

  socket.on('message', async (payload) => {
    try {
      const { conversationId, senderId, text, recipientId } = payload;
      if (!conversationId || !senderId || !text) {
        console.warn('[SOCKET MESSAGE] missing fields', payload);
        return;
      }
      const msg = await prisma.message.create({
        data: { conversationId, senderId, text },
        include: { sender: { select: { id: true, name: true, role: true } } },
      });
      io.to(conversationId).emit('message', msg);
      if (recipientId) {
        io.to(`user:${recipientId}`).emit('notify', {
          type: 'message',
          conversationId,
        });
      }
    } catch (err) {
      console.error('[SOCKET MESSAGE ERROR]', err);
    }
  });

  socket.on('disconnect', () => {
    console.log('[SOCKET DISCONNECTED]', socket.id);
  });
});

// ---------- START ----------
const PORT = process.env.PORT || 4000;
server.listen(PORT, () => {
  console.log(`[YumGo API] listening on :${PORT}`);
});