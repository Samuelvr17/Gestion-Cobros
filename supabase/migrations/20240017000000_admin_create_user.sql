-- Create function to create a user for admin
CREATE OR REPLACE FUNCTION public.admin_create_user(
  p_email TEXT,
  p_password TEXT,
  p_full_name TEXT,
  p_phone TEXT,
  p_cedula TEXT,
  p_role_id UUID
) RETURNS JSON AS $$
DECLARE v_user_id UUID; v_result JSON;
BEGIN
  v_user_id := gen_random_uuid();
  INSERT INTO auth.users (
    id, instance_id, email, encrypted_password,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at, role,
    confirmation_token, email_change, 
    email_change_token_new, recovery_token
  ) VALUES (
    v_user_id, '00000000-0000-0000-0000-000000000000',
    p_email,
    extensions.crypt(p_password, extensions.gen_salt('bf')),
    NOW(),
    '{"provider":"email","providers":["email"]}',
    jsonb_build_object('full_name', p_full_name, 
      'phone', p_phone, 'cedula', p_cedula,
      'role_id', p_role_id),
    NOW(), NOW(), 'authenticated',
    '', '', '', ''
  );
  SELECT row_to_json(up) INTO v_result 
  FROM user_profiles up WHERE id = v_user_id;
  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
