import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

interface CreateGoogleMeetRequest {
  title: string;
  description?: string;
  startTime: string; // ISO 8601 format
  duration: number; // minutes
}

interface GoogleMeetResponse {
  id: string;
  conferenceId: string;
  joinUrl: string;
  startUrl: string;
  entryPointAccessCode?: string;
  conferenceData: {
    conferenceId: string;
    entryPoints: Array<{
      entryPointType: string;
      uri: string;
      label: string;
      accessCode?: string;
    }>;
  };
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

    // Get Supabase client for database access
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Get Google Meet credentials from database (system_settings) or environment variables
    let clientEmail = Deno.env.get('GOOGLE_MEET_CLIENT_EMAIL')?.trim();
    let privateKey = Deno.env.get('GOOGLE_MEET_PRIVATE_KEY')?.trim();
    let projectId = Deno.env.get('GOOGLE_MEET_PROJECT_ID')?.trim();

    // If not in environment, try to get from database
    if (!clientEmail || !privateKey || !projectId) {
      const { data: settings, error: settingsError } = await supabase
        .from('system_settings')
        .select('setting_key, setting_value')
        .in('setting_key', ['GOOGLE_MEET_CLIENT_EMAIL', 'GOOGLE_MEET_PRIVATE_KEY', 'GOOGLE_MEET_PROJECT_ID']);

      if (!settingsError && settings) {
        for (const setting of settings) {
          const value = (setting.setting_value as string)?.trim() || '';
          if (setting.setting_key === 'GOOGLE_MEET_CLIENT_EMAIL') {
            clientEmail = value;
          } else if (setting.setting_key === 'GOOGLE_MEET_PRIVATE_KEY') {
            privateKey = value;
          } else if (setting.setting_key === 'GOOGLE_MEET_PROJECT_ID') {
            projectId = value;
          }
        }
      }
    }

    // Trim all credentials
    clientEmail = clientEmail?.trim() || '';
    privateKey = privateKey?.trim() || '';
    projectId = projectId?.trim() || '';

