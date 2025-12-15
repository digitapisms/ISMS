import type { VercelRequest, VercelResponse } from '@vercel/node';
import { serve } from 'std/server';

interface AiRequest {
  schoolId: string;
  userId?: string;
  promptKey: string;
  input: Record<string, unknown>;
}

const OPENAI_API_URL = 'https://api.openai.com/v1/chat/completions';

async function handler(req: Request): Promise<Response> {
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
    });
  }

  const apiKey = Deno.env.get('OPENAI_API_KEY');
  if (!apiKey) {
    return new Response(JSON.stringify({ error: 'Missing OPENAI_API_KEY' }), {
      status: 500,
    });
  }

  let payload: AiRequest;
  try {
    payload = await req.json();
  } catch (error) {
    return new Response(JSON.stringify({ error: 'Invalid JSON payload' }), {
      status: 400,
    });
  }

  // TODO: load prompt template from ai_prompts table based on payload.promptKey
  const prompt = `You are an AI assistant. Respond to: ${JSON.stringify(
    payload.input,
  )}`;

  const response = await fetch(OPENAI_API_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: 'gpt-4o-mini',
      messages: [
        { role: 'system', content: 'You are a helpful assistant.' },
        { role: 'user', content: prompt },
      ],
    }),
  });

  if (!response.ok) {
    const errorBody = await response.text();
    return new Response(errorBody, { status: response.status });
  }

  const data = await response.json();
  return new Response(JSON.stringify(data), {
    headers: { 'Content-Type': 'application/json' },
  });
}

serve(handler);

