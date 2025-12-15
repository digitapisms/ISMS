-- ============================================================
-- AUTOMATED SUBSCRIPTION BILLING SYSTEM
-- ============================================================

-- 1. Function to process daily subscription billing
CREATE OR REPLACE FUNCTION process_daily_subscription_billing()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_subscription RECORD;
    v_invoice_count INTEGER := 0;
    v_reminder_count INTEGER := 0;
    v_expired_count INTEGER := 0;
BEGIN
    -- Process subscriptions that need billing today
    FOR v_subscription IN 
        SELECT ss.*, sp.name as plan_name, s.name as school_name, s.admin_email
        FROM school_subscriptions ss
        JOIN subscription_plans sp ON ss.plan_id = sp.id
        JOIN schools s ON ss.school_id = s.id
        WHERE ss.status = 'active'
        AND ss.next_billing_date <= CURRENT_DATE
        AND ss.auto_renew = true
    LOOP
        -- Generate invoice for the billing period
        INSERT INTO school_invoices (
            subscription_id,
            school_id,
            invoice_number,
            issue_date,
            due_date,
            period_start,
            period_end,
            subtotal,
            total_amount,
            currency,
            status
        )
        VALUES (
            v_subscription.id,
            v_subscription.school_id,
            'INV-SCH-' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '-' || LPAD(v_subscription.id::text, 6, '0'),
            CURRENT_DATE,
            CURRENT_DATE + INTERVAL '15 days',
            v_subscription.start_date,
            v_subscription.end_date,
            CASE v_subscription.billing_cycle
                WHEN 'monthly' THEN (SELECT price_per_month FROM subscription_plans WHERE id = v_subscription.plan_id)
                WHEN 'quarterly' THEN (SELECT price_per_quarter FROM subscription_plans WHERE id = v_subscription.plan_id)
                WHEN 'half_yearly' THEN (SELECT price_per_half_year FROM subscription_plans WHERE id = v_subscription.plan_id)
                WHEN 'yearly' THEN (SELECT price_per_year FROM subscription_plans WHERE id = v_subscription.plan_id)
            END,
            CASE v_subscription.billing_cycle
                WHEN 'monthly' THEN (SELECT price_per_month FROM subscription_plans WHERE id = v_subscription.plan_id)
                WHEN 'quarterly' THEN (SELECT price_per_quarter FROM subscription_plans WHERE id = v_subscription.plan_id)
                WHEN 'half_yearly' THEN (SELECT price_per_half_year FROM subscription_plans WHERE id = v_subscription.plan_id)
                WHEN 'yearly' THEN (SELECT price_per_year FROM subscription_plans WHERE id = v_subscription.plan_id)
            END,
            'PKR',
            'unpaid'
        );
        
        -- Update next billing date
        UPDATE school_subscriptions
        SET 
            next_billing_date = CASE billing_cycle
                WHEN 'monthly' THEN CURRENT_DATE + INTERVAL '1 month'
                WHEN 'quarterly' THEN CURRENT_DATE + INTERVAL '3 months'
                WHEN 'half_yearly' THEN CURRENT_DATE + INTERVAL '6 months'
                WHEN 'yearly' THEN CURRENT_DATE + INTERVAL '1 year'
            END,
            updated_at = NOW()
        WHERE id = v_subscription.id;
        
        v_invoice_count := v_invoice_count + 1;
        
        -- Send invoice notification
        PERFORM send_subscription_notification(
            v_subscription.school_id,
            'invoice_generated',
            JSONB_BUILD_OBJECT(
                'subscription_id', v_subscription.id,
                'plan_name', v_subscription.plan_name,
                'billing_cycle', v_subscription.billing_cycle,
                'amount', CASE v_subscription.billing_cycle
                    WHEN 'monthly' THEN (SELECT price_per_month FROM subscription_plans WHERE id = v_subscription.plan_id)
                    WHEN 'quarterly' THEN (SELECT price_per_quarter FROM subscription_plans WHERE id = v_subscription.plan_id)
                    WHEN 'half_yearly' THEN (SELECT price_per_half_year FROM subscription_plans WHERE id = v_subscription.plan_id)
                    WHEN 'yearly' THEN (SELECT price_per_year FROM subscription_plans WHERE id = v_subscription.plan_id)
                END
            )
        );
    END LOOP;
    
    -- Send renewal reminders (7 days before expiration)
    FOR v_subscription IN 
        SELECT ss.*, sp.name as plan_name, s.name as school_name, s.admin_email
        FROM school_subscriptions ss
        JOIN subscription_plans sp ON ss.plan_id = sp.id
        JOIN schools s ON ss.school_id = s.id
        WHERE ss.status = 'active'
        AND ss.end_date = CURRENT_DATE + INTERVAL '7 days'
    LOOP
        PERFORM send_subscription_notification(
            v_subscription.school_id,
            'renewal_reminder',
            JSONB_BUILD_OBJECT(
                'subscription_id', v_subscription.id,
                'plan_name', v_subscription.plan_name,
                'expiration_date', v_subscription.end_date,
                'auto_renew', v_subscription.auto_renew
            )
        );
        
        v_reminder_count := v_reminder_count + 1;
    END LOOP;
    
    -- Mark expired subscriptions
    UPDATE school_subscriptions
    SET status = 'expired', updated_at = NOW()
    WHERE status = 'active'
    AND end_date < CURRENT_DATE;
    
    GET DIAGNOSTICS v_expired_count = ROW_COUNT;
    
    RETURN JSONB_BUILD_OBJECT(
        'invoices_generated', v_invoice_count,
        'reminders_sent', v_reminder_count,
        'subscriptions_expired', v_expired_count,
        'processed_at', NOW()
    );
