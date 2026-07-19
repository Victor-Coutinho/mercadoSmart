const DEFAULT_MODEL = 'gemini-2.5-flash-lite';
const MAX_TEXT_LENGTH = 12000;

const responseSchema = {
  type: 'OBJECT',
  properties: {
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
  required: ['items'],
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
    const rawText = readRawText(request.body);
    if (!rawText) {
      return response.status(400).json({ error: 'Missing rawText' });
    }

    const limitedText = rawText.slice(0, MAX_TEXT_LENGTH);
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
          system_instruction: {
            parts: [{ text: systemInstruction }],
          },
          contents: [
            {
              role: 'user',
              parts: [{ text: buildPrompt(limitedText) }],
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
      console.error('Gemini request failed', geminiResponse.status, detail);
      return response.status(502).json({ error: 'Gemini request failed' });
    }

    const payload = await geminiResponse.json();
    const text = extractOutputText(payload);
    const items = normalizeItems(decodeItems(text));

    return response.status(200).json({ items });
  } catch (error) {
    console.error('Failed to interpret shopping list', error);
    return response.status(500).json({ error: 'Failed to interpret shopping list' });
  }
};

function readRawText(body) {
  if (!body) return '';
  if (typeof body === 'string') {
    try {
      return readRawText(JSON.parse(body));
    } catch {
      return body.trim();
    }
  }
  return String(body.rawText || body.text || '').trim();
}

const systemInstruction = `
Voce e um assistente de supermercado do app MercadoSmart.
Sua tarefa e transformar texto de OCR de listas de compras em JSON valido.
Classifique cada item em uma secao curta de supermercado em portugues.
Use preferencialmente secoes como Hortifruti, Acougue, Padaria, Frios, Limpeza, Higiene, Bebidas, Congelados ou Mercearia.
Nao invente produtos que nao aparecam no texto.
`;

function buildPrompt(rawText) {
  return `
Extraia os produtos da lista abaixo.
Para cada produto, informe:
- name: nome limpo do produto
- quantity: numero decimal; use 1 quando nao houver quantidade
- unitPrice: use 0 quando nao houver preco
- sectionName: secao provavel do supermercado

Texto OCR:
"""
${rawText}
"""
`;
}

function extractOutputText(payload) {
  if (!payload || typeof payload !== 'object') return '';
  const candidate = payload.candidates?.[0];
  const parts = candidate?.content?.parts;
  if (Array.isArray(parts)) {
    const part = parts.find((entry) => typeof entry.text === 'string');
    if (part) return part.text;
  }
  return payload.output_text || payload.outputText || '';
}

function decodeItems(text) {
  if (!text || typeof text !== 'string') return [];
  const cleaned = text
    .trim()
    .replace(/^```(?:json)?\s*/i, '')
    .replace(/\s*```$/, '')
    .trim();
  const decoded = JSON.parse(cleaned);
  if (Array.isArray(decoded)) return decoded;
  if (Array.isArray(decoded.items)) return decoded.items;
  if (Array.isArray(decoded.itens)) return decoded.itens;
  if (Array.isArray(decoded.produtos)) return decoded.produtos;
  return [];
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