    if (!clientEmail || !privateKey || !projectId) {
      return new Response(
        JSON.stringify({ 
          error: 'Google Meet credentials not configured. Please configure Google Meet integration in Super Admin settings or set environment variables.',
          details: {
            hasClientEmail: !!clientEmail,
            hasPrivateKey: !!privateKey,
            hasProjectId: !!projectId,
          }
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Parse request
    const requestData: CreateGoogleMeetRequest = await req.json();

    if (!requestData.title || !requestData.startTime || !requestData.duration) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: title, startTime, duration' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Parse private key - can be JSON string (Google Service Account JSON) or PEM string
    // The createJWT function will handle both formats
    let privateKeyObj: any = privateKey;
    try {
      // Try to parse as JSON first (Google Service Account format)
      privateKeyObj = JSON.parse(privateKey);
    } catch (e) {
      // If parsing fails, it might be a PEM string - pass it as-is
      // The createJWT function will handle both formats
      privateKeyObj = privateKey;
    }

    // Get OAuth access token using Service Account
    const jwt = await createJWT(clientEmail, privateKeyObj, projectId);
    const accessToken = await getAccessToken(jwt);

    if (!accessToken) {
      return new Response(
        JSON.stringify({ error: 'Failed to obtain Google access token' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Create Google Calendar event with Google Meet conference
    const startDateTime = new Date(requestData.startTime);
    const endDateTime = new Date(startDateTime.getTime() + requestData.duration * 60 * 1000);

    const calendarEvent = {
      summary: requestData.title,
      description: requestData.description || '',
      start: {
        dateTime: startDateTime.toISOString(),
        timeZone: 'UTC',
      },
      end: {
        dateTime: endDateTime.toISOString(),
        timeZone: 'UTC',
      },
      conferenceData: {
        createRequest: {
          requestId: `isms-${Date.now()}-${Math.random().toString(36).substring(7)}`,
          conferenceSolutionKey: {
            type: 'hangoutsMeet',
          },
        },
      },
    };

    // Create event via Google Calendar API
    const calendarResponse = await fetch(
      'https://www.googleapis.com/calendar/v3/calendars/primary/events?conferenceDataVersion=1',
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${accessToken}`,
        },
        body: JSON.stringify(calendarEvent),
      }
    );

    if (!calendarResponse.ok) {
      const errorText = await calendarResponse.text();
      console.error('Google Calendar API error:', errorText);
      return new Response(
        JSON.stringify({ 
          error: 'Failed to create Google Meet',
          details: errorText 
        }),
        { status: calendarResponse.status, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const event: any = await calendarResponse.json();
    const conferenceData = event.conferenceData;
    const entryPoint = conferenceData?.entryPoints?.[0];

    // Return meeting details
    return new Response(
      JSON.stringify({
        success: true,
        meeting: {
          id: event.id,
          conferenceId: conferenceData?.conferenceId || '',
          joinUrl: entryPoint?.uri || event.htmlLink || '',
          startUrl: entryPoint?.uri || event.htmlLink || '',
          entryPointAccessCode: entryPoint?.accessCode,
          conferenceData: conferenceData,
        },
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (error) {
    console.error('Error creating Google Meet:', error);
    return new Response(
      JSON.stringify({
        error: 'Failed to create Google Meet',
        details: error instanceof Error ? error.message : String(error),
      }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    );
  }
});

// Helper function to base64url encode
function base64UrlEncode(data: string): string {
  return btoa(data)
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '');
}

// Helper function to convert PEM to ArrayBuffer
function pemToArrayBuffer(pem: string): ArrayBuffer {
  const base64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s/g, '');
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes.buffer;
}

// Extract private key from JSON - handles both PEM string and JSON object formats
function extractPrivateKeyPem(privateKey: any): string {
  // If it's already a PEM string
  if (typeof privateKey === 'string') {
    if (privateKey.includes('BEGIN PRIVATE KEY') || privateKey.includes('BEGIN RSA PRIVATE KEY')) {
      return privateKey;
    }
    // If it's a JSON string, parse it
    try {
      const parsed = JSON.parse(privateKey);
      return extractPrivateKeyPem(parsed);
    } catch {
      throw new Error('Invalid private key format: expected PEM string or JSON object');
    }
  }

  // If it's a JSON object, check for common fields
  if (typeof privateKey === 'object' && privateKey !== null) {
    // Google Service Account JSON format
    if (privateKey.private_key) {
      return privateKey.private_key;
    }
    // Alternative field names
    if (privateKey.privateKey) {
      return privateKey.privateKey;
    }
    // If it has RSA components, we'd need to reconstruct PEM (complex)
    // For now, throw an error asking for PEM format
    throw new Error(
      'Private key must be in PEM format. Please provide the private_key field from Google Service Account JSON.'
    );
  }

  throw new Error('Invalid private key format');
}

// Create JWT for Service Account authentication with proper RS256 signing
async function createJWT(clientEmail: string, privateKey: any, projectId: string): Promise<string> {
  const header = {
    alg: 'RS256',
    typ: 'JWT',
  };

  const now = Math.floor(Date.now() / 1000);
  const claim = {
    iss: clientEmail,
    scope: 'https://www.googleapis.com/auth/calendar.events',
    aud: 'https://oauth2.googleapis.com/token',
    exp: now + 3600,
    iat: now,
  };

  // Encode header and claim
  const encodedHeader = base64UrlEncode(JSON.stringify(header));
  const encodedClaim = base64UrlEncode(JSON.stringify(claim));
  
  // Create the unsigned JWT
  const unsignedJWT = `${encodedHeader}.${encodedClaim}`;

  try {
    // Extract private key PEM from the provided format
    const privateKeyPem = extractPrivateKeyPem(privateKey);

    // Convert PEM to ArrayBuffer
    const keyData = pemToArrayBuffer(privateKeyPem);

    // Import the private key using Web Crypto API
    const cryptoKey = await crypto.subtle.importKey(
      'pkcs8', // Format for PKCS#8 private key
      keyData,
      {
        name: 'RSASSA-PKCS1-v1_5',
        hash: 'SHA-256',
      },
      false,
      ['sign']
    );

    // Sign the JWT using RS256
    const signature = await crypto.subtle.sign(
      {
        name: 'RSASSA-PKCS1-v1_5',
      },
      cryptoKey,
      new TextEncoder().encode(unsignedJWT)
    );

    // Convert signature ArrayBuffer to base64url
    const signatureArray = new Uint8Array(signature);
    // Convert bytes to binary string for btoa (using loop to avoid stack overflow)
    let binaryString = '';
    for (let i = 0; i < signatureArray.length; i++) {
      binaryString += String.fromCharCode(signatureArray[i]);
    }
    // Encode to base64url
    const encodedSignature = base64UrlEncode(binaryString);

    // Return the complete signed JWT
    return `${unsignedJWT}.${encodedSignature}`;
  } catch (error) {
    console.error('Error creating JWT:', error);
    throw new Error(
      `Failed to create JWT: ${error instanceof Error ? error.message : String(error)}. ` +
      `Please ensure the private key is in valid PEM format from Google Service Account JSON.`
    );
  }
}

// Get access token from Google OAuth
async function getAccessToken(jwt: string): Promise<string | null> {
  try {
    const response = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion: jwt,
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('OAuth token error:', errorText);
      return null;
    }

    const data = await response.json();
    return data.access_token;
  } catch (error) {
    console.error('Error getting access token:', error);
    return null;
  }
}