END;
$$;

-- 2. Function to send subscription notifications
CREATE OR REPLACE FUNCTION send_subscription_notification(
    p_school_id UUID,
    p_notification_type TEXT,
    p_data JSONB DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_school RECORD;
    v_notification_id UUID;
    v_subject TEXT;
    v_body TEXT;
    v_metadata JSONB;
BEGIN
    -- Get school details
    SELECT name, admin_email, contact_phone INTO v_school
    FROM schools WHERE id = p_school_id;
    
    -- Determine subject and body based on notification type
    CASE p_notification_type
        WHEN 'invoice_generated' THEN
            v_subject := 'New Subscription Invoice - ' || v_school.name;
            v_body := 'A new invoice has been generated for your ' || 
                     (p_data->>'billing_cycle') || ' subscription to ' ||
                     (p_data->>'plan_name') || '. Amount: PKR ' ||
                     (p_data->>'amount') || '. Please pay by the due date.';
            v_metadata := JSONB_BUILD_OBJECT('type', 'invoice', 'amount', p_data->>'amount');
            
        WHEN 'renewal_reminder' THEN
            v_subject := 'Subscription Renewal Reminder - ' || v_school.name;
            v_body := 'Your subscription to ' || (p_data->>'plan_name') || 
                     ' will expire on ' || (p_data->>'expiration_date') ||
                     '. Auto-renew is ' || CASE WHEN (p_data->>'auto_renew')::boolean 
                     THEN 'enabled' ELSE 'disabled' END || '.';
            v_metadata := JSONB_BUILD_OBJECT('type', 'renewal_reminder');
            
        WHEN 'payment_failed' THEN
            v_subject := 'Payment Failed - ' || v_school.name;
            v_body := 'We were unable to process your subscription payment. ' ||
                     'Please update your payment method to avoid service interruption.';
            v_metadata := JSONB_BUILD_OBJECT('type', 'payment_failed');
            
        ELSE
            RAISE EXCEPTION 'Unknown notification type: %', p_notification_type;
    END CASE;
    
    -- Insert notification
    INSERT INTO notifications (
        type,
        recipient_email,
        recipient_name,
        subject,
        body,
        status,
        metadata,
        related_school_id
    )
    VALUES (
        'subscription_' || p_notification_type,
        v_school.admin_email,
        v_school.name,
        v_subject,
        v_body,
        'pending',
        v_metadata,
        p_school_id
    )
    RETURNING id INTO v_notification_id;
    
    RETURN v_notification_id;
END;
$$;

-- 3. Function to process overdue invoices
CREATE OR REPLACE FUNCTION process_overdue_invoices()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_invoice RECORD;
    v_overdue_count INTEGER := 0;
    v_reminder_count INTEGER := 0;
BEGIN
    -- Mark invoices as overdue
    UPDATE school_invoices
    SET status = 'overdue', updated_at = NOW()
    WHERE status = 'unpaid'
    AND due_date < CURRENT_DATE;
    
    GET DIAGNOSTICS v_overdue_count = ROW_COUNT;
    
    -- Send overdue reminders
    FOR v_invoice IN 
        SELECT si.*, s.name as school_name, s.admin_email
        FROM school_invoices si
        JOIN schools s ON si.school_id = s.id
        WHERE si.status = 'overdue'
        AND si.due_date = CURRENT_DATE - INTERVAL '7 days'
    LOOP
        PERFORM send_subscription_notification(
            v_invoice.school_id,
            'payment_overdue',
            JSONB_BUILD_OBJECT(
                'invoice_number', v_invoice.invoice_number,
                'due_date', v_invoice.due_date,
                'amount', v_invoice.total_amount
            )
        );
        
        v_reminder_count := v_reminder_count + 1;
    END LOOP;
    
    RETURN JSONB_BUILD_OBJECT(
        'invoices_marked_overdue', v_overdue_count,
        'overdue_reminders_sent', v_reminder_count,
        'processed_at', NOW()
    );
END;
$$;

-- 4. Function to suspend services for non-payment
CREATE OR REPLACE FUNCTION suspend_services_for_non_payment()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_school RECORD;
    v_suspended_count INTEGER := 0;
BEGIN
    -- Suspend schools with invoices overdue by more than 30 days
    FOR v_school IN 
        SELECT DISTINCT s.id, s.name
        FROM schools s
        JOIN school_invoices si ON s.id = si.school_id
        WHERE si.status = 'overdue'
        AND si.due_date < CURRENT_DATE - INTERVAL '30 days'
        AND s.status = 'active'
    LOOP
        -- Update school status to suspended
        UPDATE schools
        SET status = 'suspended', suspension_reason = 'non_payment', updated_at = NOW()
        WHERE id = v_school.id;
        
        -- Send suspension notification
        PERFORM send_subscription_notification(
            v_school.id,
            'service_suspended',
            JSONB_BUILD_OBJECT('reason', 'non_payment')
        );
        
        v_suspended_count := v_suspended_count + 1;
    END LOOP;
    
    RETURN JSONB_BUILD_OBJECT(
        'schools_suspended', v_suspended_count,
        'processed_at', NOW()
    );
END;
$$;

-- 5. Grant execute permissions
GRANT EXECUTE ON FUNCTION process_daily_subscription_billing() TO authenticated;
GRANT EXECUTE ON FUNCTION send_subscription_notification(UUID, TEXT, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION process_overdue_invoices() TO authenticated;
GRANT EXECUTE ON FUNCTION suspend_services_for_non_payment() TO authenticated;

-- 6. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_school_subscriptions_next_billing 
    ON school_subscriptions(next_billing_date) 
    WHERE status = 'active' AND auto_renew = true;

CREATE INDEX IF NOT EXISTS idx_school_subscriptions_end_date 
    ON school_subscriptions(end_date) 
    WHERE status = 'active';

CREATE INDEX IF NOT EXISTS idx_school_invoices_due_date 
    ON school_invoices(due_date) 
    WHERE status = 'unpaid';

CREATE INDEX IF NOT EXISTS idx_school_invoices_overdue 
    ON school_invoices(due_date) 
    WHERE status = 'overdue';

-- ============================================================
-- CRON JOB CONFIGURATION
-- ============================================================

-- Note: These cron jobs should be configured in Supabase Dashboard > Database > Functions
-- or via pg_cron extension if available

-- Daily billing processing (runs at 2:00 AM daily)
-- SELECT cron.schedule('process-daily-billing', '0 2 * * *', 
--   'SELECT process_daily_subscription_billing();');

-- Overdue invoice processing (runs at 3:00 AM daily)  
-- SELECT cron.schedule('process-overdue-invoices', '0 3 * * *',
--   'SELECT process_overdue_invoices();');

-- Non-payment suspension (runs at 4:00 AM daily)
-- SELECT cron.schedule('suspend-non-payment', '0 4 * * *',
--   'SELECT suspend_services_for_non_payment();');

-- ============================================================
-- MANUAL EXECUTION FOR TESTING
-- ============================================================

-- To test the functions manually:
-- SELECT process_daily_subscription_billing();
-- SELECT process_overdue_invoices();
-- SELECT suspend_services_for_non_payment();