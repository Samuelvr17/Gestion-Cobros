-- RPC to allow users to update only their own "must_change_password" status
-- This is more secure than a broad UPDATE RLS policy
CREATE OR REPLACE FUNCTION complete_password_change()
RETURNS void AS $$
BEGIN
    UPDATE user_profiles
    SET must_change_password = false
    WHERE id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
