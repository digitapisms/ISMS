import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

interface SendEmailRequest {
  to: string;
  subject: string;
  body: string;
  from?: string;
  is_html?: boolean;
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
    const requestData: SendEmailRequest = await req.json();

    if (!requestData.to || !requestData.subject || !requestData.body) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: to, subject, body' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Get email service configuration from environment or database
    let emailProvider = Deno.env.get('EMAIL_PROVIDER') || 'sendgrid';
    let apiKey = Deno.env.get('EMAIL_API_KEY');
    let fromEmail = Deno.env.get('EMAIL_FROM') || requestData.from || 'noreply@isms.app';

    // If not in environment, try to get from database
    if (!apiKey) {
      const { data: settings } = await supabase
        .from('system_settings')
        .select('setting_key, setting_value')
        .in('setting_key', ['EMAIL_PROVIDER', 'EMAIL_API_KEY', 'EMAIL_FROM']);

      if (settings) {
        for (const setting of settings) {
          if (setting.setting_key === 'EMAIL_PROVIDER') {
            emailProvider = setting.setting_value as string;
          } else if (setting.setting_key === 'EMAIL_API_KEY') {
            apiKey = setting.setting_value as string;
          } else if (setting.setting_key === 'EMAIL_FROM') {
            fromEmail = setting.setting_value as string;
          }
        }
      }
    }

    if (!apiKey) {
      return new Response(
        JSON.stringify({ 
          error: 'Email service not configured. Please configure email API key in system settings.',
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Send email based on provider
    let emailResponse;
    switch (emailProvider.toLowerCase()) {
      case 'sendgrid':
        emailResponse = await sendViaSendGrid(apiKey, {
          to: requestData.to,
          from: fromEmail,
          subject: requestData.subject,
          body: requestData.body,
          isHtml: requestData.is_html || false,
        });
        break;
      case 'mailgun':
        emailResponse = await sendViaMailgun(apiKey, {
          to: requestData.to,
          from: fromEmail,
          subject: requestData.subject,
          body: requestData.body,
          isHtml: requestData.is_html || false,
        });
        break;
      case 'resend':
        emailResponse = await sendViaResend(apiKey, {
          to: requestData.to,
          from: fromEmail,
          subject: requestData.subject,
          body: requestData.body,
          isHtml: requestData.is_html || false,
        });
        break;
      default:
        return new Response(
          JSON.stringify({ error: `Unsupported email provider: ${emailProvider}` }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        );
    }

    // Log email in database
    try {
      await supabase.from('email_logs').insert({
        recipient: requestData.to,
        subject: requestData.subject,
        status: emailResponse.success ? 'sent' : 'failed',
        provider: emailProvider,
        error_message: emailResponse.error,
        sent_at: new Date().toISOString(),
      });
    } catch (e) {
      // Silently fail logging
      console.error('Failed to log email:', e);
    }

    if (emailResponse.success) {
      return new Response(
        JSON.stringify({
          success: true,
          message: 'Email sent successfully',
          messageId: emailResponse.messageId,
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    } else {
      return new Response(
        JSON.stringify({
          success: false,
          error: emailResponse.error || 'Failed to send email',
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }
  } catch (error) {
    console.error('Error sending email:', error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : String(error),
      }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    );
  }
});

// SendGrid implementation
async function sendViaSendGrid(apiKey: string, email: any) {
  try {
    const response = await fetch('https://api.sendgrid.com/v3/mail/send', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        personalizations: [{ to: [{ email: email.to }] }],
        from: { email: email.from },
        subject: email.subject,
        content: [{
          type: email.isHtml ? 'text/html' : 'text/plain',
          value: email.body,
        }],
      }),
    });

    if (response.ok) {
      const messageId = response.headers.get('x-message-id');
      return { success: true, messageId };
    } else {
      const errorText = await response.text();
      return { success: false, error: errorText };
    }
  } catch (error) {
    return { success: false, error: error instanceof Error ? error.message : String(error) };
  }
}

// Mailgun implementation
async function sendViaMailgun(apiKey: string, email: any) {
  try {
    const domain = Deno.env.get('MAILGUN_DOMAIN') || 'mg.isms.app';
    const auth = btoa(`api:${apiKey}`);
    
    const formData = new FormData();
    formData.append('from', email.from);
    formData.append('to', email.to);
    formData.append('subject', email.subject);
    if (email.isHtml) {
      formData.append('html', email.body);
    } else {
      formData.append('text', email.body);
    }

    const response = await fetch(`https://api.mailgun.net/v3/${domain}/messages`, {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${auth}`,
      },
      body: formData,
    });

    if (response.ok) {
      const data = await response.json();
      return { success: true, messageId: data.id };
    } else {
      const errorText = await response.text();
      return { success: false, error: errorText };
    }
  } catch (error) {
    return { success: false, error: error instanceof Error ? error.message : String(error) };
  }
}

// Resend implementation
async function sendViaResend(apiKey: string, email: any) {
  try {
    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: email.from,
        to: [email.to],
        subject: email.subject,
        html: email.isHtml ? email.body : undefined,
        text: email.isHtml ? undefined : email.body,
      }),
    });

    if (response.ok) {
      const data = await response.json();
      return { success: true, messageId: data.id };
    } else {
      const errorText = await response.text();
      return { success: false, error: errorText };
    }
  } catch (error) {
    return { success: false, error: error instanceof Error ? error.message : String(error) };
  }
}
