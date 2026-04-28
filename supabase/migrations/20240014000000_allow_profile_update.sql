-- Add policy to allow users to update their own "must_change_password" status
CREATE POLICY "Users can update their own profile must_change_password" ON user_profiles
FOR UPDATE TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());
