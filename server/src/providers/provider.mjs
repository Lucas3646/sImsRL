/**
 * @typedef {{ buffer: Buffer, mimeType: string, category: string }} GarmentInput
 * @typedef {{ person: {buffer: Buffer, mimeType: string}, garments: GarmentInput[] }} GenerateInput
 */

export class VirtualTryOnProvider {
  /** @param {GenerateInput} _input @returns {Promise<string>} */
  async generate(_input) {
    throw new Error('VirtualTryOnProvider.generate must be implemented');
  }
}
