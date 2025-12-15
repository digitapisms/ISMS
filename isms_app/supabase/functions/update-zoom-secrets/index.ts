import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

interface UpdateSecretsRequest {
  ZOOM_ACCOUNT_ID: string;
  ZOOM_CLIENT_ID: string;
  ZOOM_CLIENT_SECRET: string;
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

    // Verify user is super admin
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Get Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Verify user is super admin
    const token = authHeader.replace('Bearer ', '');
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Check if user is super admin
    const { data: userData, error: userError } = await supabase
      .from('users')
      .select('role')
      .eq('auth_id', user.id)
      .single();

    if (userError || userData?.role !== 'super_admin') {
      return new Response(
        JSON.stringify({ error: 'Forbidden: Super admin access required' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Parse request
    const secrets: UpdateSecretsRequest = await req.json();

    if (!secrets.ZOOM_ACCOUNT_ID || !secrets.ZOOM_CLIENT_ID || !secrets.ZOOM_CLIENT_SECRET) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Update system_settings table
    const updates = [
      supabase
        .from('system_settings')
        .upsert({
          setting_key: 'ZOOM_ACCOUNT_ID',
          setting_value: secrets.ZOOM_ACCOUNT_ID,
          description: 'Zoom Account ID for OAuth authentication',
          is_encrypted: true,
        }),
      supabase
        .from('system_settings')
        .upsert({
          setting_key: 'ZOOM_CLIENT_ID',
          setting_value: secrets.ZOOM_CLIENT_ID,
          description: 'Zoom OAuth Client ID',
          is_encrypted: true,
        }),
      supabase
        .from('system_settings')
        .upsert({
          setting_key: 'ZOOM_CLIENT_SECRET',
          setting_value: secrets.ZOOM_CLIENT_SECRET,
          description: 'Zoom OAuth Client Secret',
          is_encrypted: true,
        }),
    ];

    await Promise.all(updates);

    // Note: Supabase Edge Function secrets cannot be updated via API
    // The user needs to update them manually in the Dashboard
    // But we've saved them in the database for future reference

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Zoom credentials saved to database. Please update Supabase Edge Function secrets manually in the Dashboard.',
        note: 'Go to Supabase Dashboard → Edge Functions → create-zoom-meeting → Settings to update environment variables.',
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (error) {
    console.error('Error updating Zoom secrets:', error);
    return new Response(
      JSON.stringify({
        error: 'Failed to update Zoom secrets',
        details: error instanceof Error ? error.message : String(error),
      }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    );
  }
});

