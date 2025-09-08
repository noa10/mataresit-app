-- Notification Preferences Migration
-- Adds comprehensive notification preferences system for users

-- Create notification preferences table
CREATE TABLE IF NOT EXISTS public.notification_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  
  -- Email notification preferences
  email_enabled BOOLEAN DEFAULT true,
  email_receipt_processing_started BOOLEAN DEFAULT false,
  email_receipt_processing_completed BOOLEAN DEFAULT true,
  email_receipt_processing_failed BOOLEAN DEFAULT true,
  email_receipt_ready_for_review BOOLEAN DEFAULT false,
  email_receipt_batch_completed BOOLEAN DEFAULT true,
  email_receipt_batch_failed BOOLEAN DEFAULT true,
  email_receipt_shared BOOLEAN DEFAULT false,
  email_receipt_comment_added BOOLEAN DEFAULT false,
  email_receipt_edited_by_team_member BOOLEAN DEFAULT false,
  email_receipt_approved_by_team BOOLEAN DEFAULT false,
  email_receipt_flagged_for_review BOOLEAN DEFAULT false,
  email_team_invitation_sent BOOLEAN DEFAULT true,
  email_team_invitation_accepted BOOLEAN DEFAULT true,
  email_team_member_joined BOOLEAN DEFAULT false,
  email_team_member_left BOOLEAN DEFAULT false,
  email_team_member_removed BOOLEAN DEFAULT true,
  email_team_member_role_changed BOOLEAN DEFAULT true,
  email_team_settings_updated BOOLEAN DEFAULT false,
  email_claim_submitted BOOLEAN DEFAULT true,
  email_claim_approved BOOLEAN DEFAULT true,
  email_claim_rejected BOOLEAN DEFAULT true,
  email_claim_review_requested BOOLEAN DEFAULT true,
  
  -- Push notification preferences
  push_enabled BOOLEAN DEFAULT true,
  push_receipt_processing_started BOOLEAN DEFAULT true,
  push_receipt_processing_completed BOOLEAN DEFAULT true,
  push_receipt_processing_failed BOOLEAN DEFAULT true,
  push_receipt_ready_for_review BOOLEAN DEFAULT true,
  push_receipt_batch_completed BOOLEAN DEFAULT true,
  push_receipt_batch_failed BOOLEAN DEFAULT true,
  push_receipt_shared BOOLEAN DEFAULT true,
  push_receipt_comment_added BOOLEAN DEFAULT true,
  push_receipt_edited_by_team_member BOOLEAN DEFAULT true,
  push_receipt_approved_by_team BOOLEAN DEFAULT true,
  push_receipt_flagged_for_review BOOLEAN DEFAULT true,
  push_team_invitation_sent BOOLEAN DEFAULT true,
  push_team_invitation_accepted BOOLEAN DEFAULT true,
  push_team_member_joined BOOLEAN DEFAULT true,
  push_team_member_left BOOLEAN DEFAULT false,
  push_team_member_removed BOOLEAN DEFAULT true,
  push_team_member_role_changed BOOLEAN DEFAULT true,
  push_team_settings_updated BOOLEAN DEFAULT false,
  push_claim_submitted BOOLEAN DEFAULT true,
  push_claim_approved BOOLEAN DEFAULT true,
  push_claim_rejected BOOLEAN DEFAULT true,
  push_claim_review_requested BOOLEAN DEFAULT true,
  
  -- Browser notification preferences
  browser_permission_granted BOOLEAN DEFAULT false,
  browser_permission_requested_at TIMESTAMP WITH TIME ZONE,
  
  -- Notification timing preferences
  quiet_hours_enabled BOOLEAN DEFAULT false,
  quiet_hours_start TIME, -- HH:MM format
  quiet_hours_end TIME, -- HH:MM format
  timezone TEXT DEFAULT 'Asia/Kuala_Lumpur',
  
  -- Digest preferences
  daily_digest_enabled BOOLEAN DEFAULT false,
  weekly_digest_enabled BOOLEAN DEFAULT false,
  digest_time TIME DEFAULT '09:00', -- HH:MM format
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Ensure one preference record per user
  UNIQUE(user_id)
);

