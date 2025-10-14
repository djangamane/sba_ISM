import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import routes from './routes';

const app = express();

app.use(cors());
app.use(express.json({ limit: '1mb' }));
app.use('/api', routes);

app.get('/', (_req: Request, res: Response) => {
  res.json({
    name: 'Spiritual Bible Chat Backend',
    version: '0.1.0',
    status: 'ready',
  });
});

app.use((req: Request, res: Response) => {
  res.status(404).json({ error: `Path ${req.path} not found` });
});

app.use((err: Error, _req: Request, res: Response, _next: NextFunction) => {
  // Basic error handler for now; extend with logging later.
  console.error(err);
  res.status(500).json({ error: 'Internal server error' });
});

export default app;
