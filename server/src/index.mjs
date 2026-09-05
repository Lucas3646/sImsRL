import crypto from 'node:crypto';

import express from 'express';
import multer from 'multer';

import { ReplicateIdmVtonProvider } from './providers/replicate-idm-vton.mjs';

const app = express();
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 12 * 1024 * 1024, files: 6 },
  fileFilter: (_request, file, callback) => {
    callback(null, ['image/jpeg', 'image/png', 'image/webp'].includes(file.mimetype));
  },
});

const jobs = new Map();
const provider = createProvider();

app.disable('x-powered-by');
app.get('/health', (_request, response) => {
  response.json({ ok: true, provider: process.env.VTON_PROVIDER || 'replicate-idm-vton' });
});

app.post(
  '/v1/try-on/generations',
  upload.fields([
    { name: 'person', maxCount: 1 },
    { name: 'garments', maxCount: 5 },
  ]),
  (request, response) => {
    const person = request.files?.person?.[0];
    const garmentFiles = request.files?.garments || [];
    if (!person || garmentFiles.length === 0) {
      return response.status(400).json({ message: 'A person and at least one garment are required.' });
    }
    let categories;
    try {
      categories = JSON.parse(request.body.categories || '[]');
    } catch {
      return response.status(400).json({ message: 'Invalid categories payload.' });
    }
    if (categories.length !== garmentFiles.length) {
      return response.status(400).json({ message: 'Each garment needs a category.' });
    }

    const id = crypto.randomUUID();
    jobs.set(id, job(id, 'queued'));
    void runJob(id, {
      person: { buffer: person.buffer, mimeType: person.mimetype },
      garments: garmentFiles.map((file, index) => ({
        buffer: file.buffer,
        mimeType: file.mimetype,
        category: categories[index],
      })),
    });
    return response.status(202).json(jobs.get(id));
  },
);

app.get('/v1/try-on/generations/:id', (request, response) => {
  const current = jobs.get(request.params.id);
  if (!current) return response.status(404).json({ message: 'Generation not found.' });
  return response.json(current);
});

app.use((error, _request, response, _next) => {
  if (error instanceof multer.MulterError) {
    return response.status(error.code === 'LIMIT_FILE_SIZE' ? 413 : 400).json({ message: error.message });
  }
  console.error(error);
  return response.status(500).json({ message: 'Unexpected generation service error.' });
});

async function runJob(id, input) {
  jobs.set(id, job(id, 'processing'));
  try {
    const resultUrl = await provider.generate(input);
    jobs.set(id, job(id, 'succeeded', { resultUrl }));
  } catch (error) {
    console.error('Generation failed', error);
    jobs.set(id, job(id, 'failed', { message: 'The AI provider could not create this outfit.' }));
  }
}

function job(id, status, extra = {}) {
  return { id, status, createdAt: new Date().toISOString(), ...extra };
}

function createProvider() {
  const name = process.env.VTON_PROVIDER || 'replicate-idm-vton';
  if (name === 'replicate-idm-vton') {
    return new ReplicateIdmVtonProvider({ token: process.env.REPLICATE_API_TOKEN });
  }
  throw new Error(`Unknown VTON_PROVIDER: ${name}`);
}

setInterval(() => {
  const cutoff = Date.now() - 30 * 60 * 1000;
  for (const [id, current] of jobs) {
    if (Date.parse(current.createdAt) < cutoff) jobs.delete(id);
  }
}, 5 * 60 * 1000).unref();

const port = Number(process.env.PORT || 8080);
app.listen(port, () => console.log(`sImsRL VTON backend listening on :${port}`));
