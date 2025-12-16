import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

interface CreateZoomMeetingRequest {
  title: string;
  description?: string;
  startTime: string; // ISO 8601 format
  duration: number; // minutes
  password?: string;
  settings?: {
    waitingRoom?: boolean;
    joinBeforeHost?: boolean;
    muteUponEntry?: boolean;
    watermark?: boolean;
    usePmi?: boolean;
    approvalType?: number;
    audio?: string;
    autoRecording?: string;
    enforceLogin?: boolean;
    enforceLoginDomains?: string;
    alternativeHosts?: string;
    alternativeHostsEmailNotification?: boolean;
    closeRegistration?: boolean;
    showShareButton?: boolean;
    allowMultipleDevices?: boolean;
    registrantsConfirmationEmail?: boolean;
    meetingAuthentication?: boolean;
    authenticationOptions?: {
      meetingPassword?: boolean;
      waitingRoom?: boolean;
    };
  };
}

interface ZoomMeetingResponse {
  id: number;
  uuid: string;
  host_id: string;
  host_email: string;
  topic: string;
  type: number;
  status: string;
  start_time: string;
  duration: number;
  timezone: string;
  created_at: string;
  start_url: string;
  join_url: string;
  password?: string;
  h323_password?: string;
  pstn_password?: string;
  encrypted_password?: string;
  settings: {
    host_video: boolean;
    participant_video: boolean;
    cn_meeting: boolean;
    in_meeting: boolean;
    join_before_host: boolean;
    jbh_time: number;
    mute_upon_entry: boolean;
    watermark: boolean;
    use_pmi: boolean;
    approval_type: number;
    audio: string;
    auto_recording: string;
    enforce_login: boolean;
    enforce_login_domains: string;
    alternative_hosts: string;
    alternative_hosts_email_notification: boolean;
    close_registration: boolean;
    show_share_button: boolean;
    allow_multiple_devices: boolean;
    registrants_confirmation_email: boolean;
    meeting_authentication: boolean;
    authentication_option: {
      meeting_password: boolean;
      waiting_room: boolean;
    };
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

    // Get Zoom credentials from database (system_settings) or environment variables
    let zoomAccountId = Deno.env.get('ZOOM_ACCOUNT_ID')?.trim();
    let zoomClientId = Deno.env.get('ZOOM_CLIENT_ID')?.trim();
    let zoomClientSecret = Deno.env.get('ZOOM_CLIENT_SECRET')?.trim();

    // If not in environment, try to get from database
    if (!zoomAccountId || !zoomClientId || !zoomClientSecret) {
      const { data: settings, error: settingsError } = await supabase
        .from('system_settings')
        .select('setting_key, setting_value')
        .in('setting_key', ['ZOOM_ACCOUNT_ID', 'ZOOM_CLIENT_ID', 'ZOOM_CLIENT_SECRET']);

      if (!settingsError && settings) {
        for (const setting of settings) {
          const value = (setting.setting_value as string)?.trim() || '';
          if (setting.setting_key === 'ZOOM_ACCOUNT_ID') {
            zoomAccountId = value;
          } else if (setting.setting_key === 'ZOOM_CLIENT_ID') {
            zoomClientId = value;
          } else if (setting.setting_key === 'ZOOM_CLIENT_SECRET') {
            zoomClientSecret = value;
          }
        }
      }
    }

    // Trim all credentials to remove any whitespace
    zoomAccountId = zoomAccountId?.trim() || '';
    zoomClientId = zoomClientId?.trim() || '';
    zoomClientSecret = zoomClientSecret?.trim() || '';

    if (!zoomAccountId || !zoomClientId || !zoomClientSecret) {
      return new Response(
        JSON.stringify({ 
          error: 'Zoom credentials not configured. Please configure Zoom integration in Super Admin settings or set environment variables.',
          details: {
            hasAccountId: !!zoomAccountId,
            hasClientId: !!zoomClientId,
            hasClientSecret: !!zoomClientSecret,
          }
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Validate Account ID format (should start with C-)
    if (!zoomAccountId.startsWith('C-')) {
      return new Response(
        JSON.stringify({ 
          error: 'Invalid Zoom Account ID format. Account ID should start with "C-"',
          details: { accountIdLength: zoomAccountId.length }
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Parse request
    const requestData: CreateZoomMeetingRequest = await req.json();

    if (!requestData.title || !requestData.startTime || !requestData.duration) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: title, startTime, duration' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Get OAuth access token
    // Note: Zoom Server-to-Server OAuth requires the Account ID in the request body
    // and Client ID:Client Secret in Basic Auth header
    const authString = `${zoomClientId}:${zoomClientSecret}`;
    const basicAuth = btoa(authString);
    
    console.log('Attempting Zoom OAuth with:', {
      accountId: zoomAccountId.substring(0, 5) + '...',
      clientIdLength: zoomClientId.length,
      clientSecretLength: zoomClientSecret.length,
    });

    const tokenResponse = await fetch('https://zoom.us/oauth/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': `Basic ${basicAuth}`,
      },
      body: new URLSearchParams({
        grant_type: 'account_credentials',
        account_id: zoomAccountId,
      }),
    });

    if (!tokenResponse.ok) {
      const errorText = await tokenResponse.text();
      let errorDetails;
      try {
        errorDetails = JSON.parse(errorText);
      } catch {
        errorDetails = { raw: errorText };
      }
      
      console.error('Zoom OAuth error:', {
        status: tokenResponse.status,
        statusText: tokenResponse.statusText,
        error: errorDetails,
      });

      // Provide helpful error messages based on the error
      let errorMessage = 'Failed to authenticate with Zoom API';
      if (errorDetails.error === 'invalid_client') {
        errorMessage = 'Invalid Zoom credentials. Please verify:\n' +
          '1. Client ID and Client Secret are correct\n' +
          '2. No extra spaces or characters in credentials\n' +
          '3. OAuth app is activated in Zoom Marketplace\n' +
          '4. Account ID starts with "C-" and is correct';
      } else if (errorDetails.error === 'invalid_grant') {
        errorMessage = 'Invalid Account ID. Please verify the Account ID is correct and starts with "C-"';
      }

      return new Response(
        JSON.stringify({ 
          error: errorMessage,
          details: errorDetails,
          troubleshooting: {
            checkCredentials: 'Verify credentials in Zoom Marketplace → Your App → App Credentials',
            checkActivation: 'Ensure OAuth app is activated in Zoom Marketplace',
            checkAccountId: 'Account ID should start with "C-" and match your Zoom account',
          }
        }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const tokenData = await tokenResponse.json();
    const accessToken = tokenData.access_token;

    if (!accessToken) {
      return new Response(
        JSON.stringify({ error: 'Failed to obtain Zoom access token' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Prepare meeting data
    const meetingData: any = {
      topic: requestData.title,
      type: 2, // Scheduled meeting
      start_time: requestData.startTime,
      duration: requestData.duration,
      timezone: Intl.DateTimeFormat().resolvedOptions().timeZone || 'UTC',
      settings: {
        host_video: true,
        participant_video: true,
        join_before_host: requestData.settings?.joinBeforeHost ?? false,
        mute_upon_entry: requestData.settings?.muteUponEntry ?? false,
        watermark: requestData.settings?.watermark ?? false,
        use_pmi: requestData.settings?.usePmi ?? false,
        approval_type: requestData.settings?.approvalType ?? 0, // 0 = Automatically approve
        audio: requestData.settings?.audio ?? 'both',
        auto_recording: requestData.settings?.autoRecording ?? 'none',
        enforce_login: requestData.settings?.enforceLogin ?? false,
        waiting_room: requestData.settings?.waitingRoom ?? false,
        meeting_authentication: requestData.settings?.meetingAuthentication ?? false,
      },
    };

    // Add password if provided
    if (requestData.password) {
      meetingData.password = requestData.password;
    }

    // Add description if provided
    if (requestData.description) {
      meetingData.agenda = requestData.description;
    }

    // Create Zoom meeting
    const meetingResponse = await fetch('https://api.zoom.us/v2/users/me/meetings', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${accessToken}`,
      },
      body: JSON.stringify(meetingData),
    });

    if (!meetingResponse.ok) {
      const errorText = await meetingResponse.text();
      console.error('Zoom API error:', errorText);
      return new Response(
        JSON.stringify({ 
          error: 'Failed to create Zoom meeting',
          details: errorText 
        }),
        { status: meetingResponse.status, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const meeting: ZoomMeetingResponse = await meetingResponse.json();

    // Return meeting details
    return new Response(
      JSON.stringify({
        success: true,
        meeting: {
          id: meeting.id,
          uuid: meeting.uuid,
          topic: meeting.topic,
          startTime: meeting.start_time,
          duration: meeting.duration,
          joinUrl: meeting.join_url,
          startUrl: meeting.start_url,
          password: meeting.password,
          settings: meeting.settings,
        },
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (error) {
    console.error('Error creating Zoom meeting:', error);
    return new Response(
      JSON.stringify({
        error: 'Failed to create Zoom meeting',
        details: error instanceof Error ? error.message : String(error),
      }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    );
  }
});

