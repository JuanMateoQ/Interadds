import { createServer } from 'http';
import { parse } from 'url';
import next from 'next';
import { Server as SocketIOServer } from 'socket.io';

const dev = process.env.NODE_ENV !== 'production';
const hostname = 'localhost';
const port = parseInt(process.env.PORT || '3000', 10);

const app = next({ dev, hostname, port });
const handle = app.getRequestHandler();

declare global {
  var io: SocketIOServer | undefined;
}

app.prepare().then(() => {
  const httpServer = createServer(async (req, res) => {
    try {
      const parsedUrl = parse(req.url!, true);
      await handle(req, res, parsedUrl);
    } catch (err) {
      console.error('Error en servidor HTTP:', err);
      res.statusCode = 500;
      res.end('Internal server error');
    }
  });

  const io = new SocketIOServer(httpServer, {
    path: '/api/socketio',
    cors: {
      origin: process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000',
      credentials: true,
    },
  });

  global.io = io;

  httpServer.listen(port, () => {
    console.log(`> Servidor Monolito Interadds (Next.js + Node + Socket.IO) listo en http://${hostname}:${port}`);
  });
});