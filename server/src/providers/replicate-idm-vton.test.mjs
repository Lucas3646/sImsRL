import assert from 'node:assert/strict';
import test from 'node:test';

import { ReplicateIdmVtonProvider } from './replicate-idm-vton.mjs';

test('applies upper then lower garment sequentially', async () => {
  const calls = [];
  const fetchImpl = async (_url, options) => {
    const body = JSON.parse(options.body);
    calls.push(body.input);
    return new Response(
      JSON.stringify({
        id: `prediction-${calls.length}`,
        status: 'succeeded',
        output: `https://example.com/result-${calls.length}.jpg`,
      }),
      { status: 201, headers: { 'content-type': 'application/json' } },
    );
  };
  const provider = new ReplicateIdmVtonProvider({ token: 'test', fetchImpl });

  const result = await provider.generate({
    person: { buffer: Buffer.from('person'), mimeType: 'image/jpeg' },
    garments: [
      { buffer: Buffer.from('bottom'), mimeType: 'image/jpeg', category: 'bottoms' },
      { buffer: Buffer.from('top'), mimeType: 'image/jpeg', category: 'tops' },
      { buffer: Buffer.from('shoe'), mimeType: 'image/jpeg', category: 'shoes' },
    ],
  });

  assert.equal(calls.length, 2);
  assert.equal(calls[0].category, 'upper_body');
  assert.equal(calls[1].category, 'lower_body');
  assert.equal(calls[1].human_img, 'https://example.com/result-1.jpg');
  assert.equal(result, 'https://example.com/result-2.jpg');
});
