-- Migration to create an initial admin user
-- Run this in your Supabase SQL Editor

-- Ensure pgcrypto is available
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

DO $$
DECLARE
    v_user_id UUID := gen_random_uuid();
    v_role_id UUID;
BEGIN
    -- 1. Get Admin Role ID
    SELECT id INTO v_role_id FROM public.roles WHERE name = 'admin';

    IF v_role_id IS NULL THEN
        RAISE EXCEPTION 'Role "admin" not found. Please run initial seeds first.';
    END IF;

    -- 2. Create User in auth.users if not exists
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'admin@gestion.com') THEN
        INSERT INTO auth.users (
            id,
            instance_id,
            email,
            encrypted_password,
            email_confirmed_at,
            raw_app_meta_data,
            raw_user_meta_data,
            created_at,
            updated_at,
            role,
            confirmation_token,
            email_change,
            email_change_token_new,
            recovery_token
        )
        VALUES (
            v_user_id,
            '00000000-0000-0000-0000-000000000000',
            'admin@gestion.com',
            extensions.crypt('Admin123!', extensions.gen_salt('bf')),
            NOW(),
            '{"provider":"email","providers":["email"]}',
            jsonb_build_object(
                'full_name', 'Administrador de Pruebas',
                'role_id', v_role_id,
                'cedula', '1234567890',
                'phone', '3000000000'
            ),
            NOW(),
            NOW(),
            'authenticated',
            '',
            '',
            '',
            ''
        );
    END IF;

    -- The handle_new_user() trigger will automatically create the user_profile.
END $$;
