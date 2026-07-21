const DEFAULT_MODEL = 'gemini-2.5-flash-lite';
const MAX_BASE64_LENGTH = 4 * 1024 * 1024;

const responseSchema = {
  type: 'OBJECT',
  properties: {
    rawText: { type: 'STRING' },
    items: {
      type: 'ARRAY',
      items: {
        type: 'OBJECT',
        properties: {
          name: { type: 'STRING' },
          quantity: { type: 'NUMBER' },
          unitPrice: { type: 'NUMBER' },
          sectionName: { type: 'STRING' },
        },
        required: ['name', 'quantity', 'unitPrice', 'sectionName'],
      },
    },
  },
  required: ['rawText', 'items'],
};

module.exports = async function handler(request, response) {
  response.setHeader('Access-Control-Allow-Origin', '*');
  response.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  response.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (request.method === 'OPTIONS') {
    return response.status(204).end();
  }

  if (request.method !== 'POST') {
    return response.status(405).json({ error: 'Method not allowed' });
  }

  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    return response.status(503).json({ error: 'Gemini API key is not configured' });
  }

  try {
    const body = readBody(request.body);
    const imageBase64 = normalizeBase64(body.imageBase64 || body.image);
    const mimeType = normalizeMimeType(body.mimeType);

    if (!imageBase64) {
      return response.status(400).json({ error: 'Missing imageBase64' });
    }

    if (imageBase64.length > MAX_BASE64_LENGTH) {
      return response.status(413).json({ error: 'Image is too large for the web import endpoint' });
    }

    const model = process.env.GEMINI_MODEL || DEFAULT_MODEL;
    const geminiResponse = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey,
        },
        body: JSON.stringify({
          contents: [
            {
              parts: [
                {
                  inline_data: {
                    mime_type: mimeType,
                    data: imageBase64,
                  },
                },
                { text: imagePrompt },
              ],
            },
          ],
          generationConfig: {
            temperature: 0.1,
            response_mime_type: 'application/json',
            response_schema: responseSchema,
          },
        }),
      },
    );

    if (!geminiResponse.ok) {
      const detail = await safeText(geminiResponse);
      console.error('Gemini image request failed', geminiResponse.status, detail);
      return response.status(502).json({ error: 'Gemini image request failed' });
    }

    const payload = await geminiResponse.json();
    const parsed = decodePayload(extractOutputText(payload));

    return response.status(200).json({
      rawText: readString(parsed.rawText),
      items: normalizeItems(parsed.items),
    });
  } catch (error) {
    console.error('Failed to interpret shopping image', error);
    return response.status(500).json({ error: 'Failed to interpret shopping image' });
  }
};

function readBody(body) {
  if (!body) return {};
  if (typeof body === 'string') {
    try {
      return JSON.parse(body);
    } catch {
      return {};
    }
  }
  return body;
}

function normalizeBase64(value) {
  if (typeof value !== 'string') return '';
  return value.replace(/^data:[^;]+;base64,/, '').trim();
}

function normalizeMimeType(value) {
  if (typeof value === 'string' && value.startsWith('image/')) {
    return value;
  }
  return 'image/jpeg';
}

const imagePrompt = `
Voce e o assistente de importacao por foto do app MercadoSmart.
Leia a imagem como uma lista de compras, ticket simples ou anotacao de mercado.
Primeiro transcreva em rawText o texto util que aparece na imagem.
Depois extraia apenas os produtos visiveis ou claramente escritos na imagem.
Nao invente itens.
Para cada item, retorne:
- name: nome limpo do produto em portugues
- quantity: numero decimal; use 1 quando nao houver quantidade
- unitPrice: use 0 quando nao houver preco
- sectionName: secao provavel do supermercado, como Hortifruti, Acougue, Padaria, Frios, Limpeza, Higiene, Bebidas, Congelados ou Mercearia
Retorne somente JSON valido no formato { "rawText": "...", "items": [...] }.
`;

function extractOutputText(payload) {
  const parts = payload?.candidates?.[0]?.content?.parts;
  if (Array.isArray(parts)) {
    const part = parts.find((entry) => typeof entry.text === 'string');
    if (part) return part.text;
  }
  return payload?.output_text || payload?.outputText || '';
}

function decodePayload(text) {
  if (!text || typeof text !== 'string') return {};
  const cleaned = text
    .trim()
    .replace(/^```(?:json)?\s*/i, '')
    .replace(/\s*```$/, '')
    .trim();
  return JSON.parse(cleaned);
}

function normalizeItems(items) {
  if (!Array.isArray(items)) return [];
  return items
    .map((item) => ({
      name: readString(item.name || item.produto || item.product),
      quantity: readNumber(item.quantity || item.quantidade || item.qtd, 1),
      unitPrice: readNumber(
        item.unitPrice || item.precoUnitario || item.preco || item.price,
        0,
      ),
      sectionName: readString(
        item.sectionName || item.section || item.secao || item.categoria,
        'Mercearia',
      ),
    }))
    .filter((item) => item.name.length > 0);
}

function readString(value, fallback = '') {
  const text = value == null ? '' : String(value).trim();
  return text || fallback;
}

function readNumber(value, fallback) {
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  if (typeof value === 'string') {
    const direct = Number(value.replace(',', '.'));
    if (Number.isFinite(direct)) return direct;
    const match = value.match(/\d+(?:[,.]\d+)?/);
    if (match) {
      const parsed = Number(match[0].replace(',', '.'));
      if (Number.isFinite(parsed)) return parsed;
    }
  }
  return fallback;
}

async function safeText(fetchResponse) {
  try {
    return await fetchResponse.text();
  } catch {
    return '';
  }
}
