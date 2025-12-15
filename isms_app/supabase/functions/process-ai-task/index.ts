import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const OPENAI_API_URL = 'https://api.openai.com/v1/chat/completions';
const ANTHROPIC_API_URL = 'https://api.anthropic.com/v1/messages';

interface ProcessTaskRequest {
  taskId: string;
}

interface AiPrompt {
  prompt_key: string;
  name: string;
  description: string | null;
  prompt_yaml: string;
}

interface AiTask {
  id: string;
  school_id: string;
  user_id: string | null;
  prompt_key: string;
  status: string;
  input: Record<string, unknown>;
  output: Record<string, unknown> | null;
  error_message: string | null;
  tokens_used: number | null;
  cost: number | null;
}

serve(async (req) => {
  try {
    // CORS headers
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    };

    if (req.method === 'OPTIONS') {
      return new Response('ok', { headers: corsHeaders });
    }

    // Get Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Parse request
    const { taskId }: ProcessTaskRequest = await req.json();

    if (!taskId) {
      return new Response(
        JSON.stringify({ error: 'taskId is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Fetch task from database
    const { data: task, error: taskError } = await supabase
      .from('ai_tasks')
      .select('*')
      .eq('id', taskId)
      .single();

    if (taskError || !task) {
      return new Response(
        JSON.stringify({ error: 'Task not found', details: taskError }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const aiTask = task as AiTask;

    // Check if task is already processed
    if (aiTask.status === 'completed' || aiTask.status === 'failed') {
      return new Response(
        JSON.stringify({ message: 'Task already processed', task: aiTask }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Update task status to processing
    await supabase
      .from('ai_tasks')
      .update({
        status: 'processing',
        started_at: new Date().toISOString(),
      })
      .eq('id', taskId);

    // Fetch prompt template
    const { data: prompt, error: promptError } = await supabase
      .from('ai_prompts')
      .select('*')
      .eq('prompt_key', aiTask.prompt_key)
      .single();

    if (promptError || !prompt) {
      await supabase
        .from('ai_tasks')
        .update({
          status: 'failed',
          error_message: `Prompt not found: ${aiTask.prompt_key}`,
          completed_at: new Date().toISOString(),
        })
        .eq('id', taskId);

      return new Response(
        JSON.stringify({ error: 'Prompt not found', details: promptError }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const aiPrompt = prompt as AiPrompt;

    // Get API configuration
    const provider = Deno.env.get('AI_PROVIDER') || 'openai';
    const apiKey = provider === 'anthropic'
      ? Deno.env.get('ANTHROPIC_API_KEY')
      : Deno.env.get('OPENAI_API_KEY');

    if (!apiKey) {
      await supabase
        .from('ai_tasks')
        .update({
          status: 'failed',
          error_message: `Missing API key for provider: ${provider}`,
          completed_at: new Date().toISOString(),
        })
        .eq('id', taskId);

      return new Response(
        JSON.stringify({ error: `Missing API key for provider: ${provider}` }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Build prompt from template and input
    const systemPrompt = _buildSystemPrompt(aiPrompt, aiTask);
    const userMessage = _buildUserMessage(aiTask);

    // Call AI API
    let aiResponse: Response;
    let tokensUsed = 0;
    let cost = 0;

    if (provider === 'anthropic') {
      aiResponse = await fetch(ANTHROPIC_API_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: JSON.stringify({
          model: Deno.env.get('ANTHROPIC_MODEL') || 'claude-3-haiku-20240307',
          max_tokens: 4096,
          messages: [
            { role: 'user', content: `${systemPrompt}\n\n${userMessage}` },
          ],
        }),
      });

      if (!aiResponse.ok) {
        const errorText = await aiResponse.text();
        throw new Error(`Anthropic API error: ${errorText}`);
      }

      const data = await aiResponse.json();
      const responseText = data.content[0].text;
      tokensUsed = data.usage.input_tokens + data.usage.output_tokens;
      // Approximate cost: $0.25 per 1M input tokens, $1.25 per 1M output tokens
      cost = (data.usage.input_tokens * 0.25 + data.usage.output_tokens * 1.25) / 1000000;

      // Update task with response
      await supabase
        .from('ai_tasks')
        .update({
          status: 'completed',
          output: {
            response: responseText,
            model: data.model,
            usage: data.usage,
          },
          tokens_used: tokensUsed,
          cost: cost,
          completed_at: new Date().toISOString(),
        })
        .eq('id', taskId);

      return new Response(
        JSON.stringify({
          success: true,
          taskId,
          response: responseText,
          tokensUsed,
          cost,
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    } else {
      // OpenAI
      aiResponse = await fetch(OPENAI_API_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${apiKey}`,
        },
        body: JSON.stringify({
          model: Deno.env.get('OPENAI_MODEL') || 'gpt-4o-mini',
          messages: [
            { role: 'system', content: systemPrompt },
            { role: 'user', content: userMessage },
          ],
          temperature: 0.7,
          max_tokens: 2000,
        }),
      });

      if (!aiResponse.ok) {
        const errorText = await aiResponse.text();
        throw new Error(`OpenAI API error: ${errorText}`);
      }

      const data = await aiResponse.json();
      const responseText = data.choices[0].message.content;
      tokensUsed = data.usage.total_tokens;
      // Approximate cost for gpt-4o-mini: $0.15 per 1M input tokens, $0.60 per 1M output tokens
      const inputCost = (data.usage.prompt_tokens * 0.15) / 1000000;
      const outputCost = (data.usage.completion_tokens * 0.60) / 1000000;
      cost = inputCost + outputCost;

      // Update task with response
      await supabase
        .from('ai_tasks')
        .update({
          status: 'completed',
          output: {
            response: responseText,
            model: data.model,
            usage: data.usage,
          },
          tokens_used: tokensUsed,
          cost: cost,
          completed_at: new Date().toISOString(),
        })
        .eq('id', taskId);

      return new Response(
        JSON.stringify({
          success: true,
          taskId,
          response: responseText,
          tokensUsed,
          cost,
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }
  } catch (error) {
    console.error('Error processing AI task:', error);

    // Try to update task status to failed
    try {
      const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
      const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
      const supabase = createClient(supabaseUrl, supabaseServiceKey);

      const { taskId } = await req.json().catch(() => ({ taskId: null }));
      if (taskId) {
        await supabase
          .from('ai_tasks')
          .update({
            status: 'failed',
            error_message: error instanceof Error ? error.message : String(error),
            completed_at: new Date().toISOString(),
          })
          .eq('id', taskId);
      }
    } catch (updateError) {
      console.error('Failed to update task status:', updateError);
    }

    return new Response(
      JSON.stringify({
        error: 'Failed to process AI task',
        details: error instanceof Error ? error.message : String(error),
      }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    );
  }
});

function _buildSystemPrompt(prompt: AiPrompt, task: AiTask): string {
  // Parse YAML prompt if available, otherwise use description
  // For now, use a simple template
  const basePrompt = prompt.prompt_yaml || prompt.description || prompt.name;

  // Add context based on prompt type
  switch (prompt.prompt_key) {
    case 'ai_chat':
      return `You are an AI tutor assistant for a school management system. Help students and teachers with educational questions, explanations, and guidance. Be friendly, clear, and educational.`;
    case 'homework_explain':
      return `You are a homework helper. Explain concepts step-by-step, break down problems, and help students understand the material. Be patient and educational.`;
    case 'notice_generator':
      return `You are a school notice generator. Create professional, clear, and concise school notices. Use formal but friendly language.`;
    case 'timetable_solver':
      return `You are a timetable optimization assistant. Help create and optimize school schedules, considering constraints like teacher availability, room capacity, and class requirements.`;
    default:
      return basePrompt || 'You are a helpful AI assistant.';
  }
}

function _buildUserMessage(task: AiTask): string {
  // Extract message from input
  if (task.input.message) {
    return String(task.input.message);
  }

  // Handle conversation history if present
  if (task.input.conversation_history && Array.isArray(task.input.conversation_history)) {
    const history = task.input.conversation_history as Array<{ role: string; content: string }>;
    const lastMessage = history[history.length - 1];
    if (lastMessage && lastMessage.content) {
      return lastMessage.content;
    }
  }

  // Fallback to stringifying the entire input
  return JSON.stringify(task.input);
}

