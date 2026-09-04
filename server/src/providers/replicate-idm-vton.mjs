import { VirtualTryOnProvider } from './provider.mjs';

const predictionEndpoint =
  'https://api.replicate.com/v1/models/cuuupid/idm-vton/predictions';

export class ReplicateIdmVtonProvider extends VirtualTryOnProvider {
  constructor({ token, fetchImpl = fetch }) {
    super();
    if (!token) throw new Error('REPLICATE_API_TOKEN is required');
    this.token = token;
    this.fetch = fetchImpl;
  }

  async generate({ person, garments }) {
    let currentPerson = toDataUri(person.buffer, person.mimeType);
    const supported = garments
      .filter((item) => !['shoes', 'accessories', 'other'].includes(item.category))
      .sort((a, b) => order(a.category) - order(b.category));

    if (supported.length === 0) {
      throw new Error('IDM-VTON needs an upper-body, lower-body, or outerwear garment');
    }

    // IDM-VTON handles one garment per call. Applying pieces in sequence makes
    // top + outerwear + bottom possible while preserving the previous result.
    for (const garment of supported) {
      currentPerson = await this.#runPrediction({
        humanImage: currentPerson,
        garmentImage: toDataUri(garment.buffer, garment.mimeType),
        category: toIdmCategory(garment.category),
      });
    }
    return currentPerson;
  }

  async #runPrediction({ humanImage, garmentImage, category }) {
    const response = await this.fetch(predictionEndpoint, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${this.token}`,
        'Content-Type': 'application/json',
        Prefer: 'wait=60',
      },
      body: JSON.stringify({
        input: {
          human_img: humanImage,
          garm_img: garmentImage,
          garment_des: 'A garment from the user wardrobe',
          category,
          is_checked: true,
          is_checked_crop: false,
          denoise_steps: 30,
          seed: 42,
        },
      }),
    });
    const prediction = await jsonOrThrow(response);
    const completed = isTerminal(prediction.status)
      ? prediction
      : await this.#poll(prediction.urls?.get);

    if (completed.status !== 'succeeded') {
      throw new Error(completed.error || 'Replicate generation failed');
    }
    const output = Array.isArray(completed.output)
      ? completed.output[0]
      : completed.output;
    if (typeof output !== 'string') throw new Error('Replicate returned no image');
    return output;
  }

  async #poll(statusUrl) {
    if (!statusUrl) throw new Error('Replicate did not return a status URL');
    const deadline = Date.now() + 120_000;
    while (Date.now() < deadline) {
      await new Promise((resolve) => setTimeout(resolve, 1500));
      const response = await this.fetch(statusUrl, {
        headers: { Authorization: `Bearer ${this.token}` },
      });
      const prediction = await jsonOrThrow(response);
      if (isTerminal(prediction.status)) return prediction;
    }
    throw new Error('Replicate prediction timed out');
  }
}

function toDataUri(buffer, mimeType) {
  return `data:${mimeType};base64,${buffer.toString('base64')}`;
}

function toIdmCategory(category) {
  return category === 'bottoms' ? 'lower_body' : 'upper_body';
}

function order(category) {
  return { tops: 0, outerwear: 1, bottoms: 2 }[category] ?? 99;
}

function isTerminal(status) {
  return ['succeeded', 'failed', 'canceled'].includes(status);
}

async function jsonOrThrow(response) {
  const body = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new Error(body.detail || body.title || `Replicate HTTP ${response.status}`);
  }
  return body;
}