-- Enable RLS
ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own notification preferences" ON public.notification_preferences
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can update their own notification preferences" ON public.notification_preferences
  FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own notification preferences" ON public.notification_preferences
  FOR INSERT WITH CHECK (user_id = auth.uid());

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_notification_preferences_user_id ON public.notification_preferences(user_id);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_notification_preferences_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER notification_preferences_updated_at_trigger
  BEFORE UPDATE ON public.notification_preferences
  FOR EACH ROW
  EXECUTE FUNCTION update_notification_preferences_updated_at();

-- Function to get user notification preferences with defaults
CREATE OR REPLACE FUNCTION public.get_user_notification_preferences(_user_id UUID)
RETURNS TABLE(
  id UUID,
  user_id UUID,
  email_enabled BOOLEAN,
  email_receipt_processing_started BOOLEAN,
  email_receipt_processing_completed BOOLEAN,
  email_receipt_processing_failed BOOLEAN,
  email_receipt_ready_for_review BOOLEAN,
  email_receipt_batch_completed BOOLEAN,
  email_receipt_batch_failed BOOLEAN,
  email_receipt_shared BOOLEAN,
  email_receipt_comment_added BOOLEAN,
  email_receipt_edited_by_team_member BOOLEAN,
  email_receipt_approved_by_team BOOLEAN,
  email_receipt_flagged_for_review BOOLEAN,
  email_team_invitation_sent BOOLEAN,
  email_team_invitation_accepted BOOLEAN,
  email_team_member_joined BOOLEAN,
  email_team_member_left BOOLEAN,
  email_team_member_removed BOOLEAN,
  email_team_member_role_changed BOOLEAN,
  email_team_settings_updated BOOLEAN,
  email_claim_submitted BOOLEAN,
  email_claim_approved BOOLEAN,
  email_claim_rejected BOOLEAN,
  email_claim_review_requested BOOLEAN,
  push_enabled BOOLEAN,
  push_receipt_processing_started BOOLEAN,
  push_receipt_processing_completed BOOLEAN,
  push_receipt_processing_failed BOOLEAN,
  push_receipt_ready_for_review BOOLEAN,
  push_receipt_batch_completed BOOLEAN,
  push_receipt_batch_failed BOOLEAN,
  push_receipt_shared BOOLEAN,
  push_receipt_comment_added BOOLEAN,
  push_receipt_edited_by_team_member BOOLEAN,
  push_receipt_approved_by_team BOOLEAN,
  push_receipt_flagged_for_review BOOLEAN,
  push_team_invitation_sent BOOLEAN,
  push_team_invitation_accepted BOOLEAN,
  push_team_member_joined BOOLEAN,
  push_team_member_left BOOLEAN,
  push_team_member_removed BOOLEAN,
  push_team_member_role_changed BOOLEAN,
  push_team_settings_updated BOOLEAN,
  push_claim_submitted BOOLEAN,
  push_claim_approved BOOLEAN,
  push_claim_rejected BOOLEAN,
  push_claim_review_requested BOOLEAN,
  browser_permission_granted BOOLEAN,
  browser_permission_requested_at TIMESTAMP WITH TIME ZONE,
  quiet_hours_enabled BOOLEAN,
  quiet_hours_start TIME,
  quiet_hours_end TIME,
  timezone TEXT,
  daily_digest_enabled BOOLEAN,
  weekly_digest_enabled BOOLEAN,
  digest_time TIME,
  created_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE sql
STABLE SECURITY DEFINER
AS $function$
  SELECT
    COALESCE(np.id, gen_random_uuid()) as id,
    _user_id as user_id,
    COALESCE(np.email_enabled, true) as email_enabled,
    COALESCE(np.email_receipt_processing_started, false) as email_receipt_processing_started,
    COALESCE(np.email_receipt_processing_completed, true) as email_receipt_processing_completed,
    COALESCE(np.email_receipt_processing_failed, true) as email_receipt_processing_failed,
    COALESCE(np.email_receipt_ready_for_review, false) as email_receipt_ready_for_review,
    COALESCE(np.email_receipt_batch_completed, true) as email_receipt_batch_completed,
    COALESCE(np.email_receipt_batch_failed, true) as email_receipt_batch_failed,
    COALESCE(np.email_receipt_shared, false) as email_receipt_shared,
    COALESCE(np.email_receipt_comment_added, false) as email_receipt_comment_added,
    COALESCE(np.email_receipt_edited_by_team_member, false) as email_receipt_edited_by_team_member,
    COALESCE(np.email_receipt_approved_by_team, false) as email_receipt_approved_by_team,
    COALESCE(np.email_receipt_flagged_for_review, false) as email_receipt_flagged_for_review,
    COALESCE(np.email_team_invitation_sent, true) as email_team_invitation_sent,
    COALESCE(np.email_team_invitation_accepted, true) as email_team_invitation_accepted,
    COALESCE(np.email_team_member_joined, false) as email_team_member_joined,
    COALESCE(np.email_team_member_left, false) as email_team_member_left,
    COALESCE(np.email_team_member_removed, true) as email_team_member_removed,
    COALESCE(np.email_team_member_role_changed, true) as email_team_member_role_changed,
    COALESCE(np.email_team_settings_updated, false) as email_team_settings_updated,
    COALESCE(np.email_claim_submitted, true) as email_claim_submitted,
    COALESCE(np.email_claim_approved, true) as email_claim_approved,
    COALESCE(np.email_claim_rejected, true) as email_claim_rejected,
    COALESCE(np.email_claim_review_requested, true) as email_claim_review_requested,
    COALESCE(np.push_enabled, true) as push_enabled,
    COALESCE(np.push_receipt_processing_started, true) as push_receipt_processing_started,
    COALESCE(np.push_receipt_processing_completed, true) as push_receipt_processing_completed,
    COALESCE(np.push_receipt_processing_failed, true) as push_receipt_processing_failed,
    COALESCE(np.push_receipt_ready_for_review, true) as push_receipt_ready_for_review,
    COALESCE(np.push_receipt_batch_completed, true) as push_receipt_batch_completed,
    COALESCE(np.push_receipt_batch_failed, true) as push_receipt_batch_failed,
    COALESCE(np.push_receipt_shared, true) as push_receipt_shared,
    COALESCE(np.push_receipt_comment_added, true) as push_receipt_comment_added,
    COALESCE(np.push_receipt_edited_by_team_member, true) as push_receipt_edited_by_team_member,
    COALESCE(np.push_receipt_approved_by_team, true) as push_receipt_approved_by_team,
    COALESCE(np.push_receipt_flagged_for_review, true) as push_receipt_flagged_for_review,
    COALESCE(np.push_team_invitation_sent, true) as push_team_invitation_sent,
    COALESCE(np.push_team_invitation_accepted, true) as push_team_invitation_accepted,
    COALESCE(np.push_team_member_joined, true) as push_team_member_joined,
    COALESCE(np.push_team_member_left, false) as push_team_member_left,
    COALESCE(np.push_team_member_removed, true) as push_team_member_removed,
    COALESCE(np.push_team_member_role_changed, true) as push_team_member_role_changed,
    COALESCE(np.push_team_settings_updated, false) as push_team_settings_updated,
    COALESCE(np.push_claim_submitted, true) as push_claim_submitted,
    COALESCE(np.push_claim_approved, true) as push_claim_approved,
    COALESCE(np.push_claim_rejected, true) as push_claim_rejected,
    COALESCE(np.push_claim_review_requested, true) as push_claim_review_requested,
    COALESCE(np.browser_permission_granted, false) as browser_permission_granted,
    np.browser_permission_requested_at,
    COALESCE(np.quiet_hours_enabled, false) as quiet_hours_enabled,
    np.quiet_hours_start,
    np.quiet_hours_end,
    COALESCE(np.timezone, 'Asia/Kuala_Lumpur') as timezone,
    COALESCE(np.daily_digest_enabled, false) as daily_digest_enabled,
    COALESCE(np.weekly_digest_enabled, false) as weekly_digest_enabled,
    COALESCE(np.digest_time, '09:00'::TIME) as digest_time,
    COALESCE(np.created_at, NOW()) as created_at,
    COALESCE(np.updated_at, NOW()) as updated_at
  FROM (SELECT _user_id) u
  LEFT JOIN public.notification_preferences np ON np.user_id = _user_id;
$function$;

-- Function to upsert user notification preferences
CREATE OR REPLACE FUNCTION public.upsert_notification_preferences(
  _user_id UUID,
  _preferences JSONB
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  _result_id UUID;
BEGIN
  INSERT INTO public.notification_preferences (
    user_id,
    email_enabled,
    email_receipt_processing_started,
    email_receipt_processing_completed,
    email_receipt_processing_failed,
    email_receipt_ready_for_review,
    email_receipt_batch_completed,
    email_receipt_batch_failed,
    email_receipt_shared,
    email_receipt_comment_added,
    email_receipt_edited_by_team_member,
    email_receipt_approved_by_team,
    email_receipt_flagged_for_review,
    email_team_invitation_sent,
    email_team_invitation_accepted,
    email_team_member_joined,
    email_team_member_left,
    email_team_member_removed,
    email_team_member_role_changed,
    email_team_settings_updated,
    email_claim_submitted,
    email_claim_approved,
    email_claim_rejected,
    email_claim_review_requested,
    push_enabled,
    push_receipt_processing_started,
    push_receipt_processing_completed,
    push_receipt_processing_failed,
    push_receipt_ready_for_review,
    push_receipt_batch_completed,
    push_receipt_batch_failed,
    push_receipt_shared,
    push_receipt_comment_added,
    push_receipt_edited_by_team_member,
    push_receipt_approved_by_team,
    push_receipt_flagged_for_review,
    push_team_invitation_sent,
    push_team_invitation_accepted,
    push_team_member_joined,
    push_team_member_left,
    push_team_member_removed,
    push_team_member_role_changed,
    push_team_settings_updated,
    push_claim_submitted,
    push_claim_approved,
    push_claim_rejected,
    push_claim_review_requested,
    browser_permission_granted,
    browser_permission_requested_at,
    quiet_hours_enabled,
    quiet_hours_start,
    quiet_hours_end,
    timezone,
    daily_digest_enabled,
    weekly_digest_enabled,
    digest_time
  ) VALUES (
    _user_id,
    COALESCE((_preferences->>'email_enabled')::boolean, true),
    COALESCE((_preferences->>'email_receipt_processing_started')::boolean, false),
    COALESCE((_preferences->>'email_receipt_processing_completed')::boolean, true),
    COALESCE((_preferences->>'email_receipt_processing_failed')::boolean, true),
    COALESCE((_preferences->>'email_receipt_ready_for_review')::boolean, false),
    COALESCE((_preferences->>'email_receipt_batch_completed')::boolean, true),
    COALESCE((_preferences->>'email_receipt_batch_failed')::boolean, true),
    COALESCE((_preferences->>'email_receipt_shared')::boolean, false),
    COALESCE((_preferences->>'email_receipt_comment_added')::boolean, false),
    COALESCE((_preferences->>'email_receipt_edited_by_team_member')::boolean, false),
    COALESCE((_preferences->>'email_receipt_approved_by_team')::boolean, false),
    COALESCE((_preferences->>'email_receipt_flagged_for_review')::boolean, false),
    COALESCE((_preferences->>'email_team_invitation_sent')::boolean, true),
    COALESCE((_preferences->>'email_team_invitation_accepted')::boolean, true),
    COALESCE((_preferences->>'email_team_member_joined')::boolean, false),
    COALESCE((_preferences->>'email_team_member_left')::boolean, false),
    COALESCE((_preferences->>'email_team_member_removed')::boolean, true),
    COALESCE((_preferences->>'email_team_member_role_changed')::boolean, true),
    COALESCE((_preferences->>'email_team_settings_updated')::boolean, false),
    COALESCE((_preferences->>'email_claim_submitted')::boolean, true),
    COALESCE((_preferences->>'email_claim_approved')::boolean, true),
    COALESCE((_preferences->>'email_claim_rejected')::boolean, true),
    COALESCE((_preferences->>'email_claim_review_requested')::boolean, true),
    COALESCE((_preferences->>'push_enabled')::boolean, true),
    COALESCE((_preferences->>'push_receipt_processing_started')::boolean, true),
    COALESCE((_preferences->>'push_receipt_processing_completed')::boolean, true),
    COALESCE((_preferences->>'push_receipt_processing_failed')::boolean, true),
    COALESCE((_preferences->>'push_receipt_ready_for_review')::boolean, true),
    COALESCE((_preferences->>'push_receipt_batch_completed')::boolean, true),
    COALESCE((_preferences->>'push_receipt_batch_failed')::boolean, true),
    COALESCE((_preferences->>'push_receipt_shared')::boolean, true),
    COALESCE((_preferences->>'push_receipt_comment_added')::boolean, true),
    COALESCE((_preferences->>'push_receipt_edited_by_team_member')::boolean, true),
    COALESCE((_preferences->>'push_receipt_approved_by_team')::boolean, true),
    COALESCE((_preferences->>'push_receipt_flagged_for_review')::boolean, true),
    COALESCE((_preferences->>'push_team_invitation_sent')::boolean, true),
    COALESCE((_preferences->>'push_team_invitation_accepted')::boolean, true),
    COALESCE((_preferences->>'push_team_member_joined')::boolean, true),
    COALESCE((_preferences->>'push_team_member_left')::boolean, false),
    COALESCE((_preferences->>'push_team_member_removed')::boolean, true),
    COALESCE((_preferences->>'push_team_member_role_changed')::boolean, true),
    COALESCE((_preferences->>'push_team_settings_updated')::boolean, false),
    COALESCE((_preferences->>'push_claim_submitted')::boolean, true),
    COALESCE((_preferences->>'push_claim_approved')::boolean, true),
    COALESCE((_preferences->>'push_claim_rejected')::boolean, true),
    COALESCE((_preferences->>'push_claim_review_requested')::boolean, true),
    COALESCE((_preferences->>'browser_permission_granted')::boolean, false),
    CASE WHEN _preferences->>'browser_permission_requested_at' IS NOT NULL
         THEN (_preferences->>'browser_permission_requested_at')::timestamp with time zone
         ELSE NULL END,
    COALESCE((_preferences->>'quiet_hours_enabled')::boolean, false),
    CASE WHEN _preferences->>'quiet_hours_start' IS NOT NULL
         THEN (_preferences->>'quiet_hours_start')::time
         ELSE NULL END,
    CASE WHEN _preferences->>'quiet_hours_end' IS NOT NULL
         THEN (_preferences->>'quiet_hours_end')::time
         ELSE NULL END,
    COALESCE(_preferences->>'timezone', 'Asia/Kuala_Lumpur'),
    COALESCE((_preferences->>'daily_digest_enabled')::boolean, false),
    COALESCE((_preferences->>'weekly_digest_enabled')::boolean, false),
    CASE WHEN _preferences->>'digest_time' IS NOT NULL
         THEN (_preferences->>'digest_time')::time
         ELSE '09:00'::time END
  ) ON CONFLICT (user_id) DO UPDATE SET
    email_enabled = COALESCE((_preferences->>'email_enabled')::boolean, EXCLUDED.email_enabled),
    email_receipt_processing_started = COALESCE((_preferences->>'email_receipt_processing_started')::boolean, EXCLUDED.email_receipt_processing_started),
    email_receipt_processing_completed = COALESCE((_preferences->>'email_receipt_processing_completed')::boolean, EXCLUDED.email_receipt_processing_completed),
    email_receipt_processing_failed = COALESCE((_preferences->>'email_receipt_processing_failed')::boolean, EXCLUDED.email_receipt_processing_failed),
    email_receipt_ready_for_review = COALESCE((_preferences->>'email_receipt_ready_for_review')::boolean, EXCLUDED.email_receipt_ready_for_review),
    email_receipt_batch_completed = COALESCE((_preferences->>'email_receipt_batch_completed')::boolean, EXCLUDED.email_receipt_batch_completed),
    email_receipt_batch_failed = COALESCE((_preferences->>'email_receipt_batch_failed')::boolean, EXCLUDED.email_receipt_batch_failed),
    email_receipt_shared = COALESCE((_preferences->>'email_receipt_shared')::boolean, EXCLUDED.email_receipt_shared),
    email_receipt_comment_added = COALESCE((_preferences->>'email_receipt_comment_added')::boolean, EXCLUDED.email_receipt_comment_added),
    email_receipt_edited_by_team_member = COALESCE((_preferences->>'email_receipt_edited_by_team_member')::boolean, EXCLUDED.email_receipt_edited_by_team_member),
    email_receipt_approved_by_team = COALESCE((_preferences->>'email_receipt_approved_by_team')::boolean, EXCLUDED.email_receipt_approved_by_team),
    email_receipt_flagged_for_review = COALESCE((_preferences->>'email_receipt_flagged_for_review')::boolean, EXCLUDED.email_receipt_flagged_for_review),
    email_team_invitation_sent = COALESCE((_preferences->>'email_team_invitation_sent')::boolean, EXCLUDED.email_team_invitation_sent),
    email_team_invitation_accepted = COALESCE((_preferences->>'email_team_invitation_accepted')::boolean, EXCLUDED.email_team_invitation_accepted),
    email_team_member_joined = COALESCE((_preferences->>'email_team_member_joined')::boolean, EXCLUDED.email_team_member_joined),
    email_team_member_left = COALESCE((_preferences->>'email_team_member_left')::boolean, EXCLUDED.email_team_member_left),
    email_team_member_removed = COALESCE((_preferences->>'email_team_member_removed')::boolean, EXCLUDED.email_team_member_removed),
    email_team_member_role_changed = COALESCE((_preferences->>'email_team_member_role_changed')::boolean, EXCLUDED.email_team_member_role_changed),
    email_team_settings_updated = COALESCE((_preferences->>'email_team_settings_updated')::boolean, EXCLUDED.email_team_settings_updated),
    email_claim_submitted = COALESCE((_preferences->>'email_claim_submitted')::boolean, EXCLUDED.email_claim_submitted),
    email_claim_approved = COALESCE((_preferences->>'email_claim_approved')::boolean, EXCLUDED.email_claim_approved),
    email_claim_rejected = COALESCE((_preferences->>'email_claim_rejected')::boolean, EXCLUDED.email_claim_rejected),
    email_claim_review_requested = COALESCE((_preferences->>'email_claim_review_requested')::boolean, EXCLUDED.email_claim_review_requested),
    push_enabled = COALESCE((_preferences->>'push_enabled')::boolean, EXCLUDED.push_enabled),
    push_receipt_processing_started = COALESCE((_preferences->>'push_receipt_processing_started')::boolean, EXCLUDED.push_receipt_processing_started),
    push_receipt_processing_completed = COALESCE((_preferences->>'push_receipt_processing_completed')::boolean, EXCLUDED.push_receipt_processing_completed),
    push_receipt_processing_failed = COALESCE((_preferences->>'push_receipt_processing_failed')::boolean, EXCLUDED.push_receipt_processing_failed),
    push_receipt_ready_for_review = COALESCE((_preferences->>'push_receipt_ready_for_review')::boolean, EXCLUDED.push_receipt_ready_for_review),
    push_receipt_batch_completed = COALESCE((_preferences->>'push_receipt_batch_completed')::boolean, EXCLUDED.push_receipt_batch_completed),
    push_receipt_batch_failed = COALESCE((_preferences->>'push_receipt_batch_failed')::boolean, EXCLUDED.push_receipt_batch_failed),
    push_receipt_shared = COALESCE((_preferences->>'push_receipt_shared')::boolean, EXCLUDED.push_receipt_shared),
    push_receipt_comment_added = COALESCE((_preferences->>'push_receipt_comment_added')::boolean, EXCLUDED.push_receipt_comment_added),
    push_receipt_edited_by_team_member = COALESCE((_preferences->>'push_receipt_edited_by_team_member')::boolean, EXCLUDED.push_receipt_edited_by_team_member),
    push_receipt_approved_by_team = COALESCE((_preferences->>'push_receipt_approved_by_team')::boolean, EXCLUDED.push_receipt_approved_by_team),
    push_receipt_flagged_for_review = COALESCE((_preferences->>'push_receipt_flagged_for_review')::boolean, EXCLUDED.push_receipt_flagged_for_review),
    push_team_invitation_sent = COALESCE((_preferences->>'push_team_invitation_sent')::boolean, EXCLUDED.push_team_invitation_sent),
    push_team_invitation_accepted = COALESCE((_preferences->>'push_team_invitation_accepted')::boolean, EXCLUDED.push_team_invitation_accepted),
    push_team_member_joined = COALESCE((_preferences->>'push_team_member_joined')::boolean, EXCLUDED.push_team_member_joined),
    push_team_member_left = COALESCE((_preferences->>'push_team_member_left')::boolean, EXCLUDED.push_team_member_left),
    push_team_member_removed = COALESCE((_preferences->>'push_team_member_removed')::boolean, EXCLUDED.push_team_member_removed),
    push_team_member_role_changed = COALESCE((_preferences->>'push_team_member_role_changed')::boolean, EXCLUDED.push_team_member_role_changed),
    push_team_settings_updated = COALESCE((_preferences->>'push_team_settings_updated')::boolean, EXCLUDED.push_team_settings_updated),
    push_claim_submitted = COALESCE((_preferences->>'push_claim_submitted')::boolean, EXCLUDED.push_claim_submitted),
    push_claim_approved = COALESCE((_preferences->>'push_claim_approved')::boolean, EXCLUDED.push_claim_approved),
    push_claim_rejected = COALESCE((_preferences->>'push_claim_rejected')::boolean, EXCLUDED.push_claim_rejected),
    push_claim_review_requested = COALESCE((_preferences->>'push_claim_review_requested')::boolean, EXCLUDED.push_claim_review_requested),
    browser_permission_granted = COALESCE((_preferences->>'browser_permission_granted')::boolean, EXCLUDED.browser_permission_granted),
    browser_permission_requested_at = CASE WHEN _preferences->>'browser_permission_requested_at' IS NOT NULL
                                           THEN (_preferences->>'browser_permission_requested_at')::timestamp with time zone
                                           ELSE EXCLUDED.browser_permission_requested_at END,
    quiet_hours_enabled = COALESCE((_preferences->>'quiet_hours_enabled')::boolean, EXCLUDED.quiet_hours_enabled),
    quiet_hours_start = CASE WHEN _preferences->>'quiet_hours_start' IS NOT NULL
                             THEN (_preferences->>'quiet_hours_start')::time
                             ELSE EXCLUDED.quiet_hours_start END,
    quiet_hours_end = CASE WHEN _preferences->>'quiet_hours_end' IS NOT NULL
                           THEN (_preferences->>'quiet_hours_end')::time
                           ELSE EXCLUDED.quiet_hours_end END,
    timezone = COALESCE(_preferences->>'timezone', EXCLUDED.timezone),
    daily_digest_enabled = COALESCE((_preferences->>'daily_digest_enabled')::boolean, EXCLUDED.daily_digest_enabled),
    weekly_digest_enabled = COALESCE((_preferences->>'weekly_digest_enabled')::boolean, EXCLUDED.weekly_digest_enabled),
    digest_time = CASE WHEN _preferences->>'digest_time' IS NOT NULL
                       THEN (_preferences->>'digest_time')::time
                       ELSE EXCLUDED.digest_time END,
    updated_at = NOW()
  RETURNING id INTO _result_id;

  RETURN _result_id;
END;
$function$;

-- Grant necessary permissions
GRANT ALL ON public.notification_preferences TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_notification_preferences(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.upsert_notification_preferences(UUID, JSONB) TO authenticated;
